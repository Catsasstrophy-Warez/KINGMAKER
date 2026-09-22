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

@Test func rev7AvatarMovementAndDriving() {
    var input = PlayerInputState(); input.moveY = 1
    var avatar = PlayerAvatarState(); avatar.step(input: input, dt: 1)
    #expect(avatar.position.z > 3)
    input = PlayerInputState(); input.throttle = 1; input.steer = 0.15
    var car = KingmakerDriveController(); for _ in 0..<60 { car.step(input: input, dt: 1.0/60.0, running: true) }
    #expect(car.speedKPH > 10); #expect(car.position.z > 0)
}
@Test func rev7InteractionAndTrade() {
    let best = InteractionResolver().best([.init(id:"door",prompt:"Open",distanceM:2.2),.init(id:"hood",prompt:"Inspect",distanceM:1.1)])
    #expect(best?.id == "hood")
    var trade = TradeState(); trade.playerCaps=20; trade.merchant=[.init(id:"hose",name:"Hose",massKG:0.5,value:12)]; trade.buy(id:"hose")
    #expect(trade.playerCaps == 8); #expect(trade.player.first?.id == "hose")
}
@Test func rev7AudioAndFXDeriveFromSimulation() {
    var audio=EngineAudioState(); audio.update(rpm:3200,throttle:0.7,cranking:false,running:true)
    var fx=VehicleFXState(); fx.update(speedKPH:90,slip:0.35,roadDust:0.8,coolantC:102)
    #expect(audio.gain > 0.5); #expect(fx.dust > 0.5); #expect(fx.skid > 0.5)
}
