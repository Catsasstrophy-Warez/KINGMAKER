import Foundation
import Testing
@testable import DHWorld
@testable import DHVehicle
@testable import DHNPC
@testable import DHCombat
@testable import DHGameplay
@testable import DHPresentation

// Split out of the former Rev9ProductionGameplayTests.swift. This group covers on-foot/loot/
// encounter presentation, the RealityKit scene bridge, navigation, the asset manifest/resolver,
// production contracts (render/navigation/audio), and the Rev10 slice coordinator.

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
