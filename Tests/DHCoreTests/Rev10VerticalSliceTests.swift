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
        if beat == .start {
            slice.repairKingmaker()
            slice.prepareKingmakerForStart()
        }
        let advanced = slice.advance(to: beat)
        #expect(advanced)
        if beat == .hostileEncounter { #expect(!slice.hostileEncounterResolved) }
        if beat == .radioConsequence { #expect(slice.hostileEncounterResolved) }
    }
    #expect(slice.hostileEncounterResolved)
    #expect(slice.radioConsequenceHeard)
    #expect(slice.beat == .reload)
}

@Test func reloadIsADeliberateTerminalStateWithNoOutgoingTransition() {
    // Confirms the documented intent on advance(to:): .reload has no `allowed` entry at all, so
    // every possible next beat (including back to .garage, which might look like a reasonable
    // "start a new run" transition) is rejected once the slice reaches .reload.
    var slice = DHRev10VerticalSlice()
    let beats: [DHRev10Beat] = [.inspect, .diagnose, .scavenge, .repair, .start, .drive, .hostileEncounter, .radioConsequence, .paradise, .negotiate, .recruit, .save, .reload]
    for beat in beats {
        if beat == .start { slice.repairKingmaker(); slice.prepareKingmakerForStart() }
        let advanced = slice.advance(to: beat)
        #expect(advanced)
    }
    #expect(slice.beat == .reload)
    for candidate: DHRev10Beat in [.garage, .inspect, .diagnose, .scavenge, .repair, .start, .drive, .hostileEncounter, .radioConsequence, .paradise, .negotiate, .recruit, .save, .reload] {
        let advanced = slice.advance(to: candidate)
        #expect(!advanced, "expected .reload to reject a transition to \(candidate)")
        #expect(slice.beat == .reload, "a rejected transition should never actually move the beat")
    }
}

@Test func everyVerticalSliceBeatHasOneReachableSuccessor() {
    let ordered: [DHRev10Beat] = [.garage, .inspect, .diagnose, .scavenge, .repair, .start, .drive, .hostileEncounter, .radioConsequence, .paradise, .negotiate, .recruit, .save, .reload]
    for (index, pair) in zip(ordered.indices, zip(ordered, ordered.dropFirst())) {
        let (current, next) = pair
        var slice = DHRev10VerticalSlice()
        for beat in ordered.dropFirst().prefix(index) {
            if beat == .start {
                slice.repairKingmaker()
                slice.prepareKingmakerForStart()
            }
            let advanced = slice.advance(to: beat)
            #expect(advanced)
        }
        if next == .start {
            slice.repairKingmaker()
            slice.prepareKingmakerForStart()
        }
        let advanced = slice.advance(to: next)
        #expect(advanced, "dead-end vertical-slice beat: \(current.rawValue)")
    }
}

@Test func drivingDistanceReconcilesTheActiveWorldRoute() {
    var coordinator = DHRev10SliceCoordinator()
    coordinator.updateVehicleRoute(distanceFromGarage: 0)
    #expect(coordinator.currentLocationID == "garage")
    coordinator.updateVehicleRoute(distanceFromGarage: 25)
    #expect(coordinator.currentLocationID == "farm")
    coordinator.updateVehicleRoute(distanceFromGarage: 75)
    #expect(coordinator.currentLocationID == "northApproach")
    coordinator.updateVehicleRoute(distanceFromGarage: 125)
    #expect(coordinator.currentLocationID == "paradise")
    #expect(coordinator.streamedChunkIDs.contains("southHighway"))
}

@Test func rev10SaveReloadPreservesWorldState() throws {
    var slice = DHRev10VerticalSlice()
    for beat in [DHRev10Beat.inspect, .diagnose, .scavenge, .repair, .start, .drive, .hostileEncounter, .radioConsequence, .paradise, .negotiate, .recruit, .save] {
        if beat == .start {
            slice.repairKingmaker()
            slice.prepareKingmakerForStart()
        }
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

@Test func rev10StartBeatCranksOnlyAfterRepairPriming() {
    var slice = DHRev10VerticalSlice()
    let blocked = slice.startKingmaker()
    #expect(!blocked)
    slice.repairKingmaker()
    slice.prepareKingmakerForStart()
    let started = slice.startKingmaker()
    #expect(started)
    #expect(slice.kingmaker.engineRunning)
}

@Test func rev10PlayableGarageToParadiseRoutePreservesStateAndWorldHandoffs() throws {
    var slice = DHRev10VerticalSlice()
    for beat in [DHRev10Beat.inspect, .diagnose, .scavenge, .repair] {
        let advanced = slice.advance(to: beat)
        #expect(advanced)
    }

    var repairs = DHRepairRuntime()
    for step in repairs.steps {
        let worked = repairs.work(on: step.id, seconds: 4, skill: 3)
        #expect(worked)
    }
    repairs.apply(to: &slice.kingmaker)
    slice.kingmaker.primeForStart()
    let reachedStart = slice.advance(to: .start)
    #expect(reachedStart)
    let started = slice.startKingmaker()
    #expect(started)
    #expect(slice.kingmaker.engineRunning)
    let reachedDrive = slice.advance(to: .drive)
    #expect(reachedDrive)
    let reachedEncounter = slice.advance(to: .hostileEncounter)
    #expect(reachedEncounter)
    let reachedRadio = slice.advance(to: .radioConsequence)
    #expect(reachedRadio)
    let reachedParadise = slice.advance(to: .paradise)
    #expect(reachedParadise)
    #expect(slice.hostileEncounterResolved)
    #expect(slice.radioConsequenceHeard)

    var coordinator = DHRev10SliceCoordinator()
    coordinator.travel(to: "garage", chunkID: "garage", neighbors: ["northApproach", "southFields"])
    coordinator.populateProductionVehicleRoster()
    coordinator.travel(to: "farm", chunkID: "southFields", neighbors: ["northApproach", "southHighway"])
    coordinator.travel(to: "northApproach", chunkID: "northApproach", neighbors: ["garage", "southFields"])
    coordinator.resolveEncounter()
    coordinator.travel(to: "paradise", chunkID: "paradise", neighbors: ["southHighway", "southFields"])
    coordinator.populateProductionRoster(forSite: .paradise)
    #expect(coordinator.currentLocationID == "paradise")
    #expect(coordinator.currentChunkID == "paradise")
    #expect(!coordinator.spawnedVehicleIDs.isEmpty)
    #expect(!coordinator.spawnedNPCIDs.isEmpty)

    for beat in [DHRev10Beat.negotiate, .recruit, .save] {
        let advanced = slice.advance(to: beat)
        #expect(advanced)
    }
    let saved = try slice.encodedSave()
    let restored = try DHRev10VerticalSlice.decodeSave(saved)
    #expect(restored == slice)
    let reloaded = slice.advance(to: .reload)
    #expect(reloaded)
}
