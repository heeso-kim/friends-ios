import Foundation
import Combine

/// 로그인 유스케이스
protocol LoginUseCaseProtocol {
    func execute(username: String, password: String) -> AnyPublisher<User, AppError>
    func logout() -> AnyPublisher<Void, AppError>
}

final class LoginUseCase: LoginUseCaseProtocol {
    private let authRepository: AuthRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    
    init(
        authRepository: AuthRepositoryProtocol,
        userRepository: UserRepositoryProtocol
    ) {
        self.authRepository = authRepository
        self.userRepository = userRepository
    }
    
    func execute(username: String, password: String) -> AnyPublisher<User, AppError> {
        // Validate inputs
        guard !username.isEmpty else {
            return Fail(error: AppError.missingRequiredField(field: "사용자명"))
                .eraseToAnyPublisher()
        }

        guard !password.isEmpty else {
            return Fail(error: AppError.missingRequiredField(field: "비밀번호"))
                .eraseToAnyPublisher()
        }

        // Perform login
        return authRepository.login(username: username, password: password)
            .flatMap { [weak self] authToken -> AnyPublisher<User, AppError> in
                guard let self = self else {
                    return Fail(error: AppError.unknown("예상치 못한 오류"))
                        .eraseToAnyPublisher()
                }

                // Fetch user profile
                return self.userRepository.getCurrentUser()
            }
            .flatMap { [weak self] user -> AnyPublisher<User, AppError> in
                guard let self = self else {
                    return Fail(error: AppError.unknown("예상치 못한 오류"))
                        .eraseToAnyPublisher()
                }

                // Validate user status
                return self.validateUserStatus(user)
            }
            .flatMap { [weak self] user -> AnyPublisher<User, AppError> in
                guard let self = self else {
                    return Fail(error: AppError.unknown("예상치 못한 오류"))
                        .eraseToAnyPublisher()
                }

                // Setup post-login requirements
                return self.setupPostLoginRequirements(user)
            }
            .handleEvents(receiveOutput: { user in
                Logger.info("로그인 성공: \(user.username)", category: .auth)
            }, receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("로그인 실패: \(error.localizedDescription)", category: .auth)
                }
            })
            .eraseToAnyPublisher()
    }

    // MARK: - Private Methods

    private func validateUserStatus(_ user: User) -> AnyPublisher<User, AppError> {
        // Check if user is suspended or terminated
        switch user.agentStatus {
        case .suspended:
            return Fail(error: AppError.accountSuspended)
                .eraseToAnyPublisher()
        case .terminated:
            return Fail(error: AppError.accountTerminated)
                .eraseToAnyPublisher()
        case .pending:
            return Fail(error: AppError.accountPending)
                .eraseToAnyPublisher()
        case .active:
            break
        }

        // Check employment status (e.g., leave of absence)
        if case .contract = user.employmentStatus {
            // Additional validation for contract workers if needed
        }

        // Check driver license validity
        if let driverLicense = user.driverLicense {
            if !driverLicense.isVerified {
                Logger.warning("운전면허 미인증 사용자: \(user.username)", category: .auth)
            }
            if driverLicense.isExpiringSoon {
                Logger.warning("운전면허 만료 임박: \(user.username)", category: .auth)
            }
        }

        return Just(user)
            .setFailureType(to: AppError.self)
            .eraseToAnyPublisher()
    }

    private func setupPostLoginRequirements(_ user: User) -> AnyPublisher<User, AppError> {
        // This would include:
        // 1. FCM token registration
        // 2. Location permissions check
        // 3. Safety education completion check
        // 4. Helmet photo verification
        // 5. Login agreements check

        // For now, just return the user as these features will be implemented separately
        return Just(user)
            .setFailureType(to: AppError.self)
            .eraseToAnyPublisher()
    }
    
    func logout() -> AnyPublisher<Void, AppError> {
        return authRepository.logout()
            .handleEvents(receiveOutput: { _ in
                Logger.info("로그아웃 성공", category: .auth)
            })
            .eraseToAnyPublisher()
    }
}

// MARK: - Auth Token

struct AuthToken: Codable, Equatable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int
    let tokenType: String
    let issuedAt: Date
    
    var isExpired: Bool {
        let expirationDate = issuedAt.addingTimeInterval(TimeInterval(expiresIn))
        return Date() > expirationDate
    }
    
    var bearerToken: String {
        "\(tokenType) \(accessToken)"
    }
}