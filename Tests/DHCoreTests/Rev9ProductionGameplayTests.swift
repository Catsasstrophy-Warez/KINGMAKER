import Foundation
import Testing
@testable import DHWorld
@testable import DHVehicle
@testable import DHNPC
@testable import DHCombat
@testable import DHGameplay
@testable import DHPresentation

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

@Test func rev10BlackridgeManifestAndKingmakerMapping() {
    let slice = DHRev10VerticalSlice()
    #expect(slice.county.locations.count == 10)
    #expect(slice.county.roads.count == 9)
    #expect(slice.county.locations.contains { $0.id == "paradise" && $0.interiorChunkID == "paradiseInterior" })
    #expect(slice.visualHierarchy.totalSimulationComponents == slice.kingmaker.components.count)
    #expect(slice.visualHierarchy.isComplete)
}

@Test func rev10AcceptanceBeatsAreOrderedAndPersistent() {
    var slice = DHRev10VerticalSlice()
    let beats: [DHRev10Beat] = [.inspect, .diagnose, .scavenge, .repair, .start, .drive, .hostileEncounter, .radioConsequence, .paradise, .negotiate, .recruit, .save, .reload]
    for beat in beats {
        let advanced = slice.advance(to: beat)
        #expect(advanced)
    }
    #expect(slice.hostileEncounterResolved)
    #expect(slice.radioConsequenceHeard)
    #expect(slice.beat == .reload)
}

@Test func rev10SaveReloadPreservesWorldState() throws {
    var slice = DHRev10VerticalSlice()
    for beat in [DHRev10Beat.inspect, .diagnose, .scavenge, .repair, .start, .drive, .hostileEncounter, .radioConsequence, .paradise, .negotiate, .recruit, .save] {
        _ = slice.advance(to: beat)
    }
    let reloaded = try DHRev10SaveDocument.decoded(try DHRev10SaveDocument(slice: slice).encoded())
    #expect(reloaded == slice)
    #expect(reloaded.recruitedNPCID == "paradise-mechanic")
    #expect(reloaded.scavengeLoot.count == 3)
}

@Test func rev10SaveReaderAcceptsLegacyDirectSlice() throws {
    let slice = DHRev10VerticalSlice()
    let legacyData = try JSONEncoder().encode(slice)
    #expect(try DHRev10SaveDocument.decoded(legacyData) == slice)
}

@Test func rev10RepairAndStartChangesAuthoritativeVehicleState() {
    var slice = DHRev10VerticalSlice()
    #expect(!slice.kingmaker.engineRunning)
    slice.repairKingmaker()
    slice.prepareKingmakerForStart()
    #expect(slice.kingmaker.engineRunning)
    #expect(slice.kingmaker.canStart)
}

@Test func rev10OnFootPresentationSupportsNavigationToInteractionToCombat() {
    var animation = DHHumanoidAnimationMachine()
    animation.transition(to: .run)
    animation.step(dt: 0.4)
    #expect(animation.state == .run)
    #expect(animation.normalizedTime > 0)

    var loot = DHLootInteractionState()
    let containerID = UUID()
    loot.focus(containerID: containerID, label: "farmhouse cabinet")
    let opened = loot.open()
    #expect(opened)
    let itemID = UUID()
    loot.collect(itemID)
    #expect(loot.collectedItemIDs.contains(itemID))

    var encounter = DHVehicleEncounterState(encounterID: "north-road", hostileCount: 2)
    encounter.advance(); encounter.advance(); encounter.advance(); encounter.resolve()
    #expect(encounter.presentation == .disabled)
    #expect(encounter.radioEventID == "radio.north-road.consequence")
}

@Test func rev10RealityKitBridgeHasStableManifestContract() {
    let location = DHBlackridgeCounty.verticalSlice.locations.first { $0.id == "garage" }
    #expect(location?.chunkID == "garage")
    #expect(location?.interiorChunkID == "garageInterior")
    #expect(DHBlackridgeCounty.verticalSlice.roads.allSatisfy { $0.traversable })
}

@Test func rev10NavigationGraphRoutesGarageToParadise() {
    let graph = DHBlackridgeNavigationGraph()
    #expect(graph.route(from: "garage", to: "paradise") == ["garage", "farm", "truckStop", "paradise"])
}

