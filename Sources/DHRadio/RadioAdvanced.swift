import Foundation
import DHCore

public enum StationKind:String,Codable,Sendable { case trade,patrol,propaganda,weather,pirate,mystery }
public struct RadioStation:Identifiable,Codable,Sendable,Equatable { public let id:EntityID; public var callSign:String; public var kind:StationKind; public var towerIDs:[EntityID]; public init(id:EntityID=UUID(),callSign:String,kind:StationKind,towerIDs:[EntityID]=[]){self.id=id;self.callSign=callSign;self.kind=kind;self.towerIDs=towerIDs} }
public struct RadioReceiver:Codable,Sendable,Equatable { public var antennaCondition:Double=1; public var tunedStation:EntityID?; public var staticLevel:Double=1; public init(){}; public mutating func update(signal:Double){staticLevel=max(0,min(1,1-signal*antennaCondition))} }
public enum BroadcastComposer { public static func compose(tick:UInt64,station:String,event:WorldEvent)->Broadcast { let text:String; switch event.kind { case "convoy.disrupted": text="Northbound convoy is overdue. Traders report fuel pressure rising."; case "substation.restored": text="Power has returned to the district. Machine shops are reopening."; case "settlement.attacked": text="Emergency traffic: settlement defenses are engaged."; default: text="Field report: \(event.detail)" }; return .init(tick:tick,station:station,text:text,eventKind:event.kind) } }
