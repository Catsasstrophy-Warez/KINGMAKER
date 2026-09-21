import Foundation

public struct DHWorldTile: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    public var kind: Kind
    public var elevation: Double
    public var traversable: Bool
    public enum Kind: String, Sendable, Codable { case asphalt, dirt, rubble, interior, water, rail, vegetation }
}

public struct DHStreamChunk: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    public var regionID: String
    public var tiles: [DHWorldTile]
    public var locationIDs: [String]
    public var loaded: Bool
}

public struct DHWorldStreamer: Sendable, Codable, Equatable {
    public var chunks: [String: DHStreamChunk] = [:]
    public var active: Set<String> = []
    public init(chunks: [String: DHStreamChunk] = [:], active: Set<String> = []) { self.chunks = chunks; self.active = active }
    public mutating func register(_ chunk: DHStreamChunk) { chunks[chunk.id] = chunk }
    public mutating func activate(center: String, neighbors: [String]) {
        active = Set([center] + neighbors)
        for id in chunks.keys { chunks[id]?.loaded = active.contains(id) }
    }
}

public struct DHInteriorPortal: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    public let exteriorLocationID: String
    public let interiorChunkID: String
    public var locked: Bool
}

public struct DHEnvironmentalSpawn: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    public var archetype: String
    public var density: Double
    public var simulationRelevant: Bool
}
