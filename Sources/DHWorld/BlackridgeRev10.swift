import Foundation

public enum DHBlackridgeLocationKind: String, Codable, Sendable { case garage, scrapyard, town, mine, railYard, fuelDepot, substation, farm, truckStop, paradise, storySite }

public struct DHBlackridgeLocation: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let kind: DHBlackridgeLocationKind
    public let chunkID: String
    public let interiorChunkID: String?
    public let encounterSpawnIDs: [String]
    public init(id: String, name: String, kind: DHBlackridgeLocationKind, chunkID: String, interiorChunkID: String? = nil, encounterSpawnIDs: [String] = []) { self.id = id; self.name = name; self.kind = kind; self.chunkID = chunkID; self.interiorChunkID = interiorChunkID; self.encounterSpawnIDs = encounterSpawnIDs }
}

public struct DHRoadEdge: Codable, Equatable, Sendable, Identifiable { public let id: String; public let from: String; public let to: String; public let distanceMeters: Double; public let traversable: Bool }

public struct DHBlackridgeCounty: Codable, Equatable, Sendable {
    public var locations: [DHBlackridgeLocation]
    public var roads: [DHRoadEdge]
    public var chunks: [DHStreamChunk]
    public init(locations: [DHBlackridgeLocation], roads: [DHRoadEdge], chunks: [DHStreamChunk]) { self.locations = locations; self.roads = roads; self.chunks = chunks }
    public static let verticalSlice: Self = {
        let names: [(String, String, DHBlackridgeLocationKind, String, String?)] = [
            ("garage", "Kingmaker Garage", .garage, "garage", "garageInterior"), ("scrapyard", "Blackridge Scrapyard", .scrapyard, "northApproach", nil),
            ("ruinedTown", "Old Blackridge", .town, "oldTown", "oldTownInterior"), ("mine", "Cinder Mine", .mine, "mineRoad", nil),
            ("railYard", "East Rail Yard", .railYard, "railDistrict", nil), ("fuelDepot", "County Fuel Depot", .fuelDepot, "industrial", nil),
            ("substation", "Blackridge Substation", .substation, "industrial", nil), ("farm", "Morrow Farm", .farm, "southFields", nil),
            ("truckStop", "Last Chance Truck Stop", .truckStop, "southHighway", "truckStopInterior"), ("paradise", "Paradise", .paradise, "paradise", "paradiseInterior")
        ]
        let locations = names.map { DHBlackridgeLocation(id: $0.0, name: $0.1, kind: $0.2, chunkID: $0.3, interiorChunkID: $0.4, encounterSpawnIDs: ["\($0.0)-convoy", "\($0.0)-scavenge"]) }
        let links = [("garage", "scrapyard"), ("scrapyard", "ruinedTown"), ("ruinedTown", "mine"), ("ruinedTown", "railYard"), ("railYard", "fuelDepot"), ("fuelDepot", "substation"), ("garage", "farm"), ("farm", "truckStop"), ("truckStop", "paradise")]
        let roads = links.enumerated().map { DHRoadEdge(id: "road-\($0.offset)", from: $0.element.0, to: $0.element.1, distanceMeters: 850 + Double($0.offset * 190), traversable: true) }
        let chunks = locations.map { DHStreamChunk(id: $0.chunkID, regionID: "blackridge", tiles: [], locationIDs: [$0.id], loaded: false) }
        return Self(locations: locations, roads: roads, chunks: chunks)
    }()
}
