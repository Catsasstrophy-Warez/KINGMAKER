# Visual Reference Review — Items 4–6

Date: 2026-09-23

## Current read

The authored asset set is no longer an empty blockout: the Kingmaker has a distinct XR-13 silhouette, low fastback greenhouse, hood hardware, grille, lights, wheel assemblies, cockpit landmarks, and state variants. The native RealityKit preview adds a controlled camera, neutral ground plane, and studio lighting so the promoted USDZ can be judged through the same renderer used by the app.

The remaining gap is fidelity, not basic presence:

- **Kingmaker:** recognizable and readable, but still below reference-quality paint wear, glass treatment, trim micro-detail, and hero-texture fidelity.
- **Garage:** the lift, toolwall, shelves, salvage tires, service sign, ceiling infrastructure, cable reels, spill tray, and work lamp now establish a working repair bay. Final decal language, grime layering, and hand-authored prop variation remain art-production work.
- **Road:** asphalt markings, guardrail, shoulders, rocks, patches, lamps, camp, abandoned vehicle, utility boxes, and damaged barrier now establish a traversed route. Final terrain blending, vegetation, destruction dressing, and atmospheric depth remain art-production work.
- **Paradise and encounter presentation:** runtime hooks exist for chunk activation, camera sync, ambient dust/rain/fog, combat emitters, audio cue playback, and Paradise negotiation/trade/recruitment state. A deterministic `applyCameraImpact` hook now gives encounter/collision presentation a controlled camera impulse without moving simulation state into RealityKit. Encounter presentation can also duck the engine mix to 42% through authoritative `KingmakerAudioMixState` rather than mutating AVAudioPlayer state ad hoc.

## Verification

The reference-lock geometry pass has now been promoted to all four Kingmaker USDZ
condition variants. The exported assets include the lowered fastback greenhouse,
graphite/silver body treatment, broad modernized nose, triple vertical rear lamps,
integrated deck lip, restrained roof treatment, and cockpit landmark geometry for
the analog gauges, steering wheel, and manual shifter. Each export also retained
the ten validated deformation blend shapes.

The canonical current Kingmaker capture is `kingmaker-realitykit.png`. The older
`kingmaker.png` remains as a legacy Blender preview contract and must not be used
as evidence for the newly promoted USDZ appearance.

The regenerated environment USDZ assets were promoted through the safe exporter and passed `Tools/validate_assets.py`. The legacy preview validator passes the garage and road PNGs; the RealityKit Kingmaker capture is validated by simulator launch and screenshot capture. Blender headless preview remains an external fallback because it can crash during Metal initialization.

## Recommendation

The next art pass should replace the procedural material look with authored texture atlases and decals for the Kingmaker, then give the garage and road a small number of bespoke hero props. Runtime camera/FX/audio work can proceed against the current stable contracts while final reference-matching art is iterated externally.
