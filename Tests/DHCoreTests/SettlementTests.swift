import Testing
import Foundation
@testable import DHCore
@testable import DHWorld
@testable import DHSettlement

@Test func produceConsumesInputsAndYieldsOutputs() {
    var settlement = SettlementState(name: "Workshop", site: .scrapyard, population: 10)
    settlement.inventory[.metal] = 10
    settlement.inventory[.electricity] = 5
    settlement.recipes = [.init(inputs: [.metal: 2], outputs: [.parts: 1], electricity: 2)]
    settlement.produce()
    #expect(settlement.inventory[.metal] == 8)
    #expect(settlement.inventory[.parts] == 1)
    #expect(settlement.inventory[.electricity] == 3)
}

@Test func produceSkipsRecipeWhenInputsInsufficient() {
    var settlement = SettlementState(name: "Workshop", site: .scrapyard, population: 10)
    settlement.inventory[.metal] = 1
    settlement.inventory[.electricity] = 5
    settlement.recipes = [.init(inputs: [.metal: 2], outputs: [.parts: 1], electricity: 2)]
    settlement.produce()
    #expect(settlement.inventory[.metal] == 1)
    #expect(settlement.inventory[.parts, default: 0] == 0)
}

@Test func paradiseFactoryMatchesDesignTarget() {
    let paradise = ParadiseFactory.make()
    #expect(paradise.population == 150)
    #expect(paradise.site == .paradise)
    #expect(paradise.inventory[.food] == 300)
}

@Test func civilizationRestoreRequiresSkillAndParts() {
    var runtime = CivilizationRuntime()
    let asset = InfrastructureAsset(name: "Substation", kind: .substation, condition: 0.1)
    runtime.infrastructure[asset.id] = asset
    let underqualified = runtime.restore(asset.id, skill: 1, parts: 1)
    #expect(underqualified == false)
    let restored = runtime.restore(asset.id, skill: 3, parts: 2)
    #expect(restored)
    #expect(runtime.infrastructure[asset.id]!.online)
    #expect(runtime.infrastructure[asset.id]!.condition >= 0.75)
}

@Test func civilizationApplyEffectsBoostsMatchingSettlementInventory() {
    var runtime = CivilizationRuntime()
    var settlement = SettlementState(name: "Paradise", site: .paradise, population: 150)
    let asset = InfrastructureAsset(name: "Substation", kind: .substation, condition: 1, online: true, settlementID: settlement.id)
    runtime.infrastructure[asset.id] = asset
    let before = settlement.inventory[.electricity, default: 0]
    runtime.applyEffects(to: &settlement)
    #expect(settlement.inventory[.electricity, default: 0] == before + 25)
}

@Test func civilizationApplyEffectsIgnoresOfflineOrUnmatchedAssets() {
    var runtime = CivilizationRuntime()
    var settlement = SettlementState(name: "Paradise", site: .paradise, population: 150)
    let offline = InfrastructureAsset(name: "Substation", kind: .substation, condition: 1, online: false, settlementID: settlement.id)
    let elsewhere = InfrastructureAsset(name: "Pump", kind: .waterPump, condition: 1, online: true, settlementID: UUID())
    runtime.infrastructure[offline.id] = offline
    runtime.infrastructure[elsewhere.id] = elsewhere
    let before = settlement.inventory[.electricity, default: 0]
    let beforeWater = settlement.inventory[.water, default: 0]
    runtime.applyEffects(to: &settlement)
    #expect(settlement.inventory[.electricity, default: 0] == before)
    #expect(settlement.inventory[.water, default: 0] == beforeWater)
}
