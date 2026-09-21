import Foundation

public enum DHRev10AssetKind: String, Codable, Sendable { case mesh, material, animation, navmesh, audio, prefab, particle }
public struct DHRev10AssetBinding: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let kind: DHRev10AssetKind
    public let stableEntityID: String
    public let sourceName: String
    public let required: Bool
    public init(id: String, kind: DHRev10AssetKind, stableEntityID: String, sourceName: String, required: Bool = true) { self.id = id; self.kind = kind; self.stableEntityID = stableEntityID; self.sourceName = sourceName; self.required = required }
}

public enum DHRev10AssetManifest {
    public static let bindings: [DHRev10AssetBinding] = [
        .init(id: "garage.mesh", kind: .mesh, stableEntityID: "chunk.garage", sourceName: "BlackridgeGarage.usdz"),
        .init(id: "kingmaker.mesh", kind: .mesh, stableEntityID: "kingmaker", sourceName: "Kingmaker_XR13.usdz"),
        .init(id: "kingmaker.enginebay", kind: .mesh, stableEntityID: "kingmaker.engineBay", sourceName: "Kingmaker_EngineBay.usdz"),
        .init(id: "player.navmesh", kind: .navmesh, stableEntityID: "chunk.garage", sourceName: "BlackridgeGarage.navmesh"),
        .init(id: "blackridge.terrain", kind: .mesh, stableEntityID: "chunk.paradise", sourceName: "BlackridgeCounty_Terrain.usdz"),
        .init(id: "player.walk", kind: .animation, stableEntityID: "player", sourceName: "Player_Walk.anim"),
        .init(id: "player.interact", kind: .animation, stableEntityID: "player", sourceName: "Player_Repair.anim"),
        .init(id: "kingmaker.start", kind: .animation, stableEntityID: "kingmaker", sourceName: "Kingmaker_Start.anim"),
        .init(id: "radio.consequence", kind: .audio, stableEntityID: "radio", sourceName: "Radio_Consequences.m4a"),
        .init(id: "hostile.vehicle", kind: .prefab, stableEntityID: "encounter.north-road", sourceName: "HostileVehicle_Raider.usdz"),
        .init(id: "combat.fx", kind: .particle, stableEntityID: "encounter.north-road", sourceName: "VehicleCombat_FX.usda")
        , .init(id: "engine.exhaust", kind: .audio, stableEntityID: "kingmaker.engineBay", sourceName: "XR13_Exhaust_Loop.wav")
        , .init(id: "engine.valvetrain", kind: .audio, stableEntityID: "kingmaker.engineBay", sourceName: "XR13_Valvetrain_Loop.wav")
        , .init(id: "engine.supercharger", kind: .audio, stableEntityID: "kingmaker.engineBay", sourceName: "XR13_Supercharger_Loop.wav")
        , .init(id: "transmission.shift", kind: .audio, stableEntityID: "kingmaker.driveline", sourceName: "XR13_DCT_Shift.wav")
        , .init(id: "dashboard.warning", kind: .mesh, stableEntityID: "kingmaker.dashboard", sourceName: "XR13_Dashboard.usdz")
    ]
    public static func bindings(for kind: DHRev10AssetKind) -> [DHRev10AssetBinding] { bindings.filter { $0.kind == kind } }
}
