//
//  StreetlightHeatmapRenderer.swift
//  SafeNightWalk
//
//  Created by rafiq kutty on 7/18/25.
//


import MapKit
import UIKit

class StreetlightHeatmapRenderer: MKOverlayRenderer {
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        guard let overlay = overlay as? StreetlightHeatmapOverlay else { return }

        let radius: CGFloat = max(50 / zoomScale, 8)
        for coord in overlay.points {
            let point = point(for: MKMapPoint(coord))
            let color = UIColor.yellow.withAlphaComponent(0.1).cgColor

            context.setFillColor(color)
            context.addArc(center: point, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            context.fillPath()
        }
    }
}
