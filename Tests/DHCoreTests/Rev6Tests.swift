import Testing
import Foundation
@testable import DHCore
@testable import DHVehicle
@testable import DHWorld
@testable import DHGameplay
@testable import DHCharacter
@testable import DHFleet
@testable import DHCombat
@testable import DHNPC
@testable import DHSettlement
@testable import DHEconomy
@testable import DHRadio
@testable import DHPresentation

@Test func rev6FirstPlayableSceneHasGarageHighwayParadise(){ let s=BlackridgeFirstPlayableScene(); #expect(s.garage.contains{$0.id=="kingmaker"}); #expect(s.highway.count>0); #expect(s.paradise.count>0) }
@Test func rev6StreamingCellsProgress(){ var s=StreamingCellController(); s.update(distanceFromGarageM:30); #expect(s.active.contains("highway")); s.update(distanceFromGarageM:160); #expect(s.active.contains("paradise")); #expect(!s.active.contains("garage")) }
@Test func rev6PlayableRuntimeCompletesOpening(){ var r=FirstPlayableRuntime(); r.walkToKingmaker(); r.openHood(); r.diagnoseAndRepair(); r.startKingmaker(); r.openDoor(); r.enterKingmaker(); r.drive(to:80); r.drive(to:160); r.exitVehicle(); r.tradeSalvage(); #expect(r.world.verticalSliceComplete); #expect(r.traded) }
