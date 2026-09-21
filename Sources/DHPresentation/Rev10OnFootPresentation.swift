import Foundation
import DHCore

public enum DHHumanoidAnimationState: String, Codable, Sendable { case idle, walk, run, crouch, interact, aim, fire, reload, hurt, downed, talk }

public struct DHHumanoidAnimationMachine: Codable, Equatable, Sendable {
    public private(set) var state: DHHumanoidAnimationState = .idle
    public private(set) var normalizedTime: Double = 0
    public init() {}
    public mutating func transition(to next: DHHumanoidAnimationState) { state = next; normalizedTime = 0 }
    public mutating func step(dt: Double) { normalizedTime = min(1, normalizedTime + max(0, dt) / (state == .fire || state == .interact ? 0.35 : 0.8)) }
}

public struct DHLootInteractionState: Codable, Equatable, Sendable {
    public var containerID: EntityID?
    public var prompt: String = "SEARCH"
    public var isOpen = false
    public var collectedItemIDs: Set<EntityID> = []
    public init() {}
    public mutating func focus(containerID: EntityID, label: String) { self.containerID = containerID; prompt = "SEARCH \(label.uppercased())"; isOpen = false }
    public mutating func open() -> Bool { guard containerID != nil else { return false }; isOpen = true; return true }
    public mutating func collect(_ itemID: EntityID) { guard isOpen else { return }; collectedItemIDs.insert(itemID) }
}

public enum DHVehicleEncounterPresentation: String, Codable, Sendable { case hidden, telegraph, pursuing, attacking, disabled, escaped }

public struct DHVehicleEncounterState: Codable, Equatable, Sendable {
    public var encounterID: String
    public var presentation: DHVehicleEncounterPresentation = .hidden
    public var distanceMeters: Double = 240
    public var hostileCount: Int = 0
    public var radioEventID: String?
    public init(encounterID: String, hostileCount: Int = 1) { self.encounterID = encounterID; self.hostileCount = hostileCount }
    public mutating func advance() {
        switch presentation { case .hidden: presentation = .telegraph; case .telegraph: presentation = .pursuing; case .pursuing: presentation = .attacking; default: break }
    }
    public mutating func resolve() { presentation = .disabled; radioEventID = "radio.\(encounterID).consequence" }
}
