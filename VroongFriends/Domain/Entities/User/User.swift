import Foundation

/// 사용자 도메인 모델
struct User: Codable, Equatable, Identifiable {
    let id: String
    let username: String
    let displayName: String
    let email: String?
    let phoneNumber: String?
    let profileImageUrl: String?
    let agentId: String?
    let agentStatus: AgentStatus
    let employmentStatus: EmploymentStatus
    let createdAt: Date
    let updatedAt: Date

    // 운전면허 정보
    let driverLicense: DriverLicense?

    // 차량 정보
    let vehicle: Vehicle?

    // 권한
    let permissions: Set<Permission>

    // 계산 프로퍼티
    var isActive: Bool {
        agentStatus == .active
    }

    var canAcceptOrders: Bool {
        isActive && driverLicense?.isValid == true
    }

    var fullName: String {
        displayName.isEmpty ? username : displayName
    }
}

// MARK: - Agent Status

enum AgentStatus: String, Codable, CaseIterable {
    case pending = "PENDING"
    case active = "ACTIVE"
    case suspended = "SUSPENDED"
    case terminated = "TERMINATED"

    var displayName: String {
        switch self {
        case .pending: return "대기중"
        case .active: return "활동중"
        case .suspended: return "일시정지"
        case .terminated: return "종료"
        }
    }

    var color: String {
        switch self {
        case .pending: return "#FFA500"
        case .active: return "#4CAF50"
        case .suspended: return "#FF9800"
        case .terminated: return "#F44336"
        }
    }
}

// MARK: - Employment Status

enum EmploymentStatus: String, Codable, CaseIterable {
    case fullTime = "FULL_TIME"
    case partTime = "PART_TIME"
    case contract = "CONTRACT"
    case freelance = "FREELANCE"

    var displayName: String {
        switch self {
        case .fullTime: return "정규직"
        case .partTime: return "파트타임"
        case .contract: return "계약직"
        case .freelance: return "프리랜서"
        }
    }
}

// MARK: - Driver License

struct DriverLicense: Codable, Equatable {
    let licenseNumber: String
    let licenseType: LicenseType
    let issuedDate: Date
    let expiryDate: Date
    let isVerified: Bool

    var isValid: Bool {
        isVerified && expiryDate > Date()
    }

    var isExpiringSoon: Bool {
        let daysUntilExpiry = Calendar.current.dateComponents(
            [.day],
            from: Date(),
            to: expiryDate
        ).day ?? 0
        return daysUntilExpiry <= 30 && daysUntilExpiry > 0
    }

    enum LicenseType: String, Codable {
        case type1 = "TYPE_1"  // 1종
        case type2 = "TYPE_2"  // 2종

        var displayName: String {
            switch self {
            case .type1: return "1종 보통"
            case .type2: return "2종 보통"
            }
        }
    }
}

// MARK: - Vehicle

struct Vehicle: Codable, Equatable {
    let id: String
    let type: VehicleType
    let licensePlate: String
    let manufacturer: String?
    let model: String?
    let year: Int?
    let color: String?
    let isVerified: Bool

    enum VehicleType: String, Codable, CaseIterable {
        case motorcycle = "MOTORCYCLE"
        case car = "CAR"
        case van = "VAN"
        case truck = "TRUCK"

        var displayName: String {
            switch self {
            case .motorcycle: return "오토바이"
            case .car: return "승용차"
            case .van: return "밴"
            case .truck: return "트럭"
            }
        }

        var icon: String {
            switch self {
            case .motorcycle: return "🏍️"
            case .car: return "🚗"
            case .van: return "🚐"
            case .truck: return "🚚"
            }
        }
    }
}

// MARK: - Permission

enum Permission: String, Codable {
    case viewOrders = "VIEW_ORDERS"
    case acceptOrders = "ACCEPT_ORDERS"
    case completeOrders = "COMPLETE_ORDERS"
    case viewPayments = "VIEW_PAYMENTS"
    case requestWithdrawal = "REQUEST_WITHDRAWAL"
    case viewStatistics = "VIEW_STATISTICS"
    case manageProfile = "MANAGE_PROFILE"
}

// MARK: - Mock Data

#if DEBUG
extension User {
    static let mock = User(
        id: "user123",
        username: "testuser",
        displayName: "테스트 사용자",
        email: "test@vroong.com",
        phoneNumber: "010-1234-5678",
        profileImageUrl: nil,
        agentId: "agent123",
        agentStatus: .active,
        employmentStatus: .fullTime,
        createdAt: Date(),
        updatedAt: Date(),
        driverLicense: DriverLicense(
            licenseNumber: "12-123456-78",
            licenseType: .type1,
            issuedDate: Date().addingTimeInterval(-365 * 24 * 60 * 60),
            expiryDate: Date().addingTimeInterval(365 * 24 * 60 * 60),
            isVerified: true
        ),
        vehicle: Vehicle(
            id: "vehicle123",
            type: .motorcycle,
            licensePlate: "서울12가3456",
            manufacturer: "Honda",
            model: "PCX",
            year: 2023,
            color: "Black",
            isVerified: true
        ),
        permissions: [.viewOrders, .acceptOrders, .completeOrders, .viewPayments]
    )
}
#endif