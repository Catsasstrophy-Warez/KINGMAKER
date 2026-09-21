import Testing
import Foundation
@testable import DHCore
@testable import DHWorld
@testable import DHSettlement
@testable import DHEconomy

@Test func deliverMovesInventoryBetweenSettlements() {
    var origin = SettlementState(name: "Origin", site: .truckStop, population: 10)
    origin.inventory[.fuel] = 50
    let destination = SettlementState(name: "Destination", site: .farms, population: 10)
    let route = TradeRoute(origin: origin.id, destination: destination.id, resource: .fuel, amount: 20)
    var economy = RegionalEconomy(settlements: [origin.id: origin, destination.id: destination], routes: [route.id: route])
    let delivered = economy.deliver(route.id)
    #expect(delivered)
    #expect(economy.settlements[origin.id]!.inventory[.fuel] == 30)
    #expect(economy.settlements[destination.id]!.inventory[.fuel] == 20)
}

@Test func deliverFailsWhenOriginLacksStock() {
    let origin = SettlementState(name: "Origin", site: .truckStop, population: 10)
    let destination = SettlementState(name: "Destination", site: .farms, population: 10)
    let route = TradeRoute(origin: origin.id, destination: destination.id, resource: .fuel, amount: 20)
    var economy = RegionalEconomy(settlements: [origin.id: origin, destination.id: destination], routes: [route.id: route])
    let delivered = economy.deliver(route.id)
    #expect(delivered == false)
}

@Test func deliverFailsWhenRouteDisrupted() {
    var origin = SettlementState(name: "Origin", site: .truckStop, population: 10)
    origin.inventory[.fuel] = 50
    let destination = SettlementState(name: "Destination", site: .farms, population: 10)
    var route = TradeRoute(origin: origin.id, destination: destination.id, resource: .fuel, amount: 20)
    route.disrupted = true
    var economy = RegionalEconomy(settlements: [origin.id: origin, destination.id: destination], routes: [route.id: route])
    let delivered = economy.deliver(route.id)
    #expect(delivered == false)
}

@Test func priceRisesAsStockDepletes() {
    var low = SettlementState(name: "Low", site: .scrapyard, population: 5)
    low.inventory[.parts] = 0
    var high = SettlementState(name: "High", site: .scrapyard, population: 5)
    high.inventory[.parts] = 400
    let economy = RegionalEconomy(settlements: [low.id: low, high.id: high])
    #expect(economy.price(.parts, at: low.id) > economy.price(.parts, at: high.id))
}

@Test func priceDefaultsToOneForUnknownSettlement() {
    let economy = RegionalEconomy()
    #expect(economy.price(.fuel, at: UUID()) == 1)
}
