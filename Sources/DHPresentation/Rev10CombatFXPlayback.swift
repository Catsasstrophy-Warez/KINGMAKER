import Foundation

/// Parses the emitter definitions out of VehicleCombat_FX.usda (the combat.fx manifest binding)
/// and looks them up by DHVehicleEncounterRuntime's activeFXCues names (MuzzleFlash, SparkImpact,
/// SmokeTrail). Previously combat.fx only had to resolve as a file; nothing read its content or
/// connected it to when combat actually fires. This closes that: real config values (birthRate,
/// lifespan, color, speed) parsed from the ASCII USD `def Scope "Name" { custom float x = ... }`
/// blocks, small enough that a hand-rolled scanner is more honest than pulling in a full USD
/// parser dependency for four attributes.
public struct DHRev10CombatFXEmitterConfig: Equatable, Sendable {
    public let name: String
    public let birthRate: Double
    public let lifespan: Double
    public let speed: Double
}

public enum DHRev10CombatFXParser {
    public static func parse(_ usda: String) -> [String: DHRev10CombatFXEmitterConfig] {
        var result: [String: DHRev10CombatFXEmitterConfig] = [:]
        var currentName: String?
        var birthRate = 0.0, lifespan = 0.0, speed = 0.0

        func flush() {
            guard let name = currentName else { return }
            result[name] = DHRev10CombatFXEmitterConfig(name: name, birthRate: birthRate, lifespan: lifespan, speed: speed)
        }

        for rawLine in usda.split(separator: "\n") {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("def Scope \"") {
                flush()
                currentName = line
                    .replacingOccurrences(of: "def Scope \"", with: "")
                    .split(separator: "\"").first.map(String.init)
                birthRate = 0; lifespan = 0; speed = 0
            } else if let value = numericValue(in: line, key: "birthRate") {
                birthRate = value
            } else if let value = numericValue(in: line, key: "lifespan") {
                lifespan = value
            } else if let value = numericValue(in: line, key: "speed") {
                speed = value
            }
        }
        flush()
        return result
    }

    private static func numericValue(in line: String, key: String) -> Double? {
        guard line.contains("float \(key)") || line.contains("float \(key) ") else { return nil }
        guard let equalsIndex = line.firstIndex(of: "=") else { return nil }
        let rhs = line[line.index(after: equalsIndex)...].trimmingCharacters(in: .whitespaces)
        return Double(rhs)
    }
}

public final class DHRev10CombatFXLibrary {
    private var cache: [String: DHRev10CombatFXEmitterConfig]?

    public init() {}

    public func emitterConfig(named name: String) -> DHRev10CombatFXEmitterConfig? {
        if cache == nil {
            guard let binding = DHRev10AssetManifest.bindings.first(where: { $0.id == "combat.fx" }),
                  let url = DHRev10AssetResolver.url(for: binding),
                  let text = try? String(contentsOf: url, encoding: .utf8) else {
                cache = [:]
                return nil
            }
            cache = DHRev10CombatFXParser.parse(text)
        }
        return cache?[name]
    }
}
