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

@Test func rev4AuthoredPartsAndDMM() async throws {
 let parts = KingmakerPartsCatalog.authored()
 #expect(parts.count >= 70)
 #expect(parts.contains{$0.key == "eng.crank"})
 let topo = ElectricalTopology.kingmaker()
 let red = TestPoint(id:UUID(),key:"red",electricalNodeKey:"BATT+")
 let black = TestPoint(id:UUID(),key:"black",electricalNodeKey:"BATT-")
 let reading = VirtualDMM().measure(red:red,black:black,topology:topo)
 #expect(reading.valid)
 #expect((reading.value ?? 0) > 12)
}
@Test func rev4EngineTireDiffAndRestoration() async throws {
 var e=EngineDynamics(); e.throttle=1; e.step(running:true,load:0.1,dt:1)
 #expect(e.rpm > 800); #expect(e.torqueNm > 0)
 var t=TireForceState(); t.solve(normalN:4500,mu:1,slip:0.1,slipAngle:0.05); #expect(abs(t.longitudinalN) <= 4500)
 let d=DifferentialDynamics(); let split=d.split(inputTorque:1000,leftGrip:0.5,rightGrip:1); #expect(split.0 + split.1 == 1000)
 var r=RestorationRuntime(); let advanced=r.advance(requirementsMet:true); #expect(advanced); #expect(r.stage == .locate)
}
@Test func rev4SalvageInstallationAndGarage() async throws {
 var parts=KingmakerPartsCatalog.authored(); let s=SalvagePart(id:UUID(),catalogKey:"elec.starter",condition:0.9,compatibility:"XR13")
 #expect(InstallationSystem.install(s,into:&parts,availableTools:["socket-set"]) == .installed)
 var g=GarageInteractionState(); g.set(.hood,open:true); #expect(g.openness[.hood] == 1)
}

import DHCharacter
import DHFleet
import DHCombat
import DHNPC
import DHSettlement
import DHEconomy
import DHRadio

