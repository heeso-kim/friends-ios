import Foundation

extension AppError {
    var shouldRetry: Bool {
        switch self {
        case .networkError, .timeout, .noInternetConnection:
            return true
        case .serverError(let code, _):
            return code >= 500
        case .tokenExpired:
            return false
        default:
            return false
        }
    }

    var retryDelay: TimeInterval {
        switch self {
        case .networkError, .noInternetConnection:
            return 2.0
        case .timeout:
            return 1.0
        case .serverError:
            return 3.0
        default:
            return 1.0
        }
    }

    var isNetworkRelated: Bool {
        switch self {
        case .networkError, .noInternetConnection, .timeout, .serverError:
            return true
        default:
            return false
        }
    }

    var userFriendlyMessage: String {
        switch self {
        case .noInternetConnection:
            return "인터넷 연결을 확인해주세요"
        case .timeout:
            return "요청 시간이 초과되었습니다"
        case .serverError(_, let message):
            return message ?? "서버에 문제가 발생했습니다"
        case .invalidCredentials:
            return "아이디 또는 비밀번호를 확인해주세요"
        case .tokenExpired:
            return "다시 로그인해주세요"
        case .accountSuspended:
            return "계정이 일시정지되었습니다"
        case .accountTerminated:
            return "계정이 종료되었습니다"
        case .accountPending:
            return "계정 승인 대기 중입니다"
        default:
            return errorDescription ?? "알 수 없는 오류가 발생했습니다"
        }
    }
}