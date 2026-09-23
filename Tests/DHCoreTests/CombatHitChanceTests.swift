import Foundation
import Testing
@testable import DHCombat
@testable import DHGameplay

@Test func fireWithoutRollsPreservesTheOriginalGuaranteedHitBehavior() {
    // The default (rolls: nil) must be byte-for-byte the old behavior, since existing callers
    // (including tests elsewhere in this suite) assume every fired round connects.
    var actor = DHCombatantState(id: "player", ammo: 3)
    var target = DHCombatantState(id: "raider", health: 100, ammo: 0, inCover: true)
    let outcome = DHPlayableCombatResolver().apply(.fire(rounds: 2, damage: 20), actor: &actor, target: &target)
    #expect(outcome.roundsFired == 2)
    #expect(outcome.roundsHit == 2)
    #expect(outcome.anyHit)
    #expect(actor.ammo == 1)
    #expect(target.health < 100)
}

@Test func fireWithRollsAboveHitChanceMisses() {
    var actor = DHCombatantState(id: "player", ammo: 5)
    var target = DHCombatantState(id: "raider", health: 100, ammo: 0, inCover: false)
    let threshold = DHPlayableCombatResolver.hitChance(against: target)
    #expect(threshold < 1.0, "sanity check: hit chance should be less than certain so a miss is representable")
    let allMisses = Array(repeating: threshold + 0.001, count: 3).map { min(0.999, $0) }
    let outcome = DHPlayableCombatResolver().apply(.fire(rounds: 3, damage: 20), actor: &actor, target: &target, rolls: allMisses)
    #expect(outcome.roundsFired == 3)
    #expect(outcome.roundsHit == 0)
    #expect(!outcome.anyHit)
    #expect(target.health == 100, "no rounds hit, target should be untouched")
}

@Test func fireWithRollsBelowHitChanceHits() {
    var actor = DHCombatantState(id: "player", ammo: 5)
    var target = DHCombatantState(id: "raider", health: 100, ammo: 0, inCover: false)
    let outcome = DHPlayableCombatResolver().apply(.fire(rounds: 3, damage: 20), actor: &actor, target: &target, rolls: [0.0, 0.0, 0.0])
    #expect(outcome.roundsFired == 3)
    #expect(outcome.roundsHit == 3)
    #expect(target.health == 40)
}

@Test func coverLowersHitChance() {
    let exposed = DHCombatantState(id: "a", inCover: false)
    let covered = DHCombatantState(id: "b", inCover: true)
    #expect(DHPlayableCombatResolver.hitChance(against: covered) < DHPlayableCombatResolver.hitChance(against: exposed))
}

@Test func suppressionRaisesHitChance() {
    let calm = DHCombatantState(id: "a", suppression: 0)
    let suppressed = DHCombatantState(id: "b", suppression: 1.0)
    #expect(DHPlayableCombatResolver.hitChance(against: suppressed) > DHPlayableCombatResolver.hitChance(against: calm))
}

@Test func hitChanceStaysWithinSaneBounds() {
    let extreme = DHCombatantState(id: "a", inCover: true, suppression: 0)
    let chance = DHPlayableCombatResolver.hitChance(against: extreme)
    #expect(chance >= 0.1 && chance <= 1.0)
}

@Test func vehicleEncounterFireDefaultsToGuaranteedHitLikeBefore() {
    var encounter = DHVehicleEncounterRuntime()
    let outcome = encounter.fire(rounds: 2, damage: 10)
    #expect(outcome.roundsHit == outcome.roundsFired)
    #expect(encounter.activeFXCues.contains("SparkImpact"))
}

@Test func vehicleEncounterFireWithRollsCanMiss() {
    var encounter = DHVehicleEncounterRuntime()
    let threshold = DHPlayableCombatResolver.hitChance(against: encounter.hostile)
    let guaranteedMiss = min(0.999, threshold + 0.001)
    let outcome = encounter.fire(rounds: 1, damage: 10, rolls: [guaranteedMiss])
    #expect(outcome.roundsHit == 0)
    #expect(!encounter.activeFXCues.contains("SparkImpact"), "a miss shouldn't queue an impact FX cue")
    #expect(encounter.activeFXCues.contains("MuzzleFlash"), "muzzle flash should still fire even on a miss")
}

@Test func vehicleEncounterReloadReplenishesAmmoWithoutAffectingTheHostile() {
    var encounter = DHVehicleEncounterRuntime()
    encounter.fire(rounds: 5, damage: 1)
    let ammoAfterFiring = encounter.player.ammo
    let hostileHealthBefore = encounter.hostile.health
    encounter.reload(rounds: 6)
    #expect(encounter.player.ammo == ammoAfterFiring + 6)
    #expect(encounter.hostile.health == hostileHealthBefore)
}
