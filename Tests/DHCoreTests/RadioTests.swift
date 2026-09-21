import Testing
import Foundation
@testable import DHCore
@testable import DHRadio

@Test func signalStrongestNearRepairedTower() {
    let tower = RadioTower(name: "KBRG", x: 0, y: 0, rangeKM: 10, repaired: true)
    let network = RadioNetwork(towers: [tower])
    #expect(network.signal(x: 0, y: 0) == 1)
}

@Test func signalIgnoresUnrepairedTowers() {
    let tower = RadioTower(name: "KBRG", x: 0, y: 0, rangeKM: 10, repaired: false)
    let network = RadioNetwork(towers: [tower])
    #expect(network.signal(x: 0, y: 0) == 0)
}

@Test func signalFadesWithDistance() {
    let tower = RadioTower(name: "KBRG", x: 0, y: 0, rangeKM: 10, repaired: true)
    let network = RadioNetwork(towers: [tower])
    let near = network.signal(x: 1, y: 0)
    let far = network.signal(x: 9, y: 0)
    #expect(near > far)
    #expect(far >= 0)
}

@Test func ingestAppendsBroadcastForConvoyEvent() {
    var network = RadioNetwork()
    let event = WorldEvent(tick: 5, kind: "convoy.disrupted", detail: "raiders on I-70")
    network.ingest(event)
    #expect(network.broadcasts.count == 1)
    #expect(network.broadcasts[0].eventKind == "convoy.disrupted")
    #expect(network.broadcasts[0].tick == 5)
}

@Test func ingestFallsBackToDetailForUnknownEventKind() {
    var network = RadioNetwork()
    let event = WorldEvent(tick: 1, kind: "unknown.thing", detail: "something happened")
    network.ingest(event)
    #expect(network.broadcasts[0].text.contains("something happened"))
}

@Test func broadcastComposerProducesEventSpecificText() {
    let event = WorldEvent(tick: 1, kind: "settlement.attacked", detail: "Paradise")
    let broadcast = BroadcastComposer.compose(tick: 1, station: "KBRG", event: event)
    #expect(broadcast.text.contains("defenses"))
}

@Test func radioReceiverStaticInverselyTracksSignal() {
    var receiver = RadioReceiver()
    receiver.antennaCondition = 1
    receiver.update(signal: 1)
    #expect(receiver.staticLevel == 0)
    receiver.update(signal: 0)
    #expect(receiver.staticLevel == 1)
}
