import Foundation

/// Distinct, structured failure cases for save loading. Previously any parse failure fell
/// through to JSONDecoder's raw DecodingError with no way to tell "this save is corrupt" apart
/// from "this save is from a newer build than this one" apart from "this save is older than
/// anything this build still knows how to read" -- all three need very different UI treatment
/// (retry/report a bug vs. "update the app" vs. "this save can't be opened").
public enum SaveMigrationError: Error, Equatable {
    /// `schemaVersion` is higher than `SaveMigrator.currentVersion` -- this save was written by a
    /// newer build. The UI should say "update the app," not "corrupt save."
    case unsupportedVersion(Int)
    /// `schemaVersion` is lower than `SaveMigrator.minimumSupportedVersion` -- support for
    /// migrating saves this old has been dropped. Distinct from corrupt data: the bytes decoded
    /// fine, the version is just too old to carry forward.
    case versionTooOld(Int)
    /// The data didn't decode as either a SaveEnvelope or a bare DeadHighwaySnapshot at all --
    /// genuinely malformed/corrupt, not a version problem. Wraps the underlying decode error for
    /// debugging/bug-report purposes.
    case corruptData(underlying: Error)

    public static func == (lhs: SaveMigrationError, rhs: SaveMigrationError) -> Bool {
        switch (lhs, rhs) {
        case let (.unsupportedVersion(a), .unsupportedVersion(b)): return a == b
        case let (.versionTooOld(a), .versionTooOld(b)): return a == b
        case (.corruptData, .corruptData): return true
        default: return false
        }
    }
}

public struct SaveEnvelope: Codable, Sendable, Equatable { public var schemaVersion: Int; public var payload: DeadHighwaySnapshot }

public enum SaveMigrator {
    public static let currentVersion = 2
    /// Saves older than this can no longer be migrated forward. Distinct from `currentVersion`
    /// (the newest version this build writes) so there's a real, checkable floor instead of
    /// silently accepting any version number below currentVersion, including 0 or negative ones
    /// that were never valid.
    public static let minimumSupportedVersion = 1

    /// One migration step from `version` to `version + 1`, dispatched by a plain switch rather
    /// than a dictionary of closures (Swift 6 strict concurrency flags a `[Int: (T) -> T]` static
    /// as not provably Sendable; a switch sidesteps that with no behavior difference). Adding a
    /// real migration later (when a save's field shape actually changes) means adding one case
    /// here, not touching decode()'s control flow. There is deliberately no case yet for 1->2:
    /// nothing has actually changed shape between those versions in this codebase, so falling
    /// through to the identity transform (`default`) is correct today, not a placeholder
    /// pretending to migrate something that doesn't need it.
    private static func step(from version: Int, _ snapshot: DeadHighwaySnapshot) -> DeadHighwaySnapshot {
        switch version {
        default: return snapshot
        }
    }

    public static func migrate(_ snapshot: DeadHighwaySnapshot, fromVersion: Int) -> DeadHighwaySnapshot {
        var result = snapshot
        var version = fromVersion
        while version < currentVersion {
            result = step(from: version, result)
            version += 1
        }
        return result
    }

    public static func decode(_ data: Data) throws -> DeadHighwaySnapshot {
        let decoder = JSONDecoder()
        if let envelope = try? decoder.decode(SaveEnvelope.self, from: data) {
            guard envelope.schemaVersion <= currentVersion else {
                throw SaveMigrationError.unsupportedVersion(envelope.schemaVersion)
            }
            guard envelope.schemaVersion >= minimumSupportedVersion else {
                throw SaveMigrationError.versionTooOld(envelope.schemaVersion)
            }
            return migrate(envelope.payload, fromVersion: envelope.schemaVersion)
        }
        do {
            // Legacy un-versioned saves (written before SaveEnvelope existed) -- treated as
            // minimumSupportedVersion and run through the same migration path as any other.
            let bare = try decoder.decode(DeadHighwaySnapshot.self, from: data)
            return migrate(bare, fromVersion: minimumSupportedVersion)
        } catch {
            throw SaveMigrationError.corruptData(underlying: error)
        }
    }
}
