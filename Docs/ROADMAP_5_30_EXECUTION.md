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
| 19 | Textured procedural blockout remains bundled; final authored materials, meshes, damage variants, and animations are an external art gate |
| 20 | Simulator build/launch verified; physical-device signing, thermal, memory, performance, accessibility, and release QA remain external gates |

Current verification: 105 SwiftPM tests pass, the iOS Simulator target builds
successfully, the app launches on an iPhone simulator, and the USDZ contract
validator passes. The simulator still visibly uses diagnostic world geometry
around the loaded vehicle; replacing that environment with production terrain
and garage art is intentionally not represented as complete here.
