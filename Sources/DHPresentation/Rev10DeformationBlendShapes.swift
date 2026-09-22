import Foundation
import DHVehicle

/// Maps BodyDamageState.deformation's per-CollisionZone crumple weights (0...1) to named
/// blend-shape targets a production mesh would expose. Previously body-panel deformation was
/// state-only -- KingmakerTopology.swift's BodyDamageState.apply() accumulates a deformation
/// value per zone, but nothing translated that into a shape/mesh the presentation layer could
/// drive, and Docs/KINGMAKER_XR13_ASSET_PIPELINE.md's modeling requirements explicitly call for
/// "blend shapes for body-panel deformation rather than crash-time model swaps." This is the
/// stable naming/weight contract a RealityKit scene bridge applies to a mesh's blend-shape
/// targets (via ModelComponent / MeshResource shape targets) -- it does not touch RealityKit
/// itself so it stays testable in a headless target, and doesn't require the target mesh to
/// exist yet: the blockout USDZ has no authored blend shapes, matching the "not a claim of final
/// art" posture the rest of this pipeline uses.
public enum DHRev10DeformationBlendShapes {
    /// Stable blend-shape target names, one per CollisionZone, matching the naming a mesh author
    /// would use in Blender/Reality Composer Pro's shape-key list.
    public static func targetName(for zone: CollisionZone) -> String {
        "deform_\(zone.rawValue)"
    }

    /// The full set of (target name, weight) pairs for a given damage state, ready to apply to a
    /// mesh's blend-shape weights dictionary. Weights below `epsilon` are omitted so a pristine
    /// vehicle doesn't carry a dictionary of 10 zero-weight entries.
    public static func weights(for damage: BodyDamageState, epsilon: Double = 0.01) -> [String: Float] {
        var result: [String: Float] = [:]
        for (zone, amount) in damage.deformation where amount > epsilon {
            result[targetName(for: zone)] = Float(max(0, min(1, amount)))
        }
        return result
    }
}
