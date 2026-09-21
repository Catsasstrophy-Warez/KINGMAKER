import Foundation

public enum DHAgentActivity: String, Sendable, Codable { case idle, work, eat, sleep, trade, patrol, travel, flee, fight }
public struct DHNPCScheduleBlock: Sendable, Codable, Equatable { public var startHour: Int; public var endHour: Int; public var activity: DHAgentActivity; public var locationID: String; public init(startHour:Int,endHour:Int,activity:DHAgentActivity,locationID:String){self.startHour=startHour;self.endHour=endHour;self.activity=activity;self.locationID=locationID} }
public struct DHAgentBrain: Sendable, Codable, Equatable {
    public var npcID: String
    public var activity: DHAgentActivity = .idle
    public var targetLocationID: String?
    public var alert: Double = 0
    public var schedule: [DHNPCScheduleBlock] = []
    public init(npcID:String, schedule:[DHNPCScheduleBlock] = []) { self.npcID=npcID; self.schedule=schedule }
    public mutating func tick(hour: Int, threat: Double) {
        alert = max(0, min(1, threat))
        if alert > 0.7 { activity = .flee; return }
        if let block = schedule.first(where: { $0.startHour <= hour && hour < $0.endHour }) { activity = block.activity; targetLocationID = block.locationID }
    }
}

public struct DHSimulationLODPolicy: Sendable, Codable, Equatable {
    public var fullRadius: Double = 35
    public var reducedRadius: Double = 150
    public init(fullRadius:Double=35,reducedRadius:Double=150){self.fullRadius=fullRadius;self.reducedRadius=reducedRadius}
    public func tier(distance: Double) -> Int { distance <= fullRadius ? 0 : (distance <= reducedRadius ? 1 : 2) }
}
