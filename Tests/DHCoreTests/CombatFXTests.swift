import Foundation
import Testing
import DHGameplay
@testable import DHPresentation

@Test func firingQueuesMuzzleFlashAndSparkImpactFXCues() {
    var encounter = DHVehicleEncounterRuntime()
    encounter.fire(rounds: 1, damage: 5)
    let cues = encounter.drainFXCues()
    #expect(cues.contains("MuzzleFlash"))
    #expect(encounter.activeFXCues.isEmpty)
}

@Test func attackingPhaseQueuesSmokeTrail() {
    var encounter = DHVehicleEncounterRuntime()
    while encounter.encounter.phase != .attacking && !encounter.resolved {
        encounter.tick()
    }
    #expect(encounter.activeFXCues.contains("SmokeTrail"))
}

@Test func combatFXParserExtractsAllThreeEmitterScopes() {
    let usda = """
    #usda 1.0
    def Xform "VehicleCombatFX" {
        def Scope "MuzzleFlash" {
            custom float birthRate = 240
            custom float lifespan = 0.08
            custom float speed = 6.0
        }
        def Scope "SparkImpact" {
            custom float birthRate = 400
            custom float lifespan = 0.35
            custom float speed = 4.5
        }
    }
    """
    let parsed = DHRev10CombatFXParser.parse(usda)
    #expect(parsed["MuzzleFlash"]?.birthRate == 240)
    #expect(parsed["SparkImpact"]?.lifespan == 0.35)
}

@Test func combatFXLibraryResolvesRealEmitterConfigsFromTheBundledAsset() throws {
    let library = DHRev10CombatFXLibrary()
    let muzzleFlash = try #require(library.emitterConfig(named: "MuzzleFlash"))
    #expect(muzzleFlash.birthRate > 0)
    let sparkImpact = try #require(library.emitterConfig(named: "SparkImpact"))
    #expect(sparkImpact.lifespan > 0)
    let smokeTrail = try #require(library.emitterConfig(named: "SmokeTrail"))
    #expect(smokeTrail.speed > 0)
}

@Test func fxCuesFromTheRuntimeResolveToRealEmitterConfigsThroughTheLibrary() {
    var encounter = DHVehicleEncounterRuntime()
    encounter.fire(rounds: 1, damage: 5)
    let library = DHRev10CombatFXLibrary()
    for cue in encounter.drainFXCues() {
        #expect(library.emitterConfig(named: cue) != nil, "no emitter config for FX cue \(cue)")
    }
}
