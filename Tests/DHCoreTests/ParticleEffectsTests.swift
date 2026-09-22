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
#endif
