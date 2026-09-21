import Testing
import Foundation
@testable import DHVehicle

// KingmakerRev4.swift packs its physics formulas (engine response curve, tire-force friction
// circle, differential torque bias) onto single dense lines with terse names. These tests pin
// down the actual behavior so a future edit to that math can't silently change it unnoticed.

@Test func engineDynamicsIdlesDownWhenNotRunning() {
    var engine = EngineDynamics()
    engine.rpm = 3000
    engine.throttle = 1
    engine.step(running: false, load: 0, dt: 1)
    #expect(engine.rpm < 3000)
    #expect(engine.torqueNm == 0)
}

@Test func engineDynamicsRPMClimbsTowardThrottleTarget() {
    var engine = EngineDynamics()
    engine.throttle = 1
    for _ in 0..<20 { engine.step(running: true, load: 0, dt: 0.1) }
    // target = 850 + 1*6150 = 7000; rpm should have climbed substantially toward it from 0.
    #expect(engine.rpm > 3000)
    #expect(engine.rpm <= 7000)
}

@Test func engineDynamicsProducesNoTorqueAtZeroThrottleEvenAtRPM() {
    var engine = EngineDynamics()
    engine.rpm = 4500
    engine.throttle = 0
    engine.step(running: true, load: 0, dt: 0.1)
    #expect(engine.torqueNm == 0)
}

@Test func engineDynamicsLoadReductionClampsAtSixtyFivePercent() {
    var heavyLoad = EngineDynamics()
    heavyLoad.rpm = 4500
    heavyLoad.throttle = 1
    heavyLoad.step(running: true, load: 0.65, dt: 0.1)
    var overLoad = EngineDynamics()
    overLoad.rpm = 4500
    overLoad.throttle = 1
    overLoad.step(running: true, load: 1.0, dt: 0.1)
    #expect(heavyLoad.torqueNm == overLoad.torqueNm)
}

@Test func tireForceLongitudinalScalesWithSlipWithinCap() {
    var tire = TireForceState()
    tire.solve(normalN: 1000, mu: 1, slip: 0.1, slipAngle: 0)
    #expect(tire.longitudinalN == 500) // cap=1000, 1000*0.1*5=500, within cap
}

@Test func tireForceLongitudinalClampsAtFrictionCap() {
    var tire = TireForceState()
    tire.solve(normalN: 1000, mu: 1, slip: 1.0, slipAngle: 0)
    #expect(tire.longitudinalN == 1000) // 1000*1*5=5000, clamped to cap 1000
}

@Test func tireForceZeroSlipAngleGivesZeroLateral() {
    var tire = TireForceState()
    tire.solve(normalN: 1000, mu: 1, slip: 0.1, slipAngle: 0)
    #expect(tire.lateralN == 0)
}

@Test func tireForceFrictionCircleReducesLateralWhenLongitudinalUsed() {
    var pureLateral = TireForceState()
    pureLateral.solve(normalN: 1000, mu: 1, slip: 0, slipAngle: 0.2)
    var mixed = TireForceState()
    mixed.solve(normalN: 1000, mu: 1, slip: 0.8, slipAngle: 0.2)
    #expect(abs(mixed.lateralN) < abs(pureLateral.lateralN))
}

@Test func tireForceZeroGripSurfaceProducesNoForce() {
    var tire = TireForceState()
    tire.solve(normalN: 1000, mu: 0, slip: 1, slipAngle: 1)
    #expect(tire.longitudinalN == 0)
    #expect(tire.lateralN == 0)
}

@Test func differentialSplitsEvenlyWithEqualGrip() {
    let differential = DifferentialDynamics()
    let (left, right) = differential.split(inputTorque: 400, leftGrip: 1, rightGrip: 1)
    #expect(left == 200)
    #expect(right == 200)
}

@Test func differentialConservesTotalTorqueAcrossGripSplits() {
    let differential = DifferentialDynamics(lock: 0.25)
    let (left, right) = differential.split(inputTorque: 400, leftGrip: 0.2, rightGrip: 0.9)
    #expect(abs((left + right) - 400) < 0.0001)
    // open-diff behavior: torque follows the path of least resistance, so the LOWER-grip side
    // (left, 0.2) gets more torque than the higher-grip side (right, 0.9) -- this is realistic
    // (it's also why an open diff needs a locker: an unloaded/spinning wheel gets more torque,
    // not less).
    #expect(left > right)
}

@Test func differentialFullLockIgnoresGripDifference() {
    let locked = DifferentialDynamics(lock: 1)
    let (left, right) = locked.split(inputTorque: 400, leftGrip: 0.1, rightGrip: 0.9)
    #expect(left == 200)
    #expect(right == 200)
}