@Test func rev10VehicleEncounterRuntimeIsPlayable() {
    var encounter = DHVehicleEncounterRuntime()
    encounter.tick(); encounter.tick(); encounter.tick()
    #expect(encounter.encounter.phase == .attacking)
    encounter.fire(rounds: 5, damage: 25)
    #expect(encounter.resolved)
    #expect(encounter.encounter.radioEventID == "radio.north-road.consequence")
}

@Test func kingmakerVisualStateMapsAuthoritativeCondition() {
    let component = KingmakerState.derelict().components[0]
    let visual = KingmakerComponentVisualState(componentID: component.id.uuidString, condition: component.condition)
    #expect(visual.profile.state == .broken)
    #expect(visual.profile.repairable == false)
}

@Test func rev10CoordinatorCoversInspectionRepairStreamingAndRadio() {
    var runtime = DHRev10SliceCoordinator()
    runtime.inspect(.engineBay)
    runtime.movePlayer(to: DHRev10ScenePoint(x: 2, y: 0, z: 1))
    runtime.stream(center: "northApproach", neighbors: ["oldTown", "garage"])
    runtime.repairAndStart()
    runtime.resolveEncounter()
    runtime.recruit("paradise-mechanic")
    #expect(runtime.playerMode == .dialogue)
    #expect(runtime.kingmaker.engineRunning)
    #expect(runtime.streamedChunkIDs.contains("oldTown"))
    #expect(runtime.radioText.contains("RESOLVED"))
}

@Test func rev10AssetManifestCoversProductionReplacementPoints() {
    #expect(DHRev10AssetManifest.bindings(for: .mesh).count >= 3)
    #expect(DHRev10AssetManifest.bindings(for: .navmesh).count == 1)
    #expect(DHRev10AssetManifest.bindings.contains { $0.stableEntityID == "kingmaker" && $0.kind == .animation })
    #expect(DHRev10AssetManifest.bindings.contains { $0.kind == .audio && $0.sourceName.contains("Radio") })
}

@Test func rev10BundledKingmakerAssetResolves() {
    let binding = DHRev10AssetManifest.bindings.first { $0.id == "kingmaker.mesh" }!
    #expect(DHRev10AssetResolver.url(for: binding) != nil)
    #expect(DHRev10AssetResolver.missingRequiredBindings.contains { $0.id == "kingmaker.mesh" } == false)
}

@Test func rev10ProductionContractsCoverRenderingNavigationAndAudio() {
    var budget = DHRev10RenderBudget()
    budget.reduceForThermals()
    #expect(budget.quality == .thermalReduced)
    #expect(budget.particleLimit == 400)
    #expect(DHRev10ProductionContract.navigation.contains { $0.chunkID == "paradise" && !$0.vehicleAccessible })
    var audio = DHRev10AudioState()
    audio.trigger(.radioConsequence)
    #expect(audio.activeCues == [.radioConsequence])
}

@Test func rev10GarageInteractionCatalogCoversInspectDiagnoseRepairDrive() {
    let kinds = Set(DHRev10InteractionCatalog.garage.map { $0.kind })
    #expect(kinds.contains(.inspect)); #expect(kinds.contains(.diagnose)); #expect(kinds.contains(.repair)); #expect(kinds.contains(.drive))
    var presentation = DHRev10InteractionPresentation()
    presentation.focus(DHRev10InteractionCatalog.garage[0]); presentation.diagnose("COOLING FAILED"); presentation.repairStep(dt: 2); presentation.hearRadio("CONVOY CONSEQUENCE")
    #expect(presentation.repairProgress == 1); #expect(presentation.radioText == "CONVOY CONSEQUENCE")
}

@Test func rev10RuntimePresentationCoversCameraNavigationLootParadiseAndPerformance() {
    var camera = DHRev10CameraController(); camera.follow("driving"); camera.pan(x: 2, z: -1); camera.zoomBy(0.25)
    #expect(camera.mode == "driving"); #expect(camera.zoom > 1)
    var navigation = DHRev10NavigationQuery(); navigation.activate("paradise"); navigation.blockedEntityIDs.insert("locked-gate")
    #expect(navigation.activeChunkIDs.contains("paradise")); #expect(!navigation.canEnter("locked-gate"))
    var loot = DHRev10LootRuntime(); let searched = loot.search("farmhouse-cabinet"); #expect(searched); loot.collect("fuel-filter")
    var paradise = DHRev10ParadiseRuntime(); paradise.negotiate(); paradise.trade(); paradise.recruit("mechanic")
    var sample = DHRev10PerformanceSample(); sample.record(frameTimeMS: 40, activeChunks: 3, entityCount: 120)
    #expect(loot.collectedItemIDs.contains("fuel-filter")); #expect(paradise.recruitedNPCID == "mechanic"); #expect(sample.thermalReduced)
}

