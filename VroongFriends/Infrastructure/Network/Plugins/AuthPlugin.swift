import Foundation
import Moya

/// 인증 플러그인 - 자동으로 Authorization 헤더 추가
struct AuthPlugin: PluginType {
    private let tokenManager: TokenManager
    
    init(tokenManager: TokenManager = .shared) {
        self.tokenManager = tokenManager
    }
    
    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        var request = request
        
        // 로그인, 리프레시 토큰 엔드포인트는 토큰 불필요
        if let api = target as? FriendsAPI {
            switch api {
            case .login, .refreshToken:
                return request
            default:
                break
            }
        }
        
        // 토큰 추가
        if let token = tokenManager.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
        switch result {
        case .success(let response):
            // 401 Unauthorized 처리
            if response.statusCode == 401 {
                handleUnauthorized()
            }
        case .failure:
            break
        }
    }
    
    private func handleUnauthorized() {
        // 토큰 삭제 및 로그인 화면으로 이동
        tokenManager.clearToken()
        
        // 로그인 화면으로 이동 이벤트 발송
        NotificationCenter.default.post(
            name: .authTokenExpired,
            object: nil
        )
    }
}

extension Notification.Name {
    static let authTokenExpired = Notification.Name("authTokenExpired")
}