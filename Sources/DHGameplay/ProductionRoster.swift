import Foundation
import DHCore
import DHCharacter
import DHWorld
import DHNPC
import DHVehicle
import DHFleet

// Named production content, not just abstract archetypes. DHProductionContentRegistry (DHWorld)
// lists a vehicle ARCHETYPE catalog ("Highway Interceptor", fuel type, component profile) but no
// actual world-populating instances; DHNPCPopulation is a container with no seeded residents.
// This is the "production NPC/vehicle roster" called out as unbuilt in the production-content
// handoff doc: a starting set of named, placed characters and vehicles the world can actually
// contain, rather than only data models capable of holding them.
//
// Deliberately data-only (stats + placement + narrative-relevant fields), not visual content --
// meshes/rigs for these characters are a separate, much larger effort (see the handoff doc).

public enum DHProductionNPCRoster {
    /// Stable IDs so save data and dialogue/quest hooks can reference a specific named NPC.
    public static let entries: [(id: String, name: String, occupation: Occupation, home: BlackridgeSite, faction: Faction?)] = [
        (id: "npc.mara-voss", name: "Mara Voss", occupation: .mechanic, home: .kingmakerGarage, faction: nil),
        (id: "npc.desmond-cole", name: "Desmond Cole", occupation: .trader, home: .paradise, faction: .homesteads),
        (id: "npc.rusty-hale", name: "Rusty Hale", occupation: .fuelDealer, home: .fuelDepot, faction: .refineryHouses),
        (id: "npc.calder-briggs", name: "Calder Briggs", occupation: .bountyHunter, home: .interstate, faction: .highwayPatrol),
        (id: "npc.ines-okafor", name: "Ines Okafor", occupation: .farmer, home: .farms, faction: .homesteads),
        (id: "npc.judah-price", name: "Judah Price", occupation: .mercenary, home: .scrapyard, faction: .motorTribes),
        (id: "npc.dr-halloway", name: "Dr. Halloway", occupation: .doctor, home: .paradise, faction: nil),
        (id: "npc.vince-tarrant", name: "Vince Tarrant", occupation: .gambler, home: .truckStop, faction: nil),
        (id: "npc.opal-reyes", name: "Opal Reyes", occupation: .refugee, home: .ruinedTown, faction: nil),
        (id: "npc.cutter-dolan", name: "Cutter Dolan", occupation: .thief, home: .ruinedTown, faction: .childrenOfBurn),
        (id: "npc.sable-monroe", name: "Sable Monroe", occupation: .courier, home: .interstate, faction: nil),
        (id: "npc.grady-fenn", name: "Grady Fenn", occupation: .guard, home: .substation, faction: .combine),
        (id: "npc.piper-lund", name: "Piper Lund", occupation: .scavenger, home: .scrapyard, faction: nil),
        (id: "npc.otis-marsh", name: "Otis Marsh", occupation: .railWorker, home: .railYard, faction: .railUnion),
        (id: "npc.wren-castillo", name: "Wren Castillo", occupation: .mechanic, home: .paradise, faction: .homesteads),
        (id: "npc.abel-northrup", name: "Abel Northrup", occupation: .trader, home: .quarry, faction: .combine),
        (id: "npc.dahlia-frost", name: "Dahlia Frost", occupation: .doctor, home: .mineComplex, faction: nil),
        (id: "npc.roscoe-vane", name: "Roscoe Vane", occupation: .bountyHunter, home: .forestRoads, faction: .restorationists),
        (id: "npc.june-pemberton", name: "June Pemberton", occupation: .farmer, home: .farms, faction: .homesteads),
        (id: "npc.leland-cross", name: "Leland Cross", occupation: .mercenary, home: .truckStop, faction: .motorTribes),
    ]

    public static func makePopulation() -> NPCPopulation {
        var population = NPCPopulation()
        for entry in entries {
            var npc = NPCState(id: EntityID(uuidString: stableID(entry.id)) ?? UUID(), name: entry.name, occupation: entry.occupation, home: entry.home, faction: entry.faction)
            npc.needs[.income] = 0.2
            population.add(npc)
        }
        return population
    }

    /// Deterministic UUID from a stable string key, so the same roster entry always gets the same
    /// EntityID across runs/saves instead of a fresh random UUID every time the roster is built.
    static func stableID(_ key: String) -> String {
        var hasher = Hasher()
        hasher.combine(key)
        let hash = UInt64(bitPattern: Int64(hasher.finalize()))
        return String(format: "00000000-0000-4000-8000-%012x", hash & 0xFFFFFFFFFFFF)
    }

