import Foundation
import DHCore
import DHVehicle
import DHWorld
import DHCharacter
import DHFleet
import DHSettlement
import DHRadio

public enum PlayerLocomotion:String,Codable,Sendable { case onFoot,inVehicle }
public struct FirstPlayableRuntime:Codable,Sendable,Equatable {
    public var world=WorldComesAliveState(); public var locomotion:PlayerLocomotion = .onFoot; public var playerDistanceM=0.0; public var garageDoorOpen=false; public var hoodOpen=false; public var kingmakerStarted=false; public var reachedParadise=false; public var traded=false
    public init(){}
    public mutating func walkToKingmaker(){playerDistanceM=4;world.complete(.spawnGarage);world.complete(.walkToKingmaker)}
    public mutating func openHood(){hoodOpen=true;world.complete(.openHood)}
    public mutating func diagnoseAndRepair(){world.complete(.diagnose);world.complete(.repair)}
    public mutating func startKingmaker(){guard hoodOpen else{return};kingmakerStarted=true;world.complete(.startEngine)}
    public mutating func openDoor(){garageDoorOpen=true;world.complete(.openGarageDoor)}
    public mutating func enterKingmaker(){guard kingmakerStarted && garageDoorOpen else{return};locomotion = .inVehicle;world.complete(.enterVehicle)}
    public mutating func drive(to distance:Double){guard locomotion == .inVehicle else{return};playerDistanceM=max(playerDistanceM,distance);if distance>=25{world.complete(.driveHighway)};if distance>=75{world.complete(.encounterConvoy);world.complete(.hearRadio)};if distance>=150{reachedParadise=true;world.complete(.reachParadise)}}
    public mutating func exitVehicle(){guard reachedParadise else{return};locomotion = .onFoot;world.complete(.exitVehicle);world.complete(.enterSettlement)}
    public mutating func tradeSalvage(){guard reachedParadise && locomotion == .onFoot else{return};traded=true;world.complete(.tradeSalvage)}
}
