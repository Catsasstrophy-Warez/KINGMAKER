import Foundation
import DHCore
import DHCharacter
import DHWorld

public enum LocationKind:String,Codable,CaseIterable,Sendable { case farmhouse,racetrack,tunnel,mine,subway,bunker,derailment,wreckedConvoy,radioTower,machineShop,diner,serviceStation,warehouse,residence }
public enum LootCategory:String,Codable,CaseIterable,Sendable { case food,water,medicine,ammo,parts,fuel,tool,document,junk }
public struct LootEntry:Identifiable,Codable,Sendable,Equatable { public let id:EntityID; public var name:String; public var category:LootCategory; public var quantity:Int; public var rarity:Double; public init(id:EntityID=UUID(),name:String,category:LootCategory,quantity:Int=1,rarity:Double=0.5){self.id=id;self.name=name;self.category=category;self.quantity=quantity;self.rarity=rarity} }
public struct SearchableContainer:Identifiable,Codable,Sendable,Equatable { public let id:EntityID; public var label:String; public var searched:Bool; public var loot:[LootEntry]; public init(id:EntityID=UUID(),label:String,loot:[LootEntry]){self.id=id;self.label=label;self.searched=false;self.loot=loot}; public mutating func search()->[LootEntry]{guard !searched else{return []};searched=true;return loot} }
public struct EnterableLocation:Identifiable,Codable,Sendable,Equatable { public let id:EntityID; public var name:String; public var kind:LocationKind; public var locked:Bool; public var danger:Double; public var containers:[SearchableContainer]; public var storyID:String?; public init(id:EntityID=UUID(),name:String,kind:LocationKind,locked:Bool=false,danger:Double=0,containers:[SearchableContainer]=[],storyID:String?=nil){self.id=id;self.name=name;self.kind=kind;self.locked=locked;self.danger=danger;self.containers=containers;self.storyID=storyID} }
public struct EnvironmentalStory:Identifiable,Codable,Sendable,Equatable { public let id:String; public var title:String; public var fragments:[String]; public var discoveryValue:Int; public init(id:String,title:String,fragments:[String],discoveryValue:Int=5){self.id=id;self.title=title;self.fragments=fragments;self.discoveryValue=discoveryValue} }
public enum EnvironmentalStoryCatalog { public static let blackridge:[EnvironmentalStory] = [
 .init(id:"farm.shelter",title:"Storm Cellar",fragments:["Family marks scratched into a concrete wall.","Three empty cans remain beside a hand-crank radio."]),
 .init(id:"diner.lastmeal",title:"Last Breakfast",fragments:["Coffee cups still sit beneath a collapsed counter.","A handwritten tab says the meal was never paid for."]),
 .init(id:"rail.derail",title:"The Freight That Never Arrived",fragments:["Machine parts are scattered down the embankment.","A manifest names Paradise as the destination."])
 ] }
public struct InteriorRuntime:Codable,Sendable,Equatable { public var currentLocation:EntityID?; public var discoveredStories:Set<String>=[]; public init(){}; public mutating func enter(_ location:EnterableLocation)->Bool { guard !location.locked else{return false};currentLocation=location.id;return true }; public mutating func exit(){currentLocation=nil}; public mutating func discover(_ story:EnvironmentalStory){discoveredStories.insert(story.id)} }
