import Foundation
import DHCore
import DHVehicle
import DHWorld
public struct RenderVehicleSnapshot:Sendable,Equatable { public var id:EntityID; public var speedMPS:Double; public var engineRunning:Bool; public var coolantC:Double; public var damage:Double }
public struct RenderWorldSnapshot:Sendable,Equatable { public var tick:UInt64; public var loadedCells:Set<EntityID>; public var hero:RenderVehicleSnapshot }
public protocol DeadHighwayPresentationSink:Sendable { func consume(_ snapshot:RenderWorldSnapshot) async }
#if canImport(RealityKit)
import RealityKit
@available(iOS 18.0, macOS 15.0, *) public actor RealityKitPresentationBridge:DeadHighwayPresentationSink { public init(){}; public func consume(_ snapshot:RenderWorldSnapshot) async { /* Entity caches, instancing and LOD bind here. Simulation truth remains outside RealityKit. */ } }
#endif
public enum CameraMode:String,Codable,Sendable { case onFootIsometric,vehicleChaseIsometric,garageInspection,interior }
