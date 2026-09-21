import Foundation
import Testing
@testable import DHWorld
@testable import DHVehicle
@testable import DHNPC
@testable import DHCombat
@testable import DHGameplay
@testable import DHPresentation

// Split out of the former Rev9ProductionGameplayTests.swift (292 lines, ~3x every sibling test
// file) to reduce the merge-conflict surface of one monolithic test file. This group covers
// world streaming/interiors, NPC schedules/LOD, playable combat, and camera/thermal budget.

@Test func rev9WorldStreamingAndInterior() {
    var rt = DHProductionGameplayRuntime()
    rt.streamer.register(DHStreamChunk(id:"garage", regionID:"blackridge", tiles:[], locationIDs:["kingmakerGarage"], loaded:false))
    rt.streamer.register(DHStreamChunk(id:"highway", regionID:"blackridge", tiles:[], locationIDs:[], loaded:false))
    rt.streamer.activate(center:"garage", neighbors:["highway"])
    #expect(rt.streamer.active.count == 2)
    let entered = rt.enterInterior(DHInteriorPortal(id:"door", exteriorLocationID:"paradise", interiorChunkID:"paradiseInterior", locked:false))
    #expect(entered)
    #expect(rt.mode == .interior)
}

@Test func rev9AgentScheduleAndLOD() {
    var brain = DHAgentBrain(npcID:"mechanic", schedule:[DHNPCScheduleBlock(startHour:8,endHour:18,activity:.work,locationID:"garage")])
    brain.tick(hour:10, threat:0)
    #expect(brain.activity == .work)
    brain.tick(hour:10, threat:0.9)
    #expect(brain.activity == .flee)
    let lod = DHSimulationLODPolicy()
    #expect(lod.tier(distance: 20) == 0)
    #expect(lod.tier(distance: 200) == 2)
}

@Test func rev9CombatIsPlayableState() {
    var a = DHCombatantState(id:"player", ammo:3)
    var b = DHCombatantState(id:"raider", health:100, ammo:0, inCover:true)
    DHPlayableCombatResolver().apply(.fire(rounds:2, damage:20), actor:&a, target:&b)
    #expect(a.ammo == 1)
    #expect(b.health < 100)
    #expect(b.suppression > 0)
}

@Test func rev9CameraAndThermalBudget() {
    var camera = DHIsometricCameraRig(); camera.driving(speed:80)
    #expect(camera.distance > 18)
    var fx = DHFXBudget(); fx.thermalThrottle()
    #expect(fx.dustParticles == 400)
    #expect(fx.activeDynamicLights == 3)
}
