import Foundation
import CoreGraphics

#if canImport(RealityKit)
import RealityKit

/// Environment/IBL lighting setup split out of Rev10RealityKitScene.swift to keep that file
/// focused on core anchor/world management.
@available(iOS 18.0, macOS 15.0, *)
@MainActor
extension DHRev10RealityKitScene {
    /// Adds real image-based (environment) lighting on top of the existing single DirectionalLight
    /// -- previously there was no environment/IBL lighting at all, so every material rendered
    /// against a flat, directionless background (Docs/REV10_PRODUCTION_GAP_AUDIT.md). An earlier
    /// attempt at this used a bright emissive "studio panel" reflector in the *Blender preview
    /// renderer* (Tools/BlenderAssetGen/build_kingmaker.py) and blew the render out to near-white
    /// at any workable strength -- that was a different rendering system (Blender EEVEE, offline
    /// stills) with no exposure control comparable to this one, so the failure doesn't transfer
    /// here, but the same caution applies: this deliberately starts conservative (a dim,
    /// desaturated overcast-wasteland sky gradient, negative intensityExponent) rather than a
    /// bright reflective environment, and is easy to brighten later once verified on-device.
    /// Uses RealityFoundation.ImageBasedLightComponent/ImageBasedLightReceiverComponent
    /// (available at exactly this file's iOS 18/macOS 15 deployment target) rather than the
    /// legacy ARView.Environment.ImageBasedLight, which is UIKit/AppKit-view-scoped and doesn't
    /// apply to a bare Entity-graph scene like this one.
    func buildEnvironmentLighting() {
        // CoreSimulator's RealityKit renderer currently reports missing runtime function
        // constants for ImageBasedLightComponent's post-process path and can blank the whole
        // camera after streamed USDZ materials compile. Keep the deterministic directional light
        // on simulator so smoke tests remain visible; physical/device builds still receive the
        // full wasteland IBL.
#if targetEnvironment(simulator)
        return
#else
        guard let skyImage = Self.makeWastelandSkyImage(),
              let environment = try? EnvironmentResource(equirectangular: skyImage, withName: "wasteland_sky") else { return }
        let lightSource = Entity()
        lightSource.name = "lighting.ibl"
        var ibl = ImageBasedLightComponent(source: .single(environment), intensityExponent: -0.8)
        ibl.inheritsRotation = true
        lightSource.components.set(ibl)
        root.addChild(lightSource)
        anchors["lighting.ibl"] = lightSource
        root.components.set(ImageBasedLightReceiverComponent(imageBasedLight: lightSource))
#endif
    }

    /// A small procedural equirectangular sky: desaturated overcast zenith fading to a dusty
    /// amber horizon and a dark ground band -- generated in Swift (no new bundled asset needed)
    /// so the environment map ships with the code, not a separate file to keep in sync.
    static func makeWastelandSkyImage(width: Int = 64, height: Int = 32) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
            space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        let zenith = (r: 0.22, g: 0.21, b: 0.20)
        let horizon = (r: 0.38, g: 0.29, b: 0.20)
        let ground = (r: 0.09, g: 0.08, b: 0.07)
        for y in 0..<height {
            let t = Double(y) / Double(max(1, height - 1))
            let color: (r: Double, g: Double, b: Double)
            if t < 0.5 {
                let localT = t / 0.5
                color = (zenith.r + (horizon.r - zenith.r) * localT, zenith.g + (horizon.g - zenith.g) * localT, zenith.b + (horizon.b - zenith.b) * localT)
            } else {
                let localT = (t - 0.5) / 0.5
                color = (horizon.r + (ground.r - horizon.r) * localT, horizon.g + (ground.g - horizon.g) * localT, horizon.b + (ground.b - horizon.b) * localT)
            }
            context.setFillColor(red: color.r, green: color.g, blue: color.b, alpha: 1)
            context.fill(CGRect(x: 0, y: y, width: width, height: 1))
        }
        return context.makeImage()
    }
}
#endif
