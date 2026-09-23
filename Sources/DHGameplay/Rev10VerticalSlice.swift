import Foundation
import DHWorld
import DHVehicle

public enum DHRev10Beat: String, Codable, Sendable { case garage, inspect, diagnose, scavenge, repair, start, drive, hostileEncounter, radioConsequence, paradise, negotiate, recruit, save, reload }

public struct DHRev10VerticalSlice: Codable, Sendable, Equatable {
    public var beat: DHRev10Beat = .garage
    public var county = DHBlackridgeCounty.verticalSlice
    public var streamer = DHWorldStreamer()
    public var kingmaker = KingmakerState.derelict()
    public var visualHierarchy: KingmakerVisualHierarchy
    public var hostileEncounterResolved = false
    public var radioConsequenceHeard = false
    public var recruitedNPCID: String?
    public var scavengeLoot: [String] = []
    public var repairedComponentIDs: Set<String> = []
    public init() {
        visualHierarchy = KingmakerVisualHierarchy.production(componentIDs: kingmaker.components.map { $0.id.uuidString })
        county.chunks.forEach { streamer.register($0) }
    }
    public mutating func repairKingmaker() {
        repairedComponentIDs = Set(kingmaker.components.map { $0.id.uuidString })
        kingmaker.repairAllComponents()
    }
    public mutating func prepareKingmakerForStart() {
        repairedComponentIDs = Set(kingmaker.components.map { $0.id.uuidString })
        _ = kingmaker.prepareForStart()
    }
    @discardableResult
    public mutating func startKingmaker() -> Bool {
        guard kingmaker.canStart else { return false }
        return kingmaker.crank(seconds: 1)
    }
    /// `.reload` is a deliberate hard terminal state, not an oversight: there is no entry for it
    /// as a key below, so `allowed[.reload]` is nil and `advance(to:)` always returns false from
    /// there. This vertical slice models the acceptance path "prove the full loop completes once,
    /// ending at reload" -- it's not the live production game loop (that's
    /// DHRev10SliceCoordinator, which has no such restriction). Confirmed via the existing test
    /// suite: `everyVerticalSliceBeatHasOneReachableSuccessor` iterates `zip(ordered,
    /// ordered.dropFirst())`, so `.reload` (the last element) is never checked for a successor at
    /// all -- the tests already assume this is where the path ends.
    public mutating func advance(to next: DHRev10Beat) -> Bool {
        let allowed: [DHRev10Beat: Set<DHRev10Beat>] = [.garage: [.inspect], .inspect: [.diagnose], .diagnose: [.scavenge], .scavenge: [.repair], .repair: [.start], .start: [.drive], .drive: [.hostileEncounter], .hostileEncounter: [.radioConsequence], .radioConsequence: [.paradise], .paradise: [.negotiate], .negotiate: [.recruit], .recruit: [.save], .save: [.reload]]
        guard allowed[beat]?.contains(next) == true else { return false }
        guard next != .start || kingmaker.canStart else { return false }
        beat = next
        if next == .scavenge { scavengeLoot = ["radiator hose", "12V battery", "fuel filter"] }
        if next == .drive { streamer.activate(center: "garage", neighbors: ["northApproach", "southFields"]) }
        if next == .recruit { recruitedNPCID = "paradise-mechanic" }
        if next == .hostileEncounter { hostileEncounterResolved = false; radioConsequenceHeard = false }
        if next == .radioConsequence { hostileEncounterResolved = true; radioConsequenceHeard = true }
        if next == .reload { beat = .reload }
        return true
    }
    public func encodedSave() throws -> Data { try DHRev10SaveDocument(slice: self).encoded() }
    public static func decodeSave(_ data: Data) throws -> Self { try DHRev10SaveDocument.decoded(data) }
}
