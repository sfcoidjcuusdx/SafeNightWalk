//
//  SafeRouter.swift
//  SafeNightWalk
//
//  Created by rafiq kutty on 7/18/25.
//


// SafeRouter.swift
import Foundation
import CoreLocation

class SafeRouter {
    static func calculatePath(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, using lights: [Streetlight]) -> [CLLocationCoordinate2D] {
        let nodes = SafeGraphBuilder.buildGraph(from: "footpaths", streetlights: lights)

        // Find the nearest nodes to start and end
        guard let startNode = nodes.min(by: { distance($0.coordinate, start) < distance($1.coordinate, start) }),
              let endNode = nodes.min(by: { distance($0.coordinate, end) < distance($1.coordinate, end) }) else {
            print("Could not find start/end nodes")
            return []
        }

        var cameFrom: [SafeGraphNode: SafeGraphNode] = [:]
        var costSoFar: [SafeGraphNode: Double] = [startNode: 0]
        var frontier: [SafeGraphNode] = [startNode]

        while !frontier.isEmpty {
            let current = frontier.removeFirst()

            if current == endNode {
                break
            }

            for (neighbor, cost) in current.neighbors {
                let newCost = (costSoFar[current] ?? Double.infinity) + cost
                if newCost < (costSoFar[neighbor] ?? Double.infinity) {
                    costSoFar[neighbor] = newCost
                    cameFrom[neighbor] = current
                    frontier.append(neighbor)
                }
            }

            frontier.sort { (costSoFar[$0] ?? Double.infinity) < (costSoFar[$1] ?? Double.infinity) }
        }

        // Reconstruct path
        var path: [CLLocationCoordinate2D] = []
        var current: SafeGraphNode? = endNode
        while let node = current, node != startNode {
            path.insert(node.coordinate, at: 0)
            current = cameFrom[node]
        }
        path.insert(startNode.coordinate, at: 0)

        return path
    }

    private static func distance(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Double {
        let locA = CLLocation(latitude: a.latitude, longitude: a.longitude)
        let locB = CLLocation(latitude: b.latitude, longitude: b.longitude)
        return locA.distance(from: locB)
    }
}
