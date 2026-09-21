import Foundation
import DHCore
import DHVehicle
import DHWorld
import DHCharacter
import DHFleet
import DHCombat
import DHNPC
import DHSettlement
import DHEconomy
import DHRadio
public enum PlayableMilestone:String,Codable,CaseIterable,Sendable { case spawnGarage,walkToKingmaker,openHood,diagnose,repair,startEngine,openGarageDoor,enterVehicle,driveHighway,encounterConvoy,hearRadio,reachParadise,exitVehicle,enterSettlement,tradeSalvage }
public struct WorldComesAliveState:Codable,Sendable,Equatable { public var completed:Set<PlayableMilestone>=[]; public var player=CharacterState(name:"Wanderer"); public var fleet=FleetState(); public var npcs=NPCPopulation(); public var economy=RegionalEconomy(); public var radio=RadioNetwork(); public var tactical=TacticalClock(); public init(){let p=ParadiseFactory.make();economy.settlements[p.id]=p;for i in 0..<150 { let jobs=Occupation.allCases;npcs.add(.init(name:"Paradise Resident \(i+1)",occupation:jobs[i % jobs.count],home:.truckStop)) };radio.towers=[.init(name:"Blackridge Relay",x:0,y:0,rangeKM:35,repaired:false)]}; public var current:PlayableMilestone { PlayableMilestone.allCases.first{!completed.contains($0)} ?? .tradeSalvage }; public mutating func complete(_ m:PlayableMilestone){completed.insert(m)}; public var verticalSliceComplete:Bool { Set(PlayableMilestone.allCases).isSubset(of:completed) } }
