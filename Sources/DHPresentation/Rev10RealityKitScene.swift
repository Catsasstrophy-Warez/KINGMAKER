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
    private var anchors: [String: Entity] = [:]
    private var kingmakerVariants: [String: Entity] = [:]
    private var activeKingmakerVariant: String?
    private var ambientFXEntities: [String: Entity] = [:]
    private var interactionHighlight: Entity?
    private var activeInteractionID: String?
    public private(set) var loadedAssetIDs: Set<String> = []
    public private(set) var missingAssetIDs: Set<String> = []
    private let animationLibrary = DHRev10AnimationClipLibrary()
    private let combatFXLibrary = DHRev10CombatFXLibrary()

    public init() { root.name = "Blackridge County Rev10" }

    public func beginAssetLoadReport() {
        loadedAssetIDs.removeAll()
        missingAssetIDs.removeAll()
    }

    public func recordAssetLoad(_ bindingID: String, loaded: Bool) {
        if loaded {
            loadedAssetIDs.insert(bindingID)
            missingAssetIDs.remove(bindingID)
        } else if !loadedAssetIDs.contains(bindingID) {
            missingAssetIDs.insert(bindingID)
        }
    }

    public func build(county: DHBlackridgeCounty = .verticalSlice, hierarchy: KingmakerVisualHierarchy? = nil, kingmakerSpec: KingmakerVisualSpec = .init(path: .wastelandEndurance)) {
        root.children.removeAll()
        anchors.removeAll()
        kingmakerVariants.removeAll()
        activeKingmakerVariant = nil
        ambientFXEntities.removeAll()
        interactionHighlight = nil
        activeInteractionID = nil
        let camera = PerspectiveCamera()
        camera.name = "camera.isometric"
        camera.position = [32, 28, 36]
        camera.look(at: [28, 0, 9], from: camera.position, relativeTo: root)
        root.addChild(camera)
        anchors["camera.isometric"] = camera
        let light = DirectionalLight()
        light.name = "light.blackridge"
        light.light.intensity = 18000
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
        for road in county.roads {
            let roadEntity = marker(name: "road.\(road.id)", size: 4.0, height: 0.05, color: .darkGray)
            roadEntity.scale = [1.8, 1, 0.35]
            roadEntity.position = midpoint(from: anchors[road.from], to: anchors[road.to])
            root.addChild(roadEntity)
            anchors[road.id] = roadEntity
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
    public func replaceKingmaker(with entity: Entity) {
        installKingmaker(entity)
    }
    public func registerKingmakerVariant(_ entity: Entity, id: String) {
        kingmakerVariants[id] = entity.clone(recursive: true)
        if anchors["kingmaker"] == nil { setKingmakerVariant(id) }
    }
    public func setKingmakerVariant(_ id: String) {
        guard id != activeKingmakerVariant, let source = kingmakerVariants[id] else { return }
        installKingmaker(source.clone(recursive: true))
        activeKingmakerVariant = id
    }
    private func installKingmaker(_ entity: Entity) {
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
        camera.position = targetPosition + offset
        camera.look(at: targetPosition, from: camera.position, relativeTo: root)
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
    public func installAmbientEffects(budget: DHFXBudget = .init(), rainIntensity: Double = 0, fogDensity: Double = 0.12) {
        let effects: [(String, ParticleEmitterComponent)] = [
            ("fx.dust", DHRev10ParticleEffects.dust(budget: budget)),
            ("fx.rain", DHRev10ParticleEffects.rain(intensity: rainIntensity, budget: budget)),
            ("fx.ground-fog", DHRev10ParticleEffects.groundFog(density: fogDensity)),
        ]
        for (id, emitter) in effects {
            let entity = ambientFXEntities[id] ?? Entity()
            entity.name = id
            entity.components.set(emitter)
            if entity.parent == nil { root.addChild(entity) }
            ambientFXEntities[id] = entity
            anchors[id] = entity
        }
    }
    public func updateAmbientEffects(speedKPH: Double, coolantC: Double, budget: DHFXBudget = .init()) {
        guard let dust = ambientFXEntities["fx.dust"] else { return }
        var emitter = DHRev10ParticleEffects.dust(budget: budget)
        emitter.isEmitting = speedKPH > 2
        dust.components.set(emitter)
        guard let heat = anchors["kingmaker.engineBay"] else { return }
        let heatEmitter = DHRev10ParticleEffects.heatHaze(thermalLoad: (coolantC - 85) / 35)
        heat.components.set(heatEmitter)
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
        let canonicalIDs = Set(chunkIDs.map { $0.hasPrefix("chunk.") ? $0 : "chunk.\($0)" })
        for (id, entity) in anchors where entity.name.hasPrefix("chunk.") {
            let canonicalID = id.hasPrefix("chunk.") ? id : "chunk.\(id)"
            entity.isEnabled = canonicalIDs.contains(canonicalID)
        }
    }
    public func attach(_ entity: Entity, stableID: String) { anchors[stableID] = entity; root.addChild(entity) }

    /// Samples the player.interact animation clip's spine track at `time` seconds and rotates
    /// the player-avatar entity accordingly -- the repair gesture. Previously
    /// DHRev10AnimationClipLibrary could decode/sample the clip's JSON but nothing applied it to
    /// a live entity; a no-op (both the clip and the entity are looked up defensively) when
    /// either isn't present yet, e.g. before build() runs.
    public func stepPlayerRepairAnimation(time: Double) {
        guard let clip = animationLibrary.clip(forBindingID: "player.interact"),
              let player = anchors["player.avatar"],
              let spineDegrees = clip.sample(bone: "spine", axis: "x", at: time) else { return }
        player.orientation = simd_quatf(angle: Float(spineDegrees) * .pi / 180, axis: [1, 0, 0])
    }

    /// Samples the kingmaker.start clip's chassis-shudder track at `time` seconds and offsets the
    /// chassis entity's height accordingly -- the engine-crank shudder. Same "decode existed,
    /// nothing applied it" gap as stepPlayerRepairAnimation above.
    public func stepKingmakerStartAnimation(time: Double) {
        guard let clip = animationLibrary.clip(forBindingID: "kingmaker.start"),
              let chassis = anchors["kingmaker.chassis"],
              let shudderZ = clip.sample(bone: "chassis", axis: "z", at: time) else { return }
        chassis.position = [0, 0.35 + Float(shudderZ), 0]
    }

    /// Applies BodyDamageState's per-zone deformation weights to the chassis entity.
    ///
    /// Kingmaker_XR13.usdz (Tools/BlenderAssetGen/build_kingmaker.py) now genuinely ships 10
    /// named UsdSkelBlendShape targets, one per CollisionZone (deform_frontLeft, deform_roof,
    /// etc.), matching DHRev10DeformationBlendShapes.targetName(for:) exactly -- verified via USD
    /// stage introspection that each has real, nonzero per-vertex offsets, not placeholder empty
    /// targets. What's still missing is the runtime half: as of this SDK, RealityKit's public
    /// Swift API has no BlendShape/MorphTarget weight-setting type at all (confirmed by grepping
    /// RealityKit.swiftinterface directly, not by failing to find the right name), so there is no
    /// public way to drive an imported USD blend shape's weight at runtime. Until Apple exposes
    /// that, this stays a scale-down proxy on the whole chassis -- the point is that real weight
    /// data drives *something* live on the entity graph, and the asset itself is production-ready
    /// for whenever the API exists (or for authoring tools like Reality Composer Pro that can
    /// already read/bake these targets ahead of time).
    public func applyDeformation(_ damage: BodyDamageState) {
        guard let chassis = anchors["kingmaker.chassis"] else { return }
        let severity = Float(DHRev10DeformationBlendShapes.weights(for: damage).values.max() ?? 0)
        let scale = 1 - severity * 0.06
        chassis.scale = [scale, scale, scale]
    }

    /// Looks up a queued combat-FX cue's real emitter config (see DHRev10CombatFXLibrary) and
    /// attaches a matching particle emitter to the encounter anchor, so
    /// DHVehicleEncounterRuntime.activeFXCues actually renders instead of only being consumable
    /// data. `encounterAnchorID` should match the encounter's stableEntityID (e.g.
    /// "encounter.north-road"); no-op if that anchor or the cue's config isn't present.
    @available(iOS 18.0, macOS 15.0, *)
    public func spawnCombatFX(cue: String, encounterAnchorID: String) {
        guard let anchor = anchors[encounterAnchorID],
              let config = combatFXLibrary.emitterConfig(named: cue) else { return }
        var emitter = ParticleEmitterComponent()
        emitter.mainEmitter.birthRate = Float(config.birthRate)
        emitter.mainEmitter.lifeSpan = config.lifespan
        emitter.speed = Float(config.speed)
        emitter.isEmitting = true
        let fxEntity = Entity()
        fxEntity.name = "fx.\(cue)"
        fxEntity.components.set(emitter)
        anchor.addChild(fxEntity)
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

    /// Adds real image-based (environment) lighting on top of the existing single DirectionalLight
    /// -- previously there was no environment/IBL lighting at all, so every material rendered
    /// against a flat, directionless background (Docs/REV10_PRODUCTION_GAP_AUDIT.md). An earlier
    /// attempt at this used a bright emissive "studio panel" reflector in the *Blender preview
    /// renderer* (Tools/BlenderAssetGen/build_kingmaker.py) and blew the render out to near-white
    /// at any workable strength -- that was a different rendering system (Blender EEVEE, offline
    /// stills) with no exposure control comparable to this one, so the failure doesn't transfer
    /// here, but the same caution applies: this deliberately starts conservative (a dim,
    /// desaturated overcast-wasteland sky gradient, negative intensityExponent) rather than a
    /// bright reflective environment, and is easy to brighten later once verified on-device.
    /// Uses RealityFoundation.ImageBasedLightComponent/ImageBasedLightReceiverComponent
    /// (available at exactly this file's iOS 18/macOS 15 deployment target) rather than the
    /// legacy ARView.Environment.ImageBasedLight, which is UIKit/AppKit-view-scoped and doesn't
    /// apply to a bare Entity-graph scene like this one.
    private func buildEnvironmentLighting() {
        guard let skyImage = Self.makeWastelandSkyImage(),
              let environment = try? EnvironmentResource(equirectangular: skyImage, withName: "wasteland_sky") else { return }
        let lightSource = Entity()
        lightSource.name = "lighting.ibl"
        var ibl = ImageBasedLightComponent(source: .single(environment), intensityExponent: -0.4)
        ibl.inheritsRotation = true
        lightSource.components.set(ibl)
        root.addChild(lightSource)
        anchors["lighting.ibl"] = lightSource
        root.components.set(ImageBasedLightReceiverComponent(imageBasedLight: lightSource))
    }

    /// A small procedural equirectangular sky: desaturated overcast zenith fading to a dusty
    /// amber horizon and a dark ground band -- generated in Swift (no new bundled asset needed)
    /// so the environment map ships with the code, not a separate file to keep in sync.
    private static func makeWastelandSkyImage(width: Int = 64, height: Int = 32) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
            space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        let zenith = (r: 0.22, g: 0.21, b: 0.20)
        let horizon = (r: 0.38, g: 0.29, b: 0.20)
        let ground = (r: 0.09, g: 0.08, b: 0.07)
        for y in 0..<height {
            let t = Double(y) / Double(max(1, height - 1))
            let color: (r: Double, g: Double, b: Double)
            if t < 0.5 {
                let localT = t / 0.5
                color = (zenith.r + (horizon.r - zenith.r) * localT, zenith.g + (horizon.g - zenith.g) * localT, zenith.b + (horizon.b - zenith.b) * localT)
            } else {
                let localT = (t - 0.5) / 0.5
                color = (horizon.r + (ground.r - horizon.r) * localT, horizon.g + (ground.g - horizon.g) * localT, horizon.b + (ground.b - horizon.b) * localT)
            }
            context.setFillColor(red: color.r, green: color.g, blue: color.b, alpha: 1)
            context.fill(CGRect(x: 0, y: y, width: width, height: 1))
        }
        return context.makeImage()
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
