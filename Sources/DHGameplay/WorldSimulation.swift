import Foundation
import DHCore
import DHWorld
import DHSettlement
import DHEconomy
import DHRadio
import DHNPC

public struct DynamicWorldRuntime:Codable,Sendable,Equatable { public var civilization=CivilizationRuntime(); public var economy=RegionalEconomy(); public var radio=RadioNetwork(); public var eventLog:[WorldEvent]=[]; public var tick:UInt64=0; public init(){}; public mutating func emit(kind:String,detail:String,station:String="KBRG"){ tick += 1; let e=WorldEvent(tick:tick,kind:kind,detail:detail);eventLog.append(e);radio.broadcasts.append(BroadcastComposer.compose(tick:tick,station:station,event:e)) }; public mutating func disruptRoute(_ id:EntityID){ guard var route=economy.routes[id] else{return};route.disrupted=true;economy.routes[id]=route;emit(kind:"convoy.disrupted",detail:"Route \(id) disrupted") }; public mutating func restoreInfrastructure(_ id:EntityID,skill:Int,parts:Int)->Bool { guard civilization.restore(id,skill:skill,parts:parts) else{return false};emit(kind:"substation.restored",detail:"Infrastructure restored");return true } }
