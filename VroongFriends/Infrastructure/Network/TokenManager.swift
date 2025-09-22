import Foundation

/// 토큰 관리 매니저 (싱글톤)
final class TokenManager {
    static let shared = TokenManager()
    
    private let keychainService: KeychainServiceProtocol
    private let tokenKey = "authToken"
    
    private init(keychainService: KeychainServiceProtocol = KeychainService()) {
        self.keychainService = keychainService
    }
    
    var accessToken: String? {
        get {
            try? keychainService.getToken()?.accessToken
        }
    }
    
    var refreshToken: String? {
        get {
            try? keychainService.getToken()?.refreshToken
        }
    }
    
    var authToken: AuthToken? {
        get {
            try? keychainService.getToken()
        }
        set {
            if let token = newValue {
                try? keychainService.saveToken(token)
            } else {
                try? keychainService.deleteToken()
            }
        }
    }
    
    func hasValidToken() -> Bool {
        guard let token = authToken else { return false }
        return !token.isExpired
    }
    
    func clearToken() {
        try? keychainService.deleteToken()
    }
}