    /// A [0, 1) value deterministically derived from `key`, stable across process launches --
    /// unlike Swift's Hasher (used by stableID above for EntityID generation), which reseeds
    /// randomly per process, so it can't back a "looks the same every time you open the app"
    /// guarantee. Uses FNV-1a, a small, well-known, genuinely deterministic string hash.
    static func unitHash(_ key: String) -> Double {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in key.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return Double(hash & 0xFFFFFFFF) / Double(0xFFFFFFFF)
    }

    /// A default daily schedule per occupation -- work hours at home, sleep, and an eat block --
    /// so named roster NPCs aren't just static home/faction data. DHAgentBrain.tick(hour:threat:)
    /// already reads a schedule; roster entries previously never had one, so no roster NPC ever
    /// changed activity across a day.
    public static func defaultSchedule(for occupation: Occupation, home: BlackridgeSite) -> [DHNPCScheduleBlock] {
        let homeID = home.rawValue
        let workActivity: DHAgentActivity
        switch occupation {
        case .mechanic, .fuelDealer, .railWorker: workActivity = .work
        case .trader, .gambler: workActivity = .trade
        case .bountyHunter, .guard, .mercenary: workActivity = .patrol
        case .farmer: workActivity = .work
        case .doctor: workActivity = .work
        case .courier: workActivity = .travel
        case .scavenger, .thief: workActivity = .work
        case .refugee, .sexWorker: workActivity = .idle
        }
        return [
            .init(startHour: 0, endHour: 6, activity: .sleep, locationID: homeID),
            .init(startHour: 6, endHour: 8, activity: .eat, locationID: homeID),
            .init(startHour: 8, endHour: 18, activity: workActivity, locationID: homeID),
            .init(startHour: 18, endHour: 20, activity: .eat, locationID: homeID),
            .init(startHour: 20, endHour: 24, activity: .idle, locationID: homeID),
        ]
    }

    /// One DHAgentBrain per roster entry, pre-loaded with its default schedule and keyed by the
    /// roster's stable string ID (not the derived EntityID -- matches how the coordinator's
    /// spawnedNPCIDs tracks roster membership by string id).
    public static func makeBrains() -> [String: DHAgentBrain] {
        var brains: [String: DHAgentBrain] = [:]
        for entry in entries {
            brains[entry.id] = DHAgentBrain(npcID: entry.id, schedule: defaultSchedule(for: entry.occupation, home: entry.home))
        }
        return brains
    }

    /// A minimal occupation-flavored dialogue stub: every named NPC can at least be greeted and
    /// asked about their trade, rather than only existing as home/faction data with no line of
    /// dialogue attached at all.
    public static func defaultDialogue(for entry: (id: String, name: String, occupation: Occupation, home: BlackridgeSite, faction: Faction?)) -> [DialogueOption] {
        [
            .init(text: "Hey, \(entry.name).", intent: .greet, difficulty: 0),
            .init(text: occupationLine(entry.occupation), intent: .trade, difficulty: 1),
            .init(text: "What's the word around here?", intent: .rumor, difficulty: 0),
        ]
    }

    private static func occupationLine(_ occupation: Occupation) -> String {
        switch occupation {
        case .mechanic: return "Got parts, or need parts?"
        case .trader: return "Let's talk trade."
        case .fuelDealer: return "Fuel's not cheap out here."
        case .bountyHunter: return "You got a name for me, or a price on yours?"
        case .farmer: return "Crops are thin this season."
        case .sexWorker: return "Looking for company?"
        case .mercenary: return "Work's work. What's the job?"
        case .doctor: return "Sit down before you bleed on my floor."
        case .gambler: return "Care to make it interesting?"
        case .refugee: return "Just trying to get by."
        case .thief: return "Didn't see anything. Didn't take anything."
        case .courier: return "Got a package, got a price."
        case .guard: return "Move along, or state your business."
        case .scavenger: return "Found some things. Might sell 'em."
        case .railWorker: return "Tracks don't fix themselves."
        }
    }

