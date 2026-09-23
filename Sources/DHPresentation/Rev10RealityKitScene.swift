import Foundation
import DHWorld
import DHVehicle
import CoreGraphics

#if canImport(RealityKit)
import RealityKit

@available(iOS 18.0, macOS 15.0, *)
@MainActor
public final class DHRev10RealityKitScene {
    public let root = Entity()
    var anchors: [String: Entity] = [:]
    var kingmakerVariants: [String: Entity] = [:]
    var activeKingmakerVariant: String?
    var playerAnimationVariants: [String: Entity] = [:]
    var activePlayerAnimation: String?
    var ambientFXEntities: [String: Entity] = [:]
    var interactionHighlight: Entity?
    var activeInteractionID: String?
    var npcTemplate: Entity?
    var npcEntities: [String: Entity] = [:]
    var vehicleTemplate: Entity?
    var vehicleEntities: [String: Entity] = [:]
    var cameraBasePosition = SIMD3<Float>(repeating: 0)
    public private(set) var loadedAssetIDs: Set<String> = []
    public private(set) var missingAssetIDs: Set<String> = []
    public private(set) var isReadyForUpdates = false
    public var npcIDs: Set<String> { Set(npcEntities.keys) }
    public var vehicleIDs: Set<String> { Set(vehicleEntities.keys) }
    let animationLibrary = DHRev10AnimationClipLibrary()
    let combatFXLibrary = DHRev10CombatFXLibrary()

    public init() { root.name = "Blackridge County Rev10" }

    public func beginAssetLoadReport() {
        loadedAssetIDs.removeAll()
        missingAssetIDs.removeAll()
        isReadyForUpdates = false
    }

    public func finishAssetLoad() { isReadyForUpdates = true }

    public func recordAssetLoad(_ bindingID: String, loaded: Bool) {
        if loaded {
            loadedAssetIDs.insert(bindingID)
            missingAssetIDs.remove(bindingID)
        } else if !loadedAssetIDs.contains(bindingID) {
            missingAssetIDs.insert(bindingID)
        }
    }

