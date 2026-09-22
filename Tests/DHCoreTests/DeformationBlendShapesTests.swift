import Foundation
import Testing
@testable import DHVehicle
@testable import DHPresentation

@Test func pristineVehicleProducesNoBlendShapeWeights() {
    let damage = BodyDamageState()
    #expect(DHRev10DeformationBlendShapes.weights(for: damage).isEmpty)
}

@Test func collisionZoneDamageProducesAMatchingNamedWeight() {
    var damage = BodyDamageState()
    damage.apply(zone: .frontLeft, energyJ: 450_000)
    let weights = DHRev10DeformationBlendShapes.weights(for: damage)
    #expect(weights["deform_frontLeft"] != nil)
    #expect(weights["deform_frontLeft"]! > 0)
    #expect(weights.count == 1)
}

@Test func weightsAreClampedToOne() {
    var damage = BodyDamageState()
    damage.apply(zone: .rearCenter, energyJ: 5_000_000)
    let weights = DHRev10DeformationBlendShapes.weights(for: damage)
    #expect(weights["deform_rearCenter"] == 1.0)
}

@Test func everyCollisionZoneHasAStableTargetName() {
    for zone in CollisionZone.allCases {
        #expect(DHRev10DeformationBlendShapes.targetName(for: zone) == "deform_\(zone.rawValue)")
    }
}
