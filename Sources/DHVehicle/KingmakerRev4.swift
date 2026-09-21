import Foundation
import DHCore

public enum KMAssembly:String,Codable,CaseIterable,Sendable { case engine, induction, fuel, cooling, lubrication, ignition, startingCharging, transmission, differential, frontSuspension, rearSuspension, steering, brakes, wheelsTires, chassis, body, aero, survival }
public struct KMPart:Identifiable,Codable,Sendable,Equatable { public let id:EntityID; public var key:String; public var name:String; public var assembly:KMAssembly; public var condition:Double; public var installed:Bool; public var torqueNm:Double? }
public enum KingmakerPartsCatalog {
 public static func authored()->[KMPart] {
  let rows:[(String,String,KMAssembly)] = [
   ("eng.block","Engine block",.engine),("eng.crank","Forged crankshaft",.engine),("eng.mainbearings","Main bearings",.engine),("eng.rods","Connecting rods",.engine),("eng.pistons","Pistons",.engine),("eng.rings","Piston rings",.engine),("eng.cam","Camshafts",.engine),("eng.valves","Valves and springs",.engine),("eng.headL","Left cylinder head",.engine),("eng.headR","Right cylinder head",.engine),("eng.flywheel","Flywheel",.engine),
   ("ind.blower","Supercharger",.induction),("ind.throttle","Throttle body",.induction),("ind.filter","Air filter",.induction),("ind.intercooler","Charge cooler",.induction),
   ("fuel.tank","Fuel tank",.fuel),("fuel.pump","Fuel pump",.fuel),("fuel.filter","Fuel filter",.fuel),("fuel.rail","Fuel rail",.fuel),("fuel.injectors","Injector set",.fuel),("fuel.regulator","Fuel regulator",.fuel),
   ("cool.radiator","Radiator",.cooling),("cool.waterpump","Water pump",.cooling),("cool.thermostat","Thermostat",.cooling),("cool.fan","Cooling fan",.cooling),("cool.upperhose","Upper radiator hose",.cooling),("cool.lowerhose","Lower radiator hose",.cooling),("cool.reservoir","Expansion reservoir",.cooling),
   ("lube.oilpump","Oil pump",.lubrication),("lube.filter","Oil filter",.lubrication),("lube.pan","Oil pan",.lubrication),("ign.coils","Ignition coils",.ignition),("ign.plugs","Spark plugs",.ignition),("ign.controller","Ignition controller",.ignition),
   ("elec.battery","Battery",.startingCharging),("elec.starter","Starter motor",.startingCharging),("elec.alternator","Alternator",.startingCharging),("elec.g101","G101 engine ground",.startingCharging),("elec.startrelay","Starter relay",.startingCharging),("elec.startfuse","Starter fuse",.startingCharging),
   ("trans.gearbox","Six-speed gearbox",.transmission),("trans.clutch","Twin-disc clutch",.transmission),("trans.driveshaft","Driveshaft",.transmission),("diff.carrier","Limited-slip carrier",.differential),("diff.ringpinion","Ring and pinion",.differential),
   ("sus.fl.ca","Front-left control arm",.frontSuspension),("sus.fr.ca","Front-right control arm",.frontSuspension),("sus.fl.damper","Front-left damper",.frontSuspension),("sus.fr.damper","Front-right damper",.frontSuspension),("sus.rl.link","Rear-left suspension links",.rearSuspension),("sus.rr.link","Rear-right suspension links",.rearSuspension),("sus.rl.damper","Rear-left damper",.rearSuspension),("sus.rr.damper","Rear-right damper",.rearSuspension),
   ("steer.rack","Steering rack",.steering),("brake.master","Brake master cylinder",.brakes),("brake.fl","Front-left brake",.brakes),("brake.fr","Front-right brake",.brakes),("brake.rl","Rear-left brake",.brakes),("brake.rr","Rear-right brake",.brakes),
   ("wheel.fl","Front-left wheel/tire",.wheelsTires),("wheel.fr","Front-right wheel/tire",.wheelsTires),("wheel.rl","Rear-left wheel/tire",.wheelsTires),("wheel.rr","Rear-right wheel/tire",.wheelsTires),
   ("body.hood","Hood",.body),("body.driverdoor","Driver door",.body),("body.passdoor","Passenger door",.body),("body.hatch","Rear hatch",.body),("chassis.shell","Unibody shell",.chassis),("aero.splitter","Front splitter",.aero),("aero.wing","Rear wing",.aero),("surv.extinguisher","Fire extinguisher",.survival),("surv.water","Water storage",.survival)
  ]
  return rows.map{KMPart(id:UUID(),key:$0.0,name:$0.1,assembly:$0.2,condition:0.35,installed:true,torqueNm:nil)}
 }
}

