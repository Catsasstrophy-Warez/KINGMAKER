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
#if canImport(Metal)
import Metal
public struct MetalEffectsBoundary:Sendable { public init(){} /* dust, skid, heat haze, particles, telemetry buffers */ }
#endif

public enum CameraMode:String,Codable,Sendable { case onFootIsometric,vehicleChaseIsometric,garageInspection,interior }
public struct PresentationLOD:Codable,Sendable,Equatable { public var fullNPCs=24; public var simplifiedNPCs=64; public var simulatedResidents=150; public var vehicleRenderRadiusM=450.0; public var worldCellRadius=2 }
#if canImport(RealityKit)
import RealityKit
@available(iOS 18.0, macOS 15.0, *) @MainActor public final class BlackridgeSceneBridge { public let root=Entity(); public init(){}; public func attach(_ entity:Entity){root.addChild(entity)} }
#endif
