import Foundation
import Combine

/// 인증 리포지토리 프로토콜
protocol AuthRepositoryProtocol {
    func login(username: String, password: String) -> AnyPublisher<AuthToken, AppError>
    func logout() -> AnyPublisher<Void, AppError>
    func refreshToken() -> AnyPublisher<AuthToken, AppError>
    func validateToken(_ token: String) -> AnyPublisher<Bool, AppError>
    func getCurrentToken() -> AuthToken?
    func saveToken(_ token: AuthToken) -> AnyPublisher<Void, AppError>
    func clearToken() -> AnyPublisher<Void, AppError>
}