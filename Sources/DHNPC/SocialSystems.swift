import Foundation
import DHCore
import DHCharacter
import DHWorld

public enum DialogueIntent:String,Codable,Sendable { case greet,trade,rumor,threaten,persuade,recruit,bribe,question }
public struct DialogueOption:Identifiable,Codable,Sendable,Equatable { public let id:EntityID; public var text:String; public var intent:DialogueIntent; public var difficulty:Int; public init(id:EntityID=UUID(),text:String,intent:DialogueIntent,difficulty:Int=0){self.id=id;self.text=text;self.intent=intent;self.difficulty=difficulty} }
public struct NegotiationResult:Codable,Sendable,Equatable { public var success:Bool; public var dispositionDelta:Double; public var priceMultiplier:Double }
public enum NegotiationEngine { public static func resolve(skill:Int,charisma:Int,reputation:Double,difficulty:Int)->NegotiationResult { let score=Double(skill*8+charisma*3)+reputation*20-Double(difficulty*10);let success=score>=35;return .init(success:success,dispositionDelta:success ? 0.1:-0.04,priceMultiplier:success ? max(0.7,1-Double(skill)*0.025):1.08) } }
public enum CompanionRole:String,Codable,CaseIterable,Sendable { case mechanic,gunner,medic,scout,trader,driver }
public struct CompanionState:Identifiable,Codable,Sendable,Equatable { public let id:EntityID; public var npcID:EntityID; public var role:CompanionRole; public var loyalty:Double; public var recruited:Bool; public init(id:EntityID=UUID(),npcID:EntityID,role:CompanionRole,loyalty:Double=0.5,recruited:Bool=false){self.id=id;self.npcID=npcID;self.role=role;self.loyalty=loyalty;self.recruited=recruited} }
public enum RecruitmentEngine { public static func attempt(_ c:inout CompanionState,speech:Int,reputation:Double)->Bool { guard Double(speech)*0.09+reputation*0.5+c.loyalty>=0.9 else{return false};c.recruited=true;return true } }
