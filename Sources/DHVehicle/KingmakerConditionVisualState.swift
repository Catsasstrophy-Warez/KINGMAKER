import Foundation

public enum KingmakerConditionVisualState: String, Codable, Sendable { case damaged, rusted, broken, repaired }
public struct KingmakerConditionVisualProfile: Codable, Equatable, Sendable {
    public let state: KingmakerConditionVisualState
    public let rustAmount: Double
    public let deformationAmount: Double
    public let missingPartVisibility: Double
    public let repairable: Bool
    public init(state: KingmakerConditionVisualState) {
        self.state = state
        switch state {
        case .damaged: rustAmount = 0.15; deformationAmount = 0.55; missingPartVisibility = 0.9; repairable = true
        case .rusted: rustAmount = 1.0; deformationAmount = 0.2; missingPartVisibility = 0.75; repairable = true
        case .broken: rustAmount = 0.35; deformationAmount = 0.9; missingPartVisibility = 0.25; repairable = false
        case .repaired: rustAmount = 0.08; deformationAmount = 0.08; missingPartVisibility = 1.0; repairable = true
        }
    }
    public static func from(_ condition: ComponentCondition) -> Self {
        switch condition { case .missing, .failed, .seized: return .init(state: .broken); case .poor: return .init(state: .damaged); case .serviceable, .good: return .init(state: .repaired); case .restored: return .init(state: .repaired) }
    }
}
