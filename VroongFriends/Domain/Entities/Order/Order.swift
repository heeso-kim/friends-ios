import Foundation
import CoreLocation

/// 주문 도메인 모델
struct Order: Codable, Equatable, Identifiable {
    let id: String
    let orderNumber: String
    let status: OrderStatus
    let type: OrderType

    // 고객 정보
    let customer: Customer

    // 픽업 정보
    let pickupLocation: Location
    let pickupTime: Date?
    let pickupNote: String?

    // 배송 정보
    let deliveryLocation: Location
    let deliveryTime: Date?
    let deliveryNote: String?

    // 상품 정보
    let items: [OrderItem]

    // 금액 정보
    let payment: Payment

    // 배정 정보
    let assignedAgent: Agent?
    let assignedAt: Date?
    let acceptedAt: Date?
    let completedAt: Date?

    // 거리 및 시간
    let estimatedDistance: Double? // 미터
    let estimatedDuration: Int? // 초
    let actualDistance: Double?
    let actualDuration: Int?

    // 타임스탬프
    let createdAt: Date
    let updatedAt: Date

    // 계산 프로퍼티
    var isAcceptable: Bool {
        status == .pending || status == .assigned
    }

    var isInProgress: Bool {
        status == .accepted || status == .pickingUp || status == .delivering
    }

    var isCompleted: Bool {
        status == .completed || status == .cancelled
    }

    var totalAmount: Decimal {
        payment.totalAmount
    }

    var estimatedDistanceKm: Double? {
        guard let distance = estimatedDistance else { return nil }
        return distance / 1000
    }

    var estimatedDurationMinutes: Int? {
        guard let duration = estimatedDuration else { return nil }
        return duration / 60
    }
}

// MARK: - Order Status

enum OrderStatus: String, Codable, CaseIterable {
    case pending = "PENDING"          // 대기중
    case assigned = "ASSIGNED"        // 배정됨
    case accepted = "ACCEPTED"        // 수락됨
    case pickingUp = "PICKING_UP"     // 픽업중
    case delivering = "DELIVERING"    // 배송중
    case completed = "COMPLETED"      // 완료
    case cancelled = "CANCELLED"      // 취소됨

    var displayName: String {
        switch self {
        case .pending: return "대기중"
        case .assigned: return "배정됨"
        case .accepted: return "수락됨"
        case .pickingUp: return "픽업중"
        case .delivering: return "배송중"
        case .completed: return "완료"
        case .cancelled: return "취소"
        }
    }

    var color: String {
        switch self {
        case .pending: return "#9E9E9E"
        case .assigned: return "#2196F3"
        case .accepted: return "#FF9800"
        case .pickingUp: return "#FFC107"
        case .delivering: return "#4CAF50"
        case .completed: return "#8BC34A"
        case .cancelled: return "#F44336"
        }
    }

    var icon: String {
        switch self {
        case .pending: return "⏳"
        case .assigned: return "📋"
        case .accepted: return "✅"
        case .pickingUp: return "📦"
        case .delivering: return "🚚"
        case .completed: return "✔️"
        case .cancelled: return "❌"
        }
    }
}

// MARK: - Order Type

enum OrderType: String, Codable, CaseIterable {
    case normal = "NORMAL"
    case express = "EXPRESS"
    case scheduled = "SCHEDULED"
    case subscription = "SUBSCRIPTION"

    var displayName: String {
        switch self {
        case .normal: return "일반"
        case .express: return "급송"
        case .scheduled: return "예약"
        case .subscription: return "정기"
        }
    }

    var icon: String {
        switch self {
        case .normal: return "📦"
        case .express: return "⚡"
        case .scheduled: return "📅"
        case .subscription: return "🔄"
        }
    }
}

// MARK: - Customer

struct Customer: Codable, Equatable {
    let id: String
    let name: String
    let phoneNumber: String
    let email: String?
    let isVip: Bool

