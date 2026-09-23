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

@Test func everyRosterVehicleHasAPaintColorWithValidComponents() {
    for entry in DHProductionVehicleRoster.entries {
        let color = DHProductionVehicleRoster.paintColor(for: entry)
        #expect(color.r >= 0 && color.r <= 1)
        #expect(color.g >= 0 && color.g <= 1)
        #expect(color.b >= 0 && color.b <= 1)
    }
}

@Test func vehiclePaintColorIsDeterministicAcrossCalls() {
    let entry = DHProductionVehicleRoster.entries[0]
    let first = DHProductionVehicleRoster.paintColor(for: entry)
    let second = DHProductionVehicleRoster.paintColor(for: entry)
    #expect(first == second)
}

@Test func vehicleRosterHasGenuinePaintColorVariety() {
    let colors = DHProductionVehicleRoster.entries.map { "\(DHProductionVehicleRoster.paintColor(for: $0))" }
    #expect(Set(colors).count > 1)
}

@Test func factionOwnedVehiclesDoNotAllShareTheSamePaintColor() {
    let byFaction = Dictionary(grouping: DHProductionVehicleRoster.entries, by: \.faction)
    var foundAVariedFaction = false
    for (_, entries) in byFaction where entries.count > 1 {
        let colors = Set(entries.map { "\(DHProductionVehicleRoster.paintColor(for: $0))" })
        if colors.count > 1 { foundAVariedFaction = true }
    }
    #expect(foundAVariedFaction, "every faction with multiple vehicles rendered them all identically")
}

@Test func vehiclePlacementOffsetIsDeterministicAcrossCalls() {
    let entry = DHProductionVehicleRoster.entries[0]
    let first = DHProductionVehicleRoster.localPlacementOffset(for: entry)
    let second = DHProductionVehicleRoster.localPlacementOffset(for: entry)
    #expect(first.x == second.x)
    #expect(first.z == second.z)
}

@Test func vehiclePlacementOffsetsWithinAFactionAreSpreadNotStacked() {
    let byFaction = Dictionary(grouping: DHProductionVehicleRoster.entries, by: \.faction)
    var foundAFactionWithSpread = false
    for (_, entries) in byFaction where entries.count > 1 {
        let offsets = entries.map(DHProductionVehicleRoster.localPlacementOffset(for:))
        for i in 0..<offsets.count {
            for j in (i + 1)..<offsets.count {
                let dx = offsets[i].x - offsets[j].x
                let dz = offsets[i].z - offsets[j].z
                #expect((dx * dx + dz * dz) > 0.01, "two vehicles in the same faction landed on top of each other")
            }
        }
        foundAFactionWithSpread = true
    }
    #expect(foundAFactionWithSpread, "no faction actually had multiple vehicles to test spread against")
}

@Test func vehiclePlacementOffsetsStayWithinAReasonableRadius() {
    for entry in DHProductionVehicleRoster.entries {
        let offset = DHProductionVehicleRoster.localPlacementOffset(for: entry)
        let distance = (offset.x * offset.x + offset.z * offset.z).squareRoot()
        #expect(distance < 5.0, "\(entry.id) placed unreasonably far from its faction's parking spot")
    }
}

@Test func unaffiliatedVehiclesStillGetSpreadPlacement() {
    let unaffiliated = DHProductionVehicleRoster.entries.filter { $0.faction == nil }
    #expect(unaffiliated.count > 1, "expected multiple unaffiliated vehicles to test grouping against")
    let offsets = unaffiliated.map(DHProductionVehicleRoster.localPlacementOffset(for:))
    let distinct = Set(offsets.map { "\($0.x),\($0.z)" })
    #expect(distinct.count == offsets.count, "unaffiliated vehicles (nil faction group) overlapped")
}

@Test func everyRosterNPCHasABrainWithAFullDaySchedule() throws {
    let brains = DHProductionNPCRoster.makeBrains()
    #expect(brains.count == DHProductionNPCRoster.entries.count)
    for entry in DHProductionNPCRoster.entries {
        let brain = try #require(brains[entry.id])
        #expect(brain.schedule.count == 5)
        #expect(brain.schedule.allSatisfy { $0.locationID == entry.home.rawValue })
    }
}

@Test func scheduledActivityChangesAcrossTheDay() {
    let mara = DHProductionNPCRoster.entries.first { $0.id == "npc.mara-voss" }!
    var brain = DHAgentBrain(npcID: mara.id, schedule: DHProductionNPCRoster.defaultSchedule(for: mara.occupation, home: mara.home))
    brain.tick(hour: 2, threat: 0)
    #expect(brain.activity == .sleep)
    brain.tick(hour: 10, threat: 0)
    #expect(brain.activity == .work)
}

