import Foundation
import DHCore
import DHVehicle
import DHWorld
public enum ToolKind:String,Codable,CaseIterable,Sendable { case socketSet, multimeter, testLight, jack, torqueWrench, fuelPressureGauge, compressionGauge, welder, pryBar, towRig }
public struct Tool:Identifiable,Codable,Sendable,Equatable { public let id:EntityID; public var kind:ToolKind; public var condition:Double }
public struct Encounter:Identifiable,Codable,Sendable,Equatable { public enum Kind:String,Codable,Sendable { case wreck, ambush, strandedTraveler, convoy, stormDamage, salvageCache, roadblock }; public let id:EntityID; public var kind:Kind; public var cellX:Int; public var cellY:Int; public var resolved:Bool=false }
public enum EncounterGenerator { public static func generate(rng:inout SeededGenerator,x:Int,y:Int)->Encounter { let kinds:[Encounter.Kind]=[.wreck,.ambush,.strandedTraveler,.convoy,.stormDamage,.salvageCache,.roadblock]; return .init(id:rng.nextEntityID(),kind:kinds[Int(rng.next()%UInt64(kinds.count))],cellX:x,cellY:y) } }