    var maskedPhoneNumber: String {
        guard phoneNumber.count >= 8 else { return phoneNumber }
        let startIndex = phoneNumber.index(phoneNumber.startIndex, offsetBy: 3)
        let endIndex = phoneNumber.index(phoneNumber.endIndex, offsetBy: -4)
        let middleRange = startIndex..<endIndex
        return phoneNumber.replacingCharacters(in: middleRange, with: "****")
    }
}

// MARK: - Location

struct Location: Codable, Equatable {
    let id: String?
    let address: String
    let detailAddress: String?
    let coordinate: Coordinate
    let note: String?
    let contactName: String?
    let contactPhone: String?

    var fullAddress: String {
        if let detail = detailAddress, !detail.isEmpty {
            return "\(address) \(detail)"
        }
        return address
    }

    var clLocation: CLLocation {
        CLLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
    }
}

// MARK: - Coordinate

struct Coordinate: Codable, Equatable {
    let latitude: Double
    let longitude: Double

    var isValid: Bool {
        latitude >= -90 && latitude <= 90 &&
        longitude >= -180 && longitude <= 180
    }
}

// MARK: - Order Item

struct OrderItem: Codable, Equatable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let quantity: Int
    let price: Decimal
    let imageUrl: String?

    var totalPrice: Decimal {
        price * Decimal(quantity)
    }
}

// MARK: - Payment

struct Payment: Codable, Equatable {
    let method: PaymentMethod
    let baseAmount: Decimal
    let deliveryFee: Decimal
    let tip: Decimal
    let discount: Decimal
    let totalAmount: Decimal
    let isPaid: Bool
    let paidAt: Date?

    enum PaymentMethod: String, Codable, CaseIterable {
        case cash = "CASH"
        case card = "CARD"
        case prepaid = "PREPAID"
        case postpaid = "POSTPAID"

        var displayName: String {
            switch self {
            case .cash: return "현금"
            case .card: return "카드"
            case .prepaid: return "선결제"
            case .postpaid: return "후결제"
            }
        }

        var icon: String {
            switch self {
            case .cash: return "💵"
            case .card: return "💳"
            case .prepaid: return "✅"
            case .postpaid: return "📋"
            }
        }
    }
}

// MARK: - Agent

struct Agent: Codable, Equatable {
    let id: String
    let name: String
    let phoneNumber: String
    let vehicleType: Vehicle.VehicleType
    let profileImageUrl: String?
}

// MARK: - Mock Data

#if DEBUG
extension Order {
    static let mock = Order(
        id: "order123",
        orderNumber: "ORD-2024-001",
        status: .pending,
        type: .normal,
        customer: Customer(
            id: "cust123",
            name: "김고객",
            phoneNumber: "010-1234-5678",
            email: "customer@example.com",
            isVip: false
        ),
        pickupLocation: Location(
            id: "loc1",
            address: "서울특별시 강남구 테헤란로 123",
            detailAddress: "5층",
            coordinate: Coordinate(latitude: 37.5665, longitude: 126.9780),
            note: "1층 로비에서 픽업",
            contactName: "픽업담당자",
            contactPhone: "010-1111-2222"
        ),
        deliveryLocation: Location(
            id: "loc2",
            address: "서울특별시 서초구 서초대로 456",
            detailAddress: "B동 1004호",
            coordinate: Coordinate(latitude: 37.4900, longitude: 127.0100),
            note: "문 앞에 두고 가주세요",
            contactName: "수령인",
            contactPhone: "010-3333-4444"
        ),
        items: [
            OrderItem(
                id: "item1",
                name: "상품 A",
                description: "상품 설명",
                quantity: 2,
                price: 10000,
                imageUrl: nil
            )
        ],
        payment: Payment(
            method: .card,
            baseAmount: 20000,
            deliveryFee: 3000,
            tip: 1000,
            discount: 0,
            totalAmount: 24000,
            isPaid: false,
            paidAt: nil
        ),
        assignedAgent: nil,
        assignedAt: nil,
        acceptedAt: nil,
        completedAt: nil,
        estimatedDistance: 5000,
        estimatedDuration: 900,
        actualDistance: nil,
        actualDuration: nil,
        createdAt: Date(),
        updatedAt: Date()
    )
}
#endif