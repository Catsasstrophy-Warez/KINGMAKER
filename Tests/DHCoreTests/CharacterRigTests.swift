import Foundation
import Testing
@testable import DHPresentation

@Test func playerWalkBindingResolvesToTheMannequinRig() throws {
    let binding = try #require(DHRev10AssetManifest.bindings.first { $0.id == "player.walk" })
    #expect(binding.kind == .animation)
    #expect(binding.sourceName == "Mannequin_WalkCycle.usdz")
    let url = try #require(DHRev10AssetResolver.url(for: binding))
    let data = try Data(contentsOf: url)
    // A USDZ containing a real skeleton + baked walk-cycle keyframes is several KB; an empty or
    // static-mesh-only export would be far smaller, so this guards against a silently-broken bake
    // (e.g. the rotation_mode bug that once produced zero animated samples).
    #expect(data.count > 5_000)
}

@Test func playerWalkBindingIsNotAMissingRequiredBinding() {
    #expect(!DHRev10AssetResolver.missingRequiredBindings.contains { $0.id == "player.walk" })
}
