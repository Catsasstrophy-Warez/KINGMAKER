import Testing
import Foundation
@testable import DHCore
@testable import DHVehicle
@testable import DHWorld
@testable import DHGameplay
func viable(_ s:KingmakerSystem)->VehicleComponent{.init(id:UUID(),name:s.rawValue,system:s,condition:.serviceable,wear:0.2)}
@Test func kingmakerNeedsElectricalToCrank(){ var v=KingmakerState.derelict(); v.batterySOC=1; #expect(v.canCrank == false) }
@Test func sliceBeginsAtWake(){ #expect(VerticalSliceProgress().current == .wake) }
@Test func deterministicGenerator(){ var a=SeededGenerator(seed:42),b=SeededGenerator(seed:42); #expect(a.next()==b.next()); #expect(a.next()==b.next()) }
@Test func fixedStepAccumulatorCapsAndDrainsElapsedTime() {
    var accumulator = FixedStepAccumulator(step: 0.1, maximumSteps: 3)
    var steps = 0
    #expect(accumulator.advance(elapsed: 1) { _ in steps += 1 } == 3)
    #expect(steps == 3)
    #expect(accumulator.advance(elapsed: 0.1) == 1)
}
@Test func runtimeEventsUseSeededIDs() async {
    let first = DeadHighwayRuntime(snapshot: .init(clock: .init(), playerID: UUID(), heroVehicleID: UUID()))
    let second = DeadHighwayRuntime(snapshot: .init(clock: .init(), playerID: UUID(), heroVehicleID: UUID()))
    await first.record(kind: "test", detail: "same")
    await second.record(kind: "test", detail: "same")
    let firstID = await first.snapshot.events[0].id
    let secondID = await second.snapshot.events[0].id
    #expect(firstID == secondID)
}
@Test func saveRoundTrip() async throws { let s=DeadHighwaySnapshot(clock:.init(),playerID:UUID(),heroVehicleID:UUID()); let r=DeadHighwayRuntime(snapshot:s); let data=try await r.encodedSave(); let out=try DeadHighwayRuntime.decodeSave(data); #expect(out.playerID==s.playerID) }
@Test func restoredKingmakerStarts(){ var v=KingmakerState(id:UUID(),components:[viable(.engine),viable(.electrical),viable(.fuel),viable(.ignition),viable(.lubrication),viable(.cooling)],fuelLiters:10,batterySOC:1,fuelPressureKPa:300,engineRunning:false); let started=v.crank(seconds:1); #expect(started); #expect(v.engineRunning); #expect(v.oilPressureKPa>0) }
@Test func missingFuelProducesCrankNoStart(){ let v=KingmakerState(id:UUID(),components:[viable(.engine),viable(.electrical),viable(.fuel),viable(.ignition),viable(.lubrication),viable(.cooling)],fuelLiters:0,batterySOC:1,fuelPressureKPa:300,engineRunning:false); #expect(KingmakerDiagnostics.evaluate(v) == .cranksNoStart) }
@Test func convoyChangesFuelEconomy(){ var w=BlackridgeWorld(); let c=Convoy(id:UUID(),faction:.refineryHouses,cargoFuel:25,destination:.truckStop); w.convoys=[c]; let before=w.economy.fuel; w.resolve(c.id,arrived:true); #expect(w.economy.fuel==before+25) }

@Test func productionCatalogHasDeepPersistence() { #expect(KingmakerCatalog.production().count >= 200) }
@Test func starterVoltageDropRespondsToResistance() { var a=ElectricalState(); let healthy=a.crank(); a.groundR=0.08; let bad=a.crank(); #expect(bad.voltage < healthy.voltage); #expect(bad.drop > healthy.drop) }
@Test func drivetrainAcceleratesWithinGripLimit() { var d=DrivetrainState(); d.step(throttle:1,grip:1,dt:1); #expect(d.speedMPS > 0) }
@Test func collisionEnergyCreatesDamage() { let r=CollisionSolver.impact(massKg:1850,speedMPS:30,angleCos:1); #expect(r.energyJ > 800000); #expect(r.suspensionDamage > 0) }
@Test func deterministicEncounterGeneration() { var a=SeededGenerator(seed:42); var b=SeededGenerator(seed:42); #expect(EncounterGenerator.generate(rng:&a,x:0,y:0).kind == EncounterGenerator.generate(rng:&b,x:0,y:0).kind) }
@Test func deterministicEncounterGenerationIncludesStableID() { var a=SeededGenerator(seed:42); var b=SeededGenerator(seed:42); #expect(EncounterGenerator.generate(rng:&a,x:4,y:8) == EncounterGenerator.generate(rng:&b,x:4,y:8)) }
@Test func electricalTopologyHasStarterPath(){ let t=ElectricalTopology.kingmaker(); #expect(t.nodes.count==6); #expect(t.starterPathResistance() > 0.05) }
@Test func coolingLeakConsumesFluid(){ var f=KingmakerFluidNetworks.cooling(); f.edges[0].leakRate=0.5; let before=f.nodes[0].quantity; f.step(2); #expect(f.nodes[0].quantity < before) }
@Test func transmissionHasSixForwardGears(){ let t=TransmissionState(); #expect(t.ratios.count==6); #expect(t.activeRatio() > 10) }
@Test func cargoChangesVehicleMass(){ var c=CargoHold(); c.items=[.init(id:UUID(),name:"scrap",massKg:25,quantity:4)]; #expect(c.totalMassKg==1950) }
@Test func collisionZonesPersistDeformation(){ var d=BodyDamageState(); d.apply(zone:.frontLeft,energyJ:450000); #expect(d.deformation[.frontLeft] == 0.5) }
@Test func routePlannerFindsConnectedPath(){ let a=RouteNode(id:UUID(),x:0,y:0), b=RouteNode(id:UUID(),x:1,y:0), c=RouteNode(id:UUID(),x:2,y:0); let g=RouteGraph(nodes:[a,b,c],edges:[.init(id:UUID(),from:a.id,to:b.id,distance:1,danger:0,surface:.asphalt),.init(id:UUID(),from:b.id,to:c.id,distance:1,danger:0,surface:.asphalt)]); #expect(g.route(from:a.id,to:c.id)==[a.id,b.id,c.id]) }
@Test func rainReducesRoadGrip(){ let dry=WeatherState(); var wet=WeatherState(); wet.precipitation=1; wet.kind = .rain; #expect(wet.gripMultiplier(surface:.asphalt) < dry.gripMultiplier(surface:.asphalt)) }
@Test func productionChainConsumesAndProduces(){ var s=ProductionSite(id:UUID(),name:"Refinery",inventory:[.scrap:10,.fuel:0],recipe:.init(inputs:[.scrap:2],outputs:[.fuel:5]),efficiency:1); s.tick(); #expect(s.inventory[.scrap]==8); #expect(s.inventory[.fuel]==5) }
