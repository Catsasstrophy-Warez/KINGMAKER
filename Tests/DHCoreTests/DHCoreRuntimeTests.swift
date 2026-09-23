import Foundation
import Testing
@testable import DHCore

@Test func simulationClockAdvancesTickByOne() {
    var clock = SimulationClock()
    clock.advance()
    clock.advance()
    #expect(clock.tick == 2)
}

@Test func fixedStepAccumulatorRunsWholeStepsAndKeepsRemainder() {
    var accumulator = FixedStepAccumulator(step: 0.1, maximumSteps: 8)
    var updates = 0
    let count = accumulator.advance(elapsed: 0.25) { _ in updates += 1 }
    #expect(count == 2)
    #expect(updates == 2)
    #expect(accumulator.accumulator > 0.04 && accumulator.accumulator < 0.06)
}

@Test func fixedStepAccumulatorClampsRunawayElapsedTime() {
    var accumulator = FixedStepAccumulator(step: 0.1, maximumSteps: 4)
    let count = accumulator.advance(elapsed: 10.0) { _ in }
    #expect(count == 4)
}

@Test func seededGeneratorIsDeterministicForTheSameSeed() {
    var a = SeededGenerator(seed: 42)
    var b = SeededGenerator(seed: 42)
    #expect(a.next() == b.next())
    #expect(a.next() == b.next())
}

@Test func seededGeneratorProducesStableEntityIDs() {
    var a = SeededGenerator(seed: 7)
    var b = SeededGenerator(seed: 7)
    #expect(a.nextEntityID() == b.nextEntityID())
}

@Test func deadHighwayRuntimeRecordsEventsWithAdvancingTick() async {
    let snapshot = DeadHighwaySnapshot(clock: SimulationClock(), playerID: EntityID(), heroVehicleID: EntityID())
    let runtime = DeadHighwayRuntime(snapshot: snapshot)
    await runtime.step()
    await runtime.record(kind: "test.event", detail: "hello")
    let current = await runtime.snapshot
    #expect(current.clock.tick == 1)
    #expect(current.events.count == 1)
    #expect(current.events[0].tick == 1)
    #expect(current.events[0].kind == "test.event")
}

@Test func saveMigratorDecodesLegacyBareSnapshotWithNoEnvelope() throws {
    // SaveMigrator.decode's fallback path: older saves before SaveEnvelope existed wrote a bare
    // DeadHighwaySnapshot with no {schemaVersion, payload} wrapper at all.
    let bareSnapshot = DeadHighwaySnapshot(clock: SimulationClock(), playerID: EntityID(), heroVehicleID: EntityID())
    let data = try JSONEncoder().encode(bareSnapshot)
    let decoded = try SaveMigrator.decode(data)
    #expect(decoded.playerID == bareSnapshot.playerID)
}

@Test func saveMigratorRejectsAnEnvelopeNewerThanCurrentVersion() {
    let futureEnvelope = SaveEnvelope(
        schemaVersion: SaveMigrator.currentVersion + 1,
        payload: DeadHighwaySnapshot(clock: SimulationClock(), playerID: EntityID(), heroVehicleID: EntityID())
    )
    let data = try! JSONEncoder().encode(futureEnvelope)
    #expect(throws: SaveMigrationError.unsupportedVersion(SaveMigrator.currentVersion + 1)) { try SaveMigrator.decode(data) }
}

@Test func saveMigratorRejectsAnEnvelopeOlderThanMinimumSupportedVersion() {
    let ancientEnvelope = SaveEnvelope(
        schemaVersion: SaveMigrator.minimumSupportedVersion - 1,
        payload: DeadHighwaySnapshot(clock: SimulationClock(), playerID: EntityID(), heroVehicleID: EntityID())
    )
    let data = try! JSONEncoder().encode(ancientEnvelope)
    #expect(throws: SaveMigrationError.versionTooOld(SaveMigrator.minimumSupportedVersion - 1)) { try SaveMigrator.decode(data) }
}

@Test func saveMigratorReportsGenuinelyMalformedDataAsCorruptNotAVersionProblem() {
    let garbage = Data("not json at all { [ }".utf8)
    #expect {
        try SaveMigrator.decode(garbage)
    } throws: { error in
        guard case .corruptData = error as? SaveMigrationError else { return false }
        return true
    }
}

@Test func saveMigratorMigrateIsIdentityWhenNoStepsAreRegisteredForTheGap() {
    // Nothing has actually changed shape between version 1 and currentVersion in this codebase
    // yet, so migrating from 1 up to currentVersion should be a pure identity transform.
    let snapshot = DeadHighwaySnapshot(clock: SimulationClock(), playerID: EntityID(), heroVehicleID: EntityID())
    let migrated = SaveMigrator.migrate(snapshot, fromVersion: SaveMigrator.minimumSupportedVersion)
    #expect(migrated == snapshot)
}

@Test func legacyBareSnapshotIsTreatedAsMinimumSupportedVersionNotRejected() throws {
    // A pre-SaveEnvelope save has no version at all; decode() should treat it as
    // minimumSupportedVersion and successfully migrate it forward, not reject it as too old.
    let bareSnapshot = DeadHighwaySnapshot(clock: SimulationClock(), playerID: EntityID(), heroVehicleID: EntityID())
    let data = try JSONEncoder().encode(bareSnapshot)
    #expect(throws: Never.self) { try SaveMigrator.decode(data) }
}

@Test func deadHighwayRuntimeEncodedSaveRoundTripsThroughDecodeSave() async throws {
    let snapshot = DeadHighwaySnapshot(clock: SimulationClock(), playerID: EntityID(), heroVehicleID: EntityID())
    let runtime = DeadHighwayRuntime(snapshot: snapshot)
    await runtime.record(kind: "roundtrip", detail: "check")
    let data = try await runtime.encodedSave()
    let decoded = try DeadHighwayRuntime.decodeSave(data)
    #expect(decoded.events.count == 1)
    #expect(decoded.events[0].kind == "roundtrip")
    #expect(decoded.schemaVersion == DeadHighwaySnapshot.schemaVersion)
}
