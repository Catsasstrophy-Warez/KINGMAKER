import Foundation
import Testing
@testable import DHPresentation

@Test func allRequiredManifestBindingsResolve() {
    // Previously 8 of 20 required bindings pointed at files that didn't exist in
    // Sources/DHPresentation/Resources/ (silently, since DHRev10AssetResolver.url returns nil
    // rather than crashing). This guards against that regressing again.
    #expect(DHRev10AssetResolver.missingRequiredBindings.isEmpty, "missing: \(DHRev10AssetResolver.missingRequiredBindings.map(\.id))")
}

@Test func garageNavmeshBindingResolvesToValidJSON() throws {
    let binding = try #require(DHRev10AssetManifest.bindings.first { $0.id == "player.navmesh" })
    let url = try #require(DHRev10AssetResolver.url(for: binding))
    let data = try Data(contentsOf: url)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    #expect(json?["chunkID"] as? String == "chunk.garage")
    #expect((json?["polygons"] as? [[String: Any]])?.isEmpty == false)
}

@Test func startAndRepairAnimationBindingsResolveToValidJSON() throws {
    for id in ["player.interact", "kingmaker.start"] {
        let binding = try #require(DHRev10AssetManifest.bindings.first { $0.id == id })
        let url = try #require(DHRev10AssetResolver.url(for: binding))
        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect((json?["tracks"] as? [[String: Any]])?.isEmpty == false, "\(id) has no animation tracks")
    }
}

@Test func truckStopInteriorBindingResolves() throws {
    let binding = try #require(DHRev10AssetManifest.bindings.first { $0.id == "truckstop.interior" })
    let url = try #require(DHRev10AssetResolver.url(for: binding))
    #expect(try Data(contentsOf: url).count > 1000)
}

@Test func combatFXBindingResolvesToNonEmptyUSDA() throws {
    let binding = try #require(DHRev10AssetManifest.bindings.first { $0.id == "combat.fx" })
    let url = try #require(DHRev10AssetResolver.url(for: binding))
    let text = try String(contentsOf: url, encoding: .utf8)
    #expect(text.hasPrefix("#usda"))
}
