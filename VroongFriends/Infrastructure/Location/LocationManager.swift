import Foundation
import CoreLocation
import Combine

/// 위치 관리자 (싱글톤)
final class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()
    
    // MARK: - Published Properties
    
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isTracking: Bool = false
    @Published var locationError: Error?
    
    // MARK: - Properties
    
    private let locationManager = CLLocationManager()
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = .invalid
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Setup
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // 10미터마다 업데이트
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.showsBackgroundLocationIndicator = true
        
        // 초기 권한 상태 확인
        authorizationStatus = locationManager.authorizationStatus
    }
    
    // MARK: - Public Methods
    
    func requestAuthorization() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
        case .denied, .restricted:
            Logger.error("위치 권한이 거부되었습니다", category: .location)
            locationError = AppError.locationPermissionDenied
        case .authorizedAlways:
            Logger.info("위치 권한이 허용되었습니다", category: .location)
        @unknown default:
            break
        }
    }
    
    func startTracking() {
        guard authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse else {
            Logger.error("위치 추적 실패: 권한 없음", category: .location)
            requestAuthorization()
            return
        }
        
        isTracking = true
        locationManager.startUpdatingLocation()
        locationManager.startMonitoringSignificantLocationChanges()
        
        // 백그라운드 태스크 시작
        startBackgroundTask()
        
        Logger.info("위치 추적 시작", category: .location)
    }
    
    func stopTracking() {
        isTracking = false
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
        
        // 백그라운드 태스크 종료
        endBackgroundTask()
        
        Logger.info("위치 추적 종료", category: .location)
    }
    
    func getCurrentLocation(completion: @escaping (Result<CLLocation, Error>) -> Void) {
        guard authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse else {
            completion(.failure(AppError.locationPermissionDenied))
            return
        }
        
        if let location = currentLocation {
            completion(.success(location))
        } else {
            locationManager.requestLocation()
            // TODO: Completion handler 저장 및 위치 업데이트 시 호출
        }
    }
    
    // MARK: - Background Task Management
    
    private func startBackgroundTask() {
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTaskIdentifier != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
            backgroundTaskIdentifier = .invalid
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            Logger.info("위치 권한 허용됨", category: .location)
            if isTracking {
                startTracking()
            }
        case .denied, .restricted:
            Logger.error("위치 권한 거부됨", category: .location)
            locationError = AppError.locationPermissionDenied
        case .notDetermined:
            Logger.info("위치 권한 미결정", category: .location)
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // 정확도 필터링 (50미터 이내만 사용)
        guard location.horizontalAccuracy > 0 && location.horizontalAccuracy < 50 else {
            Logger.warning("위치 정확도 부족: \(location.horizontalAccuracy)m", category: .location)
            return
        }
        
        // 시간 필터링 (5초 이내 데이터만 사용)
        guard abs(location.timestamp.timeIntervalSinceNow) < 5 else {
            Logger.warning("오래된 위치 데이터", category: .location)
            return
        }
        
        currentLocation = location
        locationError = nil
        
        Logger.debug("위치 업데이트: \(location.coordinate.latitude), \(location.coordinate.longitude)", category: .location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = error
        
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                Logger.error("위치 서비스 거부됨", category: .location)
                locationError = AppError.locationPermissionDenied
            case .locationUnknown:
                Logger.warning("위치를 확인할 수 없음", category: .location)
            case .network:
                Logger.error("네트워크 오류", category: .location)
            default:
                Logger.error("위치 오류: \(error.localizedDescription)", category: .location)
            }
        }
    }
}