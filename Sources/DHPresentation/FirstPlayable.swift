import Foundation
import DHCore
import DHVehicle
import DHWorld

public struct DHVector3: Codable, Sendable, Equatable {
    public var x: Double; public var y: Double; public var z: Double
    public init(_ x: Double = 0, _ y: Double = 0, _ z: Double = 0) { self.x=x; self.y=y; self.z=z }
}
public enum SceneObjectKind: String, Codable, Sendable { case floor, wall, garageDoor, kingmaker, workbench, highway, paradise, prop }
public struct SceneObjectDescriptor: Codable, Sendable, Equatable {
    public var id: String; public var kind: SceneObjectKind; public var position: DHVector3; public var scale: DHVector3; public var interactive: Bool
    public init(id:String,kind:SceneObjectKind,position:DHVector3,scale:DHVector3,interactive:Bool=false){self.id=id;self.kind=kind;self.position=position;self.scale=scale;self.interactive=interactive}
}
public struct BlackridgeFirstPlayableScene: Codable, Sendable, Equatable {
    public var garage:[SceneObjectDescriptor]; public var highway:[SceneObjectDescriptor]; public var paradise:[SceneObjectDescriptor]
    public init(){
        garage=[
            .init(id:"garage.floor",kind:.floor,position:.init(),scale:.init(18,0.2,14)),
            .init(id:"garage.north",kind:.wall,position:.init(0,2.5,-7),scale:.init(18,5,0.3)),
            .init(id:"garage.west",kind:.wall,position:.init(-9,2.5,0),scale:.init(0.3,5,14)),
            .init(id:"garage.east",kind:.wall,position:.init(9,2.5,0),scale:.init(0.3,5,14)),
            .init(id:"garage.door",kind:.garageDoor,position:.init(0,2.2,7),scale:.init(7,4.4,0.25),interactive:true),
            .init(id:"kingmaker",kind:.kingmaker,position:.init(0,0.8,0),scale:.init(2.1,1.2,4.8),interactive:true),
            .init(id:"workbench",kind:.workbench,position:.init(-6,1,-4.5),scale:.init(3,2,1),interactive:true)
        ]
        highway=[.init(id:"blackridge.highway",kind:.highway,position:.init(0,0,75),scale:.init(16,0.15,140))]
        paradise=[.init(id:"paradise.blockout",kind:.paradise,position:.init(0,0,180),scale:.init(42,8,36),interactive:true)]
    }
}
public struct IsometricCameraRig: Codable, Sendable, Equatable {
    public var mode:CameraMode = .onFootIsometric; public var yawDegrees = 45.0; public var pitchDegrees = -52.0; public var distance = 18.0; public var smoothing = 0.16
    public mutating func enterVehicle(){mode = .vehicleChaseIsometric; distance = 24}
    public mutating func inspectGarage(){mode = .garageInspection; distance = 8}
    public mutating func exitVehicle(){mode = .onFootIsometric; distance = 18}
}
public struct InteractionHighlight: Codable, Sendable, Equatable { public var objectID:String?; public var prompt:String?; public init(objectID:String?=nil,prompt:String?=nil){self.objectID=objectID;self.prompt=prompt} }
public struct FirstPlayableHUD: Codable, Sendable, Equatable {
    public var speedKPH=0.0; public var fuelLiters=0.0; public var coolantC=20.0; public var health=100.0; public var radioText="NO SIGNAL"; public var interaction=InteractionHighlight()
    public init() {}
}
public struct StreamingCellController: Codable, Sendable, Equatable {
    public var active:Set<String>=["garage"]; public init(){}; public mutating func update(distanceFromGarageM:Double){ if distanceFromGarageM > 20 {active.insert("highway")}; if distanceFromGarageM > 130 {active.insert("paradise")}; if distanceFromGarageM > 60 {active.remove("garage")} }
}
#if canImport(RealityKit)
import RealityKit
@available(iOS 18.0, macOS 15.0, *) @MainActor public final class FirstPlayableRealityKitBuilder {
    public let root=Entity(); private var entities:[String:Entity]=[:]
    public init(){}
    public func build(_ scene:BlackridgeFirstPlayableScene){ for d in scene.garage+scene.highway+scene.paradise { let mesh=MeshResource.generateBox(size:[Float(d.scale.x),Float(d.scale.y),Float(d.scale.z)]); let e=ModelEntity(mesh:mesh,materials:[SimpleMaterial()]); e.name=d.id; e.position=[Float(d.position.x),Float(d.position.y),Float(d.position.z)]; root.addChild(e); entities[d.id]=e } }
    public func entity(named id:String)->Entity?{entities[id]}
}
#endif
