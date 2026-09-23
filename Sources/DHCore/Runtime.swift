import Foundation
public typealias EntityID = UUID
public struct SimulationClock: Codable, Sendable, Equatable { public var tick: UInt64 = 0; public var fixedDelta: Double = 1.0/60.0; public mutating func advance(){ tick += 1 } }
public struct FixedStepAccumulator: Codable, Sendable, Equatable {
    public var accumulator: Double = 0
    public let step: Double
    public let maximumSteps: Int
    public init(step: Double = 1.0 / 60.0, maximumSteps: Int = 8) { self.step = max(0.0001, step); self.maximumSteps = max(1, maximumSteps) }
    @discardableResult public mutating func advance(elapsed: Double) -> Int { advance(elapsed: elapsed) { _ in } }
    @discardableResult public mutating func advance(elapsed: Double, _ update: (Double) -> Void) -> Int {
        accumulator += max(0, min(elapsed, step * Double(maximumSteps)))
        var count = 0
        while accumulator >= step && count < maximumSteps { update(step); accumulator -= step; count += 1 }
        return count
    }
}
public struct SeededGenerator: RandomNumberGenerator, Codable, Sendable, Equatable { public var state: UInt64; public init(seed: UInt64){ state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }; public mutating func next() -> UInt64 { state &+= 0x9E3779B97F4A7C15; var z=state; z=(z^(z>>30))&*0xBF58476D1CE4E5B9; z=(z^(z>>27))&*0x94D049BB133111EB; return z^(z>>31) } }
public extension SeededGenerator {
    /// Builds a UUID directly from 16 raw bytes (two consecutive generator draws) via
    /// `UUID(uuid:)` instead of formatting a hex string and re-parsing it with
    /// `UUID(uuidString:)!`. The old force-unwrap was actually safe in practice (the format
    /// string always produced a well-formed 8-4-4-4-12 hex layout), but going through raw bytes
    /// removes the possibility entirely rather than relying on that being true forever, and is
    /// simpler than it looks: no format string, no re-parse, same 128 bits of entropy.
    mutating func nextEntityID() -> EntityID {
        let high = next(), low = next()
        func bytes(_ value: UInt64) -> (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) {
            let big = value.bigEndian
            return (
                UInt8(truncatingIfNeeded: big), UInt8(truncatingIfNeeded: big >> 8),
                UInt8(truncatingIfNeeded: big >> 16), UInt8(truncatingIfNeeded: big >> 24),
                UInt8(truncatingIfNeeded: big >> 32), UInt8(truncatingIfNeeded: big >> 40),
                UInt8(truncatingIfNeeded: big >> 48), UInt8(truncatingIfNeeded: big >> 56)
            )
        }
        let h = bytes(high), l = bytes(low)
        return EntityID(uuid: (h.0, h.1, h.2, h.3, h.4, h.5, h.6, h.7, l.0, l.1, l.2, l.3, l.4, l.5, l.6, l.7))
    }
}
public struct WorldEvent: Codable, Sendable, Equatable, Identifiable { public let id: EntityID; public let tick: UInt64; public let kind: String; public let subject: EntityID?; public let detail: String; public init(id: EntityID = UUID(), tick:UInt64,kind:String,subject:EntityID?=nil,detail:String){self.id=id;self.tick=tick;self.kind=kind;self.subject=subject;self.detail=detail} }
public struct DeadHighwaySnapshot: Codable, Sendable, Equatable { public static let schemaVersion=1; public var schemaVersion:Int=Self.schemaVersion; public var clock: SimulationClock; public var playerID: EntityID; public var heroVehicleID: EntityID; public var rng:SeededGenerator = .init(seed: 0xD34D_41A7); public var events:[WorldEvent]=[] }
public actor DeadHighwayRuntime { public private(set) var snapshot: DeadHighwaySnapshot; public init(snapshot: DeadHighwaySnapshot){self.snapshot=snapshot}; public func step(){snapshot.clock.advance()}; public func record(kind:String,subject:EntityID?=nil,detail:String){var generator=snapshot.rng; let id=generator.nextEntityID(); snapshot.rng=generator; snapshot.events.append(.init(id:id,tick:snapshot.clock.tick,kind:kind,subject:subject,detail:detail))}; public func encodedSave() throws -> Data { try JSONEncoder().encode(SaveEnvelope(schemaVersion: snapshot.schemaVersion, payload: snapshot)) }; public static func decodeSave(_ data:Data) throws -> DeadHighwaySnapshot { try SaveMigrator.decode(data) } }
