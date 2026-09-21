import Foundation

public enum KingmakerMotionState: String, Codable, Sendable { case parked, coldStart, idling, launching, braking, articulating, disabled, towing }
public enum KingmakerFailureState: String, Codable, Sendable { case none, overheating, blownHeadGasket, deadBattery, shatteredDriveshaft, tireBlowout, warpedChassis, rollover }
public enum KingmakerCraftAction: String, Codable, Sendable { case armorPlate, dryDeckSeal, shockTowerBrace, scavengedHeadlights, e85Conversion, explosionProofConduit, gasFiltration, solarCargoRack }

public struct KingmakerOperationalState: Codable, Equatable, Sendable {
    public var motion: KingmakerMotionState = .parked
    public var failure: KingmakerFailureState = .none
    public var installedCraft: Set<KingmakerCraftAction> = []
    public var bodyDeformation = KingmakerDeformationState()
    public var wheelAnimation = KingmakerWheelAnimationState()
    public var audio = KingmakerAudioMixState()
    public var dashboard = KingmakerDashboardState()
    public var canDrive: Bool { failure == .none && motion != .disabled }
    public mutating func apply(_ action: KingmakerCraftAction) { installedCraft.insert(action) }
    public mutating func begin(_ state: KingmakerMotionState) { motion = state }
    public mutating func fail(_ state: KingmakerFailureState) { failure = state; motion = .disabled }
    public mutating func recover() { failure = .none; motion = .parked }
}
