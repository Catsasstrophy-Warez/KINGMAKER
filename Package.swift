// swift-tools-version: 6.0
import PackageDescription
let package = Package(
 name:"DeadHighway", platforms:[.iOS(.v18),.macOS(.v15)],
 products:["DHCore","DHVehicle","DHWorld","DHCharacter","DHFleet","DHCombat","DHNPC","DHSettlement","DHEconomy","DHRadio","DHGameplay","DHPresentation"].map{.library(name:$0,targets:[$0])},
 targets:[
 .target(name:"DHCore"),
 .target(name:"DHVehicle",dependencies:["DHCore"]),
 .target(name:"DHWorld",dependencies:["DHCore"]),
 .target(name:"DHCharacter",dependencies:["DHCore"]),
 .target(name:"DHFleet",dependencies:["DHCore","DHVehicle"]),
 .target(name:"DHCombat",dependencies:["DHCore","DHCharacter","DHFleet"]),
 .target(name:"DHNPC",dependencies:["DHCore","DHCharacter","DHWorld"]),
 .target(name:"DHSettlement",dependencies:["DHCore","DHWorld","DHNPC"]),
 .target(name:"DHEconomy",dependencies:["DHCore","DHWorld","DHSettlement","DHFleet"]),
 .target(name:"DHRadio",dependencies:["DHCore","DHWorld"]),
 .target(name:"DHGameplay",dependencies:["DHCore","DHVehicle","DHWorld","DHCharacter","DHFleet","DHCombat","DHNPC","DHSettlement","DHEconomy","DHRadio"]),
 .target(name:"DHPresentation",dependencies:["DHCore","DHVehicle","DHWorld","DHCharacter","DHNPC","DHRadio"],resources:[.copy("Resources/Kingmaker_XR13.usdz"),.copy("Resources/BlackridgeGarage.usdz"),.copy("Resources/BlackridgeRoadSegment.usdz"),.copy("Resources/ParadiseInterior.usdz"),.copy("Resources/Radio_Consequences.m4a"),.copy("Resources/XR13_Exhaust_Loop.wav"),.copy("Resources/XR13_Valvetrain_Loop.wav"),.copy("Resources/XR13_Supercharger_Loop.wav"),.copy("Resources/XR13_DCT_Shift.wav"),.copy("Resources/Mannequin_WalkCycle.usdz")]),
 .testTarget(name:"DHCoreTests",dependencies:["DHCore","DHVehicle","DHWorld","DHCharacter","DHFleet","DHCombat","DHNPC","DHSettlement","DHEconomy","DHRadio","DHGameplay","DHPresentation"])
 ])
