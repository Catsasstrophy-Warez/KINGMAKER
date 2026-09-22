import Testing
import Foundation
@testable import DHCore
@testable import DHVehicle
@testable import DHWorld
@testable import DHGameplay
@testable import DHCharacter
@testable import DHFleet
@testable import DHCombat
@testable import DHNPC
@testable import DHSettlement
@testable import DHEconomy
@testable import DHRadio

@Test func rev5ContinentHasTwelveDistinctRegions(){ #expect(ContinentAtlas.regions.count == 12); #expect(Set(ContinentAtlas.regions.map(\.region)).count == 12) }
@Test func rev5ParadiseTargets150Residents(){ let state=WorldComesAliveState(); #expect(state.npcs.residents.count == 150); #expect(state.economy.settlements.values.first?.population == 150) }
@Test func rev5RadioReactsToWorldEvents(){ var r=RadioNetwork(towers:[.init(name:"Relay",x:0,y:0,rangeKM:20,repaired:true)]); r.ingest(.init(tick:1,kind:"convoy.disrupted",detail:"Fuel tanker lost")); #expect(r.signal(x:1,y:1) > 0.8); #expect(r.broadcasts.last?.text.contains("convoy") == true) }
@Test func rev5EconomyPropagatesPhysicalDelivery(){ var a=SettlementState(name:"Refinery",site:.fuelDepot,population:40);let b=ParadiseFactory.make();a.inventory[.fuel]=200;let route=TradeRoute(origin:a.id,destination:b.id,resource:.fuel,amount:50);var e=RegionalEconomy(settlements:[a.id:a,b.id:b],routes:[route.id:route]);let before=e.settlements[b.id]!.inventory[.fuel]!;let delivered=e.deliver(route.id);#expect(delivered);#expect(e.settlements[b.id]!.inventory[.fuel]! == before+50) }
@Test func rev5FleetSupportsHotwireAndTow(){ var f=FleetState();let tow=FleetVehicle(name:"Tow Truck",kind:.towTruck,fuel:.gasoline,liters:20);let wreck=FleetVehicle(name:"Wreck",kind:.wreck,fuel:.gasoline,liters:0,condition:0.2);f.add(tow);f.add(wreck);let hot=f.hotwire(wreck.id,skill:3);let towed=f.tow(tower:tow.id,target:wreck.id);#expect(hot);#expect(towed);#expect(f.vehicles[tow.id]?.towTarget == wreck.id) }
@Test func rev5PlayableChainCanReachParadiseTrade(){ var s=WorldComesAliveState();for m in PlayableMilestone.allCases{s.complete(m)};#expect(s.verticalSliceComplete) }
