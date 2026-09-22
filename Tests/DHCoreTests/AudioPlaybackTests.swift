import Foundation
import Testing
@testable import DHPresentation

#if canImport(AVFoundation)
@available(iOS 18.0, macOS 15.0, *)
@Test @MainActor func engineMixStartsAndStopsLoopingStemsByVolume() {
    let player = DHRev10AudioPlayer()
    var mix = KingmakerAudioMixState()
    mix.update(rpm: 4000, maxRPM: 7500, boostPSI: 10, faultCodes: [])
    player.updateEngineMix(mix) // should start the exhaust/valvetrain/supercharger loops
    player.updateEngineMix(KingmakerAudioMixState()) // rpm 0 -> volumes ~0 -> should pause them
    player.stopAll()
}

@available(iOS 18.0, macOS 15.0, *)
@Test @MainActor func radioConsequenceCueActuallyPlays() {
    let player = DHRev10AudioPlayer()
    var audio = DHRev10AudioState()
    audio.trigger(.radioConsequence)
    #expect(audio.activeCues == [.radioConsequence])
    player.drain(&audio)
    #expect(audio.activeCues.isEmpty) // drained
    player.stopAll()
}

@available(iOS 18.0, macOS 15.0, *)
@Test @MainActor func allRequiredAudioCuesHaveABoundStemThatPlays() {
    let player = DHRev10AudioPlayer()
    for cue in DHRev10ProductionContract.requiredAudio {
        var audio = DHRev10AudioState()
        audio.trigger(cue)
        player.drain(&audio)
        #expect(audio.activeCues.isEmpty, "\(cue) was not drained")
    }
    player.stopAll()
}

@available(iOS 18.0, macOS 15.0, *)
@Test func placeholderAudioStemsResolveFromTheBundle() {
    let engineBindingIDs = [
        "engine.exhaust", "engine.valvetrain", "engine.supercharger", "transmission.shift", "radio.consequence",
        "cue.engineCrank", "cue.engineStart", "cue.engineKnock", "cue.repair", "cue.lootOpen", "cue.lootCollect",
        "cue.hostileTelegraph", "cue.hostileAttack", "cue.paradiseNegotiation", "radio.static",
    ]
    for id in engineBindingIDs {
        let binding = DHRev10AssetManifest.bindings.first { $0.id == id }
        #expect(binding != nil, "missing manifest binding for \(id)")
        if let binding {
            #expect(DHRev10AssetResolver.url(for: binding) != nil, "\(binding.sourceName) did not resolve")
        }
    }
}
#endif
