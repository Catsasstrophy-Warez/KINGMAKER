#if os(iOS) || os(macOS)
import SwiftUI
import DHPresentation
import DHGameplay

@main struct DeadHighwayApp: App {
    init() {
        PowertrainComponent.registerComponent()
        TransmissionComponent.registerComponent()
        TelemetryComponent.registerComponent()
        ThermalFeedbackComponent.registerComponent()
        KingmakerVehicleSimulationSystem.registerSystem()
    }
    @State private var session = DeadHighwaySession()
    var body: some Scene { WindowGroup { GameRootView(session: session) } }
}

@Observable @MainActor final class DeadHighwaySession {
    var hud = FirstPlayableHUD(); var input = PlayerInputState(); var settings = PauseSettingsState(); var trade = TradeState()
    var message = "BLACKRIDGE GARAGE"; var inVehicle = false
    var avatar = PlayerAvatarState(); var drive = KingmakerDriveController()
    var slice = DHRev10VerticalSlice()
    var interaction = DHRev10InteractionPresentation()
    private let saveKey = "deadhighway.rev10.slice"
    init(){
        trade.player=[.init(id:"salvaged.alternator",name:"Salvaged Alternator",massKG:6.8,value:38)]
        trade.merchant=[.init(id:"hose.upper",name:"Upper Radiator Hose",massKG:0.5,value:14),.init(id:"fuel.filter",name:"Fuel Filter",massKG:0.3,value:11)]
        if let data = UserDefaults.standard.data(forKey: saveKey), let saved = try? DHRev10SaveDocument.decoded(data) { slice = saved; message = "RESTORED \(saved.beat.rawValue.uppercased())" }
    }
    func advanceSlice() {
        let next: [DHRev10Beat: DHRev10Beat] = [.garage:.inspect, .inspect:.diagnose, .diagnose:.scavenge, .scavenge:.repair, .repair:.start, .start:.drive, .drive:.hostileEncounter, .hostileEncounter:.radioConsequence, .radioConsequence:.paradise, .paradise:.negotiate, .negotiate:.recruit, .recruit:.save, .save:.reload]
        if let target = next[slice.beat], slice.advance(to: target) { message = target.rawValue.replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression).uppercased() }
    }
    func saveSlice() { if let data = try? DHRev10SaveDocument(slice: slice).encoded() { UserDefaults.standard.set(data, forKey: saveKey); message = "WORLD SAVED" } }
    func reloadSlice() { if let data = UserDefaults.standard.data(forKey: saveKey), let saved = try? DHRev10SaveDocument.decoded(data) { slice = saved; message = "WORLD RELOADED" } }
    func inspectKingmaker() { interaction.focus(DHRev10InteractionCatalog.garage[0]); message = "INSPECTING KINGMAKER" }
    func diagnoseKingmaker() { interaction.focus(DHRev10InteractionCatalog.garage[1]); interaction.diagnose("FAILED COOLING, FUEL, ELECTRICAL; ENGINE SEIZED"); message = interaction.diagnosisText }
    func repairKingmaker() { slice.repairKingmaker(); interaction.focus(DHRev10InteractionCatalog.garage[2]); interaction.repairStep(dt: 2); message = "KINGMAKER REPAIRED" }
    func stepOnFoot(x: Double, z: Double) { input.moveX = x; input.moveY = z; avatar.step(input: input, dt: 0.15); input.moveX = 0; input.moveY = 0 }
    func stepVehicle(throttle: Double = 0, brake: Double = 0, steer: Double = 0) { input.throttle = throttle; input.brake = brake; input.steer = steer; drive.step(input: input, dt: 0.15, running: slice.kingmaker.engineRunning); input.throttle = 0; input.brake = 0; input.steer = 0; inVehicle = drive.speedMPS > 0.01 }
}
#endif
