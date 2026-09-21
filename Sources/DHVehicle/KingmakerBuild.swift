import Foundation

public enum KingmakerBuildPath: String, Codable, CaseIterable, Sendable { case restored, roadRacer, highwayInterceptor, wastelandEndurance, dragMonster, armoredPursuit, hybrid, heavyHauler, highTechScavenger, nomad }
public struct KingmakerVisualSpec: Codable, Equatable, Sendable {
    public let path: KingmakerBuildPath
    public let armorLevel: Int
    public let aeroLevel: Int
    public let cargoLevel: Int
    public let tireProfile: String
    public let accent: String
    public init(path: KingmakerBuildPath) {
        self.path = path
        switch path {
        case .restored: armorLevel = 0; aeroLevel = 2; cargoLevel = 0; tireProfile = "road"; accent = "clean-black"
        case .roadRacer: armorLevel = 0; aeroLevel = 3; cargoLevel = 0; tireProfile = "track"; accent = "graphite"
        case .highwayInterceptor: armorLevel = 1; aeroLevel = 2; cargoLevel = 1; tireProfile = "pursuit"; accent = "patrol-amber"
        case .wastelandEndurance: armorLevel = 2; aeroLevel = 1; cargoLevel = 3; tireProfile = "all-terrain"; accent = "oxidized-red"
        case .dragMonster: armorLevel = 0; aeroLevel = 1; cargoLevel = 0; tireProfile = "drag"; accent = "primer-red"
        case .armoredPursuit: armorLevel = 3; aeroLevel = 0; cargoLevel = 2; tireProfile = "reinforced"; accent = "dark-steel"
        case .hybrid: armorLevel = 2; aeroLevel = 3; cargoLevel = 2; tireProfile = "adaptive"; accent = "mixed-salvage"
        case .heavyHauler: armorLevel = 2; aeroLevel = 0; cargoLevel = 4; tireProfile = "dually"; accent = "industrial-yellow"
        case .highTechScavenger: armorLevel = 1; aeroLevel = 4; cargoLevel = 1; tireProfile = "adaptive"; accent = "carbon-salvage"
        case .nomad: armorLevel = 2; aeroLevel = 0; cargoLevel = 4; tireProfile = "all-terrain"; accent = "canvas-olive"
        }
    }
}
