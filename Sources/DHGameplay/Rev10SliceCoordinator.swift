import Foundation
import DHCore
import DHWorld
import DHVehicle
import DHCombat
import DHNPC
import DHFleet

public enum DHRev10InspectionMode: String, Codable, Sendable { case world, kingmakerExterior, engineBay, cabin, damage, dmm }
public enum DHRev10PlayerMode: String, Codable, Sendable { case onFoot, inspecting, repairing, driving, combat, dialogue }
public struct DHRev10ScenePoint: Codable, Equatable, Sendable { public var x: Double; public var y: Double; public var z: Double; public init(x: Double = 0, y: Double = 0, z: Double = 0) { self.x = x; self.y = y; self.z = z } }

public struct DHRev10SliceCoordinator: Codable, Equatable, Sendable {
    public var playerMode: DHRev10PlayerMode = .onFoot
    public var inspectionMode: DHRev10InspectionMode = .world
    public var currentChunkID = "garage"
    public var currentLocationID = "garage"
    public var playerPosition = DHRev10ScenePoint()
    public var cameraPosition = DHRev10ScenePoint(x: 0, y: 18, z: 18)
    public var kingmaker = KingmakerState.derelict()
    public var encounterPresentation = "hidden"
    public var radioText = "NO SIGNAL"
    public var streamedChunkIDs: Set<String> = ["garage"]
    public var lootCollected: Set<String> = []
    public var recruitedNPCID: String?
    public var encounter = DHVehicleEncounterRuntime()
    /// Named DHProductionNPCRoster/DHProductionVehicleRoster IDs currently spawned into the
    /// world. Previously ProductionRoster.swift's makePopulation()/makeFleet() produced content
    /// nothing in the live slice consumed; populateProductionRoster(forSite:) is how the
    /// coordinator actually puts named roster entries into the world instead of only being able
    /// to construct them off to the side.
    public var spawnedNPCIDs: Set<String> = []
    public var spawnedVehicleIDs: Set<String> = []
    public init() {}
    public mutating func populateProductionRoster(forSite site: BlackridgeSite) {
        for entry in DHProductionNPCRoster.entries where entry.home == site {
            spawnedNPCIDs.insert(entry.id)
        }
    }
    public mutating func populateProductionVehicleRoster() {
        for entry in DHProductionVehicleRoster.entries {
            spawnedVehicleIDs.insert(entry.id)
        }
    }
    public mutating func synchronizeVehicle(_ vehicle: KingmakerState) { kingmaker = vehicle }
    public mutating func inspect(_ mode: DHRev10InspectionMode) { playerMode = .inspecting; inspectionMode = mode }
    public mutating func stopInspecting() { playerMode = .onFoot; inspectionMode = .world }
    public mutating func movePlayer(to position: DHRev10ScenePoint, county: DHBlackridgeCounty = .verticalSlice) { playerPosition = position; cameraPosition = DHRev10ScenePoint(x: position.x, y: position.y + 18, z: position.z + 18); _ = county }
    public mutating func stream(center: String, neighbors: [String]) { currentChunkID = center; streamedChunkIDs = Set([center] + neighbors) }
    public mutating func repair() {
        kingmaker.components = kingmaker.components.map { var component = $0; component.condition = .serviceable; return component }
        playerMode = .repairing
        inspectionMode = .engineBay
    }
    public mutating func start() {
        kingmaker.fuelLiters = max(kingmaker.fuelLiters, 12)
        kingmaker.fuelPressureKPa = max(kingmaker.fuelPressureKPa, 350)
        kingmaker.batterySOC = max(kingmaker.batterySOC, 0.92)
        _ = kingmaker.crank(seconds: 1)
        playerMode = .driving
    }
    public mutating func repairAndStart() { kingmaker.fuelLiters = max(kingmaker.fuelLiters, 12); kingmaker.fuelPressureKPa = 350; kingmaker.batterySOC = max(kingmaker.batterySOC, 0.9); kingmaker.components = kingmaker.components.map { var c = $0; c.condition = .serviceable; return c }; _ = kingmaker.crank(seconds: 1); playerMode = .driving }
    public mutating func resolveEncounter() { encounter.resolve(); encounterPresentation = "disabled"; radioText = "HOSTILE VEHICLE ENCOUNTER RESOLVED" }
    public mutating func recruit(_ id: String) { recruitedNPCID = id; playerMode = .dialogue }
}
