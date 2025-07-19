import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var streetlights: [Streetlight] = LightingDataLoader.loadStreetlights()
    @State private var destination: CLLocationCoordinate2D? = nil
    @State private var safePath: [CLLocationCoordinate2D] = []

    var body: some View {
        ZStack {
            if locationManager.location != nil {
                MapViewWrapper(region: $locationManager.region,
                               userLocation: locationManager.location,
                               streetlights: streetlights,
                               safePath: $safePath,
                               destination: $destination)
                    .ignoresSafeArea()
            } else {
                ProgressView("Locating...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.6))
                    .foregroundColor(.white)
            }
        }
    }
}

struct MapViewWrapper: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var userLocation: CLLocation?
    var streetlights: [Streetlight]
    @Binding var safePath: [CLLocationCoordinate2D]
    @Binding var destination: CLLocationCoordinate2D?

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true

        // Tap gesture to select destination
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        mapView.addGestureRecognizer(tapGesture)

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.setRegion(region, animated: true)

        mapView.removeOverlays(mapView.overlays)

        let heatmapOverlay = StreetlightHeatmapOverlay(points: streetlights.map { $0.coordinate })
        mapView.addOverlay(heatmapOverlay)

        if !safePath.isEmpty {
            let polyline = MKPolyline(coordinates: safePath, count: safePath.count)
            mapView.addOverlay(polyline)
        }

    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewWrapper

        init(_ parent: MapViewWrapper) {
            self.parent = parent
        }

        @objc func handleTap(_ gestureRecognizer: UITapGestureRecognizer) {
            let mapView = gestureRecognizer.view as! MKMapView
            let point = gestureRecognizer.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            parent.destination = coordinate

            if let start = parent.userLocation?.coordinate {
                parent.safePath = SafeRouter.calculatePath(from: start, to: coordinate, using: parent.streetlights)
            }
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if overlay is StreetlightHeatmapOverlay {
                return StreetlightHeatmapRenderer(overlay: overlay)
            }

            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.green
                renderer.lineWidth = 4
                return renderer
            }

            return MKOverlayRenderer()
        }

    }
}

