import Foundation
import CoreLocation
import Combine

/// 실시간 위치 추적 서비스
class LocationTrackingService: ObservableObject {
    static let shared = LocationTrackingService()

    // MARK: - Published Properties

    @Published var isTracking: Bool = false
    @Published var currentLocation: CLLocation?
    @Published var trackingError: Error?
    @Published var totalDistance: Double = 0
    @Published var currentSpeed: Double = 0

    // MARK: - Properties

    private let locationManager = LocationManager.shared
    private let webSocketService: WebSocketServiceProtocol
    private let locationRepository: LocationRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    private var lastLocation: CLLocation?
    private var locationUpdateTimer: Timer?
    private let locationUpdateInterval: TimeInterval = 10 // 10초마다 서버 업데이트
    private var locations: [CLLocation] = []

    // MARK: - Initialization

    private init(
        webSocketService: WebSocketServiceProtocol = WebSocketService(environment: Environment.shared),
        locationRepository: LocationRepositoryProtocol = LocationRepository(provider: NetworkProvider.shared.provider)
    ) {
        self.webSocketService = webSocketService
        self.locationRepository = locationRepository

        setupSubscriptions()
    }

    // MARK: - Setup

    private func setupSubscriptions() {
        // LocationManager 위치 업데이트 구독
        locationManager.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.handleLocationUpdate(location)
            }
            .store(in: &cancellables)

        // LocationManager 에러 구독
        locationManager.$locationError
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.trackingError = error
                Logger.error("위치 추적 에러: \(error)", category: .location)
            }
            .store(in: &cancellables)

        // WebSocket 연결 상태 구독
        webSocketService.connectionState
            .sink { [weak self] state in
                switch state {
                case .connected:
                    Logger.info("WebSocket 연결됨 - 위치 추적 준비", category: .location)
                case .disconnected:
                    Logger.warning("WebSocket 연결 끊김", category: .location)
                case .failed(let error):
                    Logger.error("WebSocket 연결 실패: \(error)", category: .location)
                default:
                    break
                }
            }
            .store(in: &cancellables)

        // AppState 온라인 상태 구독
        AppState.shared.$isOnline
            .sink { [weak self] isOnline in
                if isOnline {
                    self?.startTracking()
                } else {
                    self?.stopTracking()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    func startTracking() {
        guard !isTracking else { return }

        isTracking = true
        locations.removeAll()
        totalDistance = 0

        // LocationManager 시작
        locationManager.startTracking()

        // WebSocket 연결
        webSocketService.connect()

        // 주기적 업데이트 타이머 시작
        startLocationUpdateTimer()

        Logger.info("실시간 위치 추적 시작", category: .location)
    }

    func stopTracking() {
        guard isTracking else { return }

        isTracking = false

        // LocationManager 중지
        locationManager.stopTracking()

        // WebSocket 연결 해제
        webSocketService.disconnect()

        // 타이머 중지
        stopLocationUpdateTimer()

        // 마지막 위치 서버에 전송
        if let location = currentLocation {
            sendLocationToServer(location)
        }

        Logger.info("실시간 위치 추적 중지", category: .location)
    }

    func getCurrentRoute() -> [CLLocation] {
        return locations
    }

    func resetDistance() {
        totalDistance = 0
        locations.removeAll()
        lastLocation = nil
    }

    // MARK: - Private Methods

    private func handleLocationUpdate(_ location: CLLocation) {
        currentLocation = location
        locations.append(location)

        // 거리 계산
        if let lastLocation = lastLocation {
            let distance = location.distance(from: lastLocation)
            if distance < 100 { // 100m 이하인 경우만 유효한 이동으로 간주
                totalDistance += distance
            }
        }

        // 속도 업데이트
        currentSpeed = max(0, location.speed * 3.6) // m/s to km/h

        lastLocation = location

        // WebSocket으로 실시간 전송 (throttled)
        sendLocationViaWebSocket(location)
    }

    private func sendLocationViaWebSocket(_ location: CLLocation) {
        let event = LocationUpdateEvent(
            agentId: AppState.shared.currentUser?.agentId ?? "",
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            accuracy: location.horizontalAccuracy,
            speed: location.speed > 0 ? location.speed : nil,
            heading: location.course > 0 ? location.course : nil,
            timestamp: Date()
        )

        let message = WebSocketMessage(
            type: .locationUpdate,
            data: event,
            timestamp: Date()
        )

        webSocketService.send(message)
    }

    private func sendLocationToServer(_ location: CLLocation) {
        locationRepository.updateLocation(location)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        Logger.error("위치 서버 업데이트 실패: \(error)", category: .location)
                    }
                },
                receiveValue: { _ in
                    Logger.debug("위치 서버 업데이트 성공", category: .location)
                }
            )
            .store(in: &cancellables)
    }

    private func startLocationUpdateTimer() {
        locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: locationUpdateInterval, repeats: true) { [weak self] _ in
            guard let self = self, let location = self.currentLocation else { return }
            self.sendLocationToServer(location)
        }
    }

    private func stopLocationUpdateTimer() {
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = nil
    }
}

// MARK: - Location Tracking Statistics

extension LocationTrackingService {
    /// 평균 속도 (km/h)
    var averageSpeed: Double {
        guard !locations.isEmpty else { return 0 }

        let speeds = locations.compactMap { $0.speed }.filter { $0 > 0 }
        guard !speeds.isEmpty else { return 0 }

        return speeds.reduce(0, +) / Double(speeds.count) * 3.6
    }

    /// 최고 속도 (km/h)
    var maxSpeed: Double {
        guard !locations.isEmpty else { return 0 }

        let speeds = locations.compactMap { $0.speed }.filter { $0 > 0 }
        return (speeds.max() ?? 0) * 3.6
    }

    /// 추적 시간 (초)
    var trackingDuration: TimeInterval {
        guard let first = locations.first,
              let last = locations.last else { return 0 }

        return last.timestamp.timeIntervalSince(first.timestamp)
    }

    /// 추적 시간 포맷된 문자열
    var formattedDuration: String {
        let duration = Int(trackingDuration)
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60
        let seconds = duration % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    /// 거리 포맷된 문자열 (km)
    var formattedDistance: String {
        if totalDistance < 1000 {
            return String(format: "%.0f m", totalDistance)
        } else {
            return String(format: "%.2f km", totalDistance / 1000)
        }
    }
}