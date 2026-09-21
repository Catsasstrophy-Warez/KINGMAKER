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
public struct DHPlayableCombatResolver: Sendable {
    public init() {}
    public func apply(_ action: DHCombatAction, actor: inout DHCombatantState, target: inout DHCombatantState) {
        switch action {
        case let .fire(rounds, damage):
            let fired = max(0, min(rounds, actor.ammo)); actor.ammo -= fired
            let cover = target.inCover ? 0.45 : 1.0
            target.health = max(0, target.health - Double(fired) * damage * cover)
            target.suppression = min(1, target.suppression + Double(fired) * 0.08)
        case let .melee(damage): target.health = max(0, target.health - damage); actor.stamina = max(0, actor.stamina - 12)
        case let .reload(rounds): actor.ammo += max(0, rounds)
        case let .takeCover(value): actor.inCover = value
        }
    }
}
