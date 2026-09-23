import Foundation
import DHVehicle

#if canImport(RealityKit)
import RealityKit

/// Kingmaker/player animation variants, ambient particle FX, animation clip sampling, combat FX,
/// and deformation -- split out of Rev10RealityKitScene.swift to keep that file focused on core
/// anchor/world management.
@available(iOS 18.0, macOS 15.0, *)
@MainActor
extension DHRev10RealityKitScene {
    public func registerKingmakerVariant(_ entity: Entity, id: String) {
        kingmakerVariants[id] = entity.clone(recursive: true)
        if anchors["kingmaker"] == nil { setKingmakerVariant(id) }
    }
    public func setKingmakerVariant(_ id: String) {
        guard id != activeKingmakerVariant, let source = kingmakerVariants[id] else { return }
        installKingmaker(source.clone(recursive: true))
        activeKingmakerVariant = id
    }
    public func registerPlayerAnimation(_ entity: Entity, id: String) {
        playerAnimationVariants[id] = entity.clone(recursive: true)
        if activePlayerAnimation == nil { setPlayerAnimation(id) }
    }
    public func setPlayerAnimation(_ id: String) {
        guard id != activePlayerAnimation, let source = playerAnimationVariants[id] else { return }
        if let current = anchors["player.avatar"] { current.removeFromParent() }
        let entity = source.clone(recursive: true)
        entity.name = "player.avatar.asset"
        anchors["player.avatar"] = entity
        root.addChild(entity)
        activePlayerAnimation = id
    }
    public func stepPlayerAnimation(time: Double, state: DHHumanoidAnimationState) {
        guard let player = anchors["player.avatar"], player.isEnabled else { return }
        let stride = state == .walk || state == .run ? 0.035 : 0.012
        player.position.y += Float(sin(time * (state == .walk || state == .run ? 8 : 2)) * stride)
        if state == .walk || state == .run {
            player.orientation = simd_quatf(angle: Float(sin(time * 4) * 0.025), axis: [0, 0, 1])
        }
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
    public func spawnCombatFX(cue: String, encounterAnchorID: String) {
        guard let anchor = anchors[encounterAnchorID],
              let config = combatFXLibrary.emitterConfig(named: cue) else { return }
        for child in anchor.children where child.name == "fx.\(cue)" {
            child.removeFromParent()
        }
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
}
#endif
