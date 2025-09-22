import Foundation

/// 환경 설정 (Flutter와 동일한 flavor 체계)
class Environment {
    static let shared = Environment()

    private init() {}
    enum Flavor: String {
        case dev1 = "dev1"
        case qa1 = "qa1"
        case qa2 = "qa2"
        case qa3 = "qa3"
        case qa4 = "qa4"
        case prod = "prod"
    }
    
    // Build Configuration에서 설정됨
    // Xcode Build Settings에서 FLAVOR 값으로 주입
    var flavor: Flavor {
        #if DEV1
        return .dev1
        #elseif QA1
        return .qa1
        #elseif QA2
        return .qa2
        #elseif QA3
        return .qa3
        #elseif QA4
        return .qa4
        #elseif PROD
        return .prod
        #else
        return .dev1 // 기본값
        #endif
    }
    
    var apiBaseURL: String {
        switch flavor {
        case .dev1:
            return "https://dev1-api-v2-vroong.meshdev.io/"
        case .qa1:
            return "https://qa.api-v2.vroong.com/"
        case .qa2:
            return "https://qa2-api-v2-vroong.meshdev.io/"
        case .qa3:
            return "https://qa3-api-v2-vroong.meshdev.io/"
        case .qa4:
            return "https://qa4-api-v2-vroong.meshdev.io/"
        case .prod:
            return "https://api-v2.vroong.com/"
        }
    }
    
    var socketURL: String {
        switch flavor {
        case .dev1:
            return "wss://dev1-socket.vroong-friends.com"
        case .qa1:
            return "wss://qa1-socket.vroong-friends.com"
        case .qa2:
            return "wss://qa2-socket.vroong-friends.com"
        case .qa3:
            return "wss://qa3-socket.vroong-friends.com"
        case .qa4:
            return "wss://qa4-socket.vroong-friends.com"
        case .prod:
            return "wss://socket.vroong-friends.com"
        }
    }
    
    var sendbirdAppId: String {
        switch flavor {
        case .dev1, .qa1, .qa2, .qa3, .qa4:
            return "7C7FA4F5-8A77-4BF1-8F65-2F9C19E67E9A" // 실제 Sendbird App ID로 교체 필요
        case .prod:
            return "B3A7F892-1234-4567-8901-234567890123" // 실제 Sendbird App ID로 교체 필요
        }
    }
    
    var naverMapClientId: String {
        switch flavor {
        case .dev1, .qa1, .qa2, .qa3, .qa4:
            return "abcu9spfbt" // NCP Key ID from Flutter
        case .prod:
            return "xr4pe9773q" // NCP Key ID from Flutter
        }
    }
    
    var kakaoAppKey: String {
        // 모든 환경에서 동일한 키 사용
        return "162af280c7bd10abdab2630f32382e84"
    }
    
    var isDebugMode: Bool {
        switch flavor {
        case .prod:
            return false
        default:
            return true
        }
    }
    
    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "com.vroong.friends"
    }

    // 추가 API URLs (Flutter에서 가져온 설정)
    var eventCollectorURL: String {
        switch flavor {
        case .dev1, .qa1, .qa2, .qa3, .qa4:
            return "https://yl7i7img9l.execute-api.ap-northeast-2.amazonaws.com/dev/"
        case .prod:
            return "https://goky9s8r27.execute-api.ap-northeast-2.amazonaws.com/prod/"
        }
    }

    var logCollectorURL: String {
        switch flavor {
        case .dev1:
            return "https://va.dev1.meshdev.io/"
        case .qa1:
            return "https://va.dev1.meshdev.io/"
        case .qa2, .qa3, .qa4:
            return "https://va.dev1.meshdev.io/" // QA 환경들도 dev1과 동일
        case .prod:
            return "https://va.msa.vroong.com/"
        }
    }

    var imageUploadURL: String {
        switch flavor {
        case .dev1:
            return "https://vroong-image-upload.meshdev.io/dev/"
        case .qa1, .qa2, .qa3, .qa4:
            return "https://vroong-image-upload.meshdev.io/qa/"
        case .prod:
            return "https://image-upload.vroong.com/"
        }
    }

    var dataHostURL: String {
        switch flavor {
        case .dev1:
            return "https://agent-data.dev1.meshdev.io/"
        case .qa1:
            return "https://agent-data.qa1.meshdev.io/"
        case .qa2:
            return "https://agent-data.qa2.meshdev.io/"
        case .qa3:
            return "https://agent-data.qa3.meshdev.io/"
        case .qa4:
            return "https://agent-data.qa4.meshdev.io/"
        case .prod:
            return "https://api-gateway.vroong.com/prod/"
        }
    }

    var certURL: String {
        switch flavor {
        case .dev1:
            return "http://dev.kmc-cert.vroong.com/common/flutter/cert/form"
        case .qa1, .qa2, .qa3, .qa4:
            return "http://qa.kmc-cert.vroong.com/common/flutter/cert/form"
        case .prod:
            return "https://kmc-cert.vroong.com/common/flutter/cert/form"
        }
    }
}