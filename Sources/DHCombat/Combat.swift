import Foundation
import DHCore
import DHCharacter
import DHFleet
public struct Weapon:Identifiable,Codable,Sendable,Equatable { public let id:EntityID; public var name:String; public var damage:Double; public var ammo:Int; public var rangeM:Double; public var melee:Bool; public init(id:EntityID=UUID(),name:String,damage:Double,ammo:Int=0,rangeM:Double=2,melee:Bool=false){self.id=id;self.name=name;self.damage=damage;self.ammo=ammo;self.rangeM=rangeM;self.melee=melee} }
public struct TacticalClock:Codable,Sendable,Equatable { public var slowdown=1.0; public init(){}; public mutating func setTactical(_ enabled:Bool){slowdown=enabled ? 0.2:1} }
public enum CombatResolver { public static func hit(base:Double,skill:Int,distanceM:Double,rangeM:Double,cover:Double)->Double { max(0,min(0.98,base+Double(skill)*0.04-distanceM/max(1,rangeM)*0.35-cover)) }; public static func vehicleRam(massKG:Double,speedMPS:Double)->Double { 0.5*massKG*speedMPS*speedMPS/1000 } }
