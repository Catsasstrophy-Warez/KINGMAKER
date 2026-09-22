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


def lowpass(samples, alpha=0.25):
    """One-pole low-pass smoothing. Raw additive-sine synthesis has hard, buzzy edges between
    harmonics; this softens them so a tone reads as filtered through metal/an exhaust pipe rather
    than a bare synth waveform. Lower alpha = more smoothing/darker tone."""
    out = []
    prev = 0.0
    for s in samples:
        prev = prev + alpha * (s - prev)
        out.append(prev)
    return out


def normalize(samples, peak=0.9):
    """Peak-normalize to a consistent target level. Previously every stem's loudness was whatever
    its synthesis function's amplitude constants happened to add up to -- some stems (e.g. the
    quiet Paradise_Negotiation murmur) were much quieter than others (e.g. Hostile_Attack) with no
    deliberate reason, and none were guaranteed not to clip. This is the mastering pass that was
    missing: every stem now hits the same real peak level."""
    peak_found = max((abs(s) for s in samples), default=0.0)
    if peak_found <= 1e-9:
        return samples
    scale = peak / peak_found
    return [s * scale for s in samples]


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


def engine_pulse_train(duration, firing_hz, harmonics, noise_amount, decay_rate=14):
    """A combustion-pulse model, not a sustained sine sum: real engine exhaust/valvetrain sound
    comes from discrete per-cylinder firing events (fast attack, exponential decay within each
    firing cycle), not a continuous tone. This keeps engine_rumble()'s harmonic-stack tonal color
    but multiplies it by a per-cycle firing envelope, so it reads as a "chugging" combustion
    texture instead of a synth pad -- the single biggest gap between the old stems and how a real
    engine actually sounds."""
    n = int(duration * SAMPLE_RATE)
    samples = []
    period = 1.0 / firing_hz
    for i in range(n):
        t = i / SAMPLE_RATE
        phase = (t % period) / period
        envelope = math.exp(-phase * decay_rate)
        v = 0.0
        for k, amp in enumerate(harmonics, start=1):
            v += amp * math.sin(2 * math.pi * firing_hz * k * t)
        v *= (0.4 + 0.6 * envelope)
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


def starter_crank(duration, cycle_hz=3.5):
    """Rhythmic starter-motor clunk-whine, the sound of the engine turning over before it catches."""
    n = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        cycle_phase = (t * cycle_hz) % 1.0
        pulse = 1.0 if cycle_phase < 0.35 else 0.0
        whine_v = 0.3 * math.sin(2 * math.pi * 80 * t) * pulse
        clank = (random.random() * 2 - 1) * 0.15 * pulse
        samples.append(whine_v + clank)
    return samples


def catch_and_settle(duration):
    """Engine catching: a rising whine that resolves into a steady idle rumble, now with the idle
    portion carrying a real per-cycle firing envelope (see engine_pulse_train) instead of settling
    into a flat sine, so the tail actually sounds like an idling engine, not a held tone."""
    n = int(duration * SAMPLE_RATE)
    samples = []
    idle_hz = 21.0
    period = 1.0 / idle_hz
    for i in range(n):
        t = i / SAMPLE_RATE
        catch_progress = min(1.0, t / (duration * 0.4))
        freq = 60 + 140 * catch_progress
        rumble = 0.5 * math.sin(2 * math.pi * freq * t)
        settle_progress = min(1.0, t / duration)
        phase = (t % period) / period
        firing_envelope = 0.5 + 0.5 * math.exp(-phase * 12)
        settle = 0.22 * math.sin(2 * math.pi * 42 * t) * firing_envelope * settle_progress
        noise = (random.random() * 2 - 1) * 0.06
        samples.append(rumble * (1 - catch_progress * 0.5) + settle + noise)
    return samples


def metal_knock(duration):
    """A single sharp metallic knock -- a fault/detonation cue, distinct from the softer clunk()."""
    n = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        decay = math.exp(-t * 40)
        v = decay * (0.7 * math.sin(2 * math.pi * 420 * t) + 0.3 * (random.random() * 2 - 1))
        samples.append(v)
    return samples