    public func build(county: DHBlackridgeCounty = .verticalSlice, hierarchy: KingmakerVisualHierarchy? = nil, kingmakerSpec: KingmakerVisualSpec = .init(path: .wastelandEndurance)) {
        isReadyForUpdates = false
        root.children.removeAll()
        anchors.removeAll()
        kingmakerVariants.removeAll()
        activeKingmakerVariant = nil
        playerAnimationVariants.removeAll()
        activePlayerAnimation = nil
        ambientFXEntities.removeAll()
        npcTemplate = nil
        npcEntities.removeAll()
        vehicleTemplate = nil
        vehicleEntities.removeAll()
        cameraBasePosition = .zero
        interactionHighlight = nil
        activeInteractionID = nil
        let camera = PerspectiveCamera()
        camera.name = "camera.isometric"
        camera.position = [32, 28, 36]
        camera.look(at: [28, 0, 9], from: camera.position, relativeTo: root)
        cameraBasePosition = camera.position
        root.addChild(camera)
        anchors["camera.isometric"] = camera
        let light = DirectionalLight()
        light.name = "light.blackridge"
        light.light.intensity = 9000
        light.look(at: [20, 0, 10], from: [20, 30, 20], relativeTo: root)
        root.addChild(light)
        buildEnvironmentLighting()
        buildGarageShell()
        for (index, location) in county.locations.enumerated() {
            let chunk = Entity(); chunk.name = "chunk.\(location.chunkID)"
            chunk.position = SIMD3<Float>(Float(index * 8), 0, Float((index % 4) * 6))
            let terrain = marker(name: "terrain.\(location.chunkID)", size: 7.5, height: 0.08, color: .darkGray)
            terrain.position.y = -0.08
            chunk.addChild(terrain)
            let entity = marker(name: "location.\(location.id)", size: 1.5, height: Float(1 + index % 3), color: color(for: location.kind))
            chunk.addChild(entity)
            anchors[location.id] = entity
            anchors[location.chunkID] = chunk
            anchors["chunk.\(location.chunkID)"] = chunk
            root.addChild(chunk)
            for (propIndex, prop) in diagnosticProps(for: location.kind).enumerated() {
                let propEntity = marker(name: "prop.\(location.id).\(prop)", size: 0.45, height: 0.7, color: .yellow)
                propEntity.position = SIMD3<Float>(Float(propIndex % 3) - 1, 0.4, Float(propIndex / 3) - 1)
                chunk.addChild(propEntity)
                anchors["prop.\(location.id).\(prop)"] = propEntity
            }
            if let interior = location.interiorChunkID {
                let interiorEntity = marker(name: "interior.\(interior)", size: 0.8, height: 0.5, color: .purple)
                interiorEntity.isEnabled = false
                chunk.addChild(interiorEntity)
                anchors[interior] = interiorEntity
                anchors["chunk.\(interior)"] = interiorEntity
            }
        }
        let player = marker(name: "player.avatar", size: 0.5, height: 1.2, color: .cyan)
        player.position = [0, 0.6, 3]
        root.addChild(player)
        anchors["player.avatar"] = player
        registerSpawnAnchor("spawn.garage.player", position: [0, 0.6, 3])
        registerSpawnAnchor("spawn.garage.vehicle", position: [0, 0.35, 0])
        if let paradiseChunk = anchors["chunk.paradise"] {
            let paradiseOrigin = paradiseChunk.position(relativeTo: root)
            registerSpawnAnchor("spawn.paradise.player", position: paradiseOrigin + [0, 0.6, 1.5])
            registerSpawnAnchor("spawn.paradise.vehicleExit", position: paradiseOrigin + [0, 0.35, -2.5])
        }
        for (index, road) in county.roads.enumerated() {
            let roadEntity = marker(name: "road.\(road.id)", size: 4.0, height: 0.05, color: .darkGray)
            roadEntity.scale = [1.8, 1, 0.35]
            roadEntity.position = midpoint(from: anchors[road.from], to: anchors[road.to])
            root.addChild(roadEntity)
            anchors[road.id] = roadEntity
            if index == 0 { anchors["road.segment.blackridge"] = roadEntity }
        }
        let encounter = marker(name: "encounter.north-road", size: 1.8, height: 0.9, color: .red)
        encounter.position = [18, 0.45, 4]
        root.addChild(encounter)
        anchors["encounter.north-road"] = encounter
        installAmbientEffects()
        if let hierarchy {
            let kingmaker = Entity(); kingmaker.name = "vehicle.kingmaker"
            let chassis = marker(name: "kingmaker.chassis", size: 3.2, height: 0.55, color: kingmakerSpec.path == .restored ? .black : .red)
            chassis.components.set(PowertrainComponent())
            chassis.components.set(TransmissionComponent())
            chassis.components.set(TelemetryComponent())
            chassis.components.set(ThermalFeedbackComponent())
            chassis.position = [0, 0.35, 0]
            kingmaker.addChild(chassis)
            anchors["kingmaker.chassis"] = chassis
            let cabin = marker(name: "kingmaker.cabin", size: 1.5, height: 0.7, color: .darkGray)
            cabin.position = [-0.2, 0.9, 0]
            kingmaker.addChild(cabin)
            anchors["kingmaker.cabin"] = cabin
            if kingmakerSpec.armorLevel > 0 {
                let armor = marker(name: "kingmaker.armor", size: 3.5, height: 0.18, color: .darkGray)
                armor.position = [0, 0.75, 0]
                kingmaker.addChild(armor); anchors["kingmaker.armor"] = armor
            }
            if kingmakerSpec.cargoLevel > 0 {
                let cargo = marker(name: "kingmaker.cargo", size: 1.25, height: 0.35, color: .brown)
                cargo.position = [-1.0, 1.25, 0]
                kingmaker.addChild(cargo); anchors["kingmaker.cargo"] = cargo
            }
            for (index, x) in [-1.05, 1.05].enumerated() {
                for (side, z) in [-0.72, 0.72].enumerated() {
                    let wheel = ModelEntity(mesh: .generateCylinder(height: 0.18, radius: 0.34), materials: [SimpleMaterial(color: .black, isMetallic: true)])
                    wheel.name = "kingmaker.wheel.\(index).\(side)"
                    wheel.position = [Float(x), 0.28, Float(z)]
                    wheel.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
                    kingmaker.addChild(wheel)
                    anchors[wheel.name] = wheel
                }
            }
            for node in hierarchy.nodes {
                let visual = marker(name: "kingmaker.\(node.id)", size: 0.22, height: 0.22, color: .red)
                kingmaker.addChild(visual); anchors["kingmaker.\(node.id)"] = visual
            }
            ensureKingmakerEngineBayAnchor(in: kingmaker)
            kingmaker.position = [0, 0, 0]
            anchors["kingmaker"] = kingmaker
            root.addChild(kingmaker)
        }
    }

