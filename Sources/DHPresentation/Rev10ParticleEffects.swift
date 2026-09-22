import Foundation

#if canImport(RealityKit)
import RealityKit
#if canImport(SwiftUI)
import SwiftUI
#endif

// VFX/particles were previously state-only (DHFXBudget just tracks a particle-count budget with
// nothing actually emitting). This wires that budget to RealityKit's real ParticleEmitterComponent
// so effects genuinely render -- still placeholder-tier (simple point/burst emitters, no authored
// VFX textures or shaders), but it emits real particles instead of only tracking a number.
@available(iOS 18.0, macOS 15.0, *)
@MainActor
public enum DHRev10ParticleEffects {
    /// Ambient road/garage dust: a slow, wide, low-opacity drift. Birth rate scales with the
    /// current FX budget so thermalThrottle() visibly reduces particle density, not just a
    /// number nobody reads.
    public static func dust(budget: DHFXBudget) -> ParticleEmitterComponent {
        var emitter = ParticleEmitterComponent()
        emitter.emitterShape = .box
        emitter.emitterShapeSize = [3, 0.2, 3]
        emitter.mainEmitter.birthRate = Float(budget.dustParticles) / 4
        emitter.mainEmitter.color = .constant(.single(.init(white: 0.55, alpha: 0.18)))
        emitter.mainEmitter.size = 0.03
        emitter.mainEmitter.sizeVariation = 0.02
        emitter.mainEmitter.lifeSpan = 4
        emitter.mainEmitter.lifeSpanVariation = 1.5
        emitter.speed = 0.05
        emitter.speedVariation = 0.05
        emitter.mainEmitter.acceleration = [0, 0.02, 0]
        emitter.isEmitting = true
        return emitter
    }

    /// Collision/impact debris: a short, energetic burst, sized to the impact severity (0...1,
    /// typically KingmakerCollisionState.impactEnergy normalized against the disable threshold).
    public static func collisionDebris(severity: Double) -> ParticleEmitterComponent {
        var emitter = ParticleEmitterComponent()
        let clamped = max(0, min(1, severity))
        emitter.emitterShape = .point
        emitter.mainEmitter.birthRate = Float(40 + clamped * 260)
        emitter.mainEmitter.color = .constant(.single(.init(white: 0.35, alpha: 0.9)))
        emitter.mainEmitter.size = Float(0.02 + clamped * 0.05)
        emitter.mainEmitter.sizeVariation = 0.02
        emitter.mainEmitter.lifeSpan = 0.6
        emitter.mainEmitter.lifeSpanVariation = 0.3
        emitter.speed = Float(0.5 + clamped * 2.5)
        emitter.speedVariation = 0.4
        emitter.mainEmitter.acceleration = [0, -1.2, 0]
        emitter.isEmitting = true
        return emitter
    }

    /// Engine bay heat haze: a small, fast-lived, near-invisible upward drift used while the
    /// engine is running or overheating, driven by ThermalFeedbackComponent.thermalLoad.
    public static func heatHaze(thermalLoad: Double) -> ParticleEmitterComponent {
        var emitter = ParticleEmitterComponent()
        let clamped = max(0, min(1, thermalLoad))
        emitter.emitterShape = .box
        emitter.emitterShapeSize = [0.4, 0.05, 0.3]
        emitter.mainEmitter.birthRate = Float(20 + clamped * 180)
        emitter.mainEmitter.color = .constant(.single(.init(white: 1.0, alpha: 0.06)))
        emitter.mainEmitter.size = 0.08
        emitter.mainEmitter.lifeSpan = 1.2
        emitter.speed = Float(0.15 + clamped * 0.35)
        emitter.mainEmitter.acceleration = [0, 0.4, 0]
        emitter.isEmitting = clamped > 0.05
        return emitter
    }

    /// Applies DHFXBudget.thermalThrottle()'s halved counts to a live emitter's birth rate, so
    /// the render-budget/thermal system actually affects what's on screen.
    public static func applyThermalThrottle(_ budget: DHFXBudget, to emitter: inout ParticleEmitterComponent) {
        emitter.mainEmitter.birthRate = Float(budget.dustParticles) / 4
    }

    /// Falling rain: dense, fast, downward streaks over a wide overhead emitter box. Intensity
    /// (0...1) scales birth rate and speed so a light drizzle and a downpour are visibly
    /// different, not just an on/off toggle.
    public static func rain(intensity: Double, budget: DHFXBudget) -> ParticleEmitterComponent {
        var emitter = ParticleEmitterComponent()
        let clamped = max(0, min(1, intensity))
        emitter.emitterShape = .box
        emitter.emitterShapeSize = [8, 0.1, 8]
        emitter.mainEmitter.birthRate = Float(Double(budget.dustParticles) * (0.5 + clamped * 2.5))
        emitter.mainEmitter.color = .constant(.single(.init(white: 0.75, alpha: 0.35)))
        emitter.mainEmitter.size = 0.01
        emitter.mainEmitter.sizeVariation = 0.005
        emitter.mainEmitter.lifeSpan = 0.8
        emitter.mainEmitter.lifeSpanVariation = 0.1
        emitter.speed = Float(2.5 + clamped * 4.0)
        emitter.speedVariation = 0.3
        emitter.mainEmitter.acceleration = [0, -6, 0]
        emitter.isEmitting = clamped > 0.02
        return emitter
    }

    /// Mud/splash kickup from wheels on a wet road surface, scaled by vehicle speed (0...1
    /// normalized) and how saturated the ground is (wetness 0...1, e.g. accumulated rain).
    public static func mudKickup(speed: Double, wetness: Double) -> ParticleEmitterComponent {
        var emitter = ParticleEmitterComponent()
        let clampedSpeed = max(0, min(1, speed))
        let clampedWetness = max(0, min(1, wetness))
        emitter.emitterShape = .point
        emitter.mainEmitter.birthRate = Float(clampedSpeed * clampedWetness * 220)
        emitter.mainEmitter.color = .constant(.single(.init(red: 0.22, green: 0.16, blue: 0.1, alpha: 0.85)))
        emitter.mainEmitter.size = Float(0.02 + clampedSpeed * 0.04)
        emitter.mainEmitter.sizeVariation = 0.015
        emitter.mainEmitter.lifeSpan = 0.5
        emitter.mainEmitter.lifeSpanVariation = 0.2
        emitter.speed = Float(0.8 + clampedSpeed * 3.0)
        emitter.speedVariation = 0.5
        emitter.mainEmitter.acceleration = [0, -3.5, 0]
        emitter.isEmitting = clampedSpeed > 0.05 && clampedWetness > 0.05
        return emitter
    }

    /// Ground fog for low-visibility wasteland weather: dense, slow-drifting, wide and flat.
    public static func groundFog(density: Double) -> ParticleEmitterComponent {
        var emitter = ParticleEmitterComponent()
        let clamped = max(0, min(1, density))
        emitter.emitterShape = .box
        emitter.emitterShapeSize = [12, 0.6, 12]
        emitter.mainEmitter.birthRate = Float(10 + clamped * 90)
        emitter.mainEmitter.color = .constant(.single(.init(white: 0.6, alpha: CGFloat(0.05 + clamped * 0.15))))
        emitter.mainEmitter.size = 0.6
        emitter.mainEmitter.sizeVariation = 0.2
        emitter.mainEmitter.lifeSpan = 8
        emitter.mainEmitter.lifeSpanVariation = 2
        emitter.speed = 0.03
        emitter.speedVariation = 0.02
        emitter.isEmitting = clamped > 0.02
        return emitter
    }
}
#endif
