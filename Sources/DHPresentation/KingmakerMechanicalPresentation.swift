import Foundation

public struct KingmakerDeformationState: Codable, Equatable, Sendable {
    public var fenderFrontLeft = 0.0
    public var fenderFrontRight = 0.0
    public var doorLeft = 0.0
    public var doorRight = 0.0
    public var hood = 0.0
    public var roof = 0.0
    public mutating func apply(zone: String, energy: Double) {
        let value = min(1, max(0, energy))
        switch zone { case "frontLeft": fenderFrontLeft = max(fenderFrontLeft, value); case "frontRight": fenderFrontRight = max(fenderFrontRight, value); case "leftSide": doorLeft = max(doorLeft, value); case "rightSide": doorRight = max(doorRight, value); case "roof": roof = max(roof, value); default: hood = max(hood, value) }
    }
}

public struct KingmakerWheelAnimationState: Codable, Equatable, Sendable {
    public var wheelSpinRadians = 0.0
    public var steeringRadians = 0.0
    public var suspensionCompression = 0.0
    public mutating func step(speedMPS: Double, steer: Double, compression: Double, deltaTime: Double) { wheelSpinRadians.formTruncatingRemainder(dividingBy: .pi * 2); wheelSpinRadians += speedMPS / 0.34 * deltaTime; steeringRadians = max(-0.52, min(0.52, steer * 0.52)); suspensionCompression = max(0, min(1, compression)) }
}

public struct KingmakerAudioMixState: Codable, Equatable, Sendable {
    public var exhaustVolume = 0.0
    public var valvetrainVolume = 0.0
    public var superchargerVolume = 0.0
    public var playbackRate = 1.0
    public var activeFaultCue: String?
    public mutating func update(rpm: Double, maxRPM: Double, boostPSI: Double, faultCodes: [UInt32]) { let normalized = max(0, min(1, rpm / max(1, maxRPM))); exhaustVolume = normalized; valvetrainVolume = 0.2 + normalized * 0.8; superchargerVolume = max(0, min(1, boostPSI / 20)); playbackRate = 0.85 + normalized * 0.45; activeFaultCue = faultCodes.contains(0x021A) ? "radiator-overheat" : nil }
}

public struct KingmakerDashboardState: Codable, Equatable, Sendable {
    public var oilPressureNeedle = 0.0
    public var coolantTemperatureNeedle = 0.0
    public var checkEngineLight = false
    public var transmissionWarningLight = false
    public mutating func ingest(oilPressure: Double, coolantC: Double, faultCodes: [UInt32]) { oilPressureNeedle = max(0, min(1, oilPressure / 65)); coolantTemperatureNeedle = max(0, min(1, (coolantC - 60) / 80)); checkEngineLight = !faultCodes.isEmpty; transmissionWarningLight = coolantC > 120 }
}
