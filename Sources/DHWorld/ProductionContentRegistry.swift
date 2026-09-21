import Foundation

public struct DHRegionDefinition: Codable, Equatable, Sendable, Identifiable { public let id: String; public let name: String; public let hazard: String; public let economy: String; public init(id: String, name: String, hazard: String, economy: String) { self.id=id; self.name=name; self.hazard=hazard; self.economy=economy } }
public struct DHFactionDefinition: Codable, Equatable, Sendable, Identifiable { public let id: String; public let name: String; public let doctrine: String; public init(id: String, name: String, doctrine: String) { self.id=id; self.name=name; self.doctrine=doctrine } }
public struct DHVehicleArchetype: Codable, Equatable, Sendable, Identifiable { public let id: String; public let name: String; public let fuelType: String; public let componentProfile: String; public init(id: String, name: String, fuelType: String, componentProfile: String) { self.id=id; self.name=name; self.fuelType=fuelType; self.componentProfile=componentProfile } }

public enum DHProductionContentRegistry {
    public static let regions: [DHRegionDefinition] = [
        .init(id:"blacktop", name:"The Blacktop", hazard:"cracked asphalt", economy:"freight"), .init(id:"ashCounty", name:"Ash County", hazard:"ash storms", economy:"salvage"), .init(id:"theGlow", name:"The Glow", hazard:"irradiated dust", economy:"rare metals"), .init(id:"ironValley", name:"Iron Valley", hazard:"rail debris", economy:"coal"), .init(id:"saltFlats", name:"Salt Flats", hazard:"whiteout heat", economy:"fuel"), .init(id:"redBasin", name:"Red Basin", hazard:"flash floods", economy:"water"), .init(id:"pineMarch", name:"Pine March", hazard:"mud", economy:"timber"), .init(id:"deadLake", name:"Dead Lake", hazard:"toxic fog", economy:"chemicals"), .init(id:"highDesert", name:"High Desert", hazard:"freezing nights", economy:"livestock"), .init(id:"riverBelt", name:"River Belt", hazard:"flooded roads", economy:"food"), .init(id:"cinderRange", name:"Cinder Range", hazard:"rockfall", economy:"ore"), .init(id:"lastHighway", name:"The Last Highway", hazard:"signal storms", economy:"unknown")
    ]
    public static let factions: [DHFactionDefinition] = [
        .init(id:"highwayPatrol", name:"Highway Patrol", doctrine:"restore law and interstate commerce"), .init(id:"refineryHouses", name:"Refinery Houses", doctrine:"control petroleum"), .init(id:"railUnion", name:"Rail Union", doctrine:"control freight"), .init(id:"motorTribes", name:"Motor Tribes", doctrine:"control roads through force"), .init(id:"restorationists", name:"Restorationists", doctrine:"reboot old technology"), .init(id:"combine", name:"The Combine", doctrine:"industrial production"), .init(id:"homesteads", name:"The Homesteads", doctrine:"protect agriculture")
    ]
    public static let vehicles: [DHVehicleArchetype] = [
        .init(id:"xr13", name:"XR-13 Kingmaker", fuelType:"gasoline", componentProfile:"kingmaker-254"), .init(id:"motorcycle", name:"Scrap Motorcycle", fuelType:"gasoline", componentProfile:"light"), .init(id:"interceptor", name:"Highway Interceptor", fuelType:"gasoline", componentProfile:"pursuit"), .init(id:"heavyTruck", name:"Heavy Hauler", fuelType:"diesel", componentProfile:"heavy"), .init(id:"bus", name:"Settlement Bus", fuelType:"diesel", componentProfile:"fleet")
    ]
}
