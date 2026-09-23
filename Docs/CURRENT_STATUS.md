# KINGMAKER Current Status

Updated: 2026-09-23

## Verified in this checkout

- Swift package tests: 287 tests currently execute successfully; the repository contains 289 test declarations including XCTest compatibility declarations.
- Production QA: resource coverage, USD readability, geometry budgets, semantic labels, audio containers, reconstruction contracts, environment-export contracts, and runtime source contracts.
- Runtime scope: garage → inspect → diagnose → scavenge → repair → start → drive → hostile encounter → radio consequence → Paradise → negotiate → recruit → save/reload.
- Asset scope: procedural/textured Kingmaker variants, garage, road, interiors, terrain, Raider, mannequin, navmesh, animation, audio, and particle bindings.
- Preview scope: native RealityKit capture is available through the `-visual-preview` launch argument; the output is `Docs/asset-previews/kingmaker-realitykit.png`.

## Not release-complete

- Hero-quality authored meshes, UVs, PBR materials, decals, damage sculpting, and final lighting.
- Production NPC and vehicle meshes, rigs, animation sets, and LODs.
- Recorded/licensed audio, voice, music, and mastered mix.
- Authored VFX textures/shaders and final combat presentation.
- Sustained frame-time, memory, thermal, accessibility, and physical-device validation.

## Current external risk

On the review host, Blender 5.2.2 can crash during Metal GPU backend initialization before Python startup. Safe export wrappers preserve the last validated USDZ assets when this happens. Kingmaker export can still succeed intermittently, but headless beauty rendering is not a reliable gate; native RealityKit capture is the current visual verification path.

## Authority rules

- `DHRev10VerticalSlice` is the authoritative gameplay beat and Kingmaker state for the app route.
- `DHRev10AssetManifest` is the authoritative runtime asset binding list.
- `Tools/production_qa.py` is the authoritative repository-side gate.
- `Docs/PRODUCTION_CONTENT_HANDOFF.md` is the authoritative boundary between code-complete blockouts and external production art.
- Historical revision reports retain their original counts and should not be used as current status.
