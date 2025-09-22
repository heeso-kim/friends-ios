import Foundation
import CoreLocation

/// 배송 위치 도메인 모델
struct DeliveryLocation: Codable, Equatable, Identifiable {
    let id: String
    let name: String
    let address: Address
    let coordinate: CLLocationCoordinate2D
    let locationType: LocationType
    let isDefault: Bool
    let note: String?
    let createdAt: Date
    let updatedAt: Date
    
    // 계산 프로퍼티
    var fullAddress: String {
        address.fullAddress
    }
    
    var distance: Double? {
        // 현재 위치로부터의 거리 (미터)
        return nil // LocationManager에서 계산
    }
}

// MARK: - Address

struct Address: Codable, Equatable {
    let street: String
    let detail: String?
    let city: String
    let state: String
    let postalCode: String
    let country: String
    
    var fullAddress: String {
        var components = [street]
        if let detail = detail, !detail.isEmpty {
            components.append(detail)
        }
        components.append(contentsOf: [city, state, postalCode, country])
        return components.joined(separator: ", ")
    }
    
    var shortAddress: String {
        if let detail = detail, !detail.isEmpty {
            return "\(street) \(detail)"
        }
        return street
    }
}

// MARK: - Location Type

enum LocationType: String, Codable, CaseIterable {
    case home = "HOME"
    case office = "OFFICE"
    case store = "STORE"
    case restaurant = "RESTAURANT"
    case warehouse = "WAREHOUSE"
    case other = "OTHER"
    
    var displayName: String {
        switch self {
        case .home: return "집"
        case .office: return "사무실"
        case .store: return "매장"
        case .restaurant: return "음식점"
        case .warehouse: return "창고"
        case .other: return "기타"
        }
    }
    
    var icon: String {
        switch self {
        case .home: return "🏠"
        case .office: return "🏢"
        case .store: return "🏪"
        case .restaurant: return "🍽️"
        case .warehouse: return "📦"
        case .other: return "📍"
        }
    }
}

// MARK: - CLLocationCoordinate2D Extension

extension CLLocationCoordinate2D: Codable {
    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
}

// MARK: - Mock Data

#if DEBUG
extension DeliveryLocation {
    static let mock = DeliveryLocation(
        id: "loc123",
        name: "우리집",
        address: Address(
            street: "테헤란로 123",
            detail: "5층 501호",
            city: "서울특별시",
            state: "강남구",
            postalCode: "06234",
            country: "대한민국"
        ),
        coordinate: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
        locationType: .home,
        isDefault: true,
        note: "벨 누르지 말고 노크해주세요",
        createdAt: Date(),
        updatedAt: Date()
    )
}
#endif