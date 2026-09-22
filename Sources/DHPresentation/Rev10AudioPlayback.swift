import Foundation

#if canImport(AVFoundation)
import AVFoundation

// Audio was previously entirely state/contract (KingmakerAudioMixState computed volumes/rate
// that nothing read, DHRev10AudioState tracked "active cues" that nothing played). This wires
// both to real AVAudioPlayer playback of the procedurally synthesized stems in
// Tools/BlenderAssetGen/build_audio.py, resolved through the existing asset manifest so audio
// asset lookup goes through the same DHRev10AssetResolver as visual assets.
@available(iOS 18.0, macOS 15.0, *)
@MainActor
public final class DHRev10AudioPlayer {
    private var loopPlayers: [String: AVAudioPlayer] = [:]
    private var oneShotPlayers: [AVAudioPlayer] = []

    public init() {}

    /// Starts/stops/retunes the three looping engine stems from KingmakerAudioMixState. Volume
    /// near zero pauses the stem instead of playing silently, so audio.exhaustVolume == 0 (engine
    /// off) doesn't leave three decoders running for nothing.
    public func updateEngineMix(_ mix: KingmakerAudioMixState) {
        apply(bindingID: "engine.exhaust", volume: mix.exhaustVolume, rate: mix.playbackRate)
        apply(bindingID: "engine.valvetrain", volume: mix.valvetrainVolume, rate: mix.playbackRate)
        apply(bindingID: "engine.supercharger", volume: mix.superchargerVolume, rate: mix.playbackRate)
    }

    /// Plays any cue that's newly active in `audio` (one-shot, not looped), then clears the
    /// state's activeCues -- "drain" in the sense of consuming the queued triggers, mirroring how
    /// DHRev10AudioState.trigger/clear already model this as a small event queue.
    public func drain(_ audio: inout DHRev10AudioState) {
        for cue in audio.activeCues {
            playOneShot(bindingID: Self.cueBindings[cue])
        }
        audio.activeCues.removeAll()
        oneShotPlayers.removeAll { !$0.isPlaying }
    }

    public func stopAll() {
        for player in loopPlayers.values { player.stop() }
        for player in oneShotPlayers { player.stop() }
        loopPlayers.removeAll()
        oneShotPlayers.removeAll()
    }

    private func apply(bindingID: String, volume: Double, rate: Double) {
        guard let url = Self.resolvedURL(bindingID) else { return }
        let player = loopPlayers[bindingID] ?? makeLoopingPlayer(url: url, key: bindingID)
        player.volume = Float(max(0, min(1, volume)))
        player.enableRate = true
        player.rate = Float(max(0.5, min(2.0, rate)))
        if volume > 0.02, !player.isPlaying {
            player.play()
        } else if volume <= 0.02, player.isPlaying {
            player.pause()
        }
    }

    private func makeLoopingPlayer(url: URL, key: String) -> AVAudioPlayer {
        let player = (try? AVAudioPlayer(contentsOf: url)) ?? AVAudioPlayer()
        player.numberOfLoops = -1
        player.volume = 0
        player.prepareToPlay()
        loopPlayers[key] = player
        return player
    }

    private func playOneShot(bindingID: String?) {
        guard let bindingID, let url = Self.resolvedURL(bindingID),
              let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.prepareToPlay()
        player.play()
        oneShotPlayers.append(player)
    }

    private static func resolvedURL(_ bindingID: String) -> URL? {
        guard let binding = DHRev10AssetManifest.bindings.first(where: { $0.id == bindingID }) else { return nil }
        return DHRev10AssetResolver.url(for: binding)
    }

    /// Every DHRev10AudioCue in Rev10ProductionContracts.swift's requiredAudio list, plus
    /// engineKnock/lootCollect/hostileTelegraph/radioStatic, now resolves to a real synthesized
    /// stem (see Tools/BlenderAssetGen/build_audio.py). engineStart is deliberately unmapped here:
    /// it's driven by updateEngineMix's loop-volume ramp, not a one-shot cue.
    private static let cueBindings: [DHRev10AudioCue: String] = [
        .engineCrank: "cue.engineCrank",
        .engineKnock: "cue.engineKnock",
        .repair: "cue.repair",
        .lootOpen: "cue.lootOpen",
        .lootCollect: "cue.lootCollect",
        .hostileTelegraph: "cue.hostileTelegraph",
        .hostileAttack: "cue.hostileAttack",
        .paradiseNegotiation: "cue.paradiseNegotiation",
        .radioStatic: "radio.static",
        .radioConsequence: "radio.consequence",
    ]
}
#endif
