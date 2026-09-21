import Foundation
public enum SaveMigrationError:Error { case unsupportedVersion(Int) }
public struct SaveEnvelope:Codable,Sendable,Equatable { public var schemaVersion:Int; public var payload:DeadHighwaySnapshot }
public enum SaveMigrator { public static let currentVersion=2; public static func migrate(_ snapshot:DeadHighwaySnapshot)->DeadHighwaySnapshot { snapshot }; public static func decode(_ data:Data)throws->DeadHighwaySnapshot { let d=JSONDecoder(); if let env=try? d.decode(SaveEnvelope.self,from:data){ guard env.schemaVersion<=currentVersion else{throw SaveMigrationError.unsupportedVersion(env.schemaVersion)}; return migrate(env.payload) }; return try d.decode(DeadHighwaySnapshot.self,from:data) } }