    public func entity(for stableID: String) -> Entity? { anchors[stableID] }
    public func worldPosition(for stableID: String) -> DHVector3? {
        guard let entity = anchors[stableID] else { return nil }
        let position = entity.position(relativeTo: root)
        return DHVector3(Double(position.x), Double(position.y), Double(position.z))
    }
    public func spawnPosition(for stableID: String) -> SIMD3<Float>? {
        anchors[stableID]?.position(relativeTo: root)
    }
    public func replaceKingmaker(with entity: Entity) {
        installKingmaker(entity)
    }
    func installKingmaker(_ entity: Entity) {
        if let current = anchors["kingmaker"] {
            let staleIDs = anchors.compactMap { key, value in isDescendantOrSelf(value, of: current) ? key : nil }
            for id in staleIDs { anchors.removeValue(forKey: id) }
            current.removeFromParent()
        }
        entity.name = "vehicle.kingmaker.asset"
        entity.components.set(CollisionComponent(shapes: [ShapeResource.generateBox(size: [4.8, 1.45, 1.95])]))
        entity.components.set(InputTargetComponent())
        anchors["kingmaker"] = entity
        root.addChild(entity)
        ensureKingmakerEngineBayAnchor(in: entity)
    }
    public func replaceChunk(_ chunkID: String, with entity: Entity) {
        let canonicalChunkID = chunkID.hasPrefix("chunk.") ? chunkID : "chunk.\(chunkID)"
        let lookupID = anchors[chunkID] != nil ? chunkID : canonicalChunkID
        guard let current = anchors[lookupID] else {
            attach(entity, stableID: canonicalChunkID)
            return
        }
        let parent = current.parent ?? root
        let transform = current.transform
        current.removeFromParent()
        entity.name = "\(canonicalChunkID).asset"
        entity.isEnabled = true
        entity.transform = transform
        let aliases = anchors.compactMap { key, value in value === current ? key : nil }
        for alias in aliases { anchors[alias] = entity }
        anchors[chunkID] = entity
        parent.addChild(entity)
        if canonicalChunkID == "chunk.garage" {
            anchors.removeValue(forKey: "garage.authored-blockout")?.removeFromParent()
        }
    }
    public func replaceAnchor(_ stableID: String, with entity: Entity) {
        guard let current = anchors[stableID] else { attach(entity, stableID: stableID); return }
        let parent = current.parent ?? root
        current.removeFromParent()
        entity.name = "\(stableID).asset"
        entity.isEnabled = true
        anchors[stableID] = entity
        parent.addChild(entity)
    }
    public func syncKingmaker(position: DHVector3, headingRadians: Double) {
        guard let entity = anchors["kingmaker"] else { return }
        entity.position = [Float(position.x), Float(position.y), Float(position.z)]
        entity.orientation = simd_quatf(angle: Float(headingRadians), axis: [0, 1, 0])
    }
    public func syncPlayerAvatar(position: DHVector3, headingRadians: Double, visible: Bool = true) {
        guard let entity = anchors["player.avatar"] else { return }
        entity.position = [Float(position.x), Float(position.y), Float(position.z)]
        entity.orientation = simd_quatf(angle: Float(headingRadians), axis: [0, 1, 0])
        entity.isEnabled = visible
    }
    /// Applies the persisted gameplay camera rig to the live RealityKit camera.
    /// The rig stores an isometric yaw/pitch in degrees; RealityKit receives the
    /// resulting world-space position and looks back at the active target.
    public func syncCamera(_ rig: IsometricCameraRig, target: DHVector3) {
        guard let camera = anchors["camera.isometric"] as? PerspectiveCamera else { return }
        let yaw = rig.yawDegrees * .pi / 180
        let pitch = rig.pitchDegrees * .pi / 180
        let horizontalDistance = cos(pitch) * rig.distance
        let offset = SIMD3<Float>(
            Float(sin(yaw) * horizontalDistance),
            Float(-sin(pitch) * rig.distance),
            Float(cos(yaw) * horizontalDistance)
        )
        let targetPosition = SIMD3<Float>(Float(target.x), Float(target.y), Float(target.z))
        cameraBasePosition = targetPosition + offset
        camera.position = cameraBasePosition
        camera.look(at: targetPosition, from: camera.position, relativeTo: root)
    }
    /// Applies a short deterministic impact offset to the active camera. Gameplay can
    /// feed normalized encounter/collision severity here without owning RealityKit
    /// camera state or introducing frame-time-dependent randomness.
    public func applyCameraImpact(severity: Double, phase: Double = 0) {
        guard let camera = anchors["camera.isometric"] as? PerspectiveCamera else { return }
        let clamped = Float(max(0, min(1, severity)))
        let amplitude = 0.08 + clamped * 0.28
        let offset = SIMD3<Float>(
            sin(Float(phase) * 17.0) * amplitude,
            abs(cos(Float(phase) * 13.0)) * amplitude * 0.55,
            cos(Float(phase) * 19.0) * amplitude * 0.35
        )
        camera.position = cameraBasePosition + offset
    }
    /// Marks the currently focused interaction hotspot in the live scene. The
    /// stable entity ID is shared with the interaction catalog and HUD prompt.
    public func syncInteractionHighlight(_ hotspot: DHRev10InteractionHotspot?) {
        if activeInteractionID == hotspot?.id, interactionHighlight != nil { return }
        interactionHighlight?.removeFromParent()
        interactionHighlight = nil
        activeInteractionID = hotspot?.id
        guard let hotspot, let target = anchors[hotspot.stableEntityID] else { return }
        let marker = ModelEntity(
            mesh: .generateCylinder(height: 0.04, radius: 0.62),
            materials: [SimpleMaterial(color: .yellow, isMetallic: false)]
        )
        marker.name = "interaction.highlight.\(hotspot.id)"
        marker.position = [0, 0.12, 0]
        target.addChild(marker)
        interactionHighlight = marker
    }
    public func setInterior(_ chunkID: String, visible: Bool) {
        let canonicalID = chunkID.hasPrefix("chunk.") ? chunkID : "chunk.\(chunkID)"
        anchors[chunkID]?.isEnabled = visible
        anchors[canonicalID]?.isEnabled = visible
    }
    public func setActiveInterior(_ chunkID: String?) {
        let canonicalID = chunkID.map { $0.hasPrefix("chunk.") ? $0 : "chunk.\($0)" }
        for (id, entity) in anchors {
            let normalizedID = id.hasPrefix("chunk.") ? id : "chunk.\(id)"
            guard normalizedID.contains("Interior") else { continue }
            entity.isEnabled = canonicalID == normalizedID
        }
    }
    public func setActiveChunks(_ chunkIDs: Set<String>) {
        let requestedIDs = chunkIDs.isEmpty ? ["garage"] : Array(chunkIDs)
        let canonicalIDs = Set(requestedIDs.map { $0.hasPrefix("chunk.") ? $0 : "chunk.\($0)" })
        for (id, entity) in anchors where entity.name.hasPrefix("chunk.") {
            let canonicalID = id.hasPrefix("chunk.") ? id : "chunk.\(id)"
            entity.isEnabled = canonicalIDs.contains(canonicalID)
        }
    }

