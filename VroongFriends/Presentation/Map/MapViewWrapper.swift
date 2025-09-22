import SwiftUI
import MapKit
import CoreLocation

/// SwiftUI Map View Wrapper
struct MapViewWrapper: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var annotations: [CustomMapAnnotation]
    @Binding var showRoute: Bool
    let pickupLocation: CLLocationCoordinate2D?
    let deliveryLocation: CLLocationCoordinate2D?
    let mapProvider: MapManagerFactory.MapProvider

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.mapType = .standard

        // Set initial region
        mapView.setRegion(region, animated: false)

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update region if needed
        if mapView.region.center.latitude != region.center.latitude ||
           mapView.region.center.longitude != region.center.longitude {
            mapView.setRegion(region, animated: true)
        }

        // Update annotations
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotations(annotations)

        // Show route if requested
        if showRoute, let pickup = pickupLocation, let delivery = deliveryLocation {
            showRouteOnMap(mapView: mapView, from: pickup, to: delivery)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func showRouteOnMap(mapView: MKMapView, from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) {
        // Remove existing overlays
        mapView.removeOverlays(mapView.overlays)

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: from))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: to))
        request.transportType = .automobile

        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            guard let response = response,
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
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewWrapper

        init(_ parent: MapViewWrapper) {
            self.parent = parent
        }

        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            parent.region = mapView.region
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if overlay is MKPolyline {
                let renderer = MKPolylineRenderer(overlay: overlay)
                renderer.strokeColor = AppColors.brandPrimary.uiColor()
                renderer.lineWidth = 4
                renderer.lineDashPattern = [10, 5]
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Skip user location annotation
            if annotation is MKUserLocation {
                return nil
            }

            guard let customAnnotation = annotation as? CustomMapAnnotation else {
                return nil
            }

            let identifier = "CustomPin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView

            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            } else {
                annotationView?.annotation = annotation
            }

            // Customize based on marker type
            switch customAnnotation.type {
            case .pickup:
                annotationView?.markerTintColor = .systemBlue
                annotationView?.glyphImage = UIImage(systemName: "mappin.circle.fill")
            case .delivery:
                annotationView?.markerTintColor = .systemRed
                annotationView?.glyphImage = UIImage(systemName: "flag.circle.fill")
            case .currentLocation:
                annotationView?.markerTintColor = .systemGreen
                annotationView?.glyphImage = UIImage(systemName: "location.circle.fill")
            case .restaurant:
                annotationView?.markerTintColor = .systemOrange
                annotationView?.glyphImage = UIImage(systemName: "fork.knife.circle.fill")
            case .customer:
                annotationView?.markerTintColor = .systemPurple
                annotationView?.glyphImage = UIImage(systemName: "person.circle.fill")
            }

            return annotationView
        }

        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            // Handle callout tap
            if let annotation = view.annotation as? CustomMapAnnotation {
                Logger.debug("Callout tapped for: \(annotation.type)", category: .location)
            }
        }
    }
}

// MARK: - SwiftUI Map View

struct DeliveryMapView: View {
    let order: Order
    @State private var region: MKCoordinateRegion
    @State private var annotations: [CustomMapAnnotation] = []
    @State private var showRoute = false
    @State private var selectedMapProvider: MapManagerFactory.MapProvider = .apple
    @StateObject private var locationManager = LocationManager.shared

    init(order: Order) {
        self.order = order

        // Initialize region centered between pickup and delivery
        let centerLat = (order.pickupLocation.coordinate.latitude + order.deliveryLocation.coordinate.latitude) / 2
        let centerLng = (order.pickupLocation.coordinate.longitude + order.deliveryLocation.coordinate.longitude) / 2

        let latDelta = abs(order.pickupLocation.coordinate.latitude - order.deliveryLocation.coordinate.latitude) * 1.5
        let lngDelta = abs(order.pickupLocation.coordinate.longitude - order.deliveryLocation.coordinate.longitude) * 1.5

        self._region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLng),
            span: MKCoordinateSpan(latitudeDelta: max(latDelta, 0.02), longitudeDelta: max(lngDelta, 0.02))
        ))
    }

    var body: some View {
        ZStack {
            MapViewWrapper(
                region: $region,
                annotations: $annotations,
                showRoute: $showRoute,
                pickupLocation: order.pickupLocation.coordinate.clLocation.coordinate,
                deliveryLocation: order.deliveryLocation.coordinate.clLocation.coordinate,
                mapProvider: selectedMapProvider
            )
            .ignoresSafeArea()

            // Map Controls
            VStack {
                HStack {
                    // Map Provider Selector
                    Menu {
                        Button("Apple Maps") {
                            selectedMapProvider = .apple
                        }
                        Button("Naver Map") {
                            selectedMapProvider = .naver
                        }
                        Button("Kakao Map") {
                            selectedMapProvider = .kakao
                        }
                    } label: {
                        Label("Map Provider", systemImage: "map")
                            .font(.system(size: 14))
                            .padding(8)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(8)
                            .shadow(radius: 2)
                    }

                    Spacer()

                    // Route Toggle
                    Button(action: { showRoute.toggle() }) {
                        Label(showRoute ? "Hide Route" : "Show Route", systemImage: "arrow.triangle.turn.up.right.diamond")
                            .font(.system(size: 14))
                            .padding(8)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(8)
                            .shadow(radius: 2)
                    }
                }
                .padding()

                Spacer()

                // Current Location Button
                HStack {
                    Spacer()

                    Button(action: centerOnCurrentLocation) {
                        Image(systemName: "location.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(AppColors.brandPrimary)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            setupAnnotations()
        }
    }

    private func setupAnnotations() {
        annotations = [
            CustomMapAnnotation(
                coordinate: order.pickupLocation.coordinate.clLocation.coordinate,
                type: .pickup
            ),
            CustomMapAnnotation(
                coordinate: order.deliveryLocation.coordinate.clLocation.coordinate,
                type: .delivery
            )
        ]

        // Add current location if available
        if let currentLocation = locationManager.currentLocation {
            annotations.append(
                CustomMapAnnotation(
                    coordinate: currentLocation.coordinate,
                    type: .currentLocation
                )
            )
        }
    }

    private func centerOnCurrentLocation() {
        if let currentLocation = locationManager.currentLocation {
            withAnimation {
                region = MKCoordinateRegion(
                    center: currentLocation.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            }
        }
    }
}

// MARK: - Extensions

extension Color {
    func uiColor() -> UIColor {
        UIColor(self)
    }
}

extension Coordinate {
    var clLocation: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
}