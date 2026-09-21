#if os(iOS) || os(macOS)
import SwiftUI
import RealityKit
import DHPresentation
import DHWorld
import DHVehicle

struct GameRootView: View {
    @Bindable var session: DeadHighwaySession
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            RealityView { content in
                let builder = DHRev10RealityKitScene()
                let kingmaker = KingmakerState.derelict()
                builder.build(county: .verticalSlice, hierarchy: .production(componentIDs: kingmaker.components.map { $0.id.uuidString }), kingmakerSpec: .init(path: .wastelandEndurance))
                if let url = DHRev10AssetResolver.url(for: DHRev10AssetManifest.bindings.first(where: { $0.id == "kingmaker.mesh" })!),
                   let asset = try? Entity.load(contentsOf: url) {
                    builder.replaceKingmaker(with: asset)
                }
                content.add(builder.root)
            }
            .ignoresSafeArea()
            VStack { HUDView(session:session); Spacer(); TouchControls(session:session) }.padding()
            if session.settings.paused { PausePanel(session:session) }
        }
    }
}
struct HUDView: View { @Bindable var session:DeadHighwaySession; var body:some View { HStack { VStack(alignment:.leading){ Text(session.message).font(.headline); Text("BEAT: \(session.slice.beat.rawValue.uppercased())").font(.caption.bold()); Text("\(Int(session.hud.speedKPH)) KM/H   FUEL \(Int(session.hud.fuelLiters)) L"); Text(session.hud.radioText).font(.caption.monospaced()) }; Spacer(); Button("II"){session.settings.paused=true} }.padding(10).background(.black.opacity(0.55)).foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius:10)) } }
struct TouchControls: View { @Bindable var session:DeadHighwaySession; var body:some View { HStack { VStack{Button("▲"){session.stepOnFoot(x:0,z:1)};HStack{Button("◀"){session.stepOnFoot(x:-1,z:0)};Button("▼"){session.stepOnFoot(x:0,z:-1)};Button("▶"){session.stepOnFoot(x:1,z:0)}}}.buttonStyle(.borderedProminent); Spacer(); VStack{Button("INSPECT"){session.inspectKingmaker()}; Button("DIAGNOSE"){session.diagnoseKingmaker()}; Button("REPAIR"){session.repairKingmaker()}; Button("ADVANCE \(session.slice.beat.rawValue.uppercased())"){session.advanceSlice()}; HStack{Button("SAVE"){session.saveSlice()};Button("RELOAD"){session.reloadSlice()}}; Button(session.inVehicle ? "BRAKE":"SPRINT"){session.stepVehicle(throttle: session.inVehicle ? 0 : 1, brake: session.inVehicle ? 1 : 0)} }.buttonStyle(.borderedProminent) } } }
struct PausePanel: View { @Bindable var session:DeadHighwaySession; var body:some View { VStack(spacing:16){Text("DEAD HIGHWAY").font(.largeTitle.bold());Button("RESUME"){session.settings.paused=false};Slider(value:$session.settings.masterVolume,in:0...1);Toggle("Haptics",isOn:$session.settings.haptics);Text("Rev7 Blackridge Playable App")}.padding(30).frame(maxWidth:420).background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius:18)) } }
#endif
