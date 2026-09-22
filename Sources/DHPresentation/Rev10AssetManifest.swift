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

public enum DHRev10SceneAssetPlacementMode: String, Codable, Sendable { case replaceChunk, replaceAnchor, attach }
public struct DHRev10SceneAssetPlacement: Codable, Equatable, Sendable, Identifiable {
    public let bindingID: String
    public let targetID: String
    public let mode: DHRev10SceneAssetPlacementMode
    public var id: String { "\(bindingID)->\(targetID)" }
    public init(bindingID: String, targetID: String, mode: DHRev10SceneAssetPlacementMode) {
        self.bindingID = bindingID; self.targetID = targetID; self.mode = mode
    }
}

public enum DHRev10AssetManifest {
    public static let bindings: [DHRev10AssetBinding] = [
        .init(id: "garage.mesh", kind: .mesh, stableEntityID: "chunk.garage", sourceName: "BlackridgeGarage.usdz"),
        .init(id: "blackridge.road", kind: .mesh, stableEntityID: "road.segment.blackridge", sourceName: "BlackridgeRoadSegment.usdz"),
        .init(id: "paradise.interior", kind: .mesh, stableEntityID: "chunk.paradiseInterior", sourceName: "ParadiseInterior.usdz"),
        .init(id: "truckstop.interior", kind: .mesh, stableEntityID: "chunk.truckStopInterior", sourceName: "TruckStopInterior.usdz"),
        .init(id: "town.interior", kind: .mesh, stableEntityID: "chunk.oldTownInterior", sourceName: "TownInterior.usdz"),
        .init(id: "kingmaker.mesh", kind: .mesh, stableEntityID: "kingmaker", sourceName: "Kingmaker_XR13.usdz"),
        .init(id: "kingmaker.repaired", kind: .mesh, stableEntityID: "kingmaker", sourceName: "Kingmaker_XR13_repaired.usdz", required: false),
        .init(id: "kingmaker.damaged", kind: .mesh, stableEntityID: "kingmaker", sourceName: "Kingmaker_XR13_damaged.usdz", required: false),
        .init(id: "kingmaker.rusted", kind: .mesh, stableEntityID: "kingmaker", sourceName: "Kingmaker_XR13_rusted.usdz", required: false),
        .init(id: "kingmaker.enginebay", kind: .mesh, stableEntityID: "kingmaker.engineBay", sourceName: "Kingmaker_EngineBay.usdz"),
        .init(id: "player.navmesh", kind: .navmesh, stableEntityID: "chunk.garage", sourceName: "BlackridgeGarage.navmesh"),
        .init(id: "blackridge.terrain", kind: .mesh, stableEntityID: "chunk.paradise", sourceName: "BlackridgeCounty_Terrain.usdz"),
        .init(id: "player.walk", kind: .animation, stableEntityID: "player", sourceName: "Mannequin_WalkCycle.usdz"),
        .init(id: "player.idle", kind: .animation, stableEntityID: "player", sourceName: "Mannequin_Idle.usdz"),
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
        , .init(id: "cue.engineCrank", kind: .audio, stableEntityID: "kingmaker.engineBay", sourceName: "Kingmaker_Crank.wav")
        , .init(id: "cue.engineStart", kind: .audio, stableEntityID: "kingmaker.engineBay", sourceName: "Kingmaker_EngineStart.wav")
        , .init(id: "cue.engineKnock", kind: .audio, stableEntityID: "kingmaker.engineBay", sourceName: "Kingmaker_EngineKnock.wav")
        , .init(id: "cue.repair", kind: .audio, stableEntityID: "player", sourceName: "Repair_ToolClink.wav")
        , .init(id: "cue.lootOpen", kind: .audio, stableEntityID: "player", sourceName: "Loot_Open.wav")
        , .init(id: "cue.lootCollect", kind: .audio, stableEntityID: "player", sourceName: "Loot_Collect.wav")
        , .init(id: "cue.hostileTelegraph", kind: .audio, stableEntityID: "encounter.north-road", sourceName: "Hostile_Telegraph.wav")
        , .init(id: "cue.hostileAttack", kind: .audio, stableEntityID: "encounter.north-road", sourceName: "Hostile_Attack.wav")
        , .init(id: "cue.paradiseNegotiation", kind: .audio, stableEntityID: "chunk.paradiseInterior", sourceName: "Paradise_Negotiation.wav")
        , .init(id: "radio.static", kind: .audio, stableEntityID: "radio", sourceName: "Radio_Static.wav")
    ]
    public static let scenePlacements: [DHRev10SceneAssetPlacement] = [
        .init(bindingID: "garage.mesh", targetID: "chunk.garage", mode: .replaceChunk),
        .init(bindingID: "blackridge.road", targetID: "road.segment.blackridge", mode: .attach),
        .init(bindingID: "blackridge.terrain", targetID: "chunk.paradise", mode: .replaceChunk),
        .init(bindingID: "paradise.interior", targetID: "chunk.paradiseInterior", mode: .replaceChunk),
        .init(bindingID: "truckstop.interior", targetID: "chunk.truckStopInterior", mode: .replaceChunk),
        .init(bindingID: "town.interior", targetID: "chunk.oldTownInterior", mode: .replaceChunk),
        .init(bindingID: "kingmaker.enginebay", targetID: "kingmaker.engineBay", mode: .replaceAnchor),
        .init(bindingID: "hostile.vehicle", targetID: "encounter.north-road", mode: .replaceAnchor),
    ]
    public static func bindings(for kind: DHRev10AssetKind) -> [DHRev10AssetBinding] { bindings.filter { $0.kind == kind } }
}

public enum DHRev10AssetResolver {
    public static func url(for binding: DHRev10AssetBinding) -> URL? {
        Bundle.module.url(forResource: binding.sourceName.replacingOccurrences(of: ".usdz", with: ""), withExtension: "usdz")
            ?? Bundle.module.url(forResource: binding.sourceName, withExtension: nil)
    }

    public static var missingRequiredBindings: [DHRev10AssetBinding] {
        DHRev10AssetManifest.bindings.filter { $0.required && url(for: $0) == nil }
    }
}
