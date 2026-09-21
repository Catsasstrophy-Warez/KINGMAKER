import Foundation

public struct KingmakerCollisionBounds: Codable, Equatable, Sendable {
    public var length: Double = 4.8
    public var width: Double = 1.95
    public var height: Double = 1.45
    public var radius: Double { max(length, width) * 0.5 }
    public init() {}
    public func overlaps(with other: KingmakerCollisionBounds, distance: Double) -> Bool { distance < radius + other.radius }
}

public struct KingmakerCollisionState: Codable, Equatable, Sendable {
    public var bounds = KingmakerCollisionBounds()
    public var impactEnergy = 0.0
    public var disabled = false
    public init() {}
    public mutating func impact(relativeSpeedMPS: Double, otherMassKG: Double) {
        impactEnergy += max(0, 0.5 * otherMassKG * relativeSpeedMPS * relativeSpeedMPS / 1000)
        if impactEnergy >= 180 { disabled = true }
    }
}
