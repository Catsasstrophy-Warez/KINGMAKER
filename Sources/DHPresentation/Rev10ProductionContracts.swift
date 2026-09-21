import Foundation

public enum DHRev10RenderQuality: String, Codable, Sendable { case diagnostic, production, thermalReduced }
public struct DHRev10RenderBudget: Codable, Equatable, Sendable {
    public var quality: DHRev10RenderQuality = .diagnostic
    public var activeChunkLimit = 3
    public var dynamicLightLimit = 8
    public var particleLimit = 1200
    public mutating func reduceForThermals() { quality = .thermalReduced; activeChunkLimit = 2; dynamicLightLimit = 3; particleLimit = 400 }
}

public struct DHRev10NavigationContract: Codable, Equatable, Sendable {
    public let chunkID: String
    public let navmeshAssetID: String
    public var walkable: Bool
    public var vehicleAccessible: Bool
    public init(chunkID: String, navmeshAssetID: String, walkable: Bool = true, vehicleAccessible: Bool = true) { self.chunkID = chunkID; self.navmeshAssetID = navmeshAssetID; self.walkable = walkable; self.vehicleAccessible = vehicleAccessible }
}

public enum DHRev10AudioCue: String, Codable, Sendable { case engineCrank, engineStart, engineKnock, repair, lootOpen, lootCollect, hostileTelegraph, hostileAttack, radioStatic, radioConsequence, paradiseNegotiation }
public struct DHRev10AudioState: Codable, Equatable, Sendable {
    public var activeCues: [DHRev10AudioCue] = []
    public var radioMix = 1.0
    public mutating func trigger(_ cue: DHRev10AudioCue) { if !activeCues.contains(cue) { activeCues.append(cue) } }
    public mutating func clear(_ cue: DHRev10AudioCue) { activeCues.removeAll { $0 == cue } }
}

public enum DHRev10ProductionContract {
    public static let navigation: [DHRev10NavigationContract] = [
        .init(chunkID: "garage", navmeshAssetID: "player.navmesh"),
        .init(chunkID: "oldTown", navmeshAssetID: "oldTown.navmesh"),
        .init(chunkID: "paradise", navmeshAssetID: "paradise.navmesh", vehicleAccessible: false)
    ]
    public static let requiredAudio: [DHRev10AudioCue] = [.engineCrank, .engineStart, .repair, .lootOpen, .hostileAttack, .radioConsequence, .paradiseNegotiation]
}
