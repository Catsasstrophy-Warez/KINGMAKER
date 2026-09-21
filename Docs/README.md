# Docs index

Implementation reports and production audits, in chronological order.
Each rev builds on the previous one; Rev10 is current (see the top-level
[`README.md`](../README.md) for the live status summary).

| Rev | Doc | Summary |
|---|---|---|
| 3 | [REV3_IMPLEMENTATION_REPORT.md](REV3_IMPLEMENTATION_REPORT.md) | Early simulation/architecture pass |
| 4 | [REV4_IMPLEMENTATION_REPORT.md](REV4_IMPLEMENTATION_REPORT.md) | Vehicle/build system expansion |
| 5 | [REV5_IMPLEMENTATION_REPORT.md](REV5_IMPLEMENTATION_REPORT.md) | World/settlement systems |
| 6 | [REV6_IMPLEMENTATION_REPORT.md](REV6_IMPLEMENTATION_REPORT.md) | First playable foundation — RealityKit garage/highway/Paradise blockouts, isometric camera, HUD, streaming cells |
| 7 | [REV7_IMPLEMENTATION_REPORT.md](REV7_IMPLEMENTATION_REPORT.md) | Blackridge playable app — Xcode app handoff, SwiftUI/RealityKit host, touch controls, HUD, audio/FX state, trading |
| 8 | [REV8_IMPLEMENTATION_REPORT.md](REV8_IMPLEMENTATION_REPORT.md) | Original-vision audit + living world gameplay — locations, scavenging, perks/equipment/injuries, combat, negotiation, recruitment, radio, vehicle entry/exit |
| 9 | [REV9_IMPLEMENTATION_REPORT.md](REV9_IMPLEMENTATION_REPORT.md) | Production gameplay integration (44/44 Swift tests passing at this point) |
| 10 | [REV10_VERTICAL_SLICE.md](REV10_VERTICAL_SLICE.md) | Blackridge County vertical slice — the single rendered/persistent acceptance path |
| 10 | [REV10_50_STEP_EXECUTION.md](REV10_50_STEP_EXECUTION.md) | 50-step execution board tracking Implemented vs. Xcode-content-pending work |
| 10 | [REV10_PRODUCTION_GAP_AUDIT.md](REV10_PRODUCTION_GAP_AUDIT.md) | **Current state of record** — what's implemented as data/contracts vs. what still needs external production assets |

## Other docs

- [KINGMAKER_DEEP_DIVE.md](KINGMAKER_DEEP_DIVE.md) — deep dive on the Kingmaker vehicle system
- [KINGMAKER_XR13_ASSET_PIPELINE.md](KINGMAKER_XR13_ASSET_PIPELINE.md) — XR-13 asset pipeline notes
- [PRODUCTION_CONTENT_HANDOFF.md](PRODUCTION_CONTENT_HANDOFF.md) — explicit boundary between shipped contracts/blockouts and external production inputs
- [DEVICE_VALIDATION_CHECKLIST.md](DEVICE_VALIDATION_CHECKLIST.md) — Simulator, physical-device, and thermal validation sequence
- [ROADMAP_1_20.md](ROADMAP_1_20.md) — implementation status for the next twenty roadmap items
- [SHA256_MANIFEST.txt](SHA256_MANIFEST.txt) — checksum snapshot from an earlier revision; paths inside it predate this reorganization and are historical only, not a current manifest
- [`../ResearchLibrary/`](../ResearchLibrary/) — design reference matrices (visual canon, hazard telemetry, parts disassembly, action reference, condition states, settlement/endgame systems)
