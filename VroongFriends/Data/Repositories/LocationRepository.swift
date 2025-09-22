import Foundation
import Combine
import CoreLocation
import Moya

/// 위치 리포지토리 구현체
final class LocationRepository: LocationRepositoryProtocol {
    private let provider: MoyaProvider<FriendsAPI>
    private let locationManager = LocationManager.shared
    
    init(provider: MoyaProvider<FriendsAPI>) {
        self.provider = provider
    }
    
    func updateLocation(_ location: CLLocation) -> AnyPublisher<Void, AppError> {
        return provider.requestPublisher(
            .updateLocation(
                lat: location.coordinate.latitude,
                lng: location.coordinate.longitude
            )
        )
        .map { _ in () }
        .mapError { error in
            if let moyaError = error as? MoyaError {
                switch moyaError {
                case .underlying(let underlyingError, _):
                    if (underlyingError as NSError).code == NSURLErrorNotConnectedToInternet {
                        return AppError.noInternetConnection
                    }
                    return AppError.locationUpdateFailed
                default:
                    return AppError.locationUpdateFailed
                }
            }
            return AppError.locationUpdateFailed
        }
        .eraseToAnyPublisher()
    }
    
    func startLocationTracking() -> AnyPublisher<Void, AppError> {
        return Future<Void, AppError> { promise in
            self.locationManager.startTracking()
            promise(.success(()))
        }
        .eraseToAnyPublisher()
    }
    
    func stopLocationTracking() -> AnyPublisher<Void, AppError> {
        return Future<Void, AppError> { promise in
            self.locationManager.stopTracking()
            promise(.success(()))
        }
        .eraseToAnyPublisher()
    }
    
    func getCurrentLocation() -> AnyPublisher<CLLocation, AppError> {
        return Future<CLLocation, AppError> { promise in
            self.locationManager.getCurrentLocation { result in
                switch result {
                case .success(let location):
                    promise(.success(location))
                case .failure(let error):
                    if let appError = error as? AppError {
                        promise(.failure(appError))
                    } else {
                        promise(.failure(AppError.locationUpdateFailed))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getLocationHistory(startDate: Date, endDate: Date) -> AnyPublisher<[LocationHistory], AppError> {
        return provider.requestPublisher(
            .getLocationHistory(startDate: startDate, endDate: endDate)
        )
        .map([LocationHistoryDTO].self)
        .map { $0.map { $0.toEntity() } }
        .mapError { _ in AppError.networkError("위치 기록 조회 실패") }
        .eraseToAnyPublisher()
    }
    
    func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }
    
    func getRoute(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> AnyPublisher<Route, AppError> {
        // TODO: 실제 네이버/카카오 맵 API 연동 필요
        // 임시로 직선 거리를 계산하여 반환
        let distance = calculateDistance(from: from, to: to)
        let estimatedDuration = distance / 10 // 10m/s 속도로 가정
        
        let route = Route(
            distance: distance,
            duration: estimatedDuration,
            polyline: "", // 실제 polyline 데이터는 맵 API에서 받아와야 함
            waypoints: [from, to]
        )
        
        return Just(route)
            .setFailureType(to: AppError.self)
            .eraseToAnyPublisher()
    }
}

// MARK: - DTOs

struct LocationHistoryDTO: Codable {
    let timestamp: Date
    let latitude: Double
    let longitude: Double
    let accuracy: Double
    let speed: Double?
    let heading: Double?
    
    func toEntity() -> LocationHistory {
        LocationHistory(
            timestamp: timestamp,
            coordinate: CLLocationCoordinate2D(
                latitude: latitude,
                longitude: longitude
            ),
            accuracy: accuracy,
            speed: speed,
            heading: heading
        )
    }
}