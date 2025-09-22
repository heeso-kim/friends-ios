import SwiftUI
import MapKit

/// 주문 지도 화면
struct OrderMapView: View {
    let order: Order
    @Environment(\.dismiss) private var dismiss
    @State private var region: MKCoordinateRegion
    @State private var selectedLocation: LocationType = .pickup

    enum LocationType: String, CaseIterable {
        case pickup = "픽업"
        case delivery = "배달"
    }

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
            // Map
            Map(coordinateRegion: $region, annotationItems: locationAnnotations) { location in
                MapAnnotation(coordinate: location.coordinate) {
                    VStack {
                        Image(systemName: location.icon)
                            .font(.title)
                            .foregroundColor(location.color)
                            .background(
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 32, height: 32)
                            )
                            .shadow(radius: 2)

                        Text(location.title)
                            .font(.caption2)
                            .padding(4)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(4)
                    }
                }
            }
            .ignoresSafeArea()

            // Top Controls
            VStack {
                HStack {
                    // Location Selector
                    Picker("Location", selection: $selectedLocation) {
                        ForEach(LocationType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    Spacer()
                }
                .padding()
                .background(
                    Color.white
                        .opacity(0.95)
                        .ignoresSafeArea(edges: .top)
                )

                Spacer()

                // Location Info Card
                locationInfoCard
                    .padding()
            }
        }
        .navigationTitle("주문 위치")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("닫기") {
                    dismiss()
                }
            }
        }
        .onChange(of: selectedLocation) { newValue in
            withAnimation {
                focusOnLocation(newValue)
            }
        }
    }

    // MARK: - Location Info Card

    private var locationInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: selectedLocation == .pickup ? "mappin.circle.fill" : "flag.circle.fill")
                    .foregroundColor(selectedLocation == .pickup ? AppColors.brandPrimary : .red)

                Text(selectedLocation.rawValue)
                    .font(.system(size: 14, weight: .semibold))

                Spacer()

                // Navigation button
                Button(action: openInMaps) {
                    Label("길안내", systemImage: "arrow.triangle.turn.up.right.diamond")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppColors.brandPrimary)
                        .cornerRadius(6)
                }
            }

            let location = selectedLocation == .pickup ? order.pickupLocation : order.deliveryLocation

            Text(location.address)
                .font(.system(size: 14))
                .foregroundColor(.black.opacity(0.8))

            if let detailAddress = location.detailAddress {
                Text(detailAddress)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }

            if let contactName = location.contactName {
                HStack {
                    Image(systemName: "person.circle")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Text(contactName)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }

            if let contactPhone = location.contactPhone {
                HStack {
                    Image(systemName: "phone.circle")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Text(contactPhone)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 8)
    }

    // MARK: - Helper Methods

    private var locationAnnotations: [LocationAnnotation] {
        [
            LocationAnnotation(
                title: "픽업",
                coordinate: order.pickupLocation.coordinate.clLocation.coordinate,
                icon: "mappin.circle.fill",
                color: AppColors.brandPrimary
            ),
            LocationAnnotation(
                title: "배달",
                coordinate: order.deliveryLocation.coordinate.clLocation.coordinate,
                icon: "flag.circle.fill",
                color: .red
            )
        ]
    }

    private func focusOnLocation(_ type: LocationType) {
        let location = type == .pickup ? order.pickupLocation : order.deliveryLocation
        region = MKCoordinateRegion(
            center: location.coordinate.clLocation.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }

    private func openInMaps() {
        let location = selectedLocation == .pickup ? order.pickupLocation : order.deliveryLocation
        let coordinate = location.coordinate.clLocation.coordinate

        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = location.address
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

// MARK: - Location Annotation

struct LocationAnnotation: Identifiable {
    let id = UUID()
    let title: String
    let coordinate: CLLocationCoordinate2D
    let icon: String
    let color: Color
}