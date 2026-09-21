import Testing
import Foundation
@testable import DHCore
@testable import DHCharacter

@Test func survivalTickIncreasesNeedsOverTime() {
    var character = CharacterState(name: "Driver")
    character.survivalTick(hours: 2)
    #expect(character.hunger == 3)
    #expect(character.thirst == 6)
    #expect(character.fatigue == 4)
}

@Test func severeThirstDamagesHealth() {
    var character = CharacterState(name: "Driver")
    character.thirst = 95
    let before = character.health
    character.survivalTick(hours: 1)
    #expect(character.health < before)
}

@Test func carryMassSumsInventoryWeight() {
    var character = CharacterState(name: "Driver")
    character.inventory = [.init(name: "Wrench", massKG: 1.5, quantity: 2), .init(name: "Fuel Can", massKG: 5, quantity: 1)]
    #expect(character.carryMass == 8)
}

@Test func progressionLevelsUpWhenXPExceedsThreshold() {
    var progression = CharacterProgression()
    progression.awardXP(150)
    #expect(progression.level == 2)
    #expect(progression.xp == 50)
}

@Test func progressionAddsPerksWithoutDuplication() {
    var progression = CharacterProgression()
    progression.addPerk(.packMule)
    progression.addPerk(.packMule)
    #expect(progression.perks.count == 1)
}

@Test func packMuleIncreasesCarryCapacity() {
    let character = CharacterState(name: "Driver")
    var withoutPerk = CharacterProgression()
    var withPerk = CharacterProgression()
    withPerk.addPerk(.packMule)
    #expect(CharacterSystems.carryCapacity(character, progression: withPerk) > CharacterSystems.carryCapacity(character, progression: withoutPerk))
}

@Test func movementMultiplierDegradesWithBurdenAndInjury() {
    var character = CharacterState(name: "Driver")
    character.inventory = [.init(name: "Scrap", massKG: 100, quantity: 1)]
    let injuries = [InjuryState(kind: .fracture, severity: 0.8, bodyPart: "leg")]
    let multiplier = CharacterSystems.movementMultiplier(character, injuries: injuries)
    #expect(multiplier < 1)
    #expect(multiplier >= 0.25)
}
