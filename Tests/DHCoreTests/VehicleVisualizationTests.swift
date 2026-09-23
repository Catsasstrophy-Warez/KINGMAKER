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
@MainActor
private func makeRaiderTemplate() -> Entity {
    // Mirrors build_secondary_meshes.py's raider part-name convention.
    let root = Entity()
    root.name = "HostileVehicle_Raider"
    for name in ["raider_chassis", "raider_cabin", "raider_ram_bar", "raider_armor_plate_L", "raider_armor_plate_R", "raider_wheel_1.4_0.95"] {
        let part = ModelEntity(mesh: .generateBox(size: 0.1), materials: [SimpleMaterial(color: .gray, isMetallic: false)])
        part.name = name
        root.addChild(part)
    }
    return root
}

@available(iOS 18.0, macOS 15.0, *)
@Test @MainActor func spawnVehicleIsANoOpWithoutARegisteredTemplate() {
    let scene = DHRev10RealityKitScene()
    scene.build()
    let spawned = scene.spawnVehicle(id: "veh.test", paintColor: (0.2, 0.2, 0.2), at: DHVector3(0, 0, 0))
    #expect(spawned == nil)
}

@available(iOS 18.0, macOS 15.0, *)
@Test @MainActor func spawnVehicleClonesTheTemplateAndPlacesItAtThePosition() throws {
    let scene = DHRev10RealityKitScene()
    scene.build()
    scene.registerVehicleTemplate(makeRaiderTemplate())
    let spawned = try #require(scene.spawnVehicle(id: "veh.patrol-cruiser-7", paintColor: (0.1, 0.1, 0.3), at: DHVector3(5, 0, 2)))
    #expect(spawned.position == [5, 0, 2])
    #expect(scene.entity(for: "veh.patrol-cruiser-7") === spawned)
}

@available(iOS 18.0, macOS 15.0, *)
@Test @MainActor func spawnVehicleOnlyRepaintsChassisAndCabinNotArmorOrWheels() throws {
    let scene = DHRev10RealityKitScene()
    scene.build()
    scene.registerVehicleTemplate(makeRaiderTemplate())
    let spawned = try #require(scene.spawnVehicle(id: "veh.a", paintColor: (0.9, 0.1, 0.1), at: DHVector3(0, 0, 0)))

    let chassis = try #require(spawned.children.first { $0.name == "raider_chassis" } as? ModelEntity)
    let cabin = try #require(spawned.children.first { $0.name == "raider_cabin" } as? ModelEntity)
    let armor = try #require(spawned.children.first { $0.name == "raider_armor_plate_L" } as? ModelEntity)
    let wheel = try #require(spawned.children.first { $0.name.hasPrefix("raider_wheel") } as? ModelEntity)

    let chassisMaterial = try #require(chassis.model?.materials.first as? SimpleMaterial)
    let cabinMaterial = try #require(cabin.model?.materials.first as? SimpleMaterial)
    let armorMaterial = try #require(armor.model?.materials.first as? SimpleMaterial)
    let wheelMaterial = try #require(wheel.model?.materials.first as? SimpleMaterial)

    #expect(components(chassisMaterial) == components(cabinMaterial), "chassis and cabin should both get the paint color")
    #expect(components(chassisMaterial) != components(armorMaterial), "armor should stay untouched")
    #expect(components(chassisMaterial) != components(wheelMaterial), "wheels should stay untouched")
}

@available(iOS 18.0, macOS 15.0, *)
@Test @MainActor func twoVehiclesWithDifferentPaintColorsGetDifferentMaterials() throws {
    let scene = DHRev10RealityKitScene()
    scene.build()
    scene.registerVehicleTemplate(makeRaiderTemplate())
    let first = try #require(scene.spawnVehicle(id: "veh.a", paintColor: (0.9, 0.1, 0.1), at: DHVector3(0, 0, 0)))
    let second = try #require(scene.spawnVehicle(id: "veh.b", paintColor: (0.1, 0.1, 0.9), at: DHVector3(1, 0, 0)))

    let firstChassis = try #require(first.children.first { $0.name == "raider_chassis" } as? ModelEntity)
    let secondChassis = try #require(second.children.first { $0.name == "raider_chassis" } as? ModelEntity)
    let firstMaterial = try #require(firstChassis.model?.materials.first as? SimpleMaterial)
    let secondMaterial = try #require(secondChassis.model?.materials.first as? SimpleMaterial)
    #expect(components(firstMaterial) != components(secondMaterial))
}

@available(iOS 18.0, macOS 15.0, *)
@Test @MainActor func spawningTheSameVehicleIDTwiceReplacesRatherThanDuplicates() throws {
    let scene = DHRev10RealityKitScene()
    scene.build()
    scene.registerVehicleTemplate(makeRaiderTemplate())
    let first = try #require(scene.spawnVehicle(id: "veh.a", paintColor: (0.5, 0.5, 0.5), at: DHVector3(0, 0, 0)))
    _ = scene.spawnVehicle(id: "veh.a", paintColor: (0.5, 0.5, 0.5), at: DHVector3(9, 0, 9))
    #expect(first.parent == nil)
    #expect(scene.entity(for: "veh.a")?.position == [9, 0, 9])
}

@available(iOS 18.0, macOS 15.0, *)
@Test @MainActor func removeVehicleClearsItFromTheScene() throws {
    let scene = DHRev10RealityKitScene()
    scene.build()
    scene.registerVehicleTemplate(makeRaiderTemplate())
    _ = try #require(scene.spawnVehicle(id: "veh.a", paintColor: (0.5, 0.5, 0.5), at: DHVector3(0, 0, 0)))
    scene.removeVehicle(id: "veh.a")
    #expect(scene.entity(for: "veh.a") == nil)
}
#endif
