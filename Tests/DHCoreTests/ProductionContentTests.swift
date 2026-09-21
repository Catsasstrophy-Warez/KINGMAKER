import Foundation
import Testing
@testable import DHWorld
@testable import DHVehicle
@testable import DHNPC
@testable import DHCombat
@testable import DHGameplay
@testable import DHPresentation

// Split out of the former Rev9ProductionGameplayTests.swift. This group covers salvage
// trading and the production content registry (regions/factions/vehicles atlas).

@Test func salvageTradeReturnsValueToPlayer() {
    var trade = TradeState()
    trade.playerCaps = 0
    trade.player = [InventorySlot(id: "scrap", name: "Scrap", massKG: 1, value: 12)]
    trade.sell(id: "scrap")
    #expect(trade.player.isEmpty)
    #expect(trade.playerCaps == 12)
}

@Test func productionRegistryCoversOriginalDesignAtlas() {
    #expect(DHProductionContentRegistry.regions.count == 12)
    #expect(DHProductionContentRegistry.factions.count == Faction.allCases.count)
    #expect(DHProductionContentRegistry.vehicles.contains { $0.id == "xr13" && $0.componentProfile == "kingmaker-254" })
    #expect(DHProductionContentRegistry.regions.contains { $0.id == "lastHighway" })
}
