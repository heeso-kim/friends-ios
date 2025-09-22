import Foundation

/// 앱 전역 에러 타입
enum AppError: LocalizedError, Equatable {
    // Network
    case networkError(String)
    case noInternetConnection
    case timeout
    case invalidResponse
    case serverError(code: Int, message: String?)

    // Authentication
    case unauthorized
    case invalidCredentials
    case tokenExpired
    case logoutFailed
    case accountSuspended
    case accountTerminated
    case accountPending

    // Validation
    case invalidInput(field: String, reason: String)
    case missingRequiredField(field: String)

    // Data
    case decodingError(String)
    case encodingError(String)
    case dataNotFound

    // Location
    case locationPermissionDenied
    case locationServiceDisabled
    case locationUpdateFailed

    // Order
    case orderNotFound
    case orderAlreadyAccepted
    case orderCannotBeModified

    // Payment
    case insufficientBalance
    case paymentFailed(reason: String)

    // General
    case unknown(String)
    case cancelled

    var errorDescription: String? {
        switch self {
        // Network
        case .networkError(let message):
            return "네트워크 오류: \(message)"
        case .noInternetConnection:
            return "인터넷 연결을 확인해주세요"
        case .timeout:
            return "요청 시간이 초과되었습니다"
        case .invalidResponse:
            return "잘못된 응답입니다"
        case .serverError(let code, let message):
            return message ?? "서버 오류 (\(code))"

        // Authentication
        case .unauthorized:
            return "인증이 필요합니다"
        case .invalidCredentials:
            return "아이디 또는 비밀번호가 올바르지 않습니다"
        case .tokenExpired:
            return "세션이 만료되었습니다. 다시 로그인해주세요"
        case .logoutFailed:
            return "로그아웃에 실패했습니다"
        case .accountSuspended:
            return "계정이 일시정지되었습니다. 고객센터에 문의해주세요"
        case .accountTerminated:
            return "계정이 종료되었습니다. 고객센터에 문의해주세요"
        case .accountPending:
            return "계정 승인 대기 중입니다"

        // Validation
        case .invalidInput(let field, let reason):
            return "\(field): \(reason)"
        case .missingRequiredField(let field):
            return "\(field)을(를) 입력해주세요"

        // Data
        case .decodingError(let message):
            return "데이터 처리 오류: \(message)"
        case .encodingError(let message):
            return "데이터 변환 오류: \(message)"
        case .dataNotFound:
            return "데이터를 찾을 수 없습니다"

        // Location
        case .locationPermissionDenied:
            return "위치 권한이 필요합니다"
        case .locationServiceDisabled:
            return "위치 서비스를 활성화해주세요"
        case .locationUpdateFailed:
            return "위치 업데이트에 실패했습니다"

        // Order
        case .orderNotFound:
            return "주문을 찾을 수 없습니다"
        case .orderAlreadyAccepted:
            return "이미 수락된 주문입니다"
        case .orderCannotBeModified:
            return "변경할 수 없는 주문입니다"

        // Payment
        case .insufficientBalance:
            return "잔액이 부족합니다"
        case .paymentFailed(let reason):
            return "결제 실패: \(reason)"

        // General
        case .unknown(let message):
            return message.isEmpty ? "알 수 없는 오류가 발생했습니다" : message
        case .cancelled:
            return "작업이 취소되었습니다"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .noInternetConnection:
            return "Wi-Fi 또는 모바일 데이터 연결을 확인하고 다시 시도해주세요"
        case .tokenExpired, .unauthorized:
            return "다시 로그인해주세요"
        case .locationPermissionDenied:
            return "설정 > 개인정보 보호 > 위치 서비스에서 권한을 허용해주세요"
        case .locationServiceDisabled:
            return "설정에서 위치 서비스를 켜주세요"
        default:
            return nil
        }
    }

    var isRetryable: Bool {
        switch self {
        case .networkError, .timeout, .serverError:
            return true
        case .tokenExpired:
            return false // Should refresh token instead
        default:
            return false
        }
    }

    var shouldShowAlert: Bool {
        switch self {
        case .noInternetConnection, .timeout:
            return false // Handle with toast or inline message
        case .invalidCredentials, .accountSuspended, .accountTerminated:
            return true // Important user alerts
        default:
            return true
        }
    }

    var priority: ErrorPriority {
        switch self {
        case .accountSuspended, .accountTerminated, .unauthorized:
            return .critical
        case .invalidCredentials, .tokenExpired:
            return .high
        case .networkError, .serverError:
            return .medium
        case .timeout, .noInternetConnection:
            return .low
        default:
            return .medium
        }
    }
}

enum ErrorPriority: Int, Comparable {
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4

    static func < (lhs: ErrorPriority, rhs: ErrorPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}