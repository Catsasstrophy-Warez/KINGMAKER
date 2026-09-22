import Foundation
import Testing
@testable import DHPresentation

@Test func repairClipDecodesAndSamplesASpineTrack() throws {
    let library = DHRev10AnimationClipLibrary()
    let clip = try #require(library.clip(forBindingID: "player.interact"))
    #expect(clip.name == "Player_Repair")
    #expect(clip.tracks.contains { $0.bone == "spine" && $0.axis == "x" })
    let midpoint = clip.sample(bone: "spine", axis: "x", at: clip.durationSeconds / 2)
    #expect(midpoint != nil)
}

@Test func startClipSamplesChassisShudderAcrossTheWholeDuration() throws {
    let library = DHRev10AnimationClipLibrary()
    let clip = try #require(library.clip(forBindingID: "kingmaker.start"))
    #expect(clip.name == "Kingmaker_Start")
    var samples: Set<Double> = []
    var t = 0.0
    while t < clip.durationSeconds {
        if let v = clip.sample(bone: "chassis", axis: "x", at: t) { samples.insert(v) }
        t += clip.durationSeconds / 20
    }
    #expect(samples.count > 1, "expected the chassis shudder to actually vary over time")
}

@Test func clipSamplingLoopsPastTheDuration() throws {
    let library = DHRev10AnimationClipLibrary()
    let clip = try #require(library.clip(forBindingID: "player.interact"))
    let a = clip.sample(bone: "spine", axis: "x", at: 0.01)
    let b = clip.sample(bone: "spine", axis: "x", at: clip.durationSeconds + 0.01)
    #expect(a != nil && b != nil)
    #expect(abs((a ?? 0) - (b ?? 0)) < 0.5)
}

@Test func sampleAllReturnsEveryTrackKeyedByBoneDotAxis() throws {
    let library = DHRev10AnimationClipLibrary()
    let clip = try #require(library.clip(forBindingID: "kingmaker.start"))
    let all = clip.sampleAll(at: 0.5)
    #expect(all.keys.contains("chassis.z"))
    #expect(all.count == clip.tracks.count)
}

@Test func missingBindingIDReturnsNilRatherThanCrashing() {
    let library = DHRev10AnimationClipLibrary()
    #expect(library.clip(forBindingID: "not.a.real.binding") == nil)
}
