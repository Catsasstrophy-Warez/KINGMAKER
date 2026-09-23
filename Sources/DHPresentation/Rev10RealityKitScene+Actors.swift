import Foundation
import DHWorld
import DHVehicle
import CoreGraphics

#if canImport(RealityKit)
import RealityKit

/// NPC and vehicle spawn/registry logic split out of Rev10RealityKitScene.swift to keep that
/// file focused on core anchor/world management. Both spawn paths share the same "one shared
/// mesh, real per-instance material variation" posture: a single registered template is cloned
/// and retinted per instance rather than pretending each roster entry has a distinct model.
@available(iOS 18.0, macOS 15.0, *)
@MainActor
extension DHRev10RealityKitScene {
    /// Registers the loaded mannequin entity (player.walk's resolved asset) as the template every
    /// spawnNPC(...) call clones. Previously no NPC -- named or otherwise -- had any visual
    /// representation in this scene at all; DHProductionNPCRoster.appearance(for:) already
    /// produces real per-NPC skin/cloth colors (DHGameplay), but this file deliberately doesn't
    /// depend on DHGameplay, so the caller (which does) is responsible for resolving that data and
    /// passing plain color tuples to spawnNPC below, the same "entities/data come in from outside"
    /// pattern replaceKingmaker/registerKingmakerVariant already use for the vehicle.
    public func registerNPCTemplate(_ entity: Entity) {
        npcTemplate = entity
    }

    /// Clones the registered NPC template and retints its skin/cloth sub-meshes (matched by the
    /// stable part names build_character_rig.py exports: head_mesh/upperarm_*/forearm_*/
    /// lowerleg_* for skin, torso/pelvis/upperleg_* for cloth) to the given colors, then places it
    /// at `position`. Returns nil (no-op) if no template has been registered yet.
    @discardableResult
    public func spawnNPC(id: String, skinTone: (r: Double, g: Double, b: Double), clothColor: (r: Double, g: Double, b: Double), at position: DHVector3) -> Entity? {
        guard let template = npcTemplate else { return nil }
        let instance = template.clone(recursive: true)
        instance.name = id
        instance.position = [Float(position.x), Float(position.y), Float(position.z)]
        instance.components.set(CollisionComponent(shapes: [ShapeResource.generateBox(size: [0.7, 1.8, 0.7])]))
        applyNPCAppearance(to: instance, skinTone: skinTone, clothColor: clothColor)
        npcEntities[id]?.removeFromParent()
        npcEntities[id] = instance
        anchors[id] = instance
        root.addChild(instance)
        return instance
    }

    public func removeNPC(id: String) {
        npcEntities[id]?.removeFromParent()
        npcEntities.removeValue(forKey: id)
        anchors.removeValue(forKey: id)
    }

    func applyNPCAppearance(to entity: Entity, skinTone: (r: Double, g: Double, b: Double), clothColor: (r: Double, g: Double, b: Double)) {
        let skinMaterial = SimpleMaterial(color: SimpleMaterial.Color(red: CGFloat(skinTone.r), green: CGFloat(skinTone.g), blue: CGFloat(skinTone.b), alpha: 1), isMetallic: false)
        let clothMaterial = SimpleMaterial(color: SimpleMaterial.Color(red: CGFloat(clothColor.r), green: CGFloat(clothColor.g), blue: CGFloat(clothColor.b), alpha: 1), isMetallic: false)
        for descendant in allDescendants(of: entity) {
            guard let model = descendant as? ModelEntity, model.model != nil else { continue }
            if Self.npcSkinPartNames.contains(descendant.name) {
                model.model?.materials = [skinMaterial]
            } else if Self.npcClothPartNames.contains(descendant.name) {
                model.model?.materials = [clothMaterial]
            }
        }
    }

    func allDescendants(of entity: Entity) -> [Entity] {
        var result: [Entity] = []
        for child in entity.children {
            result.append(child)
            result.append(contentsOf: allDescendants(of: child))
        }
        return result
    }

    /// Registers a loaded vehicle entity (currently the hostile.vehicle/HostileVehicle_Raider
    /// asset -- the only generic vehicle blockout that exists) as the template every
    /// spawnVehicle(...) clones. No mesh exists yet for the roster's actual VehicleClass variety
    /// (interceptor/buggy/pickup/tanker/semi/motorcycle/bus/sedan/atv/towTruck/wreck are all the
    /// same generic shape today); this makes the shared silhouette individually paintable per
    /// vehicle rather than pretending each roster entry has a distinct model, the same honest
    /// "one shared mesh, real per-instance material variation" posture spawnNPC already uses for
    /// the mannequin. Swap the template for real per-kind meshes later with no call-site changes.
    public func registerVehicleTemplate(_ entity: Entity) {
        vehicleTemplate = entity
    }

    /// Clones the registered vehicle template and repaints its body panels (matched by the stable
    /// part names build_secondary_meshes.py exports for the raider mesh: any descendant whose
    /// name contains "chassis" or "cabin" -- armor plates, the ram bar, and wheels are
    /// deliberately left untouched so they don't all turn the same paint color as the body).
    @discardableResult
    public func spawnVehicle(id: String, paintColor: (r: Double, g: Double, b: Double), at position: DHVector3) -> Entity? {
        guard let template = vehicleTemplate else { return nil }
        let instance = template.clone(recursive: true)
        instance.name = id
        instance.position = [Float(position.x), Float(position.y), Float(position.z)]
        instance.components.set(CollisionComponent(shapes: [ShapeResource.generateBox(size: [3.8, 1.4, 1.9])]))
        applyVehiclePaint(to: instance, paintColor: paintColor)
        vehicleEntities[id]?.removeFromParent()
        vehicleEntities[id] = instance
        anchors[id] = instance
        root.addChild(instance)
        return instance
    }

    public func removeVehicle(id: String) {
        vehicleEntities[id]?.removeFromParent()
        vehicleEntities.removeValue(forKey: id)
        anchors.removeValue(forKey: id)
    }

    func applyVehiclePaint(to entity: Entity, paintColor: (r: Double, g: Double, b: Double)) {
        let paintMaterial = SimpleMaterial(color: SimpleMaterial.Color(red: CGFloat(paintColor.r), green: CGFloat(paintColor.g), blue: CGFloat(paintColor.b), alpha: 1), isMetallic: true)
        for descendant in allDescendants(of: entity) {
            guard let model = descendant as? ModelEntity, model.model != nil else { continue }
            if descendant.name.contains("chassis") || descendant.name.contains("cabin") {
                model.model?.materials = [paintMaterial]
            }
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
extension DHRev10RealityKitScene {
    static let npcSkinPartNames: Set<String> = ["head_mesh", "upperarm_L", "forearm_L", "upperarm_R", "forearm_R", "lowerleg_L", "lowerleg_R"]
    static let npcClothPartNames: Set<String> = ["torso", "pelvis", "upperleg_L", "upperleg_R"]
}
#endif
