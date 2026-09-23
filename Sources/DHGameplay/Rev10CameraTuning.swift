import Foundation

/// Camera transition tuning for entering/leaving garage, cabin, engine-bay, and driving modes.
/// Docs/ROADMAP_1_20.md item 9 lists this as unresolved: "State contracts exist; authored camera
/// tuning and device QA remain." This supplies the tuning half (FOV, transition duration, and an
/// easing curve per DHRev10InspectionMode/DHRev10PlayerMode) as pure, testable math -- device QA
/// (item 20) still needs a physical device and is out of scope here.
public enum DHRev10CameraEasing: String, Codable, Sendable {
    case linear, easeInOut, easeOutBack

    /// Maps normalized progress (0...1) through its eased equivalent.
    public func apply(_ t: Double) -> Double {
        let clamped = max(0, min(1, t))
        switch self {
        case .linear:
            return clamped
        case .easeInOut:
            return clamped < 0.5 ? 2 * clamped * clamped : 1 - pow(-2 * clamped + 2, 2) / 2
        case .easeOutBack:
            let c1 = 1.70158
            let c3 = c1 + 1
            let x = clamped - 1
            return 1 + c3 * x * x * x + c1 * x * x
        }
    }
}

public struct DHRev10CameraTransition: Equatable, Sendable {
    public let fieldOfViewDegrees: Double
    public let durationSeconds: Double
    public let easing: DHRev10CameraEasing
    public let distance: Double

    public init(fieldOfViewDegrees: Double, durationSeconds: Double, easing: DHRev10CameraEasing, distance: Double) {
        self.fieldOfViewDegrees = fieldOfViewDegrees
        self.durationSeconds = durationSeconds
        self.easing = easing
        self.distance = distance
    }

    /// Eased field-of-view/distance interpolation from a starting transition to this one, at
    /// normalized progress `t` (0...1).
    public func interpolated(from start: DHRev10CameraTransition, progress t: Double) -> (fieldOfViewDegrees: Double, distance: Double) {
        let eased = easing.apply(t)
        let fov = start.fieldOfViewDegrees + (fieldOfViewDegrees - start.fieldOfViewDegrees) * eased
        let dist = start.distance + (distance - start.distance) * eased
        return (fov, dist)
    }
}

public enum DHRev10CameraTuning {
    /// One transition profile per inspection mode, tuned so a closer, narrower-FOV shot backs a
    /// more focused inspection (dmm/cabin) and a wider, farther shot suits the world view.
    public static let inspectionTransitions: [DHRev10InspectionMode: DHRev10CameraTransition] = [
        .world: .init(fieldOfViewDegrees: 60, durationSeconds: 0.6, easing: .easeInOut, distance: 18),
        .kingmakerExterior: .init(fieldOfViewDegrees: 45, durationSeconds: 0.5, easing: .easeInOut, distance: 4.5),
        .engineBay: .init(fieldOfViewDegrees: 38, durationSeconds: 0.45, easing: .easeOutBack, distance: 1.6),
        .cabin: .init(fieldOfViewDegrees: 42, durationSeconds: 0.45, easing: .easeOutBack, distance: 1.2),
        .damage: .init(fieldOfViewDegrees: 35, durationSeconds: 0.4, easing: .easeInOut, distance: 1.4),
        .dmm: .init(fieldOfViewDegrees: 30, durationSeconds: 0.4, easing: .easeInOut, distance: 0.9),
    ]

    /// One transition profile per player mode, for the coarser onFoot/driving/combat/dialogue
    /// camera behavior (distinct from the finer per-inspection-mode tuning above).
    public static let playerModeTransitions: [DHRev10PlayerMode: DHRev10CameraTransition] = [
        .onFoot: .init(fieldOfViewDegrees: 65, durationSeconds: 0.5, easing: .easeInOut, distance: 6),
        .inspecting: .init(fieldOfViewDegrees: 42, durationSeconds: 0.45, easing: .easeOutBack, distance: 2),
        .repairing: .init(fieldOfViewDegrees: 38, durationSeconds: 0.4, easing: .easeOutBack, distance: 1.6),
        .driving: .init(fieldOfViewDegrees: 70, durationSeconds: 0.55, easing: .easeInOut, distance: 8),
        .combat: .init(fieldOfViewDegrees: 75, durationSeconds: 0.3, easing: .linear, distance: 10),
        .dialogue: .init(fieldOfViewDegrees: 40, durationSeconds: 0.5, easing: .easeInOut, distance: 2.2),
    ]

    /// Fallback used only if inspectionTransitions is ever edited to drop a case -- a literal
    /// value rather than re-indexing the dictionary with a force-unwrap, so a future edit that
    /// forgets a case degrades gracefully instead of crashing.
    private static let fallbackInspectionTransition = DHRev10CameraTransition(fieldOfViewDegrees: 60, durationSeconds: 0.6, easing: .easeInOut, distance: 18)
    private static let fallbackPlayerModeTransition = DHRev10CameraTransition(fieldOfViewDegrees: 65, durationSeconds: 0.5, easing: .easeInOut, distance: 6)

    public static func transition(for mode: DHRev10InspectionMode) -> DHRev10CameraTransition {
        inspectionTransitions[mode] ?? fallbackInspectionTransition
    }

    public static func transition(for mode: DHRev10PlayerMode) -> DHRev10CameraTransition {
        playerModeTransitions[mode] ?? fallbackPlayerModeTransition
    }
}
