import Foundation
import Testing
@testable import DHWorld
@testable import DHVehicle
@testable import DHNPC
@testable import DHCombat
@testable import DHGameplay
@testable import DHPresentation

// Split out of the former Rev9ProductionGameplayTests.swift. This group covers the Kingmaker
// vehicle's build/profile/condition/operational systems, repair and collision runtimes, and
// the mechanical presentation (deformation, wheel animation, audio mix, dashboard).

@Test func kingmakerVisualStateMapsAuthoritativeCondition() {
    let component = KingmakerState.derelict().components[0]
    let visual = KingmakerComponentVisualState(componentID: component.id.uuidString, condition: component.condition)
    #expect(visual.profile.state == .broken)
    #expect(visual.profile.repairable == false)
}

@Test func repairRuntimePersistsPartialWorkAndAppliesCompletedSteps() {
    var repairs = DHRepairRuntime()
    let firstWork = repairs.work(on: "cooling.radiator", seconds: 2, skill: 1)
    #expect(firstWork)
    #expect(repairs.steps.first?.state == .inProgress)
    let secondWork = repairs.work(on: "cooling.radiator", seconds: 2, skill: 1)
    #expect(secondWork)
    #expect(repairs.steps.first?.state == .complete)
    var vehicle = KingmakerState.derelict()
    repairs.apply(to: &vehicle)
    #expect(vehicle.hasViable(.cooling))
}

@Test func kingmakerCollisionStateDisablesAtSevereImpact() {
    var collision = KingmakerCollisionState()
    collision.impact(relativeSpeedMPS: 25, otherMassKG: 700)
    #expect(collision.impactEnergy > 0)
    collision.impact(relativeSpeedMPS: 25, otherMassKG: 700)
    #expect(collision.disabled)
}

@Test func kingmakerBuildPathsPreserveOneVehicleIdentity() {
    let restored = KingmakerVisualSpec(path: .restored)
    let wasteland = KingmakerVisualSpec(path: .wastelandEndurance)
    let hybrid = KingmakerVisualSpec(path: .hybrid)
    #expect(restored.path == .restored)
    #expect(wasteland.armorLevel > restored.armorLevel)
    #expect(hybrid.aeroLevel == 3)
    #expect(hybrid.cargoLevel == 2)
}

@Test func kingmakerProfileUnifiesMechanicalAndVisualBuildData() {
    let profile = KingmakerProfile(buildPath: .armoredPursuit)
    #expect(profile.identity == "Blackridge XR-13 Kingmaker")
    #expect(profile.componentCount == 254)
    #expect(profile.transmissionGears == 6)
    #expect(profile.hazardousEnvironmentRating == 2)
    #expect(profile.cargoCapacity > 40)
}

@Test func kingmakerOperationalStateConnectsCraftMotionAndFailure() {
    var state = KingmakerOperationalState()
    state.apply(.explosionProofConduit); state.apply(.e85Conversion); state.begin(.coldStart); state.begin(.idling)
    #expect(state.canDrive)
    state.fail(.blownHeadGasket)
    #expect(!state.canDrive && state.motion == .disabled)
    state.recover(); state.begin(.towing)
    #expect(state.failure == .none && state.motion == .towing)
}

@Test func kingmakerConditionStatesMapSimulationToVisualPresentation() {
    #expect(KingmakerConditionVisualProfile.from(.poor).state == .damaged)
    #expect(KingmakerConditionVisualProfile.from(.failed).state == .broken)
    #expect(KingmakerConditionVisualProfile.from(.good).state == .repaired)
    #expect(KingmakerConditionVisualProfile(state: .rusted).rustAmount == 1)
}

@Test func kingmakerThermalSimulationProducesDiegeticFaultState() {
    var powertrain = PowertrainComponent(); powertrain.engineRPM = 7000; powertrain.coolantTemperature = 120; powertrain.oilPressure = 11
    var transmission = TransmissionComponent(); transmission.transmissionFluidTemp = 125; transmission.clutchClampingForce = 1
    var telemetry = TelemetryComponent(); var thermal = ThermalFeedbackComponent()
    KingmakerRealityKitSimulation.step(powertrain: &powertrain, transmission: &transmission, telemetry: &telemetry, thermal: &thermal, deltaTime: 1)
    #expect(telemetry.activeFaultCodes.contains(KingmakerRealityKitSimulation.overheatingFault))
    #expect(thermal.thermalLoad > 0)
    #expect(transmission.clutchClampingForce < 1)
}

@Test func kingmakerMechanicalPresentationDrivesVisualAudioAndDashboardState() {
    var deformation = KingmakerDeformationState(); deformation.apply(zone: "frontLeft", energy: 0.7)
    var wheels = KingmakerWheelAnimationState(); wheels.step(speedMPS: 12, steer: 0.5, compression: 0.4, deltaTime: 0.1)
    var audio = KingmakerAudioMixState(); audio.update(rpm: 4000, maxRPM: 7500, boostPSI: 10, faultCodes: [0x021A])
    var dashboard = KingmakerDashboardState(); dashboard.ingest(oilPressure: 8, coolantC: 125, faultCodes: [0x021A])
    #expect(deformation.fenderFrontLeft == 0.7); #expect(wheels.wheelSpinRadians > 0); #expect(audio.activeFaultCue == "radiator-overheat"); #expect(dashboard.checkEngineLight && dashboard.transmissionWarningLight)
}