    /// A skin tone and occupation-flavored cloth color for a roster entry, meant to be applied as
    /// a material tint on the single shared mannequin rig (Mannequin_WalkCycle.usdz/
    /// Mannequin_Idle.usdz) rather than requiring a distinct mesh per NPC -- one rig with real
    /// per-individual material variation, matching what Docs/ASSET_COMMISSIONING_BRIEF.md's
    /// Characters section asks for as the v1 bar. Both components are deterministic (from the
    /// entry's stable string id, not its derived EntityID) so the same NPC always looks the same
    /// across app launches. Skin tone is drawn from a small human-range palette; cloth color
    /// starts from an occupation-appropriate base (a mechanic isn't dressed like a trader) and is
    /// individually jittered so two NPCs sharing an occupation don't render identically.
    public static func appearance(for entry: (id: String, name: String, occupation: Occupation, home: BlackridgeSite, faction: Faction?)) -> (skinTone: (r: Double, g: Double, b: Double), clothColor: (r: Double, g: Double, b: Double)) {
        let individualHash = unitHash(entry.id)
        let skinPalette: [(Double, Double, Double)] = [
            (0.87, 0.72, 0.60), (0.76, 0.58, 0.45), (0.62, 0.45, 0.33),
            (0.48, 0.33, 0.22), (0.36, 0.24, 0.16), (0.93, 0.80, 0.69),
        ]
        let skinIndex = Int(individualHash * Double(skinPalette.count)) % skinPalette.count
        let skinTone = skinPalette[skinIndex]

        let clothBase: (Double, Double, Double)
        switch entry.occupation {
        case .mechanic, .scavenger, .railWorker: clothBase = (0.16, 0.17, 0.20)   // oil-stained navy/grey coveralls
        case .trader, .courier, .gambler: clothBase = (0.42, 0.28, 0.14)          // warm brown trade coat
        case .fuelDealer: clothBase = (0.30, 0.20, 0.10)
        case .bountyHunter, .mercenary, .guard: clothBase = (0.22, 0.20, 0.15)     // dusty tactical drab
        case .farmer: clothBase = (0.24, 0.30, 0.16)                              // earthy green
        case .sexWorker: clothBase = (0.45, 0.12, 0.22)
        case .doctor: clothBase = (0.75, 0.75, 0.72)                              // clinical off-white
        case .refugee, .thief: clothBase = (0.30, 0.28, 0.25)
        }
        // per-individual jitter so occupation-mates aren't identical -- derived from a second,
        // independent hash so it doesn't correlate with the skin-tone pick above.
        let jitterHash = unitHash(entry.id + ".cloth")
        let jitter = (jitterHash - 0.5) * 0.12
        let clothColor = (
            min(1, max(0, clothBase.0 + jitter)),
            min(1, max(0, clothBase.1 + jitter)),
            min(1, max(0, clothBase.2 + jitter))
        )
        return (skinTone, clothColor)
    }

    /// A small, deterministic local offset (relative to the NPC's home site's world anchor) so
    /// multiple NPCs sharing a home site scatter into distinct standing positions instead of
    /// rendering stacked on top of each other -- the last inert link in the roster-to-scene
    /// pipeline: appearance() has been consumable by Rev10RealityKitScene.spawnNPC(...) since it
    /// was added, but spawnNPC still needs an explicit position and nothing computed one.
    ///
    /// This deliberately does NOT know where a site's world anchor actually is -- that's owned by
    /// DHWorld/the scene layer, not the roster -- so it returns a local (x, z) offset the caller
    /// adds to that anchor's position, not an absolute world coordinate. Same-site NPCs are
    /// spread evenly around a loose circle (by index among their site-mates) with per-individual
    /// angle/radius jitter so it doesn't read as a mechanically perfect ring.
    public static func localPlacementOffset(for entry: (id: String, name: String, occupation: Occupation, home: BlackridgeSite, faction: Faction?)) -> (x: Double, z: Double) {
        let siteMates = entries.filter { $0.home == entry.home }
        let index = siteMates.firstIndex { $0.id == entry.id } ?? 0
        let siteMateCount = max(1, siteMates.count)
        let baseAngle = (2 * Double.pi * Double(index)) / Double(siteMateCount)
        let angleJitter = (unitHash(entry.id + ".angle") - 0.5) * 0.6
        let radius = 1.4 + unitHash(entry.id + ".radius") * 1.2
        let angle = baseAngle + angleJitter
        return (x: radius * cos(angle), z: radius * sin(angle))
    }
}

