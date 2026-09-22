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
@testable import DHPresentation

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
