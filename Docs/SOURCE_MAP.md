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

## DHWorld — Blackridge County

| File | Concern |
|---|---|
| `Blackridge.swift` | Core region/location model |
| `BlackridgeAdvanced.swift` | Extended world state |
| `BlackridgeRev10.swift` | Rev10 authored-location/road/chunk manifest |
| `ProductionWorld.swift` | Production-scale world data (12-region atlas) |
| `ProductionContentRegistry.swift` | Registry for production content |

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
| `Rev10AssetManifest.swift` | Rev10 asset manifest contract |
| `Rev10InteractionPresentation.swift` | Rev10 interaction state |
| `Rev10OnFootPresentation.swift` | Rev10 on-foot presentation |
| `Rev10ProductionContracts.swift` | Rev10 production data contracts |
| `Rev10RuntimePresentation.swift` | Rev10 runtime presentation state |
| `Rev10RealityKitScene.swift` | Rev10 RealityKit scene bridge (largest single file, ~161 lines) |

## Everything else

`DHCore`, `DHCharacter`, `DHCombat`, `DHEconomy`, `DHFleet`, `DHNPC`,
`DHRadio`, `DHSettlement` are each 1–3 files and small enough (7–42 lines)
to read in full without a map; see the module dependency graph in the
top-level [`README.md`](../README.md).
