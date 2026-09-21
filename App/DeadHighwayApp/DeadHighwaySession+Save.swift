#if os(iOS) || os(macOS)
import Foundation
import DHPresentation
import DHGameplay

/// Versioned snapshot of everything a save needs to restore. `decodeCurrent(_:)` rejects a
/// schema version we don't recognize instead of silently accepting a struct shape we didn't
/// actually validate -- schemaVersion used to be written but never read back.
struct DHRev10SessionDocument: Codable {
    static let currentSchemaVersion = 1

    let schemaVersion: Int
    var slice: DHRev10VerticalSlice
    var coordinator: DHRev10SliceCoordinator
    var avatar: PlayerAvatarState
    var drive: KingmakerDriveController
    var camera: IsometricCameraRig
    var trade: TradeState
    var repair: DHRepairRuntime
    var loot: DHRev10LootRuntime
    var paradise: DHRev10ParadiseRuntime
    var inVehicle: Bool

    @MainActor init(session: DeadHighwaySession) {
        schemaVersion = Self.currentSchemaVersion
        slice = session.slice
        coordinator = session.coordinator
        avatar = session.avatar
        drive = session.drive
        camera = session.camera
        trade = session.trade
        repair = session.repair
        loot = session.loot
        paradise = session.paradise
        inVehicle = session.inVehicle
    }

    /// Decodes a session document and rejects anything whose schema version we don't recognize,
    /// rather than silently accepting a struct shape we didn't actually validate. A future schema
    /// bump belongs here (migrate old versions forward) instead of relying on Codable's
    /// missing-key defaulting to paper over the difference between "old data" and "corrupt data".
    static func decodeCurrent(_ data: Data) -> DHRev10SessionDocument? {
        guard let document = try? JSONDecoder().decode(DHRev10SessionDocument.self, from: data) else { return nil }
        guard document.schemaVersion == currentSchemaVersion else {
            assertionFailure("DHRev10SessionDocument schema version \(document.schemaVersion) is not the current version \(currentSchemaVersion); add a migration instead of loading it as-is")
            return nil
        }
        return document
    }
}

extension DeadHighwaySession {
    /// Shared by init and reloadSlice so the current-schema/legacy-fallback decode logic exists in
    /// exactly one place; previously each copy could silently drift out of sync with the other.
    /// Returns whether anything was loaded.
    @discardableResult
    func loadSaved(from data: Data) -> Bool {
        if let document = DHRev10SessionDocument.decodeCurrent(data) {
            apply(document)
            return true
        }
        if let saved = try? DHRev10SaveDocument.decoded(data) {
            slice = saved
            coordinator.kingmaker = saved.kingmaker
            return true
        }
        return false
    }

    func apply(_ document: DHRev10SessionDocument) {
        slice = document.slice; coordinator = document.coordinator; avatar = document.avatar; drive = document.drive; camera = document.camera; trade = document.trade; repair = document.repair; loot = document.loot; paradise = document.paradise; inVehicle = document.inVehicle
    }

    func saveSlice() { coordinator.kingmaker = slice.kingmaker; if let data = try? JSONEncoder().encode(DHRev10SessionDocument(session: self)) { UserDefaults.standard.set(data, forKey: saveKey); message = "WORLD SAVED" } }
    func reloadSlice() { guard let data = UserDefaults.standard.data(forKey: saveKey) else { return }; if loadSaved(from: data) { message = "WORLD RELOADED"; syncHUD() } }
}
#endif
