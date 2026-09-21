# Kingmaker XR-13 asset pipeline

This is the production handoff for the RealityKit assembly. The runtime deliberately expects an assembly, not one monolithic car mesh.

## Current status

A modeled **blockout** USDZ exists at `Sources/DHPresentation/Resources/Kingmaker_XR13.usdz` (bundled via `Package.swift`'s `DHPresentation` target resources), generated headlessly in Blender via `Tools/BlenderAssetGen/build_kingmaker.py` (run with `blender --background --python Tools/BlenderAssetGen/build_kingmaker.py`; regenerates the `.blend` and re-exports the `.usdz` in place). It was built directly against this file's visual canon and multi-view spec (`ResearchLibrary/KINGMAKER_VISUAL_CANON.md`, `ResearchLibrary/KINGMAKER_MULTI_VIEW_VISUAL_SPEC.md`), not as generic primitives: a lofted low-poly fastback body with a long hood and pronounced flared haunches at both wheel arches, a distinct raised fastback greenhouse volume (tinted, not body-colored, stepped up from the beltline) rather than an open notch, a hood scoop over the supercharger, front splitter and push bar, rear diffuser fins, an active rear wing, headlights/taillights, big wheels with a visible rotor+caliper inside the rim, a roll cage/pedal box/dashboard in the cabin, and a roof cargo rack — matching the sub-assembly separation `ResearchLibrary/KINGMAKER_PARTS_DISASSEMBLY_REFERENCE.md` requires. It follows the `XR13_Assembly` hierarchy below with proportions matched to the runtime marker geometry in `Rev10RealityKitScene.swift`. Materials are flat PBR (paint/glasshouse/dark/metal/rubber/caliper/armor/cargo/light) with no UV-mapped textures, no blend shapes, no final surfacing — still a blockout. It exists so the RealityKit bridge can load a real asset file instead of code-generated marker entities while final art is produced; replacing it with production meshes (below) should not require any simulation or bridge changes, by design.

## Required entity hierarchy

`XR13_Assembly` → `chassis` → `bodyPanels`, `engineBay`, `powertrain`, `transmission`, `suspension`, `wheels`, `cabin`, `dashboard`, `armor`, `cargo`. The stable IDs are defined by `DHRev10AssetManifest` and the RealityKit scene bridge.

## Modeling requirements

Export separate meshes for the chassis, Boss 429-pattern block, Roots supercharger, radiator, DCT housing, suspension arms, wheels, dashboard needles, warning lights, armor, and cargo. Use blend shapes for body-panel deformation rather than crash-time model swaps.

## Audio requirements

Supply isolated looping stems for exhaust, valvetrain, and supercharger; transient clips for DCT shifts, radiator hiss, engine knock, and seizure; and radio consequence stems. `KingmakerAudioMixState` provides the runtime mix parameters.

## Procedural presentation

Wheel rotation, steering, suspension compression, dashboard needles, fault lights, deformation weights, thermal emission, and spatial-audio mix are driven from Swift state. Reality Composer Pro should assemble the authored hierarchy and colliders; it should not duplicate simulation logic.

The detailed modeling, animation, deformation, crafting, companion, and weather requirements are catalogued in `ResearchLibrary/KINGMAKER_PRODUCTION_REFERENCE_MATRIX.md`.

## Reality Composer Pro handoff

Create `XR13_Assembly`, import the separated USDZ parts, preserve the stable node names, add simplified body collision and primitive wheel/engine colliders, then load the scene through the existing `DHRev10RealityKitScene` bridge.