def chime(duration, base_freq, overtone_ratio=2.0):
    """A short bell-like tone for UI feedback (loot open/collect)."""
    n = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        decay = math.exp(-t * 6)
        v = decay * (0.6 * math.sin(2 * math.pi * base_freq * t) + 0.3 * math.sin(2 * math.pi * base_freq * overtone_ratio * t))
        samples.append(v)
    return samples


def tension_rise(duration):
    """A slow rising drone for a hostile-encounter telegraph cue."""
    n = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        freq = 55 + 25 * (t / duration)
        v = 0.4 * math.sin(2 * math.pi * freq * t) + 0.08 * (random.random() * 2 - 1)
        samples.append(v)
    return samples


def impact_burst(duration):
    """A short sharp impact for a hostile-attack hit cue -- noise burst layered over a low thud."""
    n = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        decay = math.exp(-t * 22)
        thud = decay * 0.6 * math.sin(2 * math.pi * 65 * t)
        noise = decay * 0.5 * (random.random() * 2 - 1)
        samples.append(thud + noise)
    return samples


def soft_murmur(duration):
    """A low ambient tone bed for the Paradise-negotiation dialogue cue (room tone, not dialogue)."""
    n = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        v = 0.15 * math.sin(2 * math.pi * 130 * t) + 0.08 * math.sin(2 * math.pi * 196 * t)
        v += 0.02 * (random.random() * 2 - 1)
        samples.append(v)
    return samples


# Exhaust/valvetrain now use engine_pulse_train's combustion-firing model instead of
# engine_rumble's sustained sine sum, and exhaust is low-pass filtered (muffled through a pipe)
# where valvetrain -- mechanical clatter under the hood, not muffled -- is left brighter.
stems = {
    "XR13_Exhaust_Loop.wav": lowpass(fade(engine_pulse_train(2.0, 42, [1.0, 0.5, 0.3, 0.15], 0.08)), alpha=0.35),
    "XR13_Valvetrain_Loop.wav": fade(engine_pulse_train(1.0, 110, [0.6, 0.4, 0.5, 0.2], 0.15, decay_rate=20)),
    "XR13_Supercharger_Loop.wav": fade(whine(1.5, 220, 40)),
    "XR13_DCT_Shift.wav": fade(clunk(0.4), in_s=0.001, out_s=0.1),
    "Kingmaker_Crank.wav": fade(starter_crank(1.6), in_s=0.01, out_s=0.05),
    "Kingmaker_EngineStart.wav": fade(catch_and_settle(1.8), in_s=0.01, out_s=0.1),
    "Kingmaker_EngineKnock.wav": fade(metal_knock(0.3), in_s=0.001, out_s=0.08),
    "Repair_ToolClink.wav": fade(clunk(0.25), in_s=0.001, out_s=0.06),
    "Loot_Open.wav": fade(chime(0.6, 440), in_s=0.001, out_s=0.1),
    "Loot_Collect.wav": fade(chime(0.35, 660, overtone_ratio=1.5), in_s=0.001, out_s=0.06),
    "Hostile_Telegraph.wav": fade(tension_rise(1.5), in_s=0.05, out_s=0.05),
    "Hostile_Attack.wav": fade(impact_burst(0.4), in_s=0.001, out_s=0.08),
    "Paradise_Negotiation.wav": fade(soft_murmur(1.6), in_s=0.1, out_s=0.15),
}

for name, samples in stems.items():
    path = os.path.join(OUT, name)
    write_wav(path, normalize(samples))
    print("WROTE", path, len(samples), "samples")

# Radio_Consequences is declared as .m4a in the manifest; synthesize the source as WAV then
# transcode with afconvert (built into macOS) since the `wave` module can't write AAC directly.
radio_wav = os.path.join(OUT, "_radio_tmp.wav")
write_wav(radio_wav, normalize(fade(static_burst(1.2), in_s=0.05, out_s=0.15)))
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

# radio.static: a shorter, un-transcoded static burst for the ambient/tuning cue (radioConsequence
# above is the "a broadcast just happened" one-shot; this is the idle scan/interference loop).
static_path = os.path.join(OUT, "Radio_Static.wav")
write_wav(static_path, normalize(fade(static_burst(0.9), in_s=0.02, out_s=0.1)))
print("WROTE", static_path)