@Test func everyRosterNPCHasAnAppearanceWithValidColorComponents() {
    for entry in DHProductionNPCRoster.entries {
        let appearance = DHProductionNPCRoster.appearance(for: entry)
        for component in [appearance.skinTone.r, appearance.skinTone.g, appearance.skinTone.b, appearance.clothColor.r, appearance.clothColor.g, appearance.clothColor.b] {
            #expect(component >= 0 && component <= 1, "color component out of range for \(entry.id)")
        }
    }
}

@Test func appearanceIsDeterministicAcrossCalls() {
    let entry = DHProductionNPCRoster.entries[0]
    let first = DHProductionNPCRoster.appearance(for: entry)
    let second = DHProductionNPCRoster.appearance(for: entry)
    #expect(first.skinTone == second.skinTone)
    #expect(first.clothColor == second.clothColor)
}

@Test func rosterHasGenuineSkinToneAndClothColorVariety() {
    let appearances = DHProductionNPCRoster.entries.map(DHProductionNPCRoster.appearance(for:))
    let distinctSkinTones = Set(appearances.map { "\($0.skinTone.r),\($0.skinTone.g),\($0.skinTone.b)" })
    let distinctClothColors = Set(appearances.map { "\($0.clothColor.r),\($0.clothColor.g),\($0.clothColor.b)" })
    #expect(distinctSkinTones.count > 1, "all 20 NPCs got the same skin tone")
    #expect(distinctClothColors.count > 1, "all 20 NPCs got the same cloth color")
}

@Test func npcsSharingAnOccupationAreNotVisuallyIdentical() {
    let byOccupation = Dictionary(grouping: DHProductionNPCRoster.entries, by: \.occupation)
    var foundAVariedPair = false
    for (_, entries) in byOccupation where entries.count > 1 {
        let appearances = entries.map(DHProductionNPCRoster.appearance(for:))
        let distinct = Set(appearances.map { "\($0.clothColor.r),\($0.clothColor.g),\($0.clothColor.b)" })
        if distinct.count > 1 { foundAVariedPair = true }
    }
    #expect(foundAVariedPair, "every occupation-sharing pair rendered with identical cloth color")
}

@Test func doctorsClothColorReadsClinicalWhiteRatherThanMechanicNavy() {
    let doctor = DHProductionNPCRoster.entries.first { $0.occupation == .doctor }!
    let mechanic = DHProductionNPCRoster.entries.first { $0.occupation == .mechanic }!
    let doctorColor = DHProductionNPCRoster.appearance(for: doctor).clothColor
    let mechanicColor = DHProductionNPCRoster.appearance(for: mechanic).clothColor
    #expect(doctorColor.r > 0.5, "doctor's cloth should read light/clinical, not dark")
    #expect(mechanicColor.r < 0.4, "mechanic's cloth should read dark/oil-stained")
}

@Test func placementOffsetIsDeterministicAcrossCalls() {
    let entry = DHProductionNPCRoster.entries[0]
    let first = DHProductionNPCRoster.localPlacementOffset(for: entry)
    let second = DHProductionNPCRoster.localPlacementOffset(for: entry)
    #expect(first.x == second.x)
    #expect(first.z == second.z)
}

@Test func placementOffsetsWithinASiteAreSpreadNotStacked() {
    let bySite = Dictionary(grouping: DHProductionNPCRoster.entries, by: \.home)
    var foundASharedSiteWithSpread = false
    for (_, entries) in bySite where entries.count > 1 {
        let offsets = entries.map(DHProductionNPCRoster.localPlacementOffset(for:))
        // No two site-mates should land on (near enough to) the exact same spot.
        for i in 0..<offsets.count {
            for j in (i + 1)..<offsets.count {
                let dx = offsets[i].x - offsets[j].x
                let dz = offsets[i].z - offsets[j].z
                #expect((dx * dx + dz * dz) > 0.01, "two NPCs at the same site landed on top of each other")
            }
        }
        foundASharedSiteWithSpread = true
    }
    #expect(foundASharedSiteWithSpread, "no site actually had multiple NPCs to test spread against")
}

@Test func placementOffsetsStayWithinAReasonableRadiusOfTheSiteAnchor() {
    for entry in DHProductionNPCRoster.entries {
        let offset = DHProductionNPCRoster.localPlacementOffset(for: entry)
        let distance = (offset.x * offset.x + offset.z * offset.z).squareRoot()
        #expect(distance < 3.0, "\(entry.id) placed unreasonably far from its site anchor")
    }
}

@Test func everyRosterNPCHasNonEmptyDialogueIncludingAGreeting() {
    for entry in DHProductionNPCRoster.entries {
        let options = DHProductionNPCRoster.defaultDialogue(for: entry)
        #expect(options.contains { $0.intent == .greet })
        #expect(options.allSatisfy { !$0.text.isEmpty })
    }
}
