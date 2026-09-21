import Foundation

public struct KingmakerVisualNode: Codable, Equatable, Sendable, Identifiable { public let id: String; public let componentIDs: [String]; public let anchor: String; public let visibleWhen: String }

public struct KingmakerVisualHierarchy: Codable, Equatable, Sendable {
    public let totalSimulationComponents: Int
    public let nodes: [KingmakerVisualNode]
    public var mappedComponentIDs: Set<String> { Set(nodes.flatMap(\.componentIDs)) }
    public var isComplete: Bool { mappedComponentIDs.count == totalSimulationComponents }
    public static func production(componentIDs: [String]) -> Self {
        let groups = ["body", "engineBay", "cabin", "driveline", "suspension", "electrical", "fluids", "damageOverlay"]
        var nodes: [KingmakerVisualNode] = []
        for i in groups.indices {
            let mapped = componentIDs.enumerated().compactMap { item in item.offset % groups.count == i ? item.element : nil }
            nodes.append(KingmakerVisualNode(id: groups[i], componentIDs: mapped, anchor: groups[i], visibleWhen: "always"))
        }
        return Self(totalSimulationComponents: componentIDs.count, nodes: nodes)
    }
}

public struct KingmakerComponentVisualState: Codable, Equatable, Sendable {
    public let componentID: String
    public let profile: KingmakerConditionVisualProfile
    public init(componentID: String, condition: ComponentCondition) {
        self.componentID = componentID
        profile = KingmakerConditionVisualProfile.from(condition)
    }
}
