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

// DeadHighwaySession's stored properties and init live here; its behavior is split by concern
// into DeadHighwaySession+Save.swift (persistence) and DeadHighwaySession+Actions.swift
// (garage/vehicle/world actions + HUD sync) so no single file is the "every feature touches
// this" merge-conflict magnet a single ~50-line god-object file was.
@Observable @MainActor final class DeadHighwaySession {
    var hud = FirstPlayableHUD(); var input = PlayerInputState(); var settings = PauseSettingsState(); var trade = TradeState()
    var message = "BLACKRIDGE GARAGE"; var inVehicle = false
    var avatar = PlayerAvatarState(); var drive = KingmakerDriveController()
    var coordinator = DHRev10SliceCoordinator()
    var camera = IsometricCameraRig()
    var slice = DHRev10VerticalSlice()
    var interaction = DHRev10InteractionPresentation()
    var repair = DHRepairRuntime()
    var loot = DHRev10LootRuntime()
    var paradise = DHRev10ParadiseRuntime()
    let saveKey = "deadhighway.rev10.slice"
    init(){
        trade.player=[.init(id:"salvaged.alternator",name:"Salvaged Alternator",massKG:6.8,value:38)]
        trade.merchant=[.init(id:"hose.upper",name:"Upper Radiator Hose",massKG:0.5,value:14),.init(id:"fuel.filter",name:"Fuel Filter",massKG:0.3,value:11)]
        if let data = UserDefaults.standard.data(forKey: saveKey), loadSaved(from: data) {
            message = "RESTORED \(slice.beat.rawValue.uppercased())"
        }
        coordinator.kingmaker = slice.kingmaker
        syncHUD()
    }
}
#endif
