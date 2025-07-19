//
//  SafeGraphNode.swift
//  SafeNightWalk
//
//  Created by rafiq kutty on 7/18/25.
//

import Foundation
import CoreLocation

class SafeGraphNode: Identifiable, Hashable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    var neighbors: [(node: SafeGraphNode, cost: Double)] = []

    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }

    static func == (lhs: SafeGraphNode, rhs: SafeGraphNode) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

class SafeGraphBuilder {
    static func buildGraph(from geoJSON: String, streetlights: [Streetlight]) -> [SafeGraphNode] {
        guard let url = Bundle.main.url(forResource: geoJSON, withExtension: "geojson"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let features = json["features"] as? [[String: Any]] else {
            return []
        }

        var nodes: [SafeGraphNode] = []

        for feature in features {
            guard let geometry = feature["geometry"] as? [String: Any],
                  let coordsArray = geometry["coordinates"] as? [[Double]],
                  geometry["type"] as? String == "LineString" else { continue }

            var prevNode: SafeGraphNode? = nil

            for coord in coordsArray {
                let newNode = SafeGraphNode(coordinate: CLLocationCoordinate2D(latitude: coord[1], longitude: coord[0]))
                if let prev = prevNode {
                    let distance = distanceBetween(prev.coordinate, newNode.coordinate)
                    let lightLevel = nearbyLights(to: newNode.coordinate, lights: streetlights)
                    let cost = distance - (Double(lightLevel) * 10.0)  // Convert lightLevel to Double

                    prev.neighbors.append((newNode, cost))
                    newNode.neighbors.append((prev, cost))
                }

                nodes.append(newNode)
                prevNode = newNode
            }
        }

        return nodes
    }

    static func distanceBetween(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Double {
        let locA = CLLocation(latitude: a.latitude, longitude: a.longitude)
        let locB = CLLocation(latitude: b.latitude, longitude: b.longitude)
        return locA.distance(from: locB)
    }

    static func nearbyLights(to point: CLLocationCoordinate2D, lights: [Streetlight]) -> Int {
        lights.filter {
            distanceBetween($0.coordinate, point) < 25
        }.count
    }
}

