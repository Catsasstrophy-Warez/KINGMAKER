import Foundation
import DHCombat

public enum DHGameplayVehicleEncounterPhase: String, Codable, Equatable, Sendable {
    case hidden, telegraph, pursuing, attacking, disabled, escaped
}

public struct DHGameplayVehicleEncounterState: Codable, Equatable, Sendable {
    public var encounterID: String
    public var phase: DHGameplayVehicleEncounterPhase = .hidden
    public var hostileCount: Int
    public var radioEventID: String?

    public init(encounterID: String, hostileCount: Int = 1) {
        self.encounterID = encounterID
        self.hostileCount = hostileCount
    }

    public mutating func advance() {
        switch phase {
        case .hidden: phase = .telegraph
        case .telegraph: phase = .pursuing
        case .pursuing: phase = .attacking
        default: break
        }
    }

    public mutating func resolve() {
        phase = .disabled
        radioEventID = "radio.\(encounterID).consequence"
    }
}

public struct DHVehicleEncounterRuntime: Codable, Equatable, Sendable {
    public var encounter: DHGameplayVehicleEncounterState
    public var player = DHCombatantState(id: "player.vehicle", ammo: 12)
    public var hostile = DHCombatantState(id: "hostile.vehicle", health: 100, ammo: 8, inCover: false)
    public var resolved = false

    public init(id: String = "north-road", hostileCount: Int = 1) {
        encounter = .init(encounterID: id, hostileCount: hostileCount)
    }

    public mutating func tick() {
        guard !resolved else { return }
        encounter.advance()
        if encounter.phase == .attacking, player.health > 0 { player.health = max(0, player.health - 8) }
    }

    public mutating func fire(rounds: Int = 2, damage: Double = 20) {
        DHPlayableCombatResolver().apply(.fire(rounds: rounds, damage: damage), actor: &player, target: &hostile)
        if hostile.health <= 0 { resolve() }
    }

    public mutating func resolve() {
        resolved = true
        encounter.resolve()
    }
}
