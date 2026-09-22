#!/usr/bin/env python3
"""Generate the remaining manifest-bound assets that aren't meshes: a navmesh, two animation
clips, and a particle-FX definition.

Rev10AssetManifest.swift binds player.navmesh, player.interact, kingmaker.start, and combat.fx to
files that didn't exist. None of these are read by any Swift code yet (grep confirms no consumer
beyond the manifest/DHRev10ProductionContracts declaring the IDs) -- DHRev10AssetResolver only
checks that the file resolves, so these are deterministic placeholder data files in plain formats
(JSON for navmesh/anim, ASCII USD for the particle def), not another Blender mesh export, matching
their non-mesh asset kinds (.navmesh, .animation, .particle) in the manifest.
"""
import json
import math
import os
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "../.."))
OUT = os.path.join(ROOT, "Sources", "DHPresentation", "Resources")
if "--output-dir" in sys.argv:
    OUT = os.path.abspath(sys.argv[sys.argv.index("--output-dir") + 1])
os.makedirs(OUT, exist_ok=True)

# ---------- BlackridgeGarage.navmesh: walkable-floor polygons for the garage interior ----------
navmesh = {
    "chunkID": "chunk.garage",
    "units": "meters",
    "polygons": [
        {"id": "bay.main", "vertices": [[-4.5, -3.0], [4.5, -3.0], [4.5, 3.0], [-4.5, 3.0]]},
        {"id": "bay.aisle", "vertices": [[-4.5, -1.0], [4.5, -1.0], [4.5, 1.0], [-4.5, 1.0]]},
        {"id": "entry.apron", "vertices": [[4.5, -2.0], [7.0, -2.0], [7.0, 2.0], [4.5, 2.0]]},
    ],
    "connections": [{"from": "bay.main", "to": "bay.aisle"}, {"from": "bay.aisle", "to": "entry.apron"}],
}
navmesh_path = os.path.join(OUT, "BlackridgeGarage.navmesh")
with open(navmesh_path, "w") as f:
    json.dump(navmesh, f, indent=2)
print("WROTE", navmesh_path)


def keyframed_clip(name, duration_s, fps, tracks):
    frames = int(duration_s * fps)
    return {
        "name": name,
        "fps": fps,
        "durationSeconds": duration_s,
        "frameCount": frames,
        "tracks": tracks,
    }


def sine_track(bone, axis, amplitude_deg, cycles, frames, phase=0.0):
    return {
        "bone": bone,
        "axis": axis,
        "keyframes": [
            round(amplitude_deg * math.sin(2 * math.pi * cycles * (i / frames) + phase), 3)
            for i in range(frames + 1)
        ],
    }


# ---------- Player_Repair.anim: a short kneeling wrench-turning gesture ----------
repair_frames = 30
repair_clip = keyframed_clip(
    "Player_Repair", duration_s=1.25, fps=24,
    tracks=[
        sine_track("upperarm.R", "x", 22, cycles=3, frames=repair_frames),
        sine_track("forearm.R", "x", 35, cycles=3, frames=repair_frames, phase=math.pi / 4),
        sine_track("spine", "x", 8, cycles=1, frames=repair_frames),
    ],
)
repair_path = os.path.join(OUT, "Player_Repair.anim")
with open(repair_path, "w") as f:
    json.dump(repair_clip, f, indent=2)
print("WROTE", repair_path)

# ---------- Kingmaker_Start.anim: engine-crank shudder + idle settle ----------
start_frames = 48
start_clip = keyframed_clip(
    "Kingmaker_Start", duration_s=2.0, fps=24,
    tracks=[
        sine_track("chassis", "z", 0.015, cycles=6, frames=start_frames),
        sine_track("chassis", "x", 0.6, cycles=6, frames=start_frames, phase=math.pi / 3),
        sine_track("exhaustTip", "y", 1.2, cycles=6, frames=start_frames),
    ],
)
start_path = os.path.join(OUT, "Kingmaker_Start.anim")
with open(start_path, "w") as f:
    json.dump(start_clip, f, indent=2)
print("WROTE", start_path)

# ---------- VehicleCombat_FX.usda: ASCII USD particle-system definition ----------
combat_fx_usda = """#usda 1.0
(
    defaultPrim = "VehicleCombatFX"
    metersPerUnit = 1
    upAxis = "Y"
)

def Xform "VehicleCombatFX" (
    kind = "component"
)
{
    def Scope "MuzzleFlash"
    {
        custom float birthRate = 240
        custom float lifespan = 0.08
        custom color3f startColor = (1.0, 0.85, 0.3)
        custom color3f endColor = (0.4, 0.1, 0.0)
        custom float speed = 6.0
    }

    def Scope "SparkImpact"
    {
        custom float birthRate = 400
        custom float lifespan = 0.35
        custom color3f startColor = (1.0, 0.7, 0.2)
        custom color3f endColor = (0.2, 0.05, 0.0)
        custom float speed = 4.5
        custom float gravity = -9.8
    }

    def Scope "SmokeTrail"
    {
        custom float birthRate = 60
        custom float lifespan = 1.8
        custom color3f startColor = (0.3, 0.3, 0.3)
        custom color3f endColor = (0.05, 0.05, 0.05)
        custom float speed = 0.8
    }
}
"""
combat_fx_path = os.path.join(OUT, "VehicleCombat_FX.usda")
with open(combat_fx_path, "w") as f:
    f.write(combat_fx_usda)
print("WROTE", combat_fx_path)
