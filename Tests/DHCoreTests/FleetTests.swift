import Testing
import Foundation
@testable import DHCore
@testable import DHVehicle
@testable import DHFleet

@Test func hotwireRequiresSufficientSkill() {
    var fleet = FleetState()
    let vehicle = FleetVehicle(name: "Sedan", kind: .sedan, fuel: .gasoline, liters: 10)
    fleet.add(vehicle)
    let firstAttempt = fleet.hotwire(vehicle.id, skill: 1)
    #expect(firstAttempt == false)
    #expect(fleet.vehicles[vehicle.id]!.stolen == false)
    let secondAttempt = fleet.hotwire(vehicle.id, skill: 3)
    #expect(secondAttempt)
    #expect(fleet.vehicles[vehicle.id]!.stolen)
    #expect(fleet.vehicles[vehicle.id]!.hotwired)
}

@Test func hotwireFailsForUnknownVehicle() {
    var fleet = FleetState()
    let attempt = fleet.hotwire(UUID(), skill: 10)
    #expect(attempt == false)
}

@Test func towRequiresBothVehiclesToExist() {
    var fleet = FleetState()
    let tower = FleetVehicle(name: "Tow Truck", kind: .towTruck, fuel: .diesel, liters: 40)
    fleet.add(tower)
    let missingTarget = fleet.tow(tower: tower.id, target: UUID())
    #expect(missingTarget == false)
    let target = FleetVehicle(name: "Wreck", kind: .wreck, fuel: .gasoline, liters: 0)
    fleet.add(target)
    let towed = fleet.tow(tower: tower.id, target: target.id)
    #expect(towed)
    #expect(fleet.vehicles[tower.id]!.towTarget == target.id)
}

@Test func hotwireDifficultyScalesWithSecurityFeatures() {
    var security = VehicleSecurity()
    security.ignitionLock = 0
    security.alarm = false
    security.immobilizer = false
    let easy = security.hotwireDifficulty()
    security.ignitionLock = 1
    security.alarm = true
    security.immobilizer = true
    let hard = security.hotwireDifficulty()
    #expect(hard > easy)
}

@Test func vehicleTheftEngineComparesSkillAgainstDifficulty() {
    var security = VehicleSecurity()
    security.ignitionLock = 1
    security.alarm = true
    security.immobilizer = true
    let difficulty = security.hotwireDifficulty()
    #expect(VehicleTheftEngine.attempt(skill: difficulty, security: security))
    #expect(VehicleTheftEngine.attempt(skill: max(0, difficulty - 1), security: security) == false)
}
