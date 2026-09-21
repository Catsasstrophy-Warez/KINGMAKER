# Source map

`Sources/` follows a "one file per concern, added incrementally per
revision" convention rather than one file per type. Files in the same
module extend the same core type(s) across separate concerns instead of
duplicating them. This map orients a reader who needs to touch a whole
subsystem across its files.

## DHVehicle — the Kingmaker (car) model

| File | Concern |
|---|---|
| `Kingmaker.swift` | Core component/condition model |
| `KingmakerRev4.swift` | Rev4 expansion of the build/component system |
| `KingmakerAdvanced.swift` | Advanced mechanical state |
| `KingmakerBuild.swift` | Build/assembly rules |
| `KingmakerProfile.swift` | Vehicle profile/archetype data |
| `KingmakerTopology.swift` | Structural/part topology |
| `KingmakerConditionVisualState.swift` | Condition → visual-state mapping |
| `KingmakerPresentation.swift` | Presentation-facing bindings |
| `KingmakerCollision.swift` | Collision bounds (length/width/height) for physics/navigation |

## DHWorld — Blackridge County

| File | Concern |
|---|---|
| `Blackridge.swift` | Core region/location model |
| `BlackridgeAdvanced.swift` | Extended world state |
| `BlackridgeRev10.swift` | Rev10 authored-location/road/chunk manifest |
| `ProductionWorld.swift` | Production-scale world data (12-region atlas) |
| `ProductionContentRegistry.swift` | Registry for production content |
| `Navigation.swift` | Navigation graph (nodes/chunks) for pathing between locations |

## DHGameplay — orchestration layer (grown past "small," gets its own map now)

| File | Concern |
|---|---|
| `VerticalSlice.swift` | Original restoration-beat vertical slice (wake → highway) |
| `WorldComesAlive.swift` | Playable-milestone runtime tying every domain module together |
| `WorldSimulation.swift` | Dynamic world runtime (civilization/economy/radio/NPC tick) |
| `Exploration.swift` | Enterable locations, loot categories, scavenging |
| `RepairScavenge.swift` | Tools and repair/scavenge actions |
| `RepairRuntime.swift` | Step-based repair work state machine (locked/available/in-progress/complete/failed) |
| `FirstPlayableRuntime.swift` | Rev6 first-playable runtime (on-foot/in-vehicle locomotion) |
| `ProductionLoop.swift` | Production-scale playable mode/streaming runtime |
| `Rev10VerticalSlice.swift` | Rev10 acceptance-path beat sequence |
| `Rev10SliceCoordinator.swift` | Coordinates inspection/repair/streaming/radio for the Rev10 slice |
| `Rev10SaveDocument.swift` | Versioned save document wrapper (schema version + slice) |
| `VehicleEncounterRuntime.swift` | Hostile vehicle encounter phase state machine |

## DHPresentation — RealityKit/UI layer (largest module)

| File | Concern |
|---|---|
| `Presentation.swift` | Core presentation types |
| `ProductionPresentation.swift` | Production-scale presentation data |
| `Garage.swift` | Garage scene state |
| `FirstPlayable.swift` | Rev6 first-playable presentation boundary |
| `PlayableControls.swift` / `PlayableAdvanced.swift` | Input/control state |
| `KingmakerMechanicalPresentation.swift` | Vehicle mechanical presentation |
| `KingmakerOperationalState.swift` | Vehicle operational/runtime state |
| `KingmakerRealityKitSimulation.swift` | RealityKit simulation bridge for the vehicle |
| `Rev10AssetManifest.swift` | Rev10 asset manifest contract + `DHRev10AssetResolver` (resolves the bundled Kingmaker USDZ) |
| `Rev10InteractionPresentation.swift` | Rev10 interaction state |
| `Rev10OnFootPresentation.swift` | Rev10 on-foot presentation |
| `Rev10ProductionContracts.swift` | Rev10 production data contracts |
| `Rev10RuntimePresentation.swift` | Rev10 runtime presentation state |
| `Rev10RealityKitScene.swift` | Rev10 RealityKit scene bridge (largest single file) |
| `Resources/` | Bundled assets — currently `Kingmaker_XR13.usdz` (see `Docs/KINGMAKER_XR13_ASSET_PIPELINE.md`) |

## Everything else

`DHCore` (2 files), `DHCharacter` (2), `DHCombat` (3), `DHEconomy` (1),
`DHFleet` (2), `DHNPC` (3), `DHRadio` (2), `DHSettlement` (2) are still
small enough to read in full without a map; see the module dependency
graph in the top-level [`README.md`](../README.md).

## Keeping this current

This project iterates fast across multiple concurrent sessions — treat this
map as a snapshot, not a guarantee. If a file you're looking for isn't
listed here, check `ls Sources/<Module>/` directly; the map is a navigation
aid for the larger modules (`DHVehicle`, `DHWorld`, `DHGameplay`,
`DHPresentation`), not a change log.
