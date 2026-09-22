import Foundation
import Testing
@testable import DHVehicle
@testable import DHPresentation

#if canImport(RealityKit)
import RealityKit
import CoreGraphics

@available(iOS 18.0, macOS 15.0, *)
private func components(_ material: SimpleMaterial) -> [CGFloat] {
    material.color.__tint.components ?? []
}

@available(iOS 18.0, macOS 15.0, *)
private func makeMannequinTemplate() -> Entity {
    // Mirrors build_character_rig.py's part-name convention (the real bundled asset uses the
    // same names), without needing to load the actual USDZ in a headless test.
    let root = Entity()
    root.name = "Mannequin_Armature"
    for name in ["torso", "pelvis", "head_mesh", "upperarm_L", "forearm_L", "upperarm_R", "forearm_R", "upperleg_L", "lowerleg_L", "upperleg_R", "lowerleg_R"] {
        let part = ModelEntity(mesh: .generateBox(size: 0.1), materials: [SimpleMaterial(color: .gray, isMetallic: false)])
        part.name = name
        root.addChild(part)
    }
    return root
}

@available(iOS 18.0, macOS 15.0, *)
@Test @MainActor func spawnNPCIsANoOpWithoutARegisteredTemplate() {
    let scene = DHRev10RealityKitScene()
    scene.build()
    let spawned = scene.spawnNPC(id: "npc.test", skinTone: (0.5, 0.5, 0.5), clothColor: (0.2, 0.2, 0.2), at: DHVector3(0, 0, 0))
    #expect(spawned == nil)
}

@available(iOS 18.0, macOS 15.0, *)
@Test @MainActor func spawnNPCClonesTheTemplateAndPlacesItAtThePosition() throws {
    let scene = DHRev10RealityKitScene()
    scene.build()
    scene.registerNPCTemplate(makeMannequinTemplate())
    let spawned = try #require(scene.spawnNPC(id: "npc.mara-voss", skinTone: (0.7, 0.5, 0.4), clothColor: (0.2, 0.2, 0.25), at: DHVector3(3, 0, 5)))
    #expect(spawned.position == [3, 0, 5])
    #expect(scene.entity(for: "npc.mara-voss") === spawned)
}

@available(iOS 18.0, macOS 15.0, *)
@Test @MainActor func spawnNPCTintsSkinAndClothPartsWithDistinctColors() throws {
    let scene = DHRev10RealityKitScene()
    scene.build()
    scene.registerNPCTemplate(makeMannequinTemplate())
    let spawned = try #require(scene.spawnNPC(id: "npc.a", skinTone: (0.8, 0.6, 0.5), clothColor: (0.1, 0.1, 0.15), at: DHVector3(0, 0, 0)))

    let head = try #require(spawned.children.first { $0.name == "head_mesh" } as? ModelEntity)
    let torso = try #require(spawned.children.first { $0.name == "torso" } as? ModelEntity)
    let headMaterial = try #require(head.model?.materials.first as? SimpleMaterial)
    let torsoMaterial = try #require(torso.model?.materials.first as? SimpleMaterial)
    // Different actual tint colors confirms skin vs. cloth parts were retargeted independently,
    // not both left on the template's shared default material.
    #expect(components(headMaterial) != components(torsoMaterial))
}

@available(iOS 18.0, macOS 15.0, *)
@Test @MainActor func twoNPCsWithDifferentAppearancesGetDifferentMaterials() throws {
    let scene = DHRev10RealityKitScene()
    scene.build()
    scene.registerNPCTemplate(makeMannequinTemplate())
    let first = try #require(scene.spawnNPC(id: "npc.a", skinTone: (0.9, 0.7, 0.6), clothColor: (0.1, 0.1, 0.1), at: DHVector3(0, 0, 0)))
    let second = try #require(scene.spawnNPC(id: "npc.b", skinTone: (0.4, 0.3, 0.2), clothColor: (0.5, 0.2, 0.2), at: DHVector3(1, 0, 0)))

    let firstHead = try #require(first.children.first { $0.name == "head_mesh" } as? ModelEntity)
    let secondHead = try #require(second.children.first { $0.name == "head_mesh" } as? ModelEntity)
    let firstMaterial = try #require(firstHead.model?.materials.first as? SimpleMaterial)
    let secondMaterial = try #require(secondHead.model?.materials.first as? SimpleMaterial)
    #expect(components(firstMaterial) != components(secondMaterial))
}

@available(iOS 18.0, macOS 15.0, *)
@Test @MainActor func spawningTheSameNPCIDTwiceReplacesRatherThanDuplicates() throws {
    let scene = DHRev10RealityKitScene()
    scene.build()
    scene.registerNPCTemplate(makeMannequinTemplate())
    let first = try #require(scene.spawnNPC(id: "npc.a", skinTone: (0.5, 0.5, 0.5), clothColor: (0.2, 0.2, 0.2), at: DHVector3(0, 0, 0)))
    _ = scene.spawnNPC(id: "npc.a", skinTone: (0.5, 0.5, 0.5), clothColor: (0.2, 0.2, 0.2), at: DHVector3(9, 0, 9))
    #expect(first.parent == nil, "the first spawn should have been removed from the scene")
    #expect(scene.entity(for: "npc.a")?.position == [9, 0, 9])
}

@available(iOS 18.0, macOS 15.0, *)
@Test @MainActor func removeNPCClearsItFromTheScene() throws {
    let scene = DHRev10RealityKitScene()
    scene.build()
    scene.registerNPCTemplate(makeMannequinTemplate())
    _ = try #require(scene.spawnNPC(id: "npc.a", skinTone: (0.5, 0.5, 0.5), clothColor: (0.2, 0.2, 0.2), at: DHVector3(0, 0, 0)))
    scene.removeNPC(id: "npc.a")
    #expect(scene.entity(for: "npc.a") == nil)
}

@available(iOS 18.0, macOS 15.0, *)
@Test @MainActor func endToEndAppearanceDataFlowsIntoDistinctSpawnedMaterials() throws {
    // Exercises the real seam: DHGameplay's appearance data (plain tuples, no DHPresentation
    // dependency) feeding straight into spawnNPC.
    let scene = DHRev10RealityKitScene()
    scene.build()
    scene.registerNPCTemplate(makeMannequinTemplate())
    let entries: [(id: String, skin: (Double, Double, Double), cloth: (Double, Double, Double))] = [
        ("npc.mara-voss", (0.62, 0.45, 0.33), (0.16, 0.17, 0.20)),
        ("npc.desmond-cole", (0.87, 0.72, 0.60), (0.42, 0.28, 0.14)),
    ]
    var materials: [[CGFloat]] = []
    for entry in entries {
        let spawned = try #require(scene.spawnNPC(id: entry.id, skinTone: entry.skin, clothColor: entry.cloth, at: DHVector3(0, 0, 0)))
        let torso = try #require(spawned.children.first { $0.name == "torso" } as? ModelEntity)
        let material = try #require(torso.model?.materials.first as? SimpleMaterial)
        materials.append(components(material))
    }
    #expect(Set(materials.map { $0.description }).count == entries.count)
}
#endif
