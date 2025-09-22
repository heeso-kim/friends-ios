import Foundation
import Combine
import Moya

/// 인증 리포지토리 구현체
final class AuthRepository: AuthRepositoryProtocol {
    private let provider: MoyaProvider<FriendsAPI>
    private let keychainService: KeychainServiceProtocol
    private var currentToken: AuthToken?
    
    init(
        provider: MoyaProvider<FriendsAPI>,
        keychainService: KeychainServiceProtocol
    ) {
        self.provider = provider
        self.keychainService = keychainService
        self.currentToken = try? keychainService.getToken()
    }
    
    func login(username: String, password: String) -> AnyPublisher<AuthToken, AppError> {
        return provider.requestPublisher(.login(username: username, password: password))
            .map(AuthTokenDTO.self)
            .map { dto in
                AuthToken(
                    accessToken: dto.accessToken,
                    refreshToken: dto.refreshToken,
                    expiresIn: dto.expiresIn,
                    tokenType: dto.tokenType,
                    issuedAt: Date()
                )
            }
            .handleEvents(receiveOutput: { [weak self] token in
                self?.currentToken = token
                try? self?.keychainService.saveToken(token)
            })
            .mapError { error in
                if let moyaError = error as? MoyaError {
                    switch moyaError {
                    case .statusCode(let response):
                        if response.statusCode == 401 {
                            return AppError.invalidCredentials
                        }
                        return AppError.serverError(code: response.statusCode, message: nil)
                    case .underlying(let underlyingError, _):
                        if (underlyingError as NSError).code == NSURLErrorNotConnectedToInternet {
                            return AppError.noInternetConnection
                        }
                        return AppError.networkError(underlyingError.localizedDescription)
                    default:
                        return AppError.networkError(moyaError.localizedDescription)
                    }
                }
                return AppError.unknown(error.localizedDescription)
            }
            .eraseToAnyPublisher()
    }
    
    func logout() -> AnyPublisher<Void, AppError> {
        return provider.requestPublisher(.logout)
            .map { _ in () }
            .handleEvents(receiveCompletion: { [weak self] _ in
                self?.currentToken = nil
                try? self?.keychainService.deleteToken()
            })
            .mapError { _ in AppError.logoutFailed }
            .eraseToAnyPublisher()
    }
    
    func refreshToken() -> AnyPublisher<AuthToken, AppError> {
        guard let refreshToken = currentToken?.refreshToken else {
            return Fail(error: AppError.tokenExpired)
                .eraseToAnyPublisher()
        }
        
        return provider.requestPublisher(.refreshToken(refreshToken: refreshToken))
            .map(AuthTokenDTO.self)
            .map { dto in
                AuthToken(
                    accessToken: dto.accessToken,
                    refreshToken: dto.refreshToken,
                    expiresIn: dto.expiresIn,
                    tokenType: dto.tokenType,
                    issuedAt: Date()
                )
            }
            .handleEvents(receiveOutput: { [weak self] token in
                self?.currentToken = token
                try? self?.keychainService.saveToken(token)
            })
            .mapError { _ in AppError.tokenExpired }
            .eraseToAnyPublisher()
    }
    
    func validateToken(_ token: String) -> AnyPublisher<Bool, AppError> {
        return provider.requestPublisher(.validateToken(token: token))
            .map { _ in true }
            .replaceError(with: false)
            .setFailureType(to: AppError.self)
            .eraseToAnyPublisher()
    }
    
    func getCurrentToken() -> AuthToken? {
        return currentToken
    }
    
    func saveToken(_ token: AuthToken) -> AnyPublisher<Void, AppError> {
        return Future<Void, AppError> { [weak self] promise in
            do {
                try self?.keychainService.saveToken(token)
                self?.currentToken = token
                promise(.success(()))
            } catch {
                promise(.failure(AppError.unknown("토큰 저장 실패")))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func clearToken() -> AnyPublisher<Void, AppError> {
        return Future<Void, AppError> { [weak self] promise in
            do {
                try self?.keychainService.deleteToken()
                self?.currentToken = nil
                promise(.success(()))
            } catch {
                promise(.failure(AppError.unknown("토큰 삭제 실패")))
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - DTO

struct AuthTokenDTO: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int
    let tokenType: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}