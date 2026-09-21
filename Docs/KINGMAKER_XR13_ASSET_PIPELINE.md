# Kingmaker XR-13 asset pipeline

This is the production handoff for the RealityKit assembly. The runtime deliberately expects an assembly, not one monolithic car mesh.

## Current status

A modeled **blockout** USDZ exists at `Sources/DHPresentation/Resources/Kingmaker_XR13.usdz` (bundled via `Package.swift`'s `DHPresentation` target resources), generated headlessly in Blender via `Tools/BlenderAssetGen/build_kingmaker.py` (run with `blender --background --python Tools/BlenderAssetGen/build_kingmaker.py`; regenerates the `.blend` and re-exports the `.usdz` in place). It was built directly against this file's visual canon and multi-view spec (`ResearchLibrary/KINGMAKER_VISUAL_CANON.md`, `ResearchLibrary/KINGMAKER_MULTI_VIEW_VISUAL_SPEC.md`), not as generic primitives: a lofted low-poly fastback body with a long hood and pronounced flared haunches at both wheel arches, a distinct raised fastback greenhouse volume (tinted, not body-colored, stepped up from the beltline) rather than an open notch, a hood scoop over the supercharger, front splitter and push bar, rear diffuser fins, an active rear wing, headlights/taillights, big wheels with a visible rotor+caliper inside the rim, a roll cage/pedal box/dashboard in the cabin, and a roof cargo rack — matching the sub-assembly separation `ResearchLibrary/KINGMAKER_PARTS_DISASSEMBLY_REFERENCE.md` requires, plus a slatted grille mesh and door seam lines for additional part separation. Proportions (roofline height/length, wheel/rim-to-tire ratio, rear treatment) were recalibrated by eye against `ResearchLibrary/ReferenceImages/ref_front.png`/`ref_side.png`/`ref_rear.png` (crops of the project owner's own reference renders): a lower and longer flat-roofed fastback greenhouse instead of a short tent-like peak, low-profile tires with a much larger visible rim, a small integrated decklid lip instead of a strut-mounted wing, quad taillights, dual exhaust tips, and a deep dark grille opening. It follows the `XR13_Assembly` hierarchy below with proportions matched to the runtime marker geometry in `Rev10RealityKitScene.swift`. Every mesh is UV-unwrapped (Blender's smart UV project) and textured with procedurally generated, numpy-authored PNG images embedded directly in the `.usdz` (worn/scratched paint, brushed metal with rust speckle, tire tread, dark trim) rather than flat colors — still not final production surfacing (no hand-painted or photo-sourced textures, no blend shapes), but no longer flat-shaded either. It exists so the RealityKit bridge can load a real asset file instead of code-generated marker entities while final art is produced; replacing it with production meshes (below) should not require any simulation or bridge changes, by design.

**Geometry/material quality pass**: the body shell and greenhouse are now Catmull-Rom-resampled from their control-point cross-sections (not raw linear facets between ~10 points) and smooth-shaded, giving rounded panel curvature instead of a faceted look. Wheels have real 5-spoke rims (hub + barrel + radiating spokes) instead of a blank disc. The paint material is a dark gunmetal clearcoat (`Coat Weight`/`Coat Roughness` on the Principled BSDF) matching `ref_side.png`'s finish, rather than flat automotive paint. None of this closes the gap to the reference images' actual photorealism (hand-modeled panel gaps, physically accurate materials, proper environment/IBL lighting, post-processing) — that remains an artist-or-image-to-3D-tool problem — but it is materially closer than the earlier flat-primitive pass.

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
