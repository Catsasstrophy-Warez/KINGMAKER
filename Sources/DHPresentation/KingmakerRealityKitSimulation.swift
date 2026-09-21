import Foundation

#if canImport(RealityKit)
import RealityKit

@available(iOS 18.0, macOS 15.0, *)
public struct PowertrainComponent: Component, Codable, Sendable, Equatable {
    public var engineRPM: Float = 0
    public var maxRPM: Float = 7500
    public var coolantTemperature: Float = 90
    public var oilPressure: Float = 65
    public var blockIntegrity: Float = 1
    public var superchargerClutchEngaged = false
    public var manifoldPressure: Float = 0
    public init() {}
}

@available(iOS 18.0, macOS 15.0, *)
public struct TransmissionComponent: Component, Codable, Sendable, Equatable {
    public var currentGear = 1
    public var isShifting = false
    public var clutchClampingForce: Float = 0
    public var transmissionFluidTemp: Float = 85
    public init() {}
}

@available(iOS 18.0, macOS 15.0, *)
public struct TelemetryComponent: Component, Codable, Sendable, Equatable {
    public var activeFaultCodes: [UInt32] = []
    public init() {}
}

@available(iOS 18.0, macOS 15.0, *)
public struct ThermalFeedbackComponent: Component, Codable, Sendable, Equatable {
    public var thermalLoad: Float = 0
    public var seizureState = false
    public init() {}
}

@available(iOS 18.0, macOS 15.0, *)
public enum KingmakerRealityKitSimulation {
    public static let overheatingFault: UInt32 = 0x021A
    public static func step(powertrain: inout PowertrainComponent, transmission: inout TransmissionComponent, telemetry: inout TelemetryComponent, thermal: inout ThermalFeedbackComponent, deltaTime: Float) {
        guard deltaTime > 0 else { return }
        if powertrain.engineRPM > 0 {
            var heatDelta = powertrain.engineRPM / max(1, powertrain.maxRPM) * 2
            if powertrain.superchargerClutchEngaged { heatDelta *= 1.5 }
            powertrain.coolantTemperature += heatDelta * deltaTime
        }
        if powertrain.coolantTemperature > 115 {
            powertrain.oilPressure -= 5 * deltaTime
            powertrain.blockIntegrity -= 0.02 * deltaTime
            if !telemetry.activeFaultCodes.contains(overheatingFault) { telemetry.activeFaultCodes.append(overheatingFault) }
        }
        if powertrain.blockIntegrity <= 0 || powertrain.oilPressure <= 10 {
            powertrain.engineRPM = 0
            powertrain.superchargerClutchEngaged = false
            thermal.seizureState = true
        }
        if transmission.transmissionFluidTemp > 120 { transmission.clutchClampingForce *= 0.8 }
        thermal.thermalLoad = max(0, min(1, (powertrain.coolantTemperature - 90) / 40))
    }
}

@available(iOS 18.0, macOS 15.0, *)
public final class KingmakerVehicleSimulationSystem: System {
    private static let mechanicalQuery = EntityQuery(where: .has(PowertrainComponent.self) && .has(TransmissionComponent.self))
    public required init(scene: RealityKit.Scene) {}
    public func update(context: SceneUpdateContext) {
        let deltaTime = Float(context.deltaTime)
        for entity in context.scene.performQuery(Self.mechanicalQuery) {
            var powertrain = entity.components[PowertrainComponent.self] ?? PowertrainComponent()
            var transmission = entity.components[TransmissionComponent.self] ?? TransmissionComponent()
            var telemetry = entity.components[TelemetryComponent.self] ?? TelemetryComponent()
            var thermal = entity.components[ThermalFeedbackComponent.self] ?? ThermalFeedbackComponent()
            KingmakerRealityKitSimulation.step(powertrain: &powertrain, transmission: &transmission, telemetry: &telemetry, thermal: &thermal, deltaTime: deltaTime)
            entity.components[PowertrainComponent.self] = powertrain
            entity.components[TransmissionComponent.self] = transmission
            entity.components[TelemetryComponent.self] = telemetry
            entity.components[ThermalFeedbackComponent.self] = thermal
        }
    }
}
#endif
