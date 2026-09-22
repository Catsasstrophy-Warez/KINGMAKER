#!/usr/bin/env python3
"""Synthesize placeholder audio stems for the Kingmaker XR-13's audio bindings.

Audio was previously entirely unbuilt (Docs/PRODUCTION_CONTENT_HANDOFF.md: "Mix/state contracts
only" -- Sources/DHPresentation/Rev10AssetManifest.swift already lists audio bindings by filename,
but none of those files existed and there was no playback code at all).

These are procedurally synthesized placeholder stems (pure Python stdlib -- sine/noise waveform
synthesis via the `wave` module, no external audio libraries or recordings), not production sound
design. They exist so DHRev10AudioPlayer (Sources/DHPresentation/Rev10AudioPlayback.swift) has
real audio to play and the manifest's required-audio bindings actually resolve, matching the same
"replaceable blockout, not final art" posture as the Blender-generated visual assets.
"""
import math
import os
import random
import struct
import subprocess
import sys
import wave

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "../.."))
OUT = os.path.join(ROOT, "Sources", "DHPresentation", "Resources")
if "--output-dir" in sys.argv:
    OUT = os.path.abspath(sys.argv[sys.argv.index("--output-dir") + 1])
os.makedirs(OUT, exist_ok=True)

SAMPLE_RATE = 22050
random.seed(13)


def write_wav(path, samples):
    with wave.open(path, "w") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SAMPLE_RATE)
        frames = b"".join(struct.pack("<h", max(-32767, min(32767, int(s * 32767)))) for s in samples)
        f.writeframes(frames)


def fade(samples, in_s=0.02, out_s=0.05):
    n_in = int(in_s * SAMPLE_RATE)
    n_out = int(out_s * SAMPLE_RATE)
    out = list(samples)
    for i in range(min(n_in, len(out))):
        out[i] *= i / n_in
    for i in range(min(n_out, len(out))):
        out[-(i + 1)] *= i / n_out
    return out


def engine_rumble(duration, base_freq, harmonics, noise_amount):
    n = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        v = 0.0
        for k, amp in enumerate(harmonics, start=1):
            v += amp * math.sin(2 * math.pi * base_freq * k * t)
        v += noise_amount * (random.random() * 2 - 1)
        samples.append(v * 0.5)
    return samples


def whine(duration, base_freq, sweep):
    n = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        freq = base_freq + sweep * (t / duration)
        samples.append(0.35 * math.sin(2 * math.pi * freq * t))
    return samples


def clunk(duration):
    n = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        decay = math.exp(-t * 18)
        v = decay * (0.6 * math.sin(2 * math.pi * 90 * t) + 0.4 * (random.random() * 2 - 1))
        samples.append(v)
    return samples


def static_burst(duration):
    n = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        envelope = 0.5 + 0.5 * math.sin(2 * math.pi * 3 * t)
        samples.append(envelope * (random.random() * 2 - 1) * 0.4)
    return samples


stems = {
    "XR13_Exhaust_Loop.wav": fade(engine_rumble(2.0, 42, [1.0, 0.5, 0.3, 0.15], 0.08)),
    "XR13_Valvetrain_Loop.wav": fade(engine_rumble(1.0, 110, [0.6, 0.4, 0.5, 0.2], 0.15)),
    "XR13_Supercharger_Loop.wav": fade(whine(1.5, 220, 40)),
    "XR13_DCT_Shift.wav": fade(clunk(0.4), in_s=0.001, out_s=0.1),
}

for name, samples in stems.items():
    path = os.path.join(OUT, name)
    write_wav(path, samples)
    print("WROTE", path, len(samples), "samples")

# Radio_Consequences is declared as .m4a in the manifest; synthesize the source as WAV then
# transcode with afconvert (built into macOS) since the `wave` module can't write AAC directly.
radio_wav = os.path.join(OUT, "_radio_tmp.wav")
write_wav(radio_wav, fade(static_burst(1.2), in_s=0.05, out_s=0.15))
radio_m4a = os.path.join(OUT, "Radio_Consequences.m4a")
try:
    subprocess.run(["afconvert", "-f", "m4af", "-d", "aac", radio_wav, radio_m4a], check=True)
    print("WROTE", radio_m4a)
except (FileNotFoundError, subprocess.CalledProcessError) as e:
    print("afconvert unavailable or failed (%s); leaving Radio_Consequences as WAV fallback" % e)
    os.replace(radio_wav, os.path.join(OUT, "Radio_Consequences.wav"))
finally:
    if os.path.exists(radio_wav):
        os.remove(radio_wav)
