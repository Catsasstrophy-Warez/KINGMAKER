import Foundation

public struct KingmakerProfile: Codable, Equatable, Sendable {
    public var identity = "Blackridge XR-13 Kingmaker"
    public var componentCount = 254
    public var buildPath: KingmakerBuildPath
    public var fuelType = "gasoline"
    public var engineDisplacementL = 7.0
    public var transmissionGears = 7
    public var armorLevel: Int
    public var cargoCapacity: Double
    public var coolingCapacity: Double
    public var telemetryEnabled = true
    public var hazardousEnvironmentRating: Int
    public init(buildPath: KingmakerBuildPath) {
        self.buildPath = buildPath
        let spec = KingmakerVisualSpec(path: buildPath)
        armorLevel = spec.armorLevel
        cargoCapacity = Double(40 + spec.cargoLevel * 30)
        coolingCapacity = buildPath == .dragMonster ? 0.8 : (buildPath == .armoredPursuit ? 1.25 : 1.0)
        hazardousEnvironmentRating = [.highwayInterceptor, .wastelandEndurance, .armoredPursuit, .heavyHauler, .nomad].contains(buildPath) ? 2 : 0
    }
}
