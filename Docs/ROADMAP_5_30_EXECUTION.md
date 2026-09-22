# Roadmap 5–30 execution status

The steps below are the concrete implementation pass after the initial
roadmap. “Verified” means it has a repository test, a successful build, or a
runtime check; “external gate” means it requires authored production content,
a physical device, or credentials outside this checkout.

| Steps | Result |
|---|---|
| 5–7 | USDZ archive/entity-label/texture-budget validation added; iOS Simulator app build and launch verified |
| 8–13 | Persistent session document, vehicle transform/HUD sync, async USDZ loading, camera modes, collision components, and mechanical tick wiring added |
| 14–16 | Navigation graph, repair runtime, collision damage state, vehicle encounter combat, radio consequence, and loot controls added |
| 17–18 | Session save now persists slice, coordinator, movement, camera, trade, repair, and loot state; coordinator is the active presentation bridge |
| 19 | Textured procedural blockout, Kingmaker damage variants, and animation bindings are bundled; final authored hero materials, meshes, and animation polish remain an external art gate |
| 20 | Simulator build/launch verified; physical-device signing, thermal, memory, performance, accessibility, and release QA remain external gates |

The runtime now uses a fixed-step accumulator for vehicle stepping, stable
navigation ordering, explicit collision layers, and a chunk reconciliation
API. These are simulation/presentation foundations. Since the prior update,
a navmesh data file, animation-clip sampling, 15 real audio stems, weather/
combat particle FX, a spawnable named NPC/vehicle roster, and a second
interior have all moved from contract-only to built and tested; authored
(not procedural) terrain, final production art, and physical-device
validation remain external production gates.

Current verification: 177 SwiftPM tests pass, the iOS Simulator target builds
successfully, and the USDZ contract validator passes. Simulator launch and
interactive UI validation remain blocked in this environment while the
CoreSimulator service is unavailable.
