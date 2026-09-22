import Foundation
import Testing
@testable import DHPresentation

#if canImport(RealityKit)
@available(iOS 18.0, macOS 15.0, *)
@Test @MainActor func dustEmitterBirthRateTracksFXBudget() {
    var budget = DHFXBudget()
    let full = DHRev10ParticleEffects.dust(budget: budget)
    budget.thermalThrottle()
    let throttled = DHRev10ParticleEffects.dust(budget: budget)
    #expect(throttled.mainEmitter.birthRate < full.mainEmitter.birthRate)
}

@available(iOS 18.0, macOS 15.0, *)
@Test @MainActor func collisionDebrisScalesWithSeverity() {
    let mild = DHRev10ParticleEffects.collisionDebris(severity: 0.1)
    let severe = DHRev10ParticleEffects.collisionDebris(severity: 1.0)
    #expect(severe.mainEmitter.birthRate > mild.mainEmitter.birthRate)
    #expect(severe.mainEmitter.size > mild.mainEmitter.size)
}

@available(iOS 18.0, macOS 15.0, *)
@Test @MainActor func heatHazeStopsEmittingBelowThreshold() {
    let cold = DHRev10ParticleEffects.heatHaze(thermalLoad: 0)
    let hot = DHRev10ParticleEffects.heatHaze(thermalLoad: 0.8)
    #expect(cold.isEmitting == false)
    #expect(hot.isEmitting)
}

@available(iOS 18.0, macOS 15.0, *)
@Test @MainActor func applyThermalThrottleUpdatesLiveEmitter() {
    var budget = DHFXBudget()
    var emitter = DHRev10ParticleEffects.dust(budget: budget)
    let before = emitter.mainEmitter.birthRate
    budget.thermalThrottle()
    DHRev10ParticleEffects.applyThermalThrottle(budget, to: &emitter)
    #expect(emitter.mainEmitter.birthRate < before)
}

@available(iOS 18.0, macOS 15.0, *)
@Test @MainActor func rainIntensityScalesBirthRateAndStopsAtZero() {
    let budget = DHFXBudget()
    let none = DHRev10ParticleEffects.rain(intensity: 0, budget: budget)
    let heavy = DHRev10ParticleEffects.rain(intensity: 1.0, budget: budget)
    #expect(none.isEmitting == false)
    #expect(heavy.isEmitting)
    #expect(heavy.mainEmitter.birthRate > none.mainEmitter.birthRate)
    #expect(heavy.speed > 2.5)
}

@available(iOS 18.0, macOS 15.0, *)
@Test @MainActor func mudKickupRequiresBothSpeedAndWetness() {
    let dryFast = DHRev10ParticleEffects.mudKickup(speed: 1.0, wetness: 0)
    let wetSlow = DHRev10ParticleEffects.mudKickup(speed: 0, wetness: 1.0)
    let wetFast = DHRev10ParticleEffects.mudKickup(speed: 1.0, wetness: 1.0)
    #expect(dryFast.isEmitting == false)
    #expect(wetSlow.isEmitting == false)
    #expect(wetFast.isEmitting)
    #expect(wetFast.mainEmitter.birthRate > 0)
}

@available(iOS 18.0, macOS 15.0, *)
@Test @MainActor func groundFogDensityControlsEmissionAndOpacity() {
    let clear = DHRev10ParticleEffects.groundFog(density: 0)
    let thick = DHRev10ParticleEffects.groundFog(density: 1.0)
    #expect(clear.isEmitting == false)
    #expect(thick.isEmitting)
    #expect(thick.mainEmitter.birthRate > clear.mainEmitter.birthRate)
}
#endif
