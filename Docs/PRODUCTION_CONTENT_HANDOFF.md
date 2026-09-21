# Production content handoff

The codebase now has a reproducible simulation/presentation contract and one
bundled Kingmaker blockout. The following items are deliberately not faked as
finished content:

| Area | Current state | Required handoff |
|---|---|---|
| Kingmaker | Textured procedural blockout USDZ | Artist-authored separated meshes, UVs, PBR materials, deformation blend shapes |
| Garage/terrain | Swift/RealityKit marker blockouts | Authored Reality Composer Pro scenes, colliders, navmesh |
| Interiors | Data contracts only | Garage, town, truck-stop, Paradise interiors with interaction anchors |
| NPCs/vehicles | State models only | Production roster, rigs, animations, LODs, encounter prefabs |
| Audio | Mix/state contracts only | Engine, valvetrain, supercharger, radio, repair, combat, weather stems |
| VFX | FX state/budget only | Dust, sparks, smoke, heat haze, rain, damage, headlights, weather |
| Device QA | Not validated here | Simulator run, physical iPhone run, thermal profiling, input/signing checks |

The source-of-truth visual references are in
ResearchLibrary/ReferenceImages/. The Blender blockout generator is
Tools/BlenderAssetGen/build_kingmaker.py; it must remain a replaceable
authoring aid, not the production asset pipeline.
