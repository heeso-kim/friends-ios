import Foundation
import Moya
import Alamofire
import Combine

/// 네트워크 프로바이더
final class NetworkProvider {
    static let shared = NetworkProvider()
    
    private let session: Session
    let provider: MoyaProvider<FriendsAPI>
    
    private init() {
        // Session Configuration
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        
        // SSL Pinning (상용 환경에서만)
        var serverTrustManager: ServerTrustManager?
        if Environment.current == .prod {
            serverTrustManager = ServerTrustManager(evaluators: [
                "api.vroong-friends.com": PinnedCertificatesTrustEvaluator()
            ])
        }
        
        // Alamofire Session
        self.session = Session(
            configuration: configuration,
            serverTrustManager: serverTrustManager
        )
        
        // Plugins
        var plugins: [PluginType] = [
            AuthPlugin(),
            LoggerPlugin()
        ]
        
        // 개발 환경에서 Network Logger 추가
        #if DEBUG
        if Environment.isDebugMode {
            plugins.append(NetworkLoggerPlugin(
                configuration: .init(
                    logOptions: .verbose
                )
            ))
        }
        #endif
        
        // MoyaProvider
        self.provider = MoyaProvider<FriendsAPI>(
            session: session,
            plugins: plugins
        )
    }
    
    /// API 호출 후 자동 에러 처리
    func request<T: Decodable>(
        _ target: FriendsAPI,
        type: T.Type,
        decoder: JSONDecoder = JSONDecoder()
    ) -> AnyPublisher<T, AppError> {
        return provider.requestPublisher(target)
            .tryMap { response in
                // Status Code 확인
                guard (200...299).contains(response.statusCode) else {
                    if response.statusCode == 401 {
                        throw AppError.unauthorized
                    }
                    if response.statusCode == 404 {
                        throw AppError.dataNotFound
                    }
                    throw AppError.serverError(
                        code: response.statusCode,
                        message: self.extractErrorMessage(from: response.data)
                    )
                }
                return response.data
            }
            .decode(type: T.self, decoder: decoder)
            .mapError { error in
                if let appError = error as? AppError {
                    return appError
                }
                if error is DecodingError {
                    return AppError.decodingError(error.localizedDescription)
                }
                return AppError.networkError(error.localizedDescription)
            }
            .eraseToAnyPublisher()
    }
    
    /// 에러 메시지 추출
    private func extractErrorMessage(from data: Data) -> String? {
        struct ErrorResponse: Decodable {
            let message: String?
            let error: String?
        }
        
        if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
            return errorResponse.message ?? errorResponse.error
        }
        
        return nil
    }
}

// MARK: - Combine Extensions

extension MoyaProvider {
    func requestPublisher(_ target: Target) -> AnyPublisher<Response, MoyaError> {
        return Future { promise in
            self.request(target) { result in
                switch result {
                case .success(let response):
                    promise(.success(response))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}