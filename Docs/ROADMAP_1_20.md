# KINGMAKER roadmap 1–20

This is the implementation status for the twenty-item follow-up pass.

| # | Area | Status |
|---:|---|---|
| 1 | Swift/Xcode build stability | CI added; local host cache permissions still block execution |
| 2 | Full test run | Regression tests added; run in CI/macOS Xcode environment |
| 3 | Continuous integration | `.github/workflows/quality.yml` added |
| 4 | USDZ asset validation | `Tools/validate_assets.py` added and run in CI |
| 5 | Simulator asset loading | Runtime loader is integrated; simulator execution remains an external gate |
| 6 | Real Kingmaker entity binding | Bundled USDZ replaces the marker vehicle when it resolves |
| 7 | Condition-to-visual contract | `KingmakerComponentVisualState` exposes condition profiles to presentation |
| 8 | Driving integration | Session drive state updates coordinator, HUD, and RealityKit placement |
| 9 | Camera/entry transitions | `DHRev10CameraTuning` supplies FOV/duration/easing per inspection and player mode; device QA remains |
| 10 | Garage interactions | Inspect, diagnose, repair, and drive hotspots are wired to session state |
| 11 | Repair progression | Repair mutates authoritative components and records interaction progress |
| 12 | Mechanical simulation | Fuel, battery, pressure, coolant, crank, and seizure state are live |
| 13 | World streaming | Blackridge chunks stream through the coordinator; production terrain remains |
| 14 | Navigation | A traversable Blackridge route graph now supports garage-to-Paradise paths |
| 15 | NPC/vehicle roster | 20 named NPCs and 12 named vehicles spawn into the live slice with per-occupation daily schedules and greet/trade/rumor dialogue stubs; production art for them remains |
| 16 | Convoy combat | `DHVehicleEncounterRuntime` provides attack, damage, resolve, and radio consequence |
| 17 | Save migration | Versioned envelopes and legacy direct-slice reads are covered by tests |
| 18 | Runtime consolidation | Session synchronizes the vertical slice and coordinator; the duplicated repair/start-engine sequence across both was found and consolidated into `KingmakerState` |
| 19 | Production materials | Every bundled asset (not just the vehicle) now has procedurally textured PBR materials instead of flat color; authored final surfaces remain |
| 20 | Device/performance/signing QA | Checklist and handoff are documented; requires simulator/device access |

The current committed test suite contains 177 Swift tests. Older revision
reports retain their historical counts intentionally; live status belongs in
the top-level README and the Rev10 execution board.

The next hard gate is a successful CI test run followed by physical-device
validation. Items 9, 15, and 18 have closed as far as code can take them.
Item 19's remaining gap (final authored surfaces vs. procedural textures) and
item 20 (device QA) require production art, Xcode/device access, or both;
they cannot be honestly completed by adding more scaffolding.
