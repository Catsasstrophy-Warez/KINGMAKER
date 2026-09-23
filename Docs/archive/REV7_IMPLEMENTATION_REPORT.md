# DEAD HIGHWAY Rev7 — Blackridge Playable App

Rev7 converts the Rev6 first-playable presentation boundary into an Xcode-app handoff architecture.

## Added
- XcodeGen `project.yml` for an iPhone/iPad app with Mac Catalyst enabled.
- SwiftUI + RealityView application shell under `App/DeadHighwayApp`.
- HUD, pause/settings overlay, touch-control surface and procedural RealityKit scene host.
- Pure-Swift player locomotion and Kingmaker driving controllers.
- Interaction resolver for nearest usable world object.
- Simulation-derived engine-audio parameters and dust/skid/heat-haze FX state.
- Inventory/trading state and save-slot/settings presentation models.
- Rev7 regression tests for movement, driving, interaction, trading, audio and FX derivation.

## Architecture rule
The app layer remains a consumer of canonical simulation state. RealityKit entities, HUD values, audio parameters and effects are presentation outputs, never authoritative gameplay truth.

## macOS/Xcode handoff
Run `xcodegen generate` from the project root, open `DeadHighway.xcodeproj`, select an Apple Development team, then build the `DeadHighway` scheme for iPhone. Production assets, animation, final audio, device signing and physical-device validation remain Xcode/macOS tasks.
