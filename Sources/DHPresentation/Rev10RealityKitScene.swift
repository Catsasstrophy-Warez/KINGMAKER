import Foundation
import DHWorld
import DHVehicle

#if canImport(RealityKit)
import RealityKit

@available(iOS 18.0, macOS 15.0, *)
@MainActor
public final class DHRev10RealityKitScene {
    public let root = Entity()
    private var anchors: [String: Entity] = [:]

    public init() { root.name = "Blackridge County Rev10" }

    public func build(county: DHBlackridgeCounty = .verticalSlice, hierarchy: KingmakerVisualHierarchy? = nil, kingmakerSpec: KingmakerVisualSpec = .init(path: .wastelandEndurance)) {
        root.children.removeAll()
        anchors.removeAll()
        let camera = PerspectiveCamera()
        camera.name = "camera.isometric"
        camera.position = [32, 28, 36]
        camera.look(at: [28, 0, 9], from: camera.position, relativeTo: root)
        root.addChild(camera)
        anchors["camera.isometric"] = camera
        let light = DirectionalLight()
        light.name = "light.blackridge"
        light.light.intensity = 18000
        light.look(at: [20, 0, 10], from: [20, 30, 20], relativeTo: root)
        root.addChild(light)
        buildGarageShell()
        for (index, location) in county.locations.enumerated() {
            let chunk = Entity(); chunk.name = "chunk.\(location.chunkID)"
            chunk.position = SIMD3<Float>(Float(index * 8), 0, Float((index % 4) * 6))
            let terrain = marker(name: "terrain.\(location.chunkID)", size: 7.5, height: 0.08, color: .darkGray)
            terrain.position.y = -0.08
            chunk.addChild(terrain)
            let entity = marker(name: "location.\(location.id)", size: 1.5, height: Float(1 + index % 3), color: color(for: location.kind))
            chunk.addChild(entity)
            anchors[location.id] = entity
            anchors[location.chunkID] = chunk
            root.addChild(chunk)
            for (propIndex, prop) in diagnosticProps(for: location.kind).enumerated() {
                let propEntity = marker(name: "prop.\(location.id).\(prop)", size: 0.45, height: 0.7, color: .yellow)
                propEntity.position = SIMD3<Float>(Float(propIndex % 3) - 1, 0.4, Float(propIndex / 3) - 1)
                chunk.addChild(propEntity)
                anchors["prop.\(location.id).\(prop)"] = propEntity
            }
            if let interior = location.interiorChunkID {
                let interiorEntity = marker(name: "interior.\(interior)", size: 0.8, height: 0.5, color: .purple)
                interiorEntity.isEnabled = false
                chunk.addChild(interiorEntity)
                anchors[interior] = interiorEntity
            }
        }
        let player = marker(name: "player.avatar", size: 0.5, height: 1.2, color: .cyan)
        player.position = [0, 0.6, 3]
        root.addChild(player)
        anchors["player.avatar"] = player
        for road in county.roads {
            let roadEntity = marker(name: "road.\(road.id)", size: 0.35, height: 0.08, color: .orange)
            roadEntity.position = midpoint(from: anchors[road.from], to: anchors[road.to])
            root.addChild(roadEntity)
            anchors[road.id] = roadEntity
        }
        if let hierarchy {
            let kingmaker = Entity(); kingmaker.name = "vehicle.kingmaker"
            let chassis = marker(name: "kingmaker.chassis", size: 3.2, height: 0.55, color: kingmakerSpec.path == .restored ? .black : .red)
            chassis.components.set(PowertrainComponent())
            chassis.components.set(TransmissionComponent())
            chassis.components.set(TelemetryComponent())
            chassis.components.set(ThermalFeedbackComponent())
            chassis.position = [0, 0.35, 0]
            kingmaker.addChild(chassis)
            anchors["kingmaker.chassis"] = chassis
            let cabin = marker(name: "kingmaker.cabin", size: 1.5, height: 0.7, color: .darkGray)
            cabin.position = [-0.2, 0.9, 0]
            kingmaker.addChild(cabin)
            anchors["kingmaker.cabin"] = cabin
            if kingmakerSpec.armorLevel > 0 {
                let armor = marker(name: "kingmaker.armor", size: 3.5, height: 0.18, color: .darkGray)
                armor.position = [0, 0.75, 0]
                kingmaker.addChild(armor); anchors["kingmaker.armor"] = armor
            }
            if kingmakerSpec.cargoLevel > 0 {
                let cargo = marker(name: "kingmaker.cargo", size: 1.25, height: 0.35, color: .brown)
                cargo.position = [-1.0, 1.25, 0]
                kingmaker.addChild(cargo); anchors["kingmaker.cargo"] = cargo
            }
            for (index, x) in [-1.05, 1.05].enumerated() {
                for (side, z) in [-0.72, 0.72].enumerated() {
                    let wheel = ModelEntity(mesh: .generateCylinder(height: 0.18, radius: 0.34), materials: [SimpleMaterial(color: .black, isMetallic: true)])
                    wheel.name = "kingmaker.wheel.\(index).\(side)"
                    wheel.position = [Float(x), 0.28, Float(z)]
                    wheel.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
                    kingmaker.addChild(wheel)
                    anchors[wheel.name] = wheel
                }
            }
            for node in hierarchy.nodes {
                let visual = marker(name: "kingmaker.\(node.id)", size: 0.22, height: 0.22, color: .red)
                kingmaker.addChild(visual); anchors["kingmaker.\(node.id)"] = visual
            }
            kingmaker.position = [0, 0, 0]
            anchors["kingmaker"] = kingmaker
            root.addChild(kingmaker)
        }
    }

