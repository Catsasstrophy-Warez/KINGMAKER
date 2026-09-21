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

private struct DHRev10SessionDocument: Codable {
    static let currentSchemaVersion = 1

    let schemaVersion: Int
    var slice: DHRev10VerticalSlice
    var coordinator: DHRev10SliceCoordinator
    var avatar: PlayerAvatarState
    var drive: KingmakerDriveController
    var camera: IsometricCameraRig
    var trade: TradeState
    var repair: DHRepairRuntime
    var loot: DHRev10LootRuntime
    var paradise: DHRev10ParadiseRuntime
    var inVehicle: Bool

    @MainActor init(session: DeadHighwaySession) {
        schemaVersion = Self.currentSchemaVersion
        slice = session.slice
        coordinator = session.coordinator
        avatar = session.avatar
        drive = session.drive
        camera = session.camera
        trade = session.trade
        repair = session.repair
        loot = session.loot
        paradise = session.paradise
        inVehicle = session.inVehicle
    }

    /// Decodes a session document and rejects anything whose schema version we don't recognize,
    /// rather than silently accepting a struct shape we didn't actually validate. A future schema
    /// bump belongs here (migrate old versions forward) instead of relying on Codable's
    /// missing-key defaulting to paper over the difference between "old data" and "corrupt data".
    static func decodeCurrent(_ data: Data) -> DHRev10SessionDocument? {
        guard let document = try? JSONDecoder().decode(DHRev10SessionDocument.self, from: data) else { return nil }
        guard document.schemaVersion == currentSchemaVersion else {
            assertionFailure("DHRev10SessionDocument schema version \(document.schemaVersion) is not the current version \(currentSchemaVersion); add a migration instead of loading it as-is")
            return nil
        }
        return document
    }
}

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
    private let saveKey = "deadhighway.rev10.slice"
    init(){
        trade.player=[.init(id:"salvaged.alternator",name:"Salvaged Alternator",massKG:6.8,value:38)]
        trade.merchant=[.init(id:"hose.upper",name:"Upper Radiator Hose",massKG:0.5,value:14),.init(id:"fuel.filter",name:"Fuel Filter",massKG:0.3,value:11)]
        if let data = UserDefaults.standard.data(forKey: saveKey), loadSaved(from: data) {
            message = "RESTORED \(slice.beat.rawValue.uppercased())"
        }
        coordinator.kingmaker = slice.kingmaker
        syncHUD()
    }

    /// Shared by init and reloadSlice so the current-schema/legacy-fallback decode logic exists in
    /// exactly one place; previously each copy could silently drift out of sync with the other.
    /// Returns whether anything was loaded.
    @discardableResult
    private func loadSaved(from data: Data) -> Bool {
        if let document = DHRev10SessionDocument.decodeCurrent(data) {
            apply(document)
            return true
        }
        if let saved = try? DHRev10SaveDocument.decoded(data) {
            slice = saved
            coordinator.kingmaker = saved.kingmaker
            return true
        }
        return false
    }

    private func apply(_ document: DHRev10SessionDocument) {
        slice = document.slice; coordinator = document.coordinator; avatar = document.avatar; drive = document.drive; camera = document.camera; trade = document.trade; repair = document.repair; loot = document.loot; paradise = document.paradise; inVehicle = document.inVehicle
    }
    func advanceSlice() {
        let next: [DHRev10Beat: DHRev10Beat] = [.garage:.inspect, .inspect:.diagnose, .diagnose:.scavenge, .scavenge:.repair, .repair:.start, .start:.drive, .drive:.hostileEncounter, .hostileEncounter:.radioConsequence, .radioConsequence:.paradise, .paradise:.negotiate, .negotiate:.recruit, .recruit:.save, .save:.reload]
        if let target = next[slice.beat], slice.advance(to: target) {
            coordinator.kingmaker = slice.kingmaker
            if target == .drive { coordinator.stream(center: "garage", neighbors: ["northApproach", "southFields"]) }
            if target == .hostileEncounter { coordinator.encounter.tick(); coordinator.encounterPresentation = coordinator.encounter.encounter.phase.rawValue }
            if target == .radioConsequence { coordinator.resolveEncounter(); interaction.hearRadio(coordinator.radioText) }
            if target == .negotiate { paradise.negotiate() }
            if target == .recruit { paradise.recruit("paradise-mechanic"); coordinator.recruit("paradise-mechanic") }
            message = target.rawValue.replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression).uppercased()
            syncHUD()
        }
    }
    func saveSlice() { coordinator.kingmaker = slice.kingmaker; if let data = try? JSONEncoder().encode(DHRev10SessionDocument(session: self)) { UserDefaults.standard.set(data, forKey: saveKey); message = "WORLD SAVED" } }
    func reloadSlice() { guard let data = UserDefaults.standard.data(forKey: saveKey) else { return }; if loadSaved(from: data) { message = "WORLD RELOADED"; syncHUD() } }
    func inspectKingmaker() { coordinator.inspect(.kingmakerExterior); camera.inspectGarage(); interaction.focus(DHRev10InteractionCatalog.garage[0]); message = "INSPECTING KINGMAKER"; syncHUD() }
    func diagnoseKingmaker() { coordinator.inspect(.engineBay); interaction.focus(DHRev10InteractionCatalog.garage[1]); interaction.diagnose("FAILED COOLING, FUEL, ELECTRICAL; ENGINE SEIZED"); message = interaction.diagnosisText; syncHUD() }
    func repairKingmaker() { for step in repair.steps { while repair.steps.first(where: { $0.id == step.id })?.state != .complete { _ = repair.work(on: step.id, seconds: 4, skill: 5) } }; repair.apply(to: &slice.kingmaker); coordinator.kingmaker = slice.kingmaker; coordinator.repair(); interaction.focus(DHRev10InteractionCatalog.garage[2]); interaction.repairStep(dt: 2); message = "KINGMAKER REPAIRED"; syncHUD() }
    func stepOnFoot(x: Double, z: Double) { input.moveX = x; input.moveY = z; avatar.step(input: input, dt: 0.15); coordinator.movePlayer(to: .init(x: avatar.position.x, y: avatar.position.y, z: avatar.position.z)); input.moveX = 0; input.moveY = 0; syncHUD() }
    func stepVehicle(throttle: Double = 0, brake: Double = 0, steer: Double = 0) { input.throttle = throttle; input.brake = brake; input.steer = steer; drive.step(input: input, dt: 0.15, running: slice.kingmaker.engineRunning); slice.kingmaker.simulate(seconds: 0.15); coordinator.kingmaker = slice.kingmaker; coordinator.playerMode = .driving; camera.enterVehicle(); coordinator.movePlayer(to: .init(x: drive.position.x, y: drive.position.y, z: drive.position.z)); input.throttle = 0; input.brake = 0; input.steer = 0; inVehicle = drive.speedMPS > 0.01; syncHUD() }
    func advanceEncounter() { coordinator.encounter.tick(); coordinator.encounterPresentation = coordinator.encounter.encounter.phase.rawValue; message = "ENCOUNTER \(coordinator.encounterPresentation.uppercased())"; syncHUD() }
    func fireEncounter() { coordinator.encounter.fire(); if coordinator.encounter.resolved { coordinator.resolveEncounter() }; message = coordinator.encounter.resolved ? "CONVOY DISABLED" : "RETURN FIRE"; syncHUD() }
    func searchSalvage() { if loot.search("farmhouse-cabinet") { message = "SALVAGE FOUND" } else { message = "ALREADY SEARCHED" }; syncHUD() }
    func collectSalvage() { loot.collect("fuel-filter"); if !trade.player.contains(where: { $0.id == "fuel-filter" }) { trade.player.append(.init(id: "fuel-filter", name: "Fuel Filter", massKG: 0.3, value: 11)) }; message = "FUEL FILTER COLLECTED"; syncHUD() }
    func tradeSalvage() { paradise.trade(); trade.sell(id: "fuel-filter"); message = "SALVAGE TRADED"; syncHUD() }
    func syncHUD() { hud.speedKPH = drive.speedKPH; hud.fuelLiters = slice.kingmaker.fuelLiters; hud.coolantC = slice.kingmaker.coolantC; hud.radioText = coordinator.radioText; hud.interaction = .init(objectID: interaction.focused?.id, prompt: interaction.focused?.prompt) }
}
#endif
