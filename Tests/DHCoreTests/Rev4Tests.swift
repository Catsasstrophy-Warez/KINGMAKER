import Testing
import Foundation
@testable import DHCore
@testable import DHVehicle
@testable import DHWorld
@testable import DHGameplay

@Test func rev4AuthoredPartsAndDMM() async throws {
 let parts = KingmakerPartsCatalog.authored()
 #expect(parts.count >= 70)
 #expect(parts.contains{$0.key == "eng.crank"})
 let topo = ElectricalTopology.kingmaker()
 let red = TestPoint(id:UUID(),key:"red",electricalNodeKey:"BATT+")
 let black = TestPoint(id:UUID(),key:"black",electricalNodeKey:"BATT-")
 let reading = VirtualDMM().measure(red:red,black:black,topology:topo)
 #expect(reading.valid)
 #expect((reading.value ?? 0) > 12)
}
@Test func rev4EngineTireDiffAndRestoration() async throws {
 var e=EngineDynamics(); e.throttle=1; e.step(running:true,load:0.1,dt:1)
 #expect(e.rpm > 800); #expect(e.torqueNm > 0)
 var t=TireForceState(); t.solve(normalN:4500,mu:1,slip:0.1,slipAngle:0.05); #expect(abs(t.longitudinalN) <= 4500)
 let d=DifferentialDynamics(); let split=d.split(inputTorque:1000,leftGrip:0.5,rightGrip:1); #expect(split.0 + split.1 == 1000)
 var r=RestorationRuntime(); let advanced=r.advance(requirementsMet:true); #expect(advanced); #expect(r.stage == .locate)
}
@Test func rev4SalvageInstallationAndGarage() async throws {
 var parts=KingmakerPartsCatalog.authored(); let s=SalvagePart(id:UUID(),catalogKey:"elec.starter",condition:0.9,compatibility:"XR13")
 #expect(InstallationSystem.install(s,into:&parts,availableTools:["socket-set"]) == .installed)
 var g=GarageInteractionState(); g.set(.hood,open:true); #expect(g.openness[.hood] == 1)
}
