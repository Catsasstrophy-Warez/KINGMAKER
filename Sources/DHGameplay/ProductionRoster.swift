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
