//
//  StreetlightHeatmapOverlay.swift
//  SafeNightWalk
//
//  Created by rafiq kutty on 7/18/25.
//


import MapKit

class StreetlightHeatmapOverlay: NSObject, MKOverlay {
    var coordinate: CLLocationCoordinate2D
    var boundingMapRect: MKMapRect
    var points: [CLLocationCoordinate2D]

    init(points: [CLLocationCoordinate2D]) {
        self.points = points

        let coords = points.map { MKMapPoint($0) }
        let rect = coords.reduce(MKMapRect.null) { $0.union(MKMapRect(origin: $1, size: MKMapSize(width: 0, height: 0))) }

        self.coordinate = CLLocationCoordinate2D(
            latitude: (rect.origin.y + rect.size.height / 2) / MKMapPointsPerMeterAtLatitude(0),
            longitude: (rect.origin.x + rect.size.width / 2) / MKMapPointsPerMeterAtLatitude(0)
        )
        self.boundingMapRect = rect
    }
}
