import Foundation
import Testing
@testable import DHPresentation

#if canImport(RealityKit)
import RealityKit

@available(iOS 18.0, macOS 15.0, *)
@Test @MainActor func buildInstallsARealImageBasedLightSource() throws {
    let scene = DHRev10RealityKitScene()
    scene.build()
    let lightSource = try #require(scene.entity(for: "lighting.ibl"))
    let ibl = try #require(lightSource.components[ImageBasedLightComponent.self])
    guard case .single = ibl.source else {
        Issue.record("expected a single-environment IBL source")
        return
    }
    #expect(ibl.intensityExponent < 0, "should start conservative/dim, not full-bright")
}

@available(iOS 18.0, macOS 15.0, *)
@Test @MainActor func rootReceivesTheImageBasedLight() throws {
    let scene = DHRev10RealityKitScene()
    scene.build()
    let lightSource = try #require(scene.entity(for: "lighting.ibl"))
    let receiver = try #require(scene.root.components[ImageBasedLightReceiverComponent.self])
    #expect(receiver.imageBasedLight === lightSource)
}

@available(iOS 18.0, macOS 15.0, *)
@Test @MainActor func rebuildingTheSceneDoesNotAccumulateLightSources() {
    let scene = DHRev10RealityKitScene()
    scene.build()
    scene.build()
    let lightSources = scene.root.children.filter { $0.name == "lighting.ibl" }
    #expect(lightSources.count == 1)
}
#endif
