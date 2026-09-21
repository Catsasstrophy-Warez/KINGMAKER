import Foundation
import DHWorld
import DHNPC
import DHCombat

public enum DHPlayableMode: String, Sendable, Codable { case onFoot, driving, interior, combat, dialogue, garage }
public struct DHProductionGameplayRuntime: Sendable {
    public var mode: DHPlayableMode = .onFoot
    public var streamer = DHWorldStreamer()
    public var agents: [String: DHAgentBrain] = [:]
    public var player = DHCombatantState(id: "player", ammo: 12)
    public var discoveredLocations: Set<String> = []
    public var enteredVehicleID: String?
    public init() {}
    public mutating func enterInterior(_ portal: DHInteriorPortal) -> Bool { guard !portal.locked else { return false }; mode = .interior; discoveredLocations.insert(portal.exteriorLocationID); return true }
    public mutating func enterVehicle(_ id: String) { enteredVehicleID = id; mode = .driving }
    public mutating func exitVehicle() { enteredVehicleID = nil; mode = .onFoot }
    public mutating func beginCombat() { mode = .combat }
    public mutating func endCombat() { mode = enteredVehicleID == nil ? .onFoot : .driving }
}
