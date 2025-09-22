import SwiftUI
import MapKit

/// 실시간 위치 추적 화면
struct LocationTrackingView: View {
    @StateObject private var trackingService = LocationTrackingService.shared
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var trackingPath: [CLLocationCoordinate2D] = []
    @State private var showingStats = true

    var body: some View {
        ZStack {
            // Map
            Map(coordinateRegion: $mapRegion, showsUserLocation: true, annotationItems: []) { _ in }
                .ignoresSafeArea()
                .onReceive(trackingService.$currentLocation) { location in
                    if let location = location {
                        withAnimation {
                            mapRegion.center = location.coordinate
                        }
                        trackingPath.append(location.coordinate)
                    }
                }

            // Overlay Controls
            VStack {
                // Top Status Bar
                if showingStats {
                    trackingStatsCard
                        .padding()
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer()

                // Bottom Controls
                bottomControls
                    .padding()
            }
        }
        .navigationTitle("위치 추적")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingStats.toggle() }) {
                    Image(systemName: showingStats ? "info.circle.fill" : "info.circle")
                }
            }
        }
    }

    // MARK: - Tracking Stats Card

    private var trackingStatsCard: some View {
        VStack(spacing: 16) {
            // Status
            HStack {
                Circle()
                    .fill(trackingService.isTracking ? Color.green : Color.gray)
                    .frame(width: 10, height: 10)

                Text(trackingService.isTracking ? "추적 중" : "대기 중")
                    .font(.system(size: 14, weight: .semibold))

                Spacer()

                Text(trackingService.formattedDuration)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }

            // Stats Grid
            HStack(spacing: 20) {
                // Distance
                VStack(spacing: 4) {
                    Image(systemName: "location.circle")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.brandPrimary)
                    Text("거리")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                    Text(trackingService.formattedDistance)
                        .font(.system(size: 14, weight: .semibold))
                }

                Divider()
                    .frame(height: 40)

                // Current Speed
                VStack(spacing: 4) {
                    Image(systemName: "speedometer")
                        .font(.system(size: 20))
                        .foregroundColor(.orange)
                    Text("현재 속도")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                    Text(String(format: "%.1f km/h", trackingService.currentSpeed))
                        .font(.system(size: 14, weight: .semibold))
                }

                Divider()
                    .frame(height: 40)

                // Average Speed
                VStack(spacing: 4) {
                    Image(systemName: "gauge")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                    Text("평균 속도")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                    Text(String(format: "%.1f km/h", trackingService.averageSpeed))
                        .font(.system(size: 14, weight: .semibold))
                }
            }

            // Error Message
            if let error = trackingService.trackingError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error.localizedDescription)
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color.white.opacity(0.95))
        .cornerRadius(12)
        .shadow(radius: 4)
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 12) {
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
            }

            // Tracking Control
            HStack(spacing: 12) {
                if trackingService.isTracking {
                    Button(action: pauseTracking) {
                        Label("일시정지", systemImage: "pause.circle.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.orange)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.95))
                            .cornerRadius(8)
                            .shadow(radius: 2)
                    }

                    Button(action: stopTracking) {
                        Label("종료", systemImage: "stop.circle.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.95))
                            .cornerRadius(8)
                            .shadow(radius: 2)
                    }
                } else {
                    Button(action: startTracking) {
                        Label("추적 시작", systemImage: "play.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppColors.brandPrimary)
                            .cornerRadius(8)
                            .shadow(radius: 2)
                    }
                }

                Button(action: resetTracking) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                        .padding(12)
                        .background(Color.white.opacity(0.95))
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
            }
        }
    }

    // MARK: - Actions

    private func centerOnCurrentLocation() {
        if let location = trackingService.currentLocation {
            withAnimation {
                mapRegion.center = location.coordinate
                mapRegion.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            }
        }
    }

    private func startTracking() {
        trackingService.startTracking()
        trackingPath.removeAll()
    }

    private func pauseTracking() {
        // TODO: Implement pause functionality
        Logger.debug("추적 일시정지", category: .location)
    }

    private func stopTracking() {
        trackingService.stopTracking()
    }

    private func resetTracking() {
        trackingService.resetDistance()
        trackingPath.removeAll()
    }
}

// MARK: - Tracking Path Overlay

struct TrackingPathOverlay: Shape {
    let coordinates: [CLLocationCoordinate2D]

    func path(in rect: CGRect) -> Path {
        var path = Path()

        guard !coordinates.isEmpty else { return path }

        // TODO: Convert coordinates to points in rect
        // This would require MapKit integration to convert lat/lng to screen points

        return path
    }
}