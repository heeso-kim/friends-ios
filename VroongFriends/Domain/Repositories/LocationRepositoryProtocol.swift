import Foundation
import Combine
import CoreLocation

/// 위치 리포지토리 프로토콜
protocol LocationRepositoryProtocol {
    func updateLocation(_ location: CLLocation) -> AnyPublisher<Void, AppError>
    func startLocationTracking() -> AnyPublisher<Void, AppError>
    func stopLocationTracking() -> AnyPublisher<Void, AppError>
    func getCurrentLocation() -> AnyPublisher<CLLocation, AppError>
    func getLocationHistory(startDate: Date, endDate: Date) -> AnyPublisher<[LocationHistory], AppError>
    func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double
    func getRoute(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> AnyPublisher<Route, AppError>
}

/// 위치 기록
struct LocationHistory: Codable, Equatable {
    let timestamp: Date
    let coordinate: CLLocationCoordinate2D
    let accuracy: Double
    let speed: Double?
    let heading: Double?
}

/// 경로 정보
struct Route: Codable, Equatable {
    let distance: Double // 미터
    let duration: TimeInterval // 초
    let polyline: String // 인코딩된 폴리라인
    let waypoints: [CLLocationCoordinate2D]
}