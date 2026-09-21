# DEAD HIGHWAY (Kingmaker)

A post-apocalyptic survival/driving game for iOS/macOS. You inhabit Blackridge
County, recover a derelict muscle car (the XR-13 "Kingmaker"), diagnose and
rebuild it component by component, then drive, scavenge, fight, trade, and
help rebuild the settlement of Paradise.

Native Swift 6 / SwiftUI / RealityKit, built with XcodeGen (`project.yml`)
over a Swift Package (`Package.swift`) of 12 library modules plus one iOS
app target.

## Current status — Rev10

Rev10 is scoped around a single rendered, persistent acceptance path: start
the game, walk the garage, inspect and diagnose Kingmaker, scavenge, repair,
start it, drive streamed Blackridge, resolve a hostile vehicle encounter,
hear its radio consequence, reach Paradise, enter, negotiate/trade/recruit,
save, quit, reload, and verify persisted state is identical.

Implemented: a 12-region production atlas, eight registry factions, five
vehicle archetypes, the Blackridge authored-location manifest (roads, chunks,
interiors, encounters), the Kingmaker simulation/render hierarchy, a bundled
procedural textured USDZ blockout, and the gameplay/persistence contracts for
the acceptance path above. The app now resolves the bundled Kingmaker asset
with diagnostic marker fallback. The package currently has 105 passing Swift
tests covering the core systems, vertical slice, asset contract, navigation,
encounter runtime, repair/collision state, and save compatibility. The iOS
Simulator app target also builds and launches successfully.

Not yet done (external production inputs): final authored USDZ/RealityKit
meshes and materials, authored navmesh resources and animation clips,
voice/music/SFX, VFX (atmosphere, dust, weather, deformation), the production
NPC/vehicle roster, and physical-device signing or validation.

See [`Docs/REV10_PRODUCTION_GAP_AUDIT.md`](Docs/REV10_PRODUCTION_GAP_AUDIT.md)
for the full gap audit, and [`Docs/README.md`](Docs/README.md) for the
complete revision history (Rev3 through Rev10).

## Build

```
swift test
```

This is an Xcode-ready Swift Package foundation, not a signed iPhone `.app`.
Production art, animations, audio, touch/controller input, app
target/signing, and physical-device validation still require further
Xcode/macOS integration work.

## Layout

- `App/` — SwiftUI app shell (`DeadHighwayApp`)
- `Sources/` — the 12 library modules (`DHCore`, `DHVehicle`, `DHWorld`,
  `DHCharacter`, `DHFleet`, `DHCombat`, `DHNPC`, `DHSettlement`,
  `DHEconomy`, `DHRadio`, `DHGameplay`, `DHPresentation`)
- `Tests/` — `DHCoreTests`
- `Docs/` — revision implementation reports and production audits
- `ResearchLibrary/` — design reference matrices (visual canon, hazard
  telemetry, parts disassembly, settlement/endgame systems, etc.)
