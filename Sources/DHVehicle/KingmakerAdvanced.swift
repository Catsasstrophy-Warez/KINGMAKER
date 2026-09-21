import Foundation
import DHCore

public enum PartDomain: String, Codable, CaseIterable, Sendable { case engine, valvetrain, induction, fuel, ignition, lubrication, cooling, electrical, starting, charging, clutch, transmission, driveshaft, differential, axle, steering, suspension, brakes, wheel, tire, chassis, body, aero, lighting, armor, cabin, survival }
public struct PersistentPart: Identifiable, Codable, Sendable, Equatable { public let id: EntityID; public var key:String; public var name:String; public var domain:PartDomain; public var health:Double; public var wear:Double; public var temperatureC:Double; public var connectionResistanceOhm:Double; public var installed:Bool }
public enum KingmakerCatalog {
 public static func production(idSeed:String="XR13") -> [PersistentPart] {
  let groups:[(PartDomain,String,Int)] = [(.engine,"Engine",24),(.valvetrain,"Valvetrain",16),(.induction,"Induction",10),(.fuel,"Fuel",14),(.ignition,"Ignition",10),(.lubrication,"Lubrication",8),(.cooling,"Cooling",12),(.electrical,"Electrical",22),(.starting,"Starting",6),(.charging,"Charging",7),(.clutch,"Clutch",5),(.transmission,"Transmission",12),(.driveshaft,"Driveshaft",4),(.differential,"Differential",8),(.axle,"Axle",6),(.steering,"Steering",7),(.suspension,"Suspension",16),(.brakes,"Brakes",14),(.wheel,"Wheel",4),(.tire,"Tire",4),(.chassis,"Chassis",8),(.body,"Body",10),(.aero,"Aero",5),(.lighting,"Lighting",6),(.armor,"Armor",5),(.cabin,"Cabin",5),(.survival,"Survival",6)]
  var out:[PersistentPart]=[]
  for (domain,label,count) in groups { for i in 1...count { let key="\(idSeed).\(domain.rawValue).\(i)"; out.append(.init(id:stableUUID(key),key:key,name:"\(label) \(i)",domain:domain,health:0.35,wear:0.65,temperatureC:20,connectionResistanceOhm:domain == .electrical ? 0.02:0,installed:true)) } }
  return out
 }
 private static func stableUUID(_ text:String)->UUID { var h1:UInt64=0xcbf29ce484222325; var h2:UInt64=0x84222325cbf29ce4; for b in text.utf8 { h1=(h1 ^ UInt64(b)) &* 1099511628211; h2=(h2 ^ UInt64(b)) &* 14029467366897019727 }; let s=String(format:"%08x-%04x-%04x-%04x-%012llx",UInt32(truncatingIfNeeded:h1),UInt16(truncatingIfNeeded:h1>>32),UInt16(truncatingIfNeeded:h1>>48),UInt16(truncatingIfNeeded:h2),h2 & 0xffffffffffff); return UUID(uuidString:s)! }
}

public struct ElectricalState: Codable, Sendable, Equatable { public var batteryOpenCircuitV=12.6; public var batteryInternalR=0.012; public var starterCableR=0.008; public var groundR=0.006; public var starterR=0.045; public var alternatorMaxA=180.0; public var accessoryA=18.0
 public func crank() -> (voltage:Double,current:Double,drop:Double) { let total=max(0.001,batteryInternalR+starterCableR+groundR+starterR); let i=batteryOpenCircuitV/total; let drop=i*(starterCableR+groundR); return (max(0,batteryOpenCircuitV-i*batteryInternalR-drop),i,drop) }
 public func chargingVoltage(rpm:Double)->Double { rpm > 700 ? min(14.7,13.6 + rpm/10000) : batteryOpenCircuitV }
}
public struct FluidCircuit: Codable, Sendable, Equatable { public var capacity:Double; public var quantity:Double; public var leakPerSecond:Double; public var pumpEfficiency:Double; public mutating func step(_ dt:Double){quantity=max(0,quantity-leakPerSecond*dt)}; public var fill:Double { capacity > 0 ? quantity/capacity:0 } }
public struct DrivetrainState: Codable, Sendable, Equatable { public var engineTorqueNm=0.0; public var gearRatio=2.66; public var finalDrive=3.73; public var drivelineEfficiency=0.88; public var wheelRadiusM=0.34; public var speedMPS=0.0; public var massKg=1850.0
 public mutating func step(throttle:Double,grip:Double,dt:Double){ engineTorqueNm=max(0,min(1,throttle))*950; let force=min(engineTorqueNm*gearRatio*finalDrive*drivelineEfficiency/wheelRadiusM, massKg*9.81*max(0,grip)); speedMPS=max(0,speedMPS+(force/massKg-0.012*speedMPS*speedMPS)*dt) }
}
public struct TireState: Codable, Sendable, Equatable { public var pressureKPa=220.0; public var tread=1.0; public var temperatureC=25.0; public var punctured=false; public var grip:Double { punctured ? 0.15 : max(0.25,min(1.15,(pressureKPa/220)*tread*(1-abs(75-temperatureC)/250))) } }
public struct CollisionResult: Codable, Sendable, Equatable { public var energyJ:Double; public var chassisDamage:Double; public var suspensionDamage:Double; public var tireDamage:Double }
public enum CollisionSolver { public static func impact(massKg:Double,speedMPS:Double,angleCos:Double)->CollisionResult { let e=0.5*massKg*speedMPS*speedMPS*max(0,min(1,abs(angleCos))); let n=min(1,e/900_000); return .init(energyJ:e,chassisDamage:n*0.55,suspensionDamage:n*0.8,tireDamage:n*0.65) } }