public enum MeterMode:String,Codable,Sendable { case dcVolts, ohms, continuity }
public struct TestPoint:Identifiable,Codable,Sendable,Equatable { public let id:EntityID; public var key:String; public var electricalNodeKey:String }
public struct DMMReading:Codable,Sendable,Equatable { public var display:String; public var value:Double?; public var unit:String; public var valid:Bool }
public struct VirtualDMM:Codable,Sendable,Equatable {
 public var mode:MeterMode = .dcVolts
 public func measure(red:TestPoint, black:TestPoint, topology:ElectricalTopology, energized:Bool=true)->DMMReading {
  guard let r=topology.node(red.electricalNodeKey), let b=topology.node(black.electricalNodeKey) else { return .init(display:"OL",value:nil,unit:"",valid:false) }
  switch mode {
  case .dcVolts: let v=(energized ? r.voltage-b.voltage : 0); return .init(display:String(format:"%.2f",v),value:v,unit:"V",valid:true)
  case .ohms: guard !energized else { return .init(display:"LIVE",value:nil,unit:"Ω",valid:false) }; let x=topology.starterPathResistance(); return .init(display:String(format:"%.3f",x),value:x,unit:"Ω",valid:true)
  case .continuity: guard !energized else { return .init(display:"LIVE",value:nil,unit:"",valid:false) }; let x=topology.starterPathResistance(); return .init(display:x < 0.1 ? "BEEP" : "OL",value:x,unit:"Ω",valid:true)
  }
 }
}

public struct EngineDynamics:Codable,Sendable,Equatable { public var rpm=0.0; public var throttle=0.0; public var torqueNm=0.0; public var oilC=20.0; public var coolantC=20.0; public mutating func step(running:Bool, load:Double, dt:Double){ guard running else { rpm=max(0,rpm-900*dt); torqueNm=0; return }; let target=850 + max(0,min(1,throttle))*6150; rpm += (target-rpm)*min(1,dt*3); let shape=max(0,1-abs(rpm-4500)/5000); torqueNm=(180+720*shape)*throttle*(1-min(0.65,max(0,load))); coolantC += (55+0.012*rpm-coolantC)*0.015*dt; oilC += (70+0.008*rpm-oilC)*0.01*dt } }
public struct TireForceState:Codable,Sendable,Equatable { public var longitudinalN=0.0; public var lateralN=0.0; public mutating func solve(normalN:Double,mu:Double,slip:Double,slipAngle:Double){ let cap=max(0,normalN*mu); longitudinalN=max(-cap,min(cap,cap*slip*5)); let remain=sqrt(max(0,cap*cap-longitudinalN*longitudinalN)); lateralN=max(-remain,min(remain,-remain*slipAngle*4)) } }
public struct DifferentialDynamics:Codable,Sendable,Equatable { public var lock=0.25; public func split(inputTorque:Double,leftGrip:Double,rightGrip:Double)->(Double,Double){ let bias=max(0,min(1,lock)); let d=(rightGrip-leftGrip)*0.25*(1-bias); return (inputTorque*(0.5+d),inputTorque*(0.5-d)) } }

public enum GaragePanel:String,Codable,CaseIterable,Sendable { case hood, driverDoor, passengerDoor, hatch, lift }
public struct GarageInteractionState:Codable,Sendable,Equatable { public var openness:[GaragePanel:Double]=Dictionary(uniqueKeysWithValues:GaragePanel.allCases.map{($0,0)}); public mutating func set(_ panel:GaragePanel,open:Bool){openness[panel]=open ? 1:0} }
public struct SalvagePart:Identifiable,Codable,Sendable,Equatable { public let id:EntityID; public var catalogKey:String; public var condition:Double; public var compatibility:String }
public enum InstallationResult:String,Codable,Sendable { case installed, incompatible, missingTool }
public struct InstallationSystem { public static func install(_ salvage:SalvagePart, into parts:inout [KMPart], availableTools:Set<String>)->InstallationResult { guard salvage.compatibility=="XR13" else{return .incompatible}; guard availableTools.contains("socket-set") else{return .missingTool}; guard let i=parts.firstIndex(where:{$0.key==salvage.catalogKey}) else{return .incompatible}; parts[i].installed=true; parts[i].condition=salvage.condition; return .installed } }

public enum RestorationStage:Int,Codable,CaseIterable,Sendable { case rumor, locate, tow, inspect, diagnose, scavenge, repairElectrical, repairFuel, repairCooling, crank, start, openGarage, highway }
public struct RestorationRuntime:Codable,Sendable,Equatable { public var stage:RestorationStage = .rumor; public var history:[RestorationStage]=[.rumor]; public mutating func advance(requirementsMet:Bool)->Bool { guard requirementsMet, let n=RestorationStage(rawValue:stage.rawValue+1) else{return false}; stage=n; history.append(n); return true } }
