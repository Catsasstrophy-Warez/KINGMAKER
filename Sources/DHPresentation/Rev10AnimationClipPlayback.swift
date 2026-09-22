import Foundation

/// Decodes and time-samples the JSON keyframe clips built by
/// Tools/BlenderAssetGen/build_data_assets.py (player.interact / kingmaker.start bindings in
/// Rev10AssetManifest.swift). Those clips previously only had to resolve as a file
/// (DHRev10AssetResolver.url); nothing actually read their keyframe content. This makes the
/// content itself usable -- decode once, then sample a bone/axis rotation at any point in the
/// clip's timeline via linear interpolation -- so a RealityKit scene bridge can drive real entity
/// rotations from it. It does not attach to a live RealityKit entity graph itself (there is no
/// scene graph in this headless package target to attach to); that wiring belongs in
/// Rev10RealityKitScene.swift, which owns entity lookup.
public struct DHRev10AnimationTrack: Codable, Equatable, Sendable {
    public let bone: String
    public let axis: String
    public let keyframes: [Double]
}

public struct DHRev10AnimationClip: Codable, Equatable, Sendable {
    public let name: String
    public let fps: Double
    public let durationSeconds: Double
    public let frameCount: Int
    public let tracks: [DHRev10AnimationTrack]

    public static func decode(from url: URL) throws -> DHRev10AnimationClip {
        try JSONDecoder().decode(DHRev10AnimationClip.self, from: Data(contentsOf: url))
    }

    /// Linear-interpolated sample (in degrees, matching the source data) of `bone`/`axis` at
    /// `time` seconds, looping the clip if `time` exceeds its duration.
    public func sample(bone: String, axis: String, at time: Double) -> Double? {
        guard let track = tracks.first(where: { $0.bone == bone && $0.axis == axis }), track.keyframes.count > 1 else { return nil }
        let loopedTime = durationSeconds > 0 ? time.truncatingRemainder(dividingBy: durationSeconds) : 0
        let progress = max(0, min(1, loopedTime / durationSeconds))
        let frameFloat = progress * Double(frameCount)
        let lowerIndex = min(Int(frameFloat), track.keyframes.count - 1)
        let upperIndex = min(lowerIndex + 1, track.keyframes.count - 1)
        let blend = frameFloat - Double(lowerIndex)
        let lower = track.keyframes[lowerIndex]
        let upper = track.keyframes[upperIndex]
        return lower + (upper - lower) * blend
    }

    /// All (bone, axis) pairs sampled at `time`, keyed by "bone.axis".
    public func sampleAll(at time: Double) -> [String: Double] {
        var result: [String: Double] = [:]
        for track in tracks {
            if let value = sample(bone: track.bone, axis: track.axis, at: time) {
                result["\(track.bone).\(track.axis)"] = value
            }
        }
        return result
    }
}

/// Loads and caches the two animation-clip bindings by manifest id ("player.interact",
/// "kingmaker.start") so callers don't re-parse the JSON file on every frame.
public final class DHRev10AnimationClipLibrary {
    private var cache: [String: DHRev10AnimationClip] = [:]

    public init() {}

    public func clip(forBindingID id: String) -> DHRev10AnimationClip? {
        if let cached = cache[id] { return cached }
        guard let binding = DHRev10AssetManifest.bindings.first(where: { $0.id == id }),
              let url = DHRev10AssetResolver.url(for: binding),
              let clip = try? DHRev10AnimationClip.decode(from: url) else { return nil }
        cache[id] = clip
        return clip
    }
}
