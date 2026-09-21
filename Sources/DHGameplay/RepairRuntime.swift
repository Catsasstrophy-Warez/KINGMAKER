import Foundation
import DHVehicle

public enum DHRepairWorkState: String, Codable, Equatable, Sendable {
    case locked, available, inProgress, complete, failed
}

public struct DHRepairStep: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let system: KingmakerSystem
    public let requiredPartID: String
    public let requiredSkill: Int
    public var progress: Double = 0
    public var state: DHRepairWorkState = .available

    public init(id: String, system: KingmakerSystem, requiredPartID: String, requiredSkill: Int = 0) {
        self.id = id; self.system = system; self.requiredPartID = requiredPartID; self.requiredSkill = requiredSkill
    }
}

public struct DHRepairRuntime: Codable, Equatable, Sendable {
    public var steps: [DHRepairStep] = [
        .init(id: "cooling.radiator", system: .cooling, requiredPartID: "radiator.hose", requiredSkill: 1),
        .init(id: "fuel.pump", system: .fuel, requiredPartID: "fuel.pump", requiredSkill: 1),
        .init(id: "electrical.battery", system: .electrical, requiredPartID: "battery.12v", requiredSkill: 2),
        .init(id: "engine.unseize", system: .engine, requiredPartID: "engine.oil", requiredSkill: 3)
    ]
    public var availablePartIDs: Set<String> = ["radiator.hose", "fuel.pump", "battery.12v", "engine.oil"]

    public init() {}

    public mutating func work(on stepID: String, seconds: Double, skill: Int) -> Bool {
        guard let index = steps.firstIndex(where: { $0.id == stepID }) else { return false }
        guard availablePartIDs.contains(steps[index].requiredPartID), skill >= steps[index].requiredSkill else { steps[index].state = .locked; return false }
        steps[index].state = .inProgress
        steps[index].progress = min(1, steps[index].progress + max(0, seconds) / 4)
        if steps[index].progress >= 1 { steps[index].state = .complete }
        return true
    }

    public func apply(to vehicle: inout KingmakerState) {
        for step in steps where step.state == .complete {
            vehicle.components = vehicle.components.map { component in
                guard component.system == step.system else { return component }
                var repaired = component; repaired.condition = .serviceable; repaired.wear = min(repaired.wear, 0.15); return repaired
            }
        }
    }
}
