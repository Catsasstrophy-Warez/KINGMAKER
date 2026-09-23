# Device validation checklist

Run this on a clean macOS/Xcode installation. Simulator launch, rendering, and
the complete interactive garage-to-Paradise route are now recorded; the
repository still needs a physical-device run.

The preflight results below are a dated evidence snapshot and intentionally
retain the test count recorded at the time they were captured. For current
status, see `Docs/CURRENT_STATUS.md`.

## Latest repository-side preflight

Recorded 2026-09-23:

- `swift test --scratch-path /tmp/kingmaker-swiftpm`: 258 tests passed, including the package-level garage-to-Paradise route, start-gating, world-space spawn-anchor, bundled-navmesh, proximity-interaction, spatial action guards, motion-driven route, encounter-visibility, live player-animation, authored-asset placement, empty-stream recovery, and readiness-gated RealityKit update coverage.
- `python3 Tools/production_qa.py`: asset contracts, manifest uniqueness/placement contract, 34-resource SHA-256 integrity manifest, checked-in visual preview contract, reconstruction workflow contract, labeled touch-control and lifecycle bindings, USD, semantic-label checks for Kingmaker, terrain, interiors, garage, road, engine bay, and hostile vehicle, audio, and Python checks passed.
- `python3 Tools/BlenderAssetGen/run_safe_environment_export.py`: Blender preflight and staged garage/road export passed; both assets were promoted only after archive, size, USDC, and stable-label validation.
- `xcodebuild ... -sdk iphonesimulator -configuration Debug -derivedDataPath /tmp/kingmaker-derived CODE_SIGNING_ALLOWED=NO build`: succeeded with isolated caches.
- `xcodebuild ... -sdk iphonesimulator -configuration Release -derivedDataPath /tmp/kingmaker-release-derived CODE_SIGNING_ALLOWED=NO build`: succeeded; a clean Release simulator capture also rendered the garage, road, and Kingmaker after the scene-readiness barrier fix.
- `python3 Tools/production_qa.py`: passed; 34/34 package and manifest resources covered, 15/15 USDZ archives readable, 15 geometry budgets inspected, 12 semantic-label contracts inspected, and 15 audio containers decoded.
- `xcrun simctl list devices available`: passed; an iPhone 16 Pro iOS 18.5 runtime was available.
- `xcrun simctl install ... DeadHighway.app` and `xcrun simctl launch ... com.deadhighway.game`: installation, process launch, and clean iPhone 17 Pro simulator rendering pass. Explicit `RealityView` virtual-camera selection now renders the garage, road, and Kingmaker after authored-asset loading.
- `xcodebuild ... -scheme DeadHighway ... -destination 'platform=iOS Simulator,id=DB049049-4CF2-4787-8AD0-567C22C1AD83' -only-testing:DeadHighwayUITests test`: both UI tests pass in 83 seconds on the clean iPhone 17 Pro Max simulator. The full route covers Garage → Inspect → Diagnose → Scavenge → Repair → Start → Drive → Hostile Encounter → Radio Consequence → Paradise. The earlier iPhone 17 Pro run was contaminated by `com.electricengineer.training.game` and is not the authoritative result.
- Blender runtime probe: `/opt/homebrew/bin/blender` passed background Python startup and the staged environment export. Older installed Blender paths may still fail during Metal initialization; the safe exporter preserves existing USDZs on any preflight failure.
- Physical-device probe: `xcrun devicectl list devices` found the registered iPhone 17 Pro Max as `unavailable`; no usable physical device or development-team signing path is currently available on this host.

These results are preflight evidence, not a substitute for the interactive
simulator and physical-device steps below.

## Gate handoff matrix

| Gate | Current evidence | Required next evidence |
|---|---|---|
| Blender export | Safe environment wrapper passes isolated preflight, staged export, archive validation, and promotion; generic host probes remain intermittently Metal-sensitive | Repeat on the release host and retain promoted USDZ hashes |
| Simulator interaction | App installs, launches, renders, and completes the garage-to-Paradise UI route on a clean iPhone 17 Pro Max simulator | Record background/foreground, orientation, and persistence results |
| Device QA | No device run has been recorded | Signed hardware run covering controls, background/foreground, memory, thermal, and persistence |
| Final art quality | Procedural blockouts, variants, semantic labels, and budgets validate | Reference comparison renders and artist approval for hero meshes/materials |

1. Generate the Xcode project from project.yml.
2. Build the Swift package and app for an iPhone Simulator.
3. Launch into the garage and verify the bundled USDZ loads.
4. Walk to Kingmaker; inspect, diagnose, complete the repair work, and verify that start remains gated until the vehicle is startable.
5. Confirm the vehicle simulation and rendered asset remain synchronized.
6. Drive, trigger the hostile encounter, hear the radio consequence, and reach
   Paradise.
7. Save, terminate, relaunch, reload, and compare the complete state.
8. Test touch controls, orientation, background/foreground, and pause/resume.
9. Profile frame time, memory, thermal state, asset loading, and texture memory.
   Also verify VoiceOver navigation, Dynamic Type scaling, and Reduced Motion
   behavior; none of these are currently exercised by any automated test.
10. Repeat on at least one physical iPhone and record signing/device results.
