import Foundation
public typealias EntityID = UUID
public struct SimulationClock: Codable, Sendable, Equatable { public var tick: UInt64 = 0; public var fixedDelta: Double = 1.0/60.0; public mutating func advance(){ tick += 1 } }
public struct SeededGenerator: RandomNumberGenerator, Codable, Sendable, Equatable { public var state: UInt64; public init(seed: UInt64){ state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }; public mutating func next() -> UInt64 { state &+= 0x9E3779B97F4A7C15; var z=state; z=(z^(z>>30))&*0xBF58476D1CE4E5B9; z=(z^(z>>27))&*0x94D049BB133111EB; return z^(z>>31) } }
public extension SeededGenerator {
    mutating func nextEntityID() -> EntityID {
        let high = next(), low = next()
        let text = String(format: "%08x-%04x-%04x-%04x-%012llx", UInt32(truncatingIfNeeded: high), UInt16(truncatingIfNeeded: high >> 32), UInt16(truncatingIfNeeded: high >> 48), UInt16(truncatingIfNeeded: low), low & 0x0000_ffff_ffff_ffff)
        return EntityID(uuidString: text)!
    }
}
public struct WorldEvent: Codable, Sendable, Equatable, Identifiable { public let id: EntityID; public let tick: UInt64; public let kind: String; public let subject: EntityID?; public let detail: String; public init(tick:UInt64,kind:String,subject:EntityID?=nil,detail:String){id=UUID();self.tick=tick;self.kind=kind;self.subject=subject;self.detail=detail} }
public struct DeadHighwaySnapshot: Codable, Sendable, Equatable { public static let schemaVersion=1; public var schemaVersion:Int=Self.schemaVersion; public var clock: SimulationClock; public var playerID: EntityID; public var heroVehicleID: EntityID; public var rng:SeededGenerator = .init(seed: 0xD34D_41A7); public var events:[WorldEvent]=[] }
public actor DeadHighwayRuntime { public private(set) var snapshot: DeadHighwaySnapshot; public init(snapshot: DeadHighwaySnapshot){self.snapshot=snapshot}; public func step(){snapshot.clock.advance()}; public func record(kind:String,subject:EntityID?=nil,detail:String){snapshot.events.append(.init(tick:snapshot.clock.tick,kind:kind,subject:subject,detail:detail))}; public func encodedSave() throws -> Data { try JSONEncoder().encode(SaveEnvelope(schemaVersion: snapshot.schemaVersion, payload: snapshot)) }; public static func decodeSave(_ data:Data) throws -> DeadHighwaySnapshot { try SaveMigrator.decode(data) } }
