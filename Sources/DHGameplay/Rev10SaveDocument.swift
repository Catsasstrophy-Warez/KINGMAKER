import Foundation

public enum DHRev10SaveError: Error, Equatable { case unsupportedVersion(Int) }

public struct DHRev10SaveDocument: Codable, Sendable, Equatable {
    public static let currentVersion = 1
    public let schemaVersion: Int
    public var slice: DHRev10VerticalSlice

    public init(slice: DHRev10VerticalSlice, schemaVersion: Int = Self.currentVersion) {
        self.schemaVersion = schemaVersion
        self.slice = slice
    }

    public func encoded() throws -> Data { try JSONEncoder().encode(self) }

    public static func decoded(_ data: Data) throws -> DHRev10VerticalSlice {
        let decoder = JSONDecoder()
        if let document = try? decoder.decode(Self.self, from: data) {
            guard document.schemaVersion <= currentVersion else { throw DHRev10SaveError.unsupportedVersion(document.schemaVersion) }
            return document.slice
        }
        // Rev10 originally wrote the slice directly. Keep old local saves readable.
        return try decoder.decode(DHRev10VerticalSlice.self, from: data)
    }
}
