import Foundation
import MapKit
import CoreLocation

/// Apple MapKit 매니저 (Fallback)
class AppleMapManager: NSObject, MapManagerProtocol {
    private var mapView: MKMapView?
    private var markers: [MKAnnotation] = []
    private var currentLocation: CLLocationCoordinate2D?

    func initialize(with config: MapConfiguration) {
        mapView = MKMapView()
        mapView?.showsUserLocation = config.enableUserLocation
        mapView?.showsCompass = config.enableCompass
        mapView?.showsScale = true
        mapView?.mapType = .standard

        // Set initial zoom level
        if let mapView = mapView {
            let region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780), // Seoul
                latitudinalMeters: 1000 * (20 - config.initialZoomLevel),
                longitudinalMeters: 1000 * (20 - config.initialZoomLevel)
            )
            mapView.setRegion(region, animated: false)
        }

        Logger.debug("Apple 맵 초기화", category: .general)
    }

    func showRoute(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) {
        guard let mapView = mapView else { return }

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: from))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: to))
        request.transportType = .automobile

        let directions = MKDirections(request: request)
        directions.calculate { [weak self] response, error in
            guard let self = self,
                  let response = response,
                  let route = response.routes.first else {
                Logger.error("경로 계산 실패: \(error?.localizedDescription ?? "")", category: .location)
                return
            }

            mapView.addOverlay(route.polyline)
            mapView.setVisibleMapRect(
                route.polyline.boundingMapRect,
                edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50),
                animated: true
            )
        }

        Logger.debug("경로 표시: \(from) -> \(to)", category: .location)
    }

    func addMarker(at coordinate: CLLocationCoordinate2D, type: MarkerType) {
        guard let mapView = mapView else { return }

        let annotation = CustomMapAnnotation(
            coordinate: coordinate,
            type: type
        )

        mapView.addAnnotation(annotation)
        markers.append(annotation)

        Logger.debug("마커 추가: \(type) at \(coordinate)", category: .location)
    }

    func removeAllMarkers() {
        guard let mapView = mapView else { return }

        mapView.removeAnnotations(markers)
        markers.removeAll()

        Logger.debug("모든 마커 제거", category: .location)
    }

    func centerMap(at coordinate: CLLocationCoordinate2D, zoomLevel: Double) {
        guard let mapView = mapView else { return }

        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 1000 * (20 - zoomLevel),
            longitudinalMeters: 1000 * (20 - zoomLevel)
        )

        mapView.setRegion(region, animated: true)

        Logger.debug("맵 중앙 이동: \(coordinate), zoom: \(zoomLevel)", category: .location)
    }

    func getCurrentLocation() -> CLLocationCoordinate2D? {
        return currentLocation ?? mapView?.userLocation.coordinate
    }
}

// MARK: - MKMapViewDelegate

extension AppleMapManager: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor.systemBlue
            renderer.lineWidth = 3
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let customAnnotation = annotation as? CustomMapAnnotation else {
            return nil
        }

        let identifier = "CustomPin"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView

        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
        } else {
            annotationView?.annotation = annotation
        }

        // Customize based on marker type
        switch customAnnotation.type {
        case .pickup:
            annotationView?.markerTintColor = .systemBlue
            annotationView?.glyphImage = UIImage(systemName: "mappin.circle")
        case .delivery:
            annotationView?.markerTintColor = .systemRed
            annotationView?.glyphImage = UIImage(systemName: "flag.circle")
        case .currentLocation:
            annotationView?.markerTintColor = .systemGreen
            annotationView?.glyphImage = UIImage(systemName: "location.circle")
        case .restaurant:
            annotationView?.markerTintColor = .systemOrange
            annotationView?.glyphImage = UIImage(systemName: "fork.knife.circle")
        case .customer:
            annotationView?.markerTintColor = .systemPurple
            annotationView?.glyphImage = UIImage(systemName: "person.circle")
        }

        return annotationView
    }

    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        currentLocation = userLocation.coordinate
    }
}

// MARK: - Custom Map Annotation

class CustomMapAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let type: MarkerType
    var title: String?
    var subtitle: String?

    init(coordinate: CLLocationCoordinate2D, type: MarkerType) {
        self.coordinate = coordinate
        self.type = type

        switch type {
        case .pickup:
            self.title = "픽업 위치"
        case .delivery:
            self.title = "배달 위치"
        case .currentLocation:
            self.title = "현재 위치"
        case .restaurant:
            self.title = "음식점"
        case .customer:
            self.title = "고객"
        }

        super.init()
    }
}