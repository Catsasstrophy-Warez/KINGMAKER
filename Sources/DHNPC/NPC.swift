import Foundation
import DHCore
import DHCharacter
import DHWorld
public enum Occupation:String,Codable,CaseIterable,Sendable { case mechanic,trader,fuelDealer,bountyHunter,farmer,sexWorker,mercenary,doctor,gambler,refugee,thief,courier,`guard`,scavenger,railWorker }
public enum Need:String,Codable,CaseIterable,Sendable { case food,water,shelter,safety,income,medicine }
public struct NPCState:Identifiable,Codable,Sendable,Equatable { public let id:EntityID; public var character:CharacterState; public var occupation:Occupation; public var faction:Faction?; public var home:BlackridgeSite; public var current:BlackridgeSite; public var needs:[Need:Double]; public var relationships:[EntityID:Double]=[:]; public var dialogueFlags:Set<String> = []; public init(id:EntityID=UUID(),name:String,occupation:Occupation,home:BlackridgeSite,faction:Faction?=nil){self.id=id;character = .init(id:id,name:name);self.occupation=occupation;self.home=home;current=home;self.faction=faction;needs=Dictionary(uniqueKeysWithValues:Need.allCases.map{($0,0)})} }
public struct NPCPopulation:Codable,Sendable,Equatable { public var residents:[EntityID:NPCState]=[:]; public init(){}; public mutating func add(_ n:NPCState){residents[n.id]=n}; public func active(near site:BlackridgeSite,limit:Int)->[NPCState]{Array(residents.values.filter{$0.current==site}.prefix(limit))} }
