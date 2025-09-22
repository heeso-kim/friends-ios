import Foundation
import CoreLocation

/// 지도 매니저 프로토콜
protocol MapManagerProtocol {
    func initialize(with config: MapConfiguration)
    func showRoute(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D)
    func addMarker(at coordinate: CLLocationCoordinate2D, type: MarkerType)
    func removeAllMarkers()
    func centerMap(at coordinate: CLLocationCoordinate2D, zoomLevel: Double)
    func getCurrentLocation() -> CLLocationCoordinate2D?
}

/// 지도 설정
struct MapConfiguration {
    let apiKey: String
    let enableUserLocation: Bool
    let enableCompass: Bool
    let enableZoomControls: Bool
    let initialZoomLevel: Double

    init(
        apiKey: String,
        enableUserLocation: Bool = true,
        enableCompass: Bool = true,
        enableZoomControls: Bool = true,
        initialZoomLevel: Double = 14.0
    ) {
        self.apiKey = apiKey
        self.enableUserLocation = enableUserLocation
        self.enableCompass = enableCompass
        self.enableZoomControls = enableZoomControls
        self.initialZoomLevel = initialZoomLevel
    }
}

/// 마커 타입
enum MarkerType {
    case pickup
    case delivery
    case currentLocation
    case restaurant
    case customer

    var imageName: String {
        switch self {
        case .pickup: return "map_marker_pickup"
        case .delivery: return "map_marker_delivery"
        case .currentLocation: return "map_marker_current"
        case .restaurant: return "map_marker_restaurant"
        case .customer: return "map_marker_customer"
        }
    }

    var color: String {
        switch self {
        case .pickup: return "#007AFF"
        case .delivery: return "#FF3B30"
        case .currentLocation: return "#34C759"
        case .restaurant: return "#FF9500"
        case .customer: return "#AF52DE"
        }
    }
}

/// 지도 매니저 팩토리
class MapManagerFactory {
    enum MapProvider {
        case naver
        case kakao
        case apple  // Fallback option
    }

    static func createMapManager(provider: MapProvider) -> MapManagerProtocol {
        switch provider {
        case .naver:
            return NaverMapManager()
        case .kakao:
            return KakaoMapManager()
        case .apple:
            return AppleMapManager()
        }
    }
}