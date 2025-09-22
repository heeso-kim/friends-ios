import Foundation
import Security

/// Keychain 서비스 프로토콜
protocol KeychainServiceProtocol {
    func saveToken(_ token: AuthToken) throws
    func getToken() throws -> AuthToken?
    func deleteToken() throws
    func saveCredentials(username: String, password: String) throws
    func getCredentials() throws -> (username: String, password: String)?
    func deleteCredentials() throws
}

/// Keychain 서비스 구현체
final class KeychainService: KeychainServiceProtocol {
    private let service = Bundle.main.bundleIdentifier ?? "com.vroong.friends"
    private let tokenKey = "authToken"
    private let credentialsKey = "credentials"
    
    // MARK: - Token Management
    
    func saveToken(_ token: AuthToken) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(token)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenKey,
            kSecValueData as String: data
        ]
        
        // 기존 항목 삭제
        SecItemDelete(query as CFDictionary)
        
        // 새 항목 추가
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    func getToken() throws -> AuthToken? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw KeychainError.unhandledError(status: status)
        }
        
        guard let data = dataTypeRef as? Data else {
            throw KeychainError.unexpectedData
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(AuthToken.self, from: data)
    }
    
    func deleteToken() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenKey
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    // MARK: - Credentials Management
    
    func saveCredentials(username: String, password: String) throws {
        let credentials = ["username": username, "password": password]
        let data = try JSONSerialization.data(withJSONObject: credentials, options: [])
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: credentialsKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    func getCredentials() throws -> (username: String, password: String)? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: credentialsKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw KeychainError.unhandledError(status: status)
        }
        
        guard let data = dataTypeRef as? Data,
              let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String],
              let username = json["username"],
              let password = json["password"] else {
            throw KeychainError.unexpectedData
        }
        
        return (username, password)
    }
    
    func deleteCredentials() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: credentialsKey
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
}

// MARK: - Keychain Error

enum KeychainError: LocalizedError {
    case unexpectedData
    case unhandledError(status: OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .unexpectedData:
            return "Keychain에서 예상치 못한 데이터를 받았습니다"
        case .unhandledError(let status):
            return "Keychain 오류: \(status)"
        }
    }
}