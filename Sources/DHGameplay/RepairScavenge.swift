import Foundation
import DHCore
import DHVehicle
import DHWorld
public enum ToolKind:String,Codable,CaseIterable,Sendable { case socketSet, multimeter, testLight, jack, torqueWrench, fuelPressureGauge, compressionGauge, welder, pryBar, towRig }
public struct Tool:Identifiable,Codable,Sendable,Equatable { public let id:EntityID; public var kind:ToolKind; public var condition:Double }
public struct SalvageLot:Identifiable,Codable,Sendable,Equatable { public let id:EntityID; public var site:BlackridgeSite; public var parts:[PersistentPart]; public var searched:Bool=false }
public struct RepairOutcome:Codable,Sendable,Equatable { public var success:Bool; public var healthGain:Double; public var consumed:String? }
public enum RepairEngine { public static func repair(part:inout PersistentPart, tools:[Tool], skill:Double)->RepairOutcome { let needed:ToolKind = [.electrical,.starting,.charging,.lighting].contains(part.domain) ? .multimeter : ([.body,.chassis,.armor].contains(part.domain) ? .welder:.socketSet); guard tools.contains(where:{$0.kind==needed && $0.condition>0.2}) else{return .init(success:false,healthGain:0,consumed:nil)}; let gain=max(0.05,min(0.45,0.12+skill*0.3)); part.health=min(1,part.health+gain); part.wear=max(0,part.wear-gain*0.55); return .init(success:true,healthGain:gain,consumed:nil) } }
public struct Encounter:Identifiable,Codable,Sendable,Equatable { public enum Kind:String,Codable,Sendable { case wreck, ambush, strandedTraveler, convoy, stormDamage, salvageCache, roadblock }; public let id:EntityID; public var kind:Kind; public var cellX:Int; public var cellY:Int; public var resolved:Bool=false }
public enum EncounterGenerator { public static func generate(rng:inout SeededGenerator,x:Int,y:Int)->Encounter { let kinds:[Encounter.Kind]=[.wreck,.ambush,.strandedTraveler,.convoy,.stormDamage,.salvageCache,.roadblock]; return .init(id:UUID(),kind:kinds[Int(rng.next()%UInt64(kinds.count))],cellX:x,cellY:y) } }
