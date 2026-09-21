import Foundation
import DHCore

public enum DHRev10InteractionKind: String, Codable, Sendable { case inspect, diagnose, repair, search, enter, trade, recruit, drive }
public struct DHRev10InteractionHotspot: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let stableEntityID: String
    public let kind: DHRev10InteractionKind
    public let prompt: String
    public init(id: String, stableEntityID: String, kind: DHRev10InteractionKind, prompt: String) { self.id = id; self.stableEntityID = stableEntityID; self.kind = kind; self.prompt = prompt }
}
public struct DHRev10InteractionPresentation: Codable, Equatable, Sendable {
    public var focused: DHRev10InteractionHotspot?
    public var diagnosisText = "NO DIAGNOSIS"
    public var repairProgress = 0.0
    public var radioText = "NO SIGNAL"
    public init() {}
    public mutating func focus(_ hotspot: DHRev10InteractionHotspot) { focused = hotspot }
    public mutating func diagnose(_ text: String) { diagnosisText = text }
    public mutating func repairStep(dt: Double) { repairProgress = min(1, repairProgress + max(0, dt) / 2.0) }
    public mutating func hearRadio(_ text: String) { radioText = text }
}

public enum DHRev10InteractionCatalog {
    public static let garage: [DHRev10InteractionHotspot] = [
        .init(id: "inspect.kingmaker", stableEntityID: "kingmaker.chassis", kind: .inspect, prompt: "INSPECT KINGMAKER"),
        .init(id: "diagnose.kingmaker", stableEntityID: "kingmaker.engineBay", kind: .diagnose, prompt: "DIAGNOSE VEHICLE"),
        .init(id: "repair.kingmaker", stableEntityID: "kingmaker.engineBay", kind: .repair, prompt: "REPAIR KINGMAKER"),
        .init(id: "drive.kingmaker", stableEntityID: "kingmaker", kind: .drive, prompt: "START AND DRIVE")
    ]
}
