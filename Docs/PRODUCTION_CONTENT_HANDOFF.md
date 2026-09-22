# Production content handoff

The codebase now has a reproducible simulation/presentation contract and one
bundled Kingmaker blockout. The following items are deliberately not faked as
finished content:

| Area | Current state | Required handoff |
|---|---|---|
| Kingmaker | Textured procedural blockout USDZ, plus repaired/damaged/rusted condition variants | Artist-authored separated meshes, UVs, PBR materials, deformation blend shapes |
| Garage/terrain/raider/dashboard/engine bay | Generated USDZ blockouts bundled, procedurally PBR-textured; marker fallback remains | Authored Reality Composer Pro scenes, production colliders, navmesh geometry, lighting and dressing |
| Interiors | Garage, Paradise, truck-stop, and town interior blockouts all bundled with interaction anchors | Production-quality dressing for all four |
| NPCs/vehicles | 20 named NPCs and 12 named vehicles spawn into the live slice with daily schedules and dialogue stubs; a mannequin walk-cycle rig exists | Production character/vehicle meshes, rigs, animations, LODs, encounter prefabs (the raider mesh is a blockout, not a rigged prefab) |
| Audio | 15 real synthesized stems cover every required cue (engine, valvetrain, supercharger, radio, repair, loot, hostile, negotiation) and are wired to real playback | Recorded/licensed voice, music, and mastered SFX to replace the synthesized placeholders |
| VFX | Dust, collision debris, heat haze, rain, mud kickup, and ground fog are real RealityKit particle emitters; combat FX (muzzle flash, spark impact, smoke trail) fire from real combat events | Authored VFX textures/shaders; headlight-specific effects |
| Device QA | Not validated here | Simulator run, physical iPhone run, thermal profiling, input/signing checks |

The source-of-truth visual references are in
ResearchLibrary/ReferenceImages/. The Blender blockout generator is
Tools/BlenderAssetGen/build_kingmaker.py; it must remain a replaceable
authoring aid, not the production asset pipeline.
