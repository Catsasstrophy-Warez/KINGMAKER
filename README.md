# DEAD HIGHWAY Rev9 — Production Gameplay Integration

# DEAD HIGHWAY — Rev7 Blackridge Playable App

Rev7 adds the Xcode app handoff, SwiftUI/RealityKit host, touch-control/HUD shell, player and vehicle controllers, interaction selection, audio/FX state, trading and settings while preserving the deterministic simulation architecture.

See `REV7_IMPLEMENTATION_REPORT.md`.

# DEAD HIGHWAY Rev6 — First Playable Foundation

Native Swift 6 simulation/game architecture for the Blackridge vertical slice.

Rev6 adds the first concrete playable presentation boundary: procedural RealityKit garage/highway/Paradise blockouts, isometric camera state, HUD and interaction state, streaming cells, and an executable opening runtime spanning garage exploration through the first Paradise trade.

## Build
`swift test`

## Important
This archive is an Xcode-ready Swift Package foundation, not a signed iPhone `.app`. Production art, animations, audio, touch/controller input, app target/signing and physical-device validation still require Xcode/macOS integration.

## Rev8 — Original Vision Audit + Living World Gameplay
Rev8 expands DEAD HIGHWAY beyond the garage/highway prototype with enterable-location and scavenging systems, environmental stories, character perks/equipment/injuries, ballistic and vehicle-combat foundations, negotiation and companion recruitment, vehicle theft/security, civilization infrastructure restoration, dynamic radio consequences, collision/navigation, vehicle entry/exit and animation state, and UI state for DMM/inventory/radio. See `REV8_IMPLEMENTATION_REPORT.md` for the line-by-line audit against the original game pitch.

Current portable validation: **44/44 Swift tests passing**.
