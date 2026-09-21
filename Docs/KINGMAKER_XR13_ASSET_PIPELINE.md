# Kingmaker XR-13 asset pipeline

This is the production handoff for the RealityKit assembly. The runtime deliberately expects an assembly, not one monolithic car mesh.

## Current status

A modeled **blockout** USDZ exists at `Sources/DHPresentation/Resources/Kingmaker_XR13.usdz` (bundled via `Package.swift`'s `DHPresentation` target resources), generated headlessly in Blender via `Tools/BlenderAssetGen/build_kingmaker.py` (run with `blender --background --python Tools/BlenderAssetGen/build_kingmaker.py`; regenerates the `.blend` and re-exports the `.usdz` in place). It is a lofted low-poly fastback body shell (hand-tuned cross-section profile, not primitives) plus modeled engine-bay, suspension, wheel (torus tire + rim), cabin, dashboard, roof-brace, and cargo-rack geometry with flat PBR materials — no UV-mapped textures, no blend shapes, no final surfacing. It follows the `XR13_Assembly` hierarchy below with proportions matched to the runtime marker geometry in `Rev10RealityKitScene.swift`. It's an open-cockpit shape (no windshield glass — an attempt at glass panels z-fought with the shell's own roof geometry and was dropped; an open cockpit also reads as a plausible stripped-down scavenger build). It exists so the RealityKit bridge can load a real asset file instead of code-generated marker entities while final art is produced. Replacing it with production meshes (below) should not require any simulation or bridge changes, by design.

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