@Test func productionRegistryCoversOriginalDesignAtlas() {
    #expect(DHProductionContentRegistry.regions.count == 12)
    #expect(DHProductionContentRegistry.factions.count == Faction.allCases.count)
    #expect(DHProductionContentRegistry.vehicles.contains { $0.id == "xr13" && $0.componentProfile == "kingmaker-254" })
    #expect(DHProductionContentRegistry.regions.contains { $0.id == "lastHighway" })
}

@Test func kingmakerBuildPathsPreserveOneVehicleIdentity() {
    let restored = KingmakerVisualSpec(path: .restored)
    let wasteland = KingmakerVisualSpec(path: .wastelandEndurance)
    let hybrid = KingmakerVisualSpec(path: .hybrid)
    #expect(restored.path == .restored)
    #expect(wasteland.armorLevel > restored.armorLevel)
    #expect(hybrid.aeroLevel == 3)
    #expect(hybrid.cargoLevel == 2)
}

@Test func kingmakerProfileUnifiesMechanicalAndVisualBuildData() {
    let profile = KingmakerProfile(buildPath: .armoredPursuit)
    #expect(profile.identity == "Blackridge XR-13 Kingmaker")
    #expect(profile.componentCount == 254)
    #expect(profile.transmissionGears == 6)
    #expect(profile.hazardousEnvironmentRating == 2)
    #expect(profile.cargoCapacity > 40)
}

@Test func kingmakerOperationalStateConnectsCraftMotionAndFailure() {
    var state = KingmakerOperationalState()
    state.apply(.explosionProofConduit); state.apply(.e85Conversion); state.begin(.coldStart); state.begin(.idling)
    #expect(state.canDrive)
    state.fail(.blownHeadGasket)
    #expect(!state.canDrive && state.motion == .disabled)
    state.recover(); state.begin(.towing)
    #expect(state.failure == .none && state.motion == .towing)
}

@Test func kingmakerConditionStatesMapSimulationToVisualPresentation() {
    #expect(KingmakerConditionVisualProfile.from(.poor).state == .damaged)
    #expect(KingmakerConditionVisualProfile.from(.failed).state == .broken)
    #expect(KingmakerConditionVisualProfile.from(.good).state == .repaired)
    #expect(KingmakerConditionVisualProfile(state: .rusted).rustAmount == 1)
}

@Test func kingmakerThermalSimulationProducesDiegeticFaultState() {
    var powertrain = PowertrainComponent(); powertrain.engineRPM = 7000; powertrain.coolantTemperature = 120; powertrain.oilPressure = 11
    var transmission = TransmissionComponent(); transmission.transmissionFluidTemp = 125; transmission.clutchClampingForce = 1
    var telemetry = TelemetryComponent(); var thermal = ThermalFeedbackComponent()
    KingmakerRealityKitSimulation.step(powertrain: &powertrain, transmission: &transmission, telemetry: &telemetry, thermal: &thermal, deltaTime: 1)
    #expect(telemetry.activeFaultCodes.contains(KingmakerRealityKitSimulation.overheatingFault))
    #expect(thermal.thermalLoad > 0)
    #expect(transmission.clutchClampingForce < 1)
}

@Test func kingmakerMechanicalPresentationDrivesVisualAudioAndDashboardState() {
    var deformation = KingmakerDeformationState(); deformation.apply(zone: "frontLeft", energy: 0.7)
    var wheels = KingmakerWheelAnimationState(); wheels.step(speedMPS: 12, steer: 0.5, compression: 0.4, deltaTime: 0.1)
    var audio = KingmakerAudioMixState(); audio.update(rpm: 4000, maxRPM: 7500, boostPSI: 10, faultCodes: [0x021A])
    var dashboard = KingmakerDashboardState(); dashboard.ingest(oilPressure: 8, coolantC: 125, faultCodes: [0x021A])
    #expect(deformation.fenderFrontLeft == 0.7); #expect(wheels.wheelSpinRadians > 0); #expect(audio.activeFaultCue == "radiator-overheat"); #expect(dashboard.checkEngineLight && dashboard.transmissionWarningLight)
}