    public func setEncounterVisible(_ visible: Bool) {
        anchors["encounter.north-road"]?.isEnabled = visible
    }
    /// Attaches an authored asset to an existing world anchor without losing the anchor's
    /// placement. Loaded USDZ roots arrive at their own origin, while diagnostic county anchors
    /// already carry the authored world transform.
    public func attach(_ entity: Entity, stableID: String) {
        if let target = anchors[stableID] {
            entity.position = target.position(relativeTo: root)
            entity.orientation = target.orientation(relativeTo: root)
            entity.scale = target.scale(relativeTo: root)
            target.isEnabled = false
        }
        entity.name = "\(stableID).asset"
        entity.isEnabled = true
        anchors[stableID] = entity
        root.addChild(entity)
    }

    func registerSpawnAnchor(_ stableID: String, position: SIMD3<Float>) {
        let anchor = Entity()
        anchor.name = stableID
        anchor.position = position
        anchors[stableID] = anchor
        root.addChild(anchor)
    }

    private func diagnosticProps(for kind: DHBlackridgeLocationKind) -> [String] {
        switch kind {
        case .garage: return ["lift", "toolwall", "kingmaker-bay"]
        case .scrapyard: return ["wreck-stack", "crusher", "parts-pile"]
        case .town: return ["diner", "water-tower", "collapsed-store"]
        case .mine: return ["headframe", "ore-cart", "vent-shaft"]
        case .railYard: return ["coal-car", "signal-box", "freight-crane"]
        case .fuelDepot: return ["tank-farm", "pump-island", "office"]
        case .substation: return ["transformer", "switchyard", "control-room"]
        case .farm: return ["barn", "silo", "irrigation-pump"]
        case .truckStop: return ["canopy", "diner", "repair-bay"]
        case .paradise: return ["gate", "market", "radio-tower"]
        case .storySite: return ["story-prop"]
        }
    }