@Test func rev5ContinentHasTwelveDistinctRegions(){ #expect(ContinentAtlas.regions.count == 12); #expect(Set(ContinentAtlas.regions.map(\.region)).count == 12) }
@Test func rev5ParadiseTargets150Residents(){ let state=WorldComesAliveState(); #expect(state.npcs.residents.count == 150); #expect(state.economy.settlements.values.first?.population == 150) }
@Test func rev5RadioReactsToWorldEvents(){ var r=RadioNetwork(towers:[.init(name:"Relay",x:0,y:0,rangeKM:20,repaired:true)]); r.ingest(.init(tick:1,kind:"convoy.disrupted",detail:"Fuel tanker lost")); #expect(r.signal(x:1,y:1) > 0.8); #expect(r.broadcasts.last?.text.contains("convoy") == true) }
@Test func rev5EconomyPropagatesPhysicalDelivery(){ var a=SettlementState(name:"Refinery",site:.fuelDepot,population:40);let b=ParadiseFactory.make();a.inventory[.fuel]=200;let route=TradeRoute(origin:a.id,destination:b.id,resource:.fuel,amount:50);var e=RegionalEconomy(settlements:[a.id:a,b.id:b],routes:[route.id:route]);let before=e.settlements[b.id]!.inventory[.fuel]!;let delivered=e.deliver(route.id);#expect(delivered);#expect(e.settlements[b.id]!.inventory[.fuel]! == before+50) }
@Test func rev5FleetSupportsHotwireAndTow(){ var f=FleetState();let tow=FleetVehicle(name:"Tow Truck",kind:.towTruck,fuel:.gasoline,liters:20);let wreck=FleetVehicle(name:"Wreck",kind:.wreck,fuel:.gasoline,liters:0,condition:0.2);f.add(tow);f.add(wreck);let hot=f.hotwire(wreck.id,skill:3);let towed=f.tow(tower:tow.id,target:wreck.id);#expect(hot);#expect(towed);#expect(f.vehicles[tow.id]?.towTarget == wreck.id) }
@Test func rev5PlayableChainCanReachParadiseTrade(){ var s=WorldComesAliveState();for m in PlayableMilestone.allCases{s.complete(m)};#expect(s.verticalSliceComplete) }

import DHPresentation
@Test func rev6FirstPlayableSceneHasGarageHighwayParadise(){ let s=BlackridgeFirstPlayableScene(); #expect(s.garage.contains{$0.id=="kingmaker"}); #expect(s.highway.count>0); #expect(s.paradise.count>0) }
@Test func rev6StreamingCellsProgress(){ var s=StreamingCellController(); s.update(distanceFromGarageM:30); #expect(s.active.contains("highway")); s.update(distanceFromGarageM:160); #expect(s.active.contains("paradise")); #expect(!s.active.contains("garage")) }
@Test func rev6PlayableRuntimeCompletesOpening(){ var r=FirstPlayableRuntime(); r.walkToKingmaker(); r.openHood(); r.diagnoseAndRepair(); r.startKingmaker(); r.openDoor(); r.enterKingmaker(); r.drive(to:80); r.drive(to:160); r.exitVehicle(); r.tradeSalvage(); #expect(r.world.verticalSliceComplete); #expect(r.traded) }

@Test func rev7AvatarMovementAndDriving() {
    var input = PlayerInputState(); input.moveY = 1
    var avatar = PlayerAvatarState(); avatar.step(input: input, dt: 1)
    #expect(avatar.position.z > 3)
    input = PlayerInputState(); input.throttle = 1; input.steer = 0.15
    var car = KingmakerDriveController(); for _ in 0..<60 { car.step(input: input, dt: 1.0/60.0, running: true) }
    #expect(car.speedKPH > 10); #expect(car.position.z > 0)
}
@Test func rev7InteractionAndTrade() {
    let best = InteractionResolver().best([.init(id:"door",prompt:"Open",distanceM:2.2),.init(id:"hood",prompt:"Inspect",distanceM:1.1)])
    #expect(best?.id == "hood")
    var trade = TradeState(); trade.playerCaps=20; trade.merchant=[.init(id:"hose",name:"Hose",massKG:0.5,value:12)]; trade.buy(id:"hose")
    #expect(trade.playerCaps == 8); #expect(trade.player.first?.id == "hose")
}
@Test func rev7AudioAndFXDeriveFromSimulation() {
    var audio=EngineAudioState(); audio.update(rpm:3200,throttle:0.7,cranking:false,running:true)
    var fx=VehicleFXState(); fx.update(speedKPH:90,slip:0.35,roadDust:0.8,coolantC:102)
    #expect(audio.gain > 0.5); #expect(fx.dust > 0.5); #expect(fx.skid > 0.5)
}

@Test func rev8ExplorationSupportsEnterSearchAndStory(){
 var box=SearchableContainer(label:"Kitchen cabinet",loot:[.init(name:"Peaches",category:.food,quantity:3)])
 #expect(box.search().first?.quantity == 3); #expect(box.search().isEmpty)
 let loc=EnterableLocation(name:"Farmhouse",kind:.farmhouse,containers:[box],storyID:"farm.shelter")
 var interior=InteriorRuntime(); let entered = interior.enter(loc); #expect(entered); interior.discover(EnvironmentalStoryCatalog.blackridge[0]); #expect(interior.discoveredStories.contains("farm.shelter"))
}
@Test func rev8NegotiationAndCompanions(){
 let n=NegotiationEngine.resolve(skill:6,charisma:6,reputation:0.5,difficulty:3); #expect(n.success); #expect(n.priceMultiplier < 1)
 var c=CompanionState(npcID:UUID(),role:.mechanic,loyalty:0.7); #expect(RecruitmentEngine.attempt(&c,speech:4,reputation:0.4)); #expect(c.recruited)
}
@Test func rev8VehicleTheftSecurityMatters(){ var sec=VehicleSecurity(); sec.ignitionLock=0.8;sec.alarm=true;sec.immobilizer=true;#expect(!VehicleTheftEngine.attempt(skill:3,security:sec));#expect(VehicleTheftEngine.attempt(skill:7,security:sec)) }
@Test func rev8CombatAndVehicleWeapons(){ let w=BallisticWeapon(name:"Carbine",muzzleVelocity:750,baseDamage:34,magazine:30,ammo:30,accuracy:0.7);let r=AdvancedCombatResolver.resolve(weapon:w,skill:5,distanceM:20,target:.init(armor:2,cover:0.15));#expect(r.hitChance>0.5);var mount=VehicleWeaponMount(name:"Roof gun",ammunition:2,arcDegrees:180);#expect(VehicleCombatResolver.fire(&mount));#expect(mount.ammunition==1) }
@Test func rev8InfrastructureChangesCivilization(){ var s=ParadiseFactory.make(); var c=CivilizationRuntime();let a=InfrastructureAsset(name:"Paradise Substation",kind:.substation,condition:0.2,settlementID:s.id);c.infrastructure[a.id]=a; let restored = c.restore(a.id,skill:4,parts:3); #expect(restored);let before=s.inventory[.electricity]!;c.applyEffects(to:&s);#expect(s.inventory[.electricity]! > before) }
@Test func rev8DynamicWorldEmitsRadioConsequences(){ var w=DynamicWorldRuntime();w.emit(kind:"settlement.attacked",detail:"Paradise under attack");#expect(w.radio.broadcasts.last?.text.contains("defenses") == true) }
@Test func rev8NavigationPreventsWalkingThroughWalls(){ let nav=SimpleNavigationRuntime(obstacles:[.init(id:"wall",minX:1,maxX:2,minZ:1,maxZ:2)]);let start=DHVector3(0,0,0);#expect(nav.resolvedMove(from:start,to:.init(1.5,0,1.5)) == start) }
@Test func rev8EnterExitAnimationAndVehicleAnimation(){ var e=VehicleEntryExitState();e.beginEnter();e.step(dt:1);#expect(e.state == .driving);var a=VehicleAnimationState();a.update(steer:0.5,speedMPS:20,dt:0.1);#expect(a.steeringWheelRadians != 0);#expect(a.wheelSpinRadians > 0) }
@Test func rev8OpeningMissionShellCanComplete(){ var m=OpeningMissionRuntime();for id in ["find","diagnose","repair","highway","paradise","trade"]{m.complete(id)};#expect(m.complete) }
