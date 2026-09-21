import Foundation
import DHCore
import DHVehicle
import DHCharacter
import DHNPC
import DHRadio

public struct NavigationObstacle:Identifiable,Codable,Sendable,Equatable { public let id:String; public var minX:Double; public var maxX:Double; public var minZ:Double; public var maxZ:Double; public init(id:String,minX:Double,maxX:Double,minZ:Double,maxZ:Double){self.id=id;self.minX=minX;self.maxX=maxX;self.minZ=minZ;self.maxZ=maxZ}; public func contains(_ p:DHVector3)->Bool { p.x>=minX && p.x<=maxX && p.z>=minZ && p.z<=maxZ } }
public struct SimpleNavigationRuntime:Codable,Sendable,Equatable { public var obstacles:[NavigationObstacle]=[]; public init(obstacles:[NavigationObstacle]=[]){self.obstacles=obstacles}; public func resolvedMove(from:DHVector3,to:DHVector3)->DHVector3 { obstacles.contains{$0.contains(to)} ? from:to } }

public enum VehicleOccupancyState:String,Codable,Sendable { case onFoot,entering,driving,exiting }
public struct VehicleEntryExitState:Codable,Sendable,Equatable { public var state:VehicleOccupancyState = .onFoot; public var progress:Double=0; public init(){}; public mutating func beginEnter(){guard state == .onFoot else{return};state = .entering;progress=0}; public mutating func beginExit(){guard state == .driving else{return};state = .exiting;progress=0}; public mutating func step(dt:Double){guard state == .entering || state == .exiting else{return};progress=min(1,progress+dt/0.65);if progress>=1 { state = state == .entering ? .driving:.onFoot }} }

public struct VehicleAnimationState:Codable,Sendable,Equatable { public var steeringWheelRadians=0.0; public var frontWheelRadians=0.0; public var wheelSpinRadians=0.0; public var suspensionCompression=0.0; public init(){}; public mutating func update(steer:Double,speedMPS:Double,dt:Double){frontWheelRadians=max(-0.52,min(0.52,steer*0.52));steeringWheelRadians=frontWheelRadians*12;wheelSpinRadians.formTruncatingRemainder(dividingBy:.pi*2);wheelSpinRadians += speedMPS/max(0.1,0.34)*dt} }

public enum PresentationDMMMode:String,Codable,Sendable { case dcVoltage,resistance,continuity }
public struct DMMPanelState:Codable,Sendable,Equatable { public var mode:PresentationDMMMode = .dcVoltage; public var redPoint:String?; public var blackPoint:String?; public var readingText="---"; public var warning:String?; public init(){}; public mutating func display(_ reading:DMMReading){ if let v=reading.value { readingText=String(format:"%.3f %@",v,reading.unit) } else { readingText="OL" }; warning = reading.valid ? nil : reading.display } }

public struct InventoryPanelState:Codable,Sendable,Equatable { public var visible=false; public var selectedItemID:String?; public var filter:String="ALL"; public init(){} }
public struct RadioPanelState:Codable,Sendable,Equatable { public var visible=false; public var frequencyMHz=98.7; public var station="KBRG"; public var signal=0.0; public var staticLevel=1.0; public var latestText="NO SIGNAL"; public init(){}; public mutating func ingest(_ b:Broadcast?,signal:Double){self.signal=signal;self.staticLevel=1-signal;latestText = signal>0.15 ? (b?.text ?? "..."):"NO SIGNAL"} }

public struct NPCVisualAgent:Identifiable,Codable,Sendable,Equatable { public let id:EntityID; public var position:DHVector3; public var target:DHVector3; public var speed:Double; public var detailLevel:Int; public init(id:EntityID=UUID(),position:DHVector3,target:DHVector3,speed:Double=1.4,detailLevel:Int=2){self.id=id;self.position=position;self.target=target;self.speed=speed;self.detailLevel=detailLevel}; public mutating func step(dt:Double){let dx=target.x-position.x,dz=target.z-position.z,d=hypot(dx,dz);guard d>0.05 else{return};position.x += dx/d*speed*dt;position.z += dz/d*speed*dt} }

public enum MissionObjectiveState:String,Codable,Sendable { case hidden,active,complete,failed }
public struct MissionObjective:Identifiable,Codable,Sendable,Equatable { public let id:String; public var text:String; public var state:MissionObjectiveState; public init(id:String,text:String,state:MissionObjectiveState = .hidden){self.id=id;self.text=text;self.state=state} }
public struct OpeningMissionRuntime:Codable,Sendable,Equatable { public var objectives:[MissionObjective] = [
 .init(id:"find",text:"Find the buried garage",state:.active), .init(id:"diagnose",text:"Diagnose the XR-13"), .init(id:"repair",text:"Make Kingmaker run"), .init(id:"highway",text:"Reach Blackridge Highway"), .init(id:"paradise",text:"Reach Paradise"), .init(id:"trade",text:"Trade salvage") ]; public init(){}; public mutating func complete(_ id:String){guard let i=objectives.firstIndex(where:{$0.id==id}) else{return};objectives[i].state = .complete;if i+1<objectives.count && objectives[i+1].state == .hidden {objectives[i+1].state = .active}}; public var complete:Bool { objectives.allSatisfy{$0.state == .complete} } }
