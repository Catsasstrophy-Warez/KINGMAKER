import Foundation
import Testing
import DHCore
@testable import DHGameplay

@Test func everyEncounterKindHasAValidOutcome() {
    let kinds: [Encounter.Kind] = [.wreck, .ambush, .strandedTraveler, .convoy, .stormDamage, .salvageCache, .roadblock]
    for kind in kinds {
        let outcome = kind.outcome
        #expect(!outcome.lootTable.isEmpty, "\(kind) has no loot at all")
        #expect(outcome.dangerLevel >= 0 && outcome.dangerLevel <= 1, "\(kind) danger level out of range")
        #expect(outcome.timeCostMinutes > 0, "\(kind) has no time cost")
    }
}

@Test func encounterKindsAreNotAllIdentical() {
    // The bug this closes: all 7 kinds previously behaved identically because nothing consumed
    // .kind at all. Confirm they now genuinely differ, not just exist as separate enum cases.
    let kinds: [Encounter.Kind] = [.wreck, .ambush, .strandedTraveler, .convoy, .stormDamage, .salvageCache, .roadblock]
    let outcomes = kinds.map { $0.outcome }
    let distinctDanger = Set(outcomes.map(\.dangerLevel))
    let distinctLoot = Set(outcomes.map { $0.lootTable.joined(separator: ",") })
    #expect(distinctDanger.count > 1)
    #expect(distinctLoot.count == kinds.count, "every kind should have a distinct loot table")
}

@Test func hostileKindsAreMoreDangerousThanNonHostileOnes() {
    let hostileKinds: [Encounter.Kind] = [.ambush, .convoy, .roadblock]
    let nonHostileKinds: [Encounter.Kind] = [.wreck, .strandedTraveler, .stormDamage, .salvageCache]
    for kind in hostileKinds { #expect(kind.outcome.isHostile) }
    for kind in nonHostileKinds { #expect(!kind.outcome.isHostile) }
    let avgHostileDanger = hostileKinds.map { $0.outcome.dangerLevel }.reduce(0, +) / Double(hostileKinds.count)
    let avgSafeDanger = nonHostileKinds.map { $0.outcome.dangerLevel }.reduce(0, +) / Double(nonHostileKinds.count)
    #expect(avgHostileDanger > avgSafeDanger, "hostile encounter kinds should read as more dangerous on average")
}

@Test func resolvingAnEncounterMarksItResolvedAndReturnsItsKindsOutcome() {
    var rng = SeededGenerator(seed: 42)
    var encounter = EncounterGenerator.generate(rng: &rng, x: 3, y: 5)
    #expect(!encounter.resolved)
    let outcome = encounter.resolve()
    #expect(encounter.resolved)
    #expect(outcome.lootTable == encounter.kind.outcome.lootTable)
}

@Test func encounterGeneratorStillProducesAllSevenKindsAcrossManyRolls() {
    // Sanity check that the generator's own distribution wasn't affected by this change.
    var rng = SeededGenerator(seed: 7)
    var seenKinds: Set<Encounter.Kind> = []
    for i in 0..<200 {
        seenKinds.insert(EncounterGenerator.generate(rng: &rng, x: i, y: 0).kind)
    }
    #expect(seenKinds.count == 7, "expected all 7 encounter kinds to appear across 200 rolls")
}
