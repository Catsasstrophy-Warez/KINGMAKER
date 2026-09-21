import Foundation

public struct DHNavigationNode: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let chunkID: String
    public init(id: String, chunkID: String) { self.id = id; self.chunkID = chunkID }
}

public struct DHBlackridgeNavigationGraph: Codable, Equatable, Sendable {
    public let nodes: [String: DHNavigationNode]
    public let edges: [String: Set<String>]

    public init(county: DHBlackridgeCounty = .verticalSlice) {
        nodes = Dictionary(uniqueKeysWithValues: county.locations.map { ($0.id, DHNavigationNode(id: $0.id, chunkID: $0.chunkID)) })
        var adjacency: [String: Set<String>] = [:]
        for road in county.roads where road.traversable {
            adjacency[road.from, default: []].insert(road.to)
            adjacency[road.to, default: []].insert(road.from)
        }
        edges = adjacency
    }

    public func route(from start: String, to destination: String) -> [String]? {
        guard nodes[start] != nil, nodes[destination] != nil else { return nil }
        if start == destination { return [start] }
        var queue = [start]
        var predecessor: [String: String] = [:]
        var visited: Set<String> = [start]
        while let current = queue.first {
            queue.removeFirst()
            for next in edges[current, default: []] where visited.insert(next).inserted {
                predecessor[next] = current
                if next == destination {
                    var path = [destination]
                    var cursor = destination
                    while let previous = predecessor[cursor] { path.append(previous); cursor = previous }
                    return path.reversed()
                }
                queue.append(next)
            }
        }
        return nil
    }
}
