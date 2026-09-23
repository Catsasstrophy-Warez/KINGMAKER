import Foundation

public struct DHCombatantState: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    public var health: Double = 100
    public var stamina: Double = 100
    public var ammo: Int = 0
    public var inCover: Bool = false
    public var suppression: Double = 0
    public init(id: String, health: Double = 100, stamina: Double = 100, ammo: Int = 0, inCover: Bool = false, suppression: Double = 0) { self.id=id; self.health=health; self.stamina=stamina; self.ammo=ammo; self.inCover=inCover; self.suppression=suppression }
}
public enum DHCombatAction: Sendable, Equatable { case fire(rounds: Int, damage: Double), melee(damage: Double), reload(rounds: Int), takeCover(Bool) }

/// What actually happened when a DHCombatAction resolved -- previously apply() was Void, so a
/// .fire action gave its caller no way to tell a hit from a miss (every fired round always dealt
/// damage; VehicleEncounterRuntime.fire() always queued the same "hit" FX/cue regardless).
/// roundsFired/roundsHit are 0 for non-.fire actions.
public struct DHCombatOutcome: Sendable, Equatable {
    public let roundsFired: Int
    public let roundsHit: Int
    public var anyHit: Bool { roundsHit > 0 }
    public init(roundsFired: Int = 0, roundsHit: Int = 0) { self.roundsFired = roundsFired; self.roundsHit = roundsHit }
}

public struct DHPlayableCombatResolver: Sendable {
    public init() {}

    /// The per-round hit probability .fire uses when `rolls` are supplied (see apply(...)
    /// below). A suppressed target is easier to hit (harder to react); cover makes a hit less
    /// likely on top of dealing less damage when it does land. Exposed so a caller wiring up
    /// real combat can show/reason about the same number the resolver actually uses.
    public static func hitChance(against target: DHCombatantState) -> Double {
        min(0.97, max(0.15, 0.8 - (target.inCover ? 0.25 : 0) + target.suppression * 0.15))
    }

    /// `rolls`: one value in [0, 1) per round about to be fired, compared against
    /// `Self.hitChance(against:)` to decide hit vs. miss. **Deliberately opt-in and
    /// backward-compatible**: passing `nil` (the default) preserves the original
    /// every-fired-round-always-hits behavior exactly, so existing callers/tests are
    /// unaffected. A caller that wants real hit/miss supplies its own rolls (from a seeded RNG
    /// for reproducibility, or `Double.random(in:)` for live gameplay) -- the resolver never
    /// generates randomness itself, so it stays a pure, deterministically-testable function.
    @discardableResult
    public func apply(_ action: DHCombatAction, actor: inout DHCombatantState, target: inout DHCombatantState, rolls: [Double]? = nil) -> DHCombatOutcome {
        switch action {
        case let .fire(rounds, damage):
            let fired = max(0, min(rounds, actor.ammo)); actor.ammo -= fired
            let cover = target.inCover ? 0.45 : 1.0
            let hits: Int
            if let rolls {
                let threshold = Self.hitChance(against: target)
                hits = rolls.prefix(fired).filter { $0 < threshold }.count
            } else {
                hits = fired
            }
            target.health = max(0, target.health - Double(hits) * damage * cover)
            target.suppression = min(1, target.suppression + Double(fired) * 0.08)
            return DHCombatOutcome(roundsFired: fired, roundsHit: hits)
        case let .melee(damage):
            target.health = max(0, target.health - damage); actor.stamina = max(0, actor.stamina - 12)
            return DHCombatOutcome(roundsFired: 1, roundsHit: 1)
        case let .reload(rounds):
            actor.ammo += max(0, rounds)
            return DHCombatOutcome()
        case let .takeCover(value):
            actor.inCover = value
            return DHCombatOutcome()
        }
    }
}
