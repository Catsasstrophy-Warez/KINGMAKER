import Foundation
import Testing
@testable import DHVehicle
@testable import DHPresentation

#if canImport(RealityKit)
import RealityKit

@available(iOS 18.0, macOS 15.0, *)
@Test @MainActor func stepPlayerRepairAnimationRotatesThePlayerEntityOverTime() throws {
    let scene = DHRev10RealityKitScene()
    scene.build()
    let player = try #require(scene.entity(for: "player.avatar"))
    let start = player.orientation
    scene.stepPlayerRepairAnimation(time: 0.4)
    #expect(player.orientation != start)
}

@available(iOS 18.0, macOS 15.0, *)
@Test @MainActor func stepKingmakerStartAnimationShudderesTheChassisHeight() throws {
    let scene = DHRev10RealityKitScene()
    let hierarchy = KingmakerVisualHierarchy.production(componentIDs: ["a", "b"])
    scene.build(hierarchy: hierarchy)
    let chassis = try #require(scene.entity(for: "kingmaker.chassis"))
    let restHeight = chassis.position.y
    scene.stepKingmakerStartAnimation(time: 0.3)
    #expect(chassis.position.y != restHeight)
}

@available(iOS 18.0, macOS 15.0, *)
@Test @MainActor func stepAnimationsAreNoOpsBeforeBuildRuns() {
    let scene = DHRev10RealityKitScene()
    // No crash, no anchors to touch -- both are pure no-ops when build() hasn't populated the
    // scene yet (e.g. player.avatar/kingmaker.chassis don't exist).
    scene.stepPlayerRepairAnimation(time: 0.1)
    scene.stepKingmakerStartAnimation(time: 0.1)
}

@available(iOS 18.0, macOS 15.0, *)
@Test @MainActor func applyDeformationScalesTheChassisDownWithSeverity() throws {
    let scene = DHRev10RealityKitScene()
    let hierarchy = KingmakerVisualHierarchy.production(componentIDs: ["a"])
    scene.build(hierarchy: hierarchy)
    let chassis = try #require(scene.entity(for: "kingmaker.chassis"))
    let restScale = chassis.scale.x
    var damage = BodyDamageState()
    damage.apply(zone: .frontLeft, energyJ: 900_000)
    scene.applyDeformation(damage)
    #expect(chassis.scale.x < restScale)
}

@available(iOS 18.0, macOS 15.0, *)
@Test @MainActor func pristineDamageStateLeavesChassisScaleUnchanged() throws {
    let scene = DHRev10RealityKitScene()
    let hierarchy = KingmakerVisualHierarchy.production(componentIDs: ["a"])
    scene.build(hierarchy: hierarchy)
    let chassis = try #require(scene.entity(for: "kingmaker.chassis"))
    scene.applyDeformation(BodyDamageState())
    #expect(chassis.scale.x == 1)
}

@available(iOS 18.0, macOS 15.0, *)
@Test @MainActor func spawnCombatFXAttachesARealParticleEmitterUnderTheEncounterAnchor() {
    let scene = DHRev10RealityKitScene()
    scene.build()
    let anchor = Entity()
    scene.attach(anchor, stableID: "encounter.north-road")
    scene.spawnCombatFX(cue: "MuzzleFlash", encounterAnchorID: "encounter.north-road")
    let fx = anchor.children.first { $0.name == "fx.MuzzleFlash" }
    #expect(fx != nil)
    #expect(fx?.components[ParticleEmitterComponent.self]?.isEmitting == true)
}
#endif
