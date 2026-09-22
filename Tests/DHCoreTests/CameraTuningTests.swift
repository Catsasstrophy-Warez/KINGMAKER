import Foundation
import Testing
@testable import DHGameplay

@Test func everyInspectionModeHasATransitionProfile() {
    for mode in [DHRev10InspectionMode.world, .kingmakerExterior, .engineBay, .cabin, .damage, .dmm] {
        let transition = DHRev10CameraTuning.transition(for: mode)
        #expect(transition.fieldOfViewDegrees > 0)
        #expect(transition.durationSeconds > 0)
        #expect(transition.distance > 0)
    }
}

@Test func everyPlayerModeHasATransitionProfile() {
    for mode in [DHRev10PlayerMode.onFoot, .inspecting, .repairing, .driving, .combat, .dialogue] {
        let transition = DHRev10CameraTuning.transition(for: mode)
        #expect(transition.fieldOfViewDegrees > 0)
    }
}

@Test func closerInspectionModesHaveNarrowerFOVAndShorterDistance() {
    let world = DHRev10CameraTuning.transition(for: .world)
    let dmm = DHRev10CameraTuning.transition(for: .dmm)
    #expect(dmm.fieldOfViewDegrees < world.fieldOfViewDegrees)
    #expect(dmm.distance < world.distance)
}

@Test func linearEasingIsIdentity() {
    #expect(DHRev10CameraEasing.linear.apply(0.3) == 0.3)
}

@Test func easeInOutStartsAndEndsAtBoundaries() {
    let easing = DHRev10CameraEasing.easeInOut
    #expect(abs(easing.apply(0) - 0) < 0.0001)
    #expect(abs(easing.apply(1) - 1) < 0.0001)
}

@Test func interpolatedTransitionMovesFromStartToEndAcrossProgress() {
    let start = DHRev10CameraTuning.transition(for: .world)
    let end = DHRev10CameraTuning.transition(for: .dmm)
    let atStart = end.interpolated(from: start, progress: 0)
    let atEnd = end.interpolated(from: start, progress: 1)
    #expect(abs(atStart.fieldOfViewDegrees - start.fieldOfViewDegrees) < 0.01)
    #expect(abs(atEnd.fieldOfViewDegrees - end.fieldOfViewDegrees) < 0.01)
}
