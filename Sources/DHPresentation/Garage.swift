import Foundation
import DHCore
import DHVehicle
public enum GarageInspectable:String,CaseIterable,Sendable { case battery,starter,fuseBox,fuelPump,radiator,engine,transmission,frontLeftWheel,frontRightWheel,rearLeftWheel,rearRightWheel }
public struct GarageInspection:Sendable,Equatable { public var target:GarageInspectable; public var title:String; public var condition:String; public var measurement:String }
public struct GaragePresenter:Sendable { public init(){}; public func inspect(_ target:GarageInspectable,vehicle:KingmakerState,electrical:ElectricalTopology)->GarageInspection { switch target { case .battery: return .init(target:target,title:"Battery",condition:vehicle.batterySOC > 0.5 ? "charged":"discharged",measurement:String(format:"%.1f V",12.0+vehicle.batterySOC*0.7)); case .starter: return .init(target:target,title:"Starter circuit",condition:electrical.starterPathResistance() < 0.08 ? "serviceable":"high resistance",measurement:String(format:"%.3f Ω",electrical.starterPathResistance())); default:return .init(target:target,title:target.rawValue,condition:"inspect",measurement:"physical inspection required") } } }
#if canImport(RealityKit)
import RealityKit
@available(iOS 18.0, macOS 15.0, *) @MainActor public final class KingmakerGarageScene {
 public private(set) var root=Entity(); private var cache:[GarageInspectable:Entity]=[:]
 public init() { root.name="Blackridge Kingmaker Garage" }
 public func register(_ entity:Entity,as target:GarageInspectable){entity.name=target.rawValue;cache[target]=entity;root.addChild(entity)}
 public func entity(for target:GarageInspectable)->Entity?{cache[target]}
 public func setInspectionHighlight(_ target:GarageInspectable?){ for (key,entity) in cache { entity.isEnabled = target == nil || key == target } }
}
#endif
