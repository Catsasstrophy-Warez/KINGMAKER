import Foundation
import DHCore

public struct DHRev10CameraController: Codable, Equatable, Sendable {
    public var mode = "isometric"
    public var zoom = 1.0
    public var panX = 0.0
    public var panZ = 0.0
    public mutating func pan(x: Double, z: Double) { panX += x; panZ += z }
    public mutating func zoomBy(_ amount: Double) { zoom = min(2.0, max(0.5, zoom + amount)) }
    public mutating func follow(_ mode: String) { self.mode = mode }
}

public struct DHRev10NavigationQuery: Codable, Equatable, Sendable {
    public var blockedEntityIDs: Set<String> = []
    public var activeChunkIDs: Set<String> = ["garage"]
    public mutating func activate(_ chunkID: String) { activeChunkIDs.insert(chunkID) }
    public func canEnter(_ entityID: String) -> Bool { !blockedEntityIDs.contains(entityID) }
}

public struct DHRev10LootRuntime: Codable, Equatable, Sendable {
    public var containerID: String?
    public var searchedContainers: Set<String> = []
    public var collectedItemIDs: Set<String> = []
    public mutating func search(_ containerID: String) -> Bool { guard !searchedContainers.contains(containerID) else { return false }; self.containerID = containerID; searchedContainers.insert(containerID); return true }
    public mutating func collect(_ itemID: String) { collectedItemIDs.insert(itemID) }
}

public struct DHRev10ParadiseRuntime: Codable, Equatable, Sendable {
    public var negotiationOpen = false
    public var tradeOpen = false
    public var recruitedNPCID: String?
    public mutating func negotiate() { negotiationOpen = true }
    public mutating func trade() { tradeOpen = true }
    public mutating func recruit(_ npcID: String) { recruitedNPCID = npcID }
}

public struct DHRev10PerformanceSample: Codable, Equatable, Sendable {
    public var frameTimeMS = 0.0
    public var activeChunks = 0
    public var entityCount = 0
    public var thermalReduced = false
    public mutating func record(frameTimeMS: Double, activeChunks: Int, entityCount: Int) { self.frameTimeMS = frameTimeMS; self.activeChunks = activeChunks; self.entityCount = entityCount; thermalReduced = frameTimeMS > 33.3 }
}
