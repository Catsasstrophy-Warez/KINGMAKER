import Foundation
import Testing
@testable import DHCore
@testable import DHNPC
@testable import DHFleet
@testable import DHGameplay

@Test func productionNPCRosterPopulatesNamedResidents() {
    let population = DHProductionNPCRoster.makePopulation()
    #expect(population.residents.count == DHProductionNPCRoster.entries.count)
    #expect(population.residents.values.contains { $0.character.name == "Mara Voss" && $0.occupation == .mechanic })
}

@Test func productionNPCRosterIDsAreStableAcrossBuilds() {
    let first = DHProductionNPCRoster.makePopulation()
    let second = DHProductionNPCRoster.makePopulation()
    #expect(Set(first.residents.keys) == Set(second.residents.keys))
}

@Test func productionVehicleRosterPopulatesNamedFleet() {
    let fleet = DHProductionVehicleRoster.makeFleet()
    #expect(fleet.vehicles.count == DHProductionVehicleRoster.entries.count)
    #expect(fleet.vehicles.values.contains { $0.name == "Patrol Cruiser Seven" && $0.kind == .interceptor })
    #expect(fleet.vehicles.values.contains { $0.kind == .wreck && $0.condition < 1 })
}

@Test func coordinatorPopulatesOnlyTheNPCsWhoseHomeMatchesTheRequestedSite() {
    var coordinator = DHRev10SliceCoordinator()
    #expect(coordinator.spawnedNPCIDs.isEmpty)
    coordinator.populateProductionRoster(forSite: .kingmakerGarage)
    let expected = Set(DHProductionNPCRoster.entries.filter { $0.home == .kingmakerGarage }.map(\.id))
    #expect(!expected.isEmpty)
    #expect(coordinator.spawnedNPCIDs == expected)
}

@Test func coordinatorPopulatesTheFullVehicleRoster() {
    var coordinator = DHRev10SliceCoordinator()
    coordinator.populateProductionVehicleRoster()
    #expect(coordinator.spawnedVehicleIDs.count == DHProductionVehicleRoster.entries.count)
    #expect(coordinator.spawnedVehicleIDs.contains("veh.patrol-cruiser-7"))
}
