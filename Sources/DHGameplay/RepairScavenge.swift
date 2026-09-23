import Foundation
import DHCore
import DHVehicle
import DHWorld
public enum ToolKind:String,Codable,CaseIterable,Sendable { case socketSet, multimeter, testLight, jack, torqueWrench, fuelPressureGauge, compressionGauge, welder, pryBar, towRig }
public struct Tool:Identifiable,Codable,Sendable,Equatable { public let id:EntityID; public var kind:ToolKind; public var condition:Double }
public struct Encounter:Identifiable,Codable,Sendable,Equatable { public enum Kind:String,Codable,Sendable { case wreck, ambush, strandedTraveler, convoy, stormDamage, salvageCache, roadblock }; public let id:EntityID; public var kind:Kind; public var cellX:Int; public var cellY:Int; public var resolved:Bool=false }
public enum EncounterGenerator { public static func generate(rng:inout SeededGenerator,x:Int,y:Int)->Encounter { let kinds:[Encounter.Kind]=[.wreck,.ambush,.strandedTraveler,.convoy,.stormDamage,.salvageCache,.roadblock]; return .init(id:rng.nextEntityID(),kind:kinds[Int(rng.next()%UInt64(kinds.count))],cellX:x,cellY:y) } }

/// What actually happens when an encounter is resolved. Previously all 7 Encounter.Kind cases
/// were inert labels -- EncounterGenerator picked one, nothing anywhere consumed it differently,
/// so "wreck" and "ambush" behaved identically (only the vehicle-pursuit path, a separate system
/// entirely, was actually playable). This gives each kind real, distinguishing data: what it
/// yields, how dangerous it is, how long it costs, and whether it's a combat encounter at all.
/// Final wiring into the live vertical slice (deciding when one spawns, applying the outcome to
/// player time/inventory) is separate follow-up work -- this closes the "the data doesn't
/// distinguish these" half of the gap, not the "the game triggers all 7" half.
public struct EncounterOutcome: Codable, Sendable, Equatable {
    public let lootTable: [String]
    public let dangerLevel: Double
    public let timeCostMinutes: Int
    public let isHostile: Bool
    public init(lootTable: [String], dangerLevel: Double, timeCostMinutes: Int, isHostile: Bool) {
        self.lootTable = lootTable; self.dangerLevel = dangerLevel; self.timeCostMinutes = timeCostMinutes; self.isHostile = isHostile
    }
}

public extension Encounter.Kind {
    var outcome: EncounterOutcome {
        switch self {
        case .wreck: return .init(lootTable: ["scrap metal", "spare tire", "cracked windshield"], dangerLevel: 0.1, timeCostMinutes: 10, isHostile: false)
        case .ambush: return .init(lootTable: ["ammunition", "sidearm"], dangerLevel: 0.9, timeCostMinutes: 5, isHostile: true)
        case .strandedTraveler: return .init(lootTable: ["caps", "rumor"], dangerLevel: 0.2, timeCostMinutes: 15, isHostile: false)
        case .convoy: return .init(lootTable: ["fuel canister", "trade goods"], dangerLevel: 0.5, timeCostMinutes: 20, isHostile: true)
        case .stormDamage: return .init(lootTable: ["scrap metal", "electrical parts"], dangerLevel: 0.15, timeCostMinutes: 12, isHostile: false)
        case .salvageCache: return .init(lootTable: ["rare part", "caps", "tool"], dangerLevel: 0.3, timeCostMinutes: 8, isHostile: false)
        case .roadblock: return .init(lootTable: ["toll payment demanded"], dangerLevel: 0.6, timeCostMinutes: 10, isHostile: true)
        }
    }
}

public extension Encounter {
    /// Marks the encounter resolved and returns its kind's outcome data for the caller to apply
    /// (grant loot, spend time, start combat if hostile, etc.).
    @discardableResult
    mutating func resolve() -> EncounterOutcome {
        resolved = true
        return kind.outcome
    }
}
