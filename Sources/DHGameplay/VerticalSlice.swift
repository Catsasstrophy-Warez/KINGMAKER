import Foundation
import DHCore
import DHVehicle
import DHWorld
public enum RestorationBeat: String, Codable, CaseIterable, Sendable { case wake, rumor, driveJunker, discoverGarage, inspectKingmaker, towHome, diagnose, scavenge, repair, fuel, battery, crank, start, highway }
public struct InventoryItem:Identifiable,Codable,Sendable,Equatable { public let id:EntityID; public var name:String; public var quantity:Int }
public struct PlayerState:Codable,Sendable,Equatable { public let id:EntityID; public var health:Double=1; public var inventory:[InventoryItem]=[]; public var caps:Int=0 }
public struct TowState:Codable,Sendable,Equatable { public var attachedVehicle:EntityID?; public var integrity:Double=1 }
public struct VerticalSliceProgress: Codable, Sendable, Equatable { public var completed: Set<RestorationBeat> = []; public init() {}; public var current: RestorationBeat { RestorationBeat.allCases.first { !completed.contains($0) } ?? .highway }; public mutating func complete(_ beat: RestorationBeat) { completed.insert(beat) } }
public enum DiagnosticResult:String,Codable,Sendable { case noCrank, cranksNoStart, starts, overheats }
public enum KingmakerDiagnostics { public static func evaluate(_ v:KingmakerState)->DiagnosticResult { if !v.canCrank{return .noCrank}; if !v.canStart{return .cranksNoStart}; if v.coolantC>110{return .overheats}; return .starts } }
