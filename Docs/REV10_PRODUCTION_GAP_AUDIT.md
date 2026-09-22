# Rev10 production gap audit

The original DEAD HIGHWAY design is now represented by executable data and presentation contracts. This audit records the remaining work without conflating contracts with finished content.

Implemented in the repository:

- 12-region production atlas, eight factions, and five vehicle archetypes.
- Blackridge authored-location manifest, roads, chunks, interiors, encounters, and blockout props.
- Kingmaker simulation and render hierarchy mapping.
- Player, inspection, diagnosis, repair, startup, driving, loot, combat, radio, negotiation, recruitment, and persistence contracts.
- Xcode project, non-signing Simulator configuration, RealityKit bridge, camera, lighting, bundled garage/road blockouts, and visible Kingmaker.
- Render budget, thermal reduction, navmesh, audio, asset, and performance contracts.
- A navmesh data file, two sampled animation clips (player repair, engine start), 15 synthesized
  audio stems covering every `DHRev10ProductionContract.requiredAudio` cue, and a parsed
  combat-FX particle definition wired to `DHVehicleEncounterRuntime`'s fire/attack phases.
- Weather VFX (rain, mud kickup, ground fog) alongside the existing dust/debris/heat-haze
  emitters, and a per-collision-zone blend-shape deformation weight contract.
- 20 named production NPCs and 12 named production vehicles that spawn into the live slice
  (`DHRev10SliceCoordinator.populateProductionRoster`/`populateProductionVehicleRoster`), each
  NPC with a daily schedule and greet/trade/rumor dialogue stub.
- A second interior (truck stop) alongside the garage/Paradise ones, and environmental-story
  props (an abandoned vehicle, a scavenger camp) along the road segment.
- Procedural PBR texturing (not flat color) on every bundled mesh, not just the vehicle.
- Camera transition tuning (FOV/duration/easing) per inspection and player mode.

External production inputs still required:

- Final, hand-sculpted or photogrammetry-sourced USDZ meshes and materials -- everything bundled
  today is a procedural blockout, textured but not painted/scanned. This is a categorical gap
  (sculpted continuous surfaces, panel gaps, modeled optics, environment/IBL lighting), not
  something more scripting can close; see `Docs/KINGMAKER_XR13_ASSET_PIPELINE.md`.
- Real voice, music, and mastered SFX -- current audio is procedurally synthesized (sine/noise
  waveform placeholders), not recorded or licensed.
- Proper environment/IBL lighting (a flat background color remains after an earlier attempt at
  a lit studio-panel environment blew out the paint's exposure).
- Physical-device signing, touch/controller validation, thermal profiling, and acceptance testing on iPhone.

The correct next milestone is a content drop containing the garage, Kingmaker, and one Blackridge road segment. The existing stable IDs allow those assets to replace blockout entities without another simulation redesign.
