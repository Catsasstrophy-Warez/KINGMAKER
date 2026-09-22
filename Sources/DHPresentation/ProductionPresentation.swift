import Foundation

public struct DHIsometricCameraRig: Sendable, Codable, Equatable {
    public var pitchDegrees: Double = 52
    public var yawDegrees: Double = 45
    public var distance: Double = 18
    public var lookAhead: Double = 3
    public mutating func driving(speed: Double) { distance = min(34, 18 + abs(speed) * 0.18); lookAhead = min(12, 3 + abs(speed) * 0.1) }
}
public struct DHInteractionPrompt: Sendable, Codable, Equatable { public var targetID: String; public var verb: String; public var enabled: Bool }
public struct DHFXBudget: Sendable, Codable, Equatable {
    public var dustParticles: Int = 800
    public var debrisParticles: Int = 200
    public var activeDynamicLights: Int = 6
    public mutating func thermalThrottle() { dustParticles /= 2; debrisParticles /= 2; activeDynamicLights = max(2, activeDynamicLights / 2) }
}
