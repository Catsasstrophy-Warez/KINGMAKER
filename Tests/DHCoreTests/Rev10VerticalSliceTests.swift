import Foundation
import Testing
@testable import DHWorld
@testable import DHVehicle
@testable import DHNPC
@testable import DHCombat
@testable import DHGameplay
@testable import DHPresentation

// Split out of the former Rev9ProductionGameplayTests.swift. This group covers the Rev10
// vertical slice's beat sequence, save/reload (including legacy-format compatibility), and
// authoritative vehicle state after repair/start.

@Test func rev10BlackridgeManifestAndKingmakerMapping() {
    let slice = DHRev10VerticalSlice()
    #expect(slice.county.locations.count == 10)
    #expect(slice.county.roads.count == 9)
    #expect(slice.county.locations.contains { $0.id == "paradise" && $0.interiorChunkID == "paradiseInterior" })
    #expect(slice.visualHierarchy.totalSimulationComponents == slice.kingmaker.components.count)
    #expect(slice.visualHierarchy.isComplete)
}

@Test func rev10AcceptanceBeatsAreOrderedAndPersistent() {
    var slice = DHRev10VerticalSlice()
    let beats: [DHRev10Beat] = [.inspect, .diagnose, .scavenge, .repair, .start, .drive, .hostileEncounter, .radioConsequence, .paradise, .negotiate, .recruit, .save, .reload]
    for beat in beats {
        let advanced = slice.advance(to: beat)
        #expect(advanced)
    }
    #expect(slice.hostileEncounterResolved)
    #expect(slice.radioConsequenceHeard)
    #expect(slice.beat == .reload)
}

@Test func everyVerticalSliceBeatHasOneReachableSuccessor() {
    let ordered: [DHRev10Beat] = [.garage, .inspect, .diagnose, .scavenge, .repair, .start, .drive, .hostileEncounter, .radioConsequence, .paradise, .negotiate, .recruit, .save, .reload]
    for (current, next) in zip(ordered, ordered.dropFirst()) {
        var slice = DHRev10VerticalSlice()
        if current != .garage {
            for beat in ordered.dropLast() {
                if beat == current { break }
                let advanced = slice.advance(to: beat == .garage ? .inspect : beat)
                #expect(advanced)
            }
        }
        let advanced = slice.advance(to: next)
        #expect(advanced, "dead-end vertical-slice beat: \(current.rawValue)")
    }
}

@Test func rev10SaveReloadPreservesWorldState() throws {
    var slice = DHRev10VerticalSlice()
    for beat in [DHRev10Beat.inspect, .diagnose, .scavenge, .repair, .start, .drive, .hostileEncounter, .radioConsequence, .paradise, .negotiate, .recruit, .save] {
        _ = slice.advance(to: beat)
    }
    let reloaded = try DHRev10SaveDocument.decoded(try DHRev10SaveDocument(slice: slice).encoded())
    #expect(reloaded == slice)
    #expect(reloaded.recruitedNPCID == "paradise-mechanic")
    #expect(reloaded.scavengeLoot.count == 3)
}

@Test func rev10SaveReaderAcceptsLegacyDirectSlice() throws {
    let slice = DHRev10VerticalSlice()
    let legacyData = try JSONEncoder().encode(slice)
    #expect(try DHRev10SaveDocument.decoded(legacyData) == slice)
}

@Test func rev10RepairAndStartChangesAuthoritativeVehicleState() {
    var slice = DHRev10VerticalSlice()
    #expect(!slice.kingmaker.engineRunning)
    slice.repairKingmaker()
    slice.prepareKingmakerForStart()
    #expect(slice.kingmaker.engineRunning)
    #expect(slice.kingmaker.canStart)
}
