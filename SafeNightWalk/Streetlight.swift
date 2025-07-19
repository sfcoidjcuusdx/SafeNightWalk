import Foundation
import MapKit

struct Streetlight: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

class LightingDataLoader {
    static func loadStreetlights() -> [Streetlight] {
        guard let url = Bundle.main.url(forResource: "streetlights", withExtension: "geojson"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let features = json["features"] as? [[String: Any]] else {
            print("Could not load or parse GeoJSON")
            return []
        }

        var lights: [Streetlight] = []

        for feature in features {
            guard let geometry = feature["geometry"] as? [String: Any],
                  let type = geometry["type"] as? String else { continue }

            if type == "MultiPoint",
               let coordinates = geometry["coordinates"] as? [[Double]] {
                for pair in coordinates where pair.count == 2 {
                    let coord = CLLocationCoordinate2D(latitude: pair[1], longitude: pair[0])
                    lights.append(Streetlight(coordinate: coord))
                }
                continue
            }

            // Optional: fallback if other types are encountered
        }

        print("Loaded \(lights.count) streetlights from GeoJSON")
        return lights
    }
}