    private func ensureKingmakerEngineBayAnchor(in kingmaker: Entity) {
        if let existing = anchors["kingmaker.engineBay"], existing.parent === kingmaker { return }
        let engineBay = marker(name: "kingmaker.engineBay", size: 0.7, height: 0.18, color: .orange)
        engineBay.position = [0.2, 0.72, 0.65]
        kingmaker.addChild(engineBay)
        anchors["kingmaker.engineBay"] = engineBay
    }

    private func isDescendantOrSelf(_ entity: Entity, of ancestor: Entity) -> Bool {
        var current: Entity? = entity
        while let node = current {
            if node === ancestor { return true }
            current = node.parent
        }
        return false
    }

    private func buildGarageShell() {
        let garage = Entity(); garage.name = "garage.authored-blockout"
        let back = marker(name: "garage.back-wall", size: 14, height: 4, color: .darkGray); back.position = [0, 2, -5]; garage.addChild(back)
        let left = marker(name: "garage.left-wall", size: 0.3, height: 4, color: .darkGray); left.scale = [1, 1, 10]; left.position = [-7, 2, 0]; garage.addChild(left)
        let right = marker(name: "garage.right-wall", size: 0.3, height: 4, color: .darkGray); right.scale = [1, 1, 10]; right.position = [7, 2, 0]; garage.addChild(right)
        let lift = marker(name: "garage.vehicle-lift", size: 4.5, height: 0.12, color: .yellow); lift.position = [0, 0.1, 0]; garage.addChild(lift)
        let bench = marker(name: "garage.workbench", size: 3, height: 1.2, color: .orange); bench.position = [4, 0.6, -3]; garage.addChild(bench)
        root.addChild(garage); anchors[garage.name] = garage
    }

    private func marker(name: String, size: Float, height: Float, color: SimpleMaterial.Color = .gray) -> ModelEntity {
        let entity = ModelEntity(mesh: .generateBox(size: [size, height, size]), materials: [SimpleMaterial(color: color, isMetallic: false)])
        entity.name = name
        entity.components.set(CollisionComponent(shapes: [ShapeResource.generateBox(size: [size, height, size])]))
        return entity
    }

    private func color(for kind: DHBlackridgeLocationKind) -> SimpleMaterial.Color {
        switch kind {
        case .garage: return .red
        case .scrapyard, .mine: return .orange
        case .town, .farm, .truckStop: return .green
        case .railYard, .fuelDepot, .substation: return .blue
        case .paradise: return .purple
        case .storySite: return .yellow
        }
    }

    private func midpoint(from first: Entity?, to second: Entity?) -> SIMD3<Float> {
        guard let first, let second else { return .zero }
        return (first.position(relativeTo: root) + second.position(relativeTo: root)) / 2
    }
}
#endif
