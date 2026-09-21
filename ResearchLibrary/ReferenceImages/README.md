# XR-13 Kingmaker — canonical reference images

These three images are the canonical visual ground truth for the Kingmaker XR-13,
provided directly by the project owner. They supersede the text-only descriptions
in `KINGMAKER_VISUAL_CANON.md` and `KINGMAKER_MULTI_VIEW_VISUAL_SPEC.md` wherever the
two disagree — those docs describe intent, these images show the target fidelity and
silhouette. Any future 3D art pass (artist-modeled or AI-image-to-3D) should be built
directly from these, not from the procedural Blender blockout in
`Sources/DHPresentation/Resources/Kingmaker_XR13.usdz`, which is a placeholder only
and is not visually representative of the intended final asset.

## XR13_OrthogonalsAndWasteland.png

The clearest single reference for overall shape and finish. Four sections:

- **External orthogonals (clean/restored config)**: front, side, and rear orthographic
  views of the restored Kingmaker — a dark gunmetal fastback with a Shelby-GT500-style
  aggressive front fascia (large lower grille opening, hood vents/scoop), correct
  fastback greenhouse proportions, quad-style rear lighting, and a subtle rear lip
  spoiler.
- **Technical & deep mechanics**: top-down chassis/aero view, underneath view showing
  the full exhaust/suspension/driveline routing, an engine bay labeled "the Predator
  block" (supercharged V8), and a suspension/brake close-up (big brake package,
  coilover, dust/wear detail).
- **Operator environment**: cabin with roll cage and bucket seat, and a dashboard with
  a diegetic digital display readout (ECT/EOP/BOOST gauges) alongside analog
  instruments and toggle switches.
- **Wasteland configuration**: the same silhouette in a dynamic driving shot — roof
  cargo rack, dust/headlight atmosphere, driving past a "DEAD END" road sign.

## XR13_DisassemblyAndComponentBreakdown.png

A parts/exploded-view breakdown, organized to match
`KINGMAKER_PARTS_DISASSEMBLY_REFERENCE.md`'s required sub-assembly separation:
external disassembly (front fascia, side door/aero framing, rear aero/lighting/exhaust
cluster), technical component breakdown (top-down chassis, underneath
suspension/powertrain, engine bay internals, cockpit tactile/pedal detail), operator
environment (cockpit frame, dashboard wiring/switch panel), and a wasteland
configuration section (accessory cart, disassembled headlight/optics unit).

## XR13_ParkDisassembly_DamagedRustedBrokenRepaired.png

The same component set shown across four condition states — damaged, rusted, broken,
and repaired — matching the `ComponentCondition` states already modeled in
`Sources/DHVehicle/Kingmaker.swift` (`missing/seized/failed/poor/serviceable/good/restored`).
Useful as the direct visual target for what each condition tier should look like per
component (e.g. the front fascia panel progressing from a clean weathered state to
heavy rust to structurally broken to fully repaired).

## Status

Reference only — not yet integrated into any 3D pipeline. The next production step
(per `KINGMAKER_XR13_ASSET_PIPELINE.md`) is for an actual 3D artist, or an
image-to-3D generation tool seeded with these images, to model production meshes
against this reference, replacing the current procedural blockout.
