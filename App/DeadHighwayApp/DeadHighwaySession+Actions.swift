#if os(iOS) || os(macOS)
import Foundation
import DHPresentation
import DHGameplay

extension DeadHighwaySession {
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
