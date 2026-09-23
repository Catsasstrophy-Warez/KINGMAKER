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

    /// `rolls`: forwarded to DHPlayableCombatResolver.apply -- nil (the default) preserves the
    /// original every-round-hits behavior exactly, so every existing caller/test is unaffected.
    /// Pass real per-round rolls (a seeded RNG for reproducible tests, Double.random for live
    /// gameplay) to get genuine hit/miss instead of every fired round automatically connecting;
    /// see DHPlayableCombatResolver's doc comment for why this stays opt-in.
    @discardableResult
    public mutating func fire(rounds: Int = 2, damage: Double = 20, rolls: [Double]? = nil) -> DHCombatOutcome {
        let outcome = DHPlayableCombatResolver().apply(.fire(rounds: rounds, damage: damage), actor: &player, target: &hostile, rolls: rolls)
        activeFXCues.append("MuzzleFlash")
        if outcome.anyHit { activeFXCues.append("SparkImpact") }
        if hostile.health <= 0 { resolve() }
        return outcome
    }

    /// Wraps DHCombatAction.reload -- the resolver already modeled reload, but nothing on the
    /// vehicle-encounter path exposed a way to call it, so ammo (capped implicitly by never
    /// being replenished) could only ever go down mid-encounter.
    public mutating func reload(rounds: Int) {
        var dummyTarget = hostile
        DHPlayableCombatResolver().apply(.reload(rounds: rounds), actor: &player, target: &dummyTarget)
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