    public func entity(for stableID: String) -> Entity? { anchors[stableID] }
    public func setInterior(_ chunkID: String, visible: Bool) { anchors[chunkID]?.isEnabled = visible }
    public func attach(_ entity: Entity, stableID: String) { anchors[stableID] = entity; root.addChild(entity) }

    private func diagnosticProps(for kind: DHBlackridgeLocationKind) -> [String] {
        switch kind {
        case .garage: return ["lift", "toolwall", "kingmaker-bay"]
        case .scrapyard: return ["wreck-stack", "crusher", "parts-pile"]
        case .town: return ["diner", "water-tower", "collapsed-store"]
        case .mine: return ["headframe", "ore-cart", "vent-shaft"]
        case .railYard: return ["coal-car", "signal-box", "freight-crane"]
        case .fuelDepot: return ["tank-farm", "pump-island", "office"]
        case .substation: return ["transformer", "switchyard", "control-room"]
        case .farm: return ["barn", "silo", "irrigation-pump"]
        case .truckStop: return ["canopy", "diner", "repair-bay"]
        case .paradise: return ["gate", "market", "radio-tower"]
        case .storySite: return ["story-prop"]
        }
    }

    private func buildGarageShell() {
        let garage = Entity(); garage.name = "garage.authored-blockout"
        let back = marker(name: "garage.back-wall", size: 14, height: 4, color: .darkGray); back.position = [0, 2, -5]; garage.addChild(back)
        let left = marker(name: "garage.left-wall", size: 0.3, height: 4, color: .darkGray); left.scale = [1, 1, 10]; left.position = [-7, 2, 0]; garage.addChild(left)
        let right = marker(name: "garage.right-wall", size: 0.3, height: 4, color: .darkGray); right.scale = [1, 1, 10]; right.position = [7, 2, 0]; garage.addChild(right)
        let lift = marker(name: "garage.vehicle-lift", size: 4.5, height: 0.12, color: .yellow); lift.position = [0, 0.1, 0]; garage.addChild(lift)
        let bench = marker(name: "garage.workbench", size: 3, height: 1.2, color: .orange); bench.position = [4, 0.6, -3]; garage.addChild(bench)
        root.addChild(garage); anchors[garage.name] = garage
    }

    private func marker(name: String, size: Float, height: Float, color: SimpleMaterial.Color = .gray) -> ModelEntity {
        let entity = ModelEntity(mesh: .generateBox(size: [size, height, size]), materials: [SimpleMaterial(color: color, isMetallic: false)])
        entity.name = name
        return entity
    }

    private func color(for kind: DHBlackridgeLocationKind) -> SimpleMaterial.Color {
        switch kind {
        case .garage: return .red
        case .scrapyard, .mine: return .orange
        case .town, .farm, .truckStop: return .green
        case .railYard, .fuelDepot, .substation: return .blue
        case .paradise: return .purple
        case .storySite: return .yellow
        }
    }

    private func midpoint(from first: Entity?, to second: Entity?) -> SIMD3<Float> {
        guard let first, let second else { return .zero }
        return (first.position(relativeTo: root) + second.position(relativeTo: root)) / 2
    }
}
#endif