public enum DHProductionVehicleRoster {
    /// Named vehicle instances, distinct from DHProductionContentRegistry.vehicles' abstract
    /// archetypes -- these are specific vehicles that can actually be placed in the world, owned
    /// by a faction, and driven/salvaged/stolen.
    public static let entries: [(id: String, name: String, kind: VehicleClass, fuel: FuelKind, liters: Double, faction: Faction?)] = [
        (id: "veh.patrol-cruiser-7", name: "Patrol Cruiser Seven", kind: .interceptor, fuel: .gasoline, liters: 60, faction: .highwayPatrol),
        (id: "veh.rust-runner", name: "Rust Runner", kind: .buggy, fuel: .gasoline, liters: 20, faction: .motorTribes),
        (id: "veh.homestead-flatbed", name: "Homestead Flatbed", kind: .pickup, fuel: .diesel, liters: 70, faction: .homesteads),
        (id: "veh.refinery-tanker-3", name: "Refinery Tanker Three", kind: .tanker, fuel: .diesel, liters: 400, faction: .refineryHouses),
        (id: "veh.combine-hauler", name: "Combine Hauler", kind: .semi, fuel: .diesel, liters: 300, faction: .combine),
        (id: "veh.rail-union-pickup", name: "Rail Union Pickup", kind: .pickup, fuel: .gasoline, liters: 55, faction: .railUnion),
        (id: "veh.scrap-motorcycle-2", name: "Scrap Motorcycle Two", kind: .motorcycle, fuel: .gasoline, liters: 8, faction: nil),
        (id: "veh.paradise-bus", name: "Paradise Settlement Bus", kind: .bus, fuel: .diesel, liters: 150, faction: .homesteads),
        (id: "veh.restorationist-sedan", name: "Restorationist Sedan", kind: .sedan, fuel: .gasoline, liters: 45, faction: .restorationists),
        (id: "veh.burnt-atv", name: "Burnt ATV", kind: .atv, fuel: .gasoline, liters: 15, faction: .childrenOfBurn),
        (id: "veh.tow-rig-one", name: "Blackridge Tow Rig One", kind: .towTruck, fuel: .diesel, liters: 90, faction: nil),
        (id: "veh.wreck-derelict-honda", name: "Derelict Wreck", kind: .wreck, fuel: .gasoline, liters: 0, faction: nil),
    ]

    /// A deterministic paint color for a roster vehicle, faction-flavored the same way
    /// DHProductionNPCRoster.appearance(for:)'s cloth color is occupation-flavored (a Highway
    /// Patrol cruiser isn't painted like a Motor Tribes buggy), with per-individual jitter so two
    /// vehicles owned by the same faction aren't identical. Meant to tint a shared placeholder
    /// vehicle mesh's body panels the same way appearance() tints the shared mannequin's
    /// skin/cloth -- no unique mesh per vehicle kind exists yet (interceptor/buggy/pickup/tanker/
    /// semi/motorcycle/bus/sedan/atv/towTruck/wreck are all still the same generic blockout).
    public static func paintColor(for entry: (id: String, name: String, kind: VehicleClass, fuel: FuelKind, liters: Double, faction: Faction?)) -> (r: Double, g: Double, b: Double) {
        let factionBase: (Double, Double, Double)
        switch entry.faction {
        case .highwayPatrol: factionBase = (0.08, 0.12, 0.28)      // dark patrol blue
        case .motorTribes: factionBase = (0.35, 0.16, 0.06)        // rust/scrap orange-brown
        case .homesteads: factionBase = (0.22, 0.28, 0.14)         // earthy homestead green
        case .refineryHouses: factionBase = (0.55, 0.42, 0.05)     // industrial hazard yellow
        case .combine: factionBase = (0.14, 0.14, 0.16)            // corporate grey-black
        case .railUnion: factionBase = (0.30, 0.08, 0.08)          // rail-union dark red
        case .restorationists: factionBase = (0.62, 0.62, 0.60)    // clean restored silver
        case .childrenOfBurn: factionBase = (0.06, 0.05, 0.05)     // charred black
        case nil: factionBase = (0.24, 0.22, 0.20)                 // unaffiliated neutral rust-grey
        }
        let jitterHash = DHProductionNPCRoster.unitHash(entry.id + ".paint")
        let jitter = (jitterHash - 0.5) * 0.14
        return (
            min(1, max(0, factionBase.0 + jitter)),
            min(1, max(0, factionBase.1 + jitter)),
            min(1, max(0, factionBase.2 + jitter))
        )
    }

    public static func makeFleet() -> FleetState {
        var fleet = FleetState()
        for entry in entries {
            let id = EntityID(uuidString: DHProductionNPCRoster.stableID(entry.id)) ?? UUID()
            var vehicle = FleetVehicle(id: id, name: entry.name, kind: entry.kind, fuel: entry.fuel, liters: entry.liters)
            if entry.kind == .wreck { vehicle.condition = 0.1 }
            fleet.add(vehicle)
        }
        return fleet
    }
}
