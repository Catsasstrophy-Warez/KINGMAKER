import Foundation
import DHCore

public struct VehicleUpgradeSlots:Codable,Sendable,Equatable { public var engine:String?; public var transmission:String?; public var differential:String?; public var suspension:String?; public var armor:String?; public var auxiliaryFuelLiters:Double=0; public var radio:String?; public var weaponMounts:[String]=[]; public var cargoRackKG:Double=0; public init(){} }
public struct VehicleOwnership:Codable,Sendable,Equatable { public var ownerFaction:String?; public var ownerNPC:EntityID?; public var playerOwned=false; public var theftHeat:Double=0; public init(){} }
public struct VehicleSecurity:Codable,Sendable,Equatable { public var ignitionLock=0.5; public var alarm=false; public var immobilizer=false; public init(){}; public func hotwireDifficulty()->Int { Int((ignitionLock*4).rounded()) + (alarm ? 1:0) + (immobilizer ? 2:0) } }
public enum VehicleTheftEngine { public static func attempt(skill:Int,security:VehicleSecurity)->Bool { skill >= max(1,security.hotwireDifficulty()) } }
