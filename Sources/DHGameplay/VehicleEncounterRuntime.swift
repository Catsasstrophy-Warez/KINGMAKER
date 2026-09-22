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
    /// Queued combat-FX cue names (matching the Scope names in the combat.fx manifest binding's
    /// VehicleCombat_FX.usda -- MuzzleFlash, SparkImpact, SmokeTrail), consumed and cleared by
    /// drainFXCues(). Mirrors DHRev10AudioState.activeCues' small-event-queue shape, but lives in
    /// DHGameplay (no RealityKit/DHPresentation dependency) since it's the runtime that knows when
    /// combat actually happens.
    public var activeFXCues: [String] = []

    public init(id: String = "north-road", hostileCount: Int = 1) {
        encounter = .init(encounterID: id, hostileCount: hostileCount)
    }

    public mutating func tick() {
        guard !resolved else { return }
        encounter.advance()
        if encounter.phase == .attacking {
            if player.health > 0 { player.health = max(0, player.health - 8) }
            activeFXCues.append("SmokeTrail")
        }
    }

    public mutating func fire(rounds: Int = 2, damage: Double = 20) {
        DHPlayableCombatResolver().apply(.fire(rounds: rounds, damage: damage), actor: &player, target: &hostile)
        activeFXCues.append("MuzzleFlash")
        if hostile.health > 0 { activeFXCues.append("SparkImpact") }
        if hostile.health <= 0 { resolve() }
    }

    public mutating func resolve() {
        resolved = true
        encounter.resolve()
    }

    @discardableResult
    public mutating func drainFXCues() -> [String] {
        let cues = activeFXCues
        activeFXCues.removeAll()
        return cues
    }
}
