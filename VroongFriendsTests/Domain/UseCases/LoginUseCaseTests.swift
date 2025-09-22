import XCTest
import Combine
@testable import VroongFriends

final class LoginUseCaseTests: XCTestCase {
    private var sut: LoginUseCaseImpl!
    private var mockRepository: MockAuthRepository!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockRepository = MockAuthRepository()
        sut = LoginUseCaseImpl(authRepository: mockRepository)
        cancellables = []
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        cancellables = nil
        super.tearDown()
    }

    func testLoginSuccess() {
        // Given
        let expectedUser = User(
            id: "123",
            email: "test@vroong.com",
            name: "Test User",
            phoneNumber: "010-1234-5678",
            role: .delivery,
            profileImageUrl: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        let expectedToken = AuthToken(
            accessToken: "access_token",
            refreshToken: "refresh_token",
            expiresIn: 3600,
            tokenType: "Bearer",
            scope: "all",
            issuedAt: Date()
        )

        mockRepository.loginResult = .success((expectedUser, expectedToken))

        let expectation = XCTestExpectation(description: "Login succeeds")

        // When
        sut.execute(email: "test@vroong.com", password: "password123")
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        XCTFail("Expected success but got failure")
                    }
                },
                receiveValue: { user, token in
                    // Then
                    XCTAssertEqual(user.id, expectedUser.id)
                    XCTAssertEqual(user.email, expectedUser.email)
                    XCTAssertEqual(token.accessToken, expectedToken.accessToken)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func testLoginFailureInvalidCredentials() {
        // Given
        mockRepository.loginResult = .failure(NetworkError.unauthorized)

        let expectation = XCTestExpectation(description: "Login fails with invalid credentials")

        // When
        sut.execute(email: "wrong@vroong.com", password: "wrongpassword")
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        // Then
                        XCTAssertEqual(error as? NetworkError, NetworkError.unauthorized)
                        expectation.fulfill()
                    }
                },
                receiveValue: { _, _ in
                    XCTFail("Expected failure but got success")
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func testLoginValidatesEmailFormat() {
        // Given
        let invalidEmail = "invalid-email"

        let expectation = XCTestExpectation(description: "Login fails with invalid email format")

        // When
        sut.execute(email: invalidEmail, password: "password123")
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        // Then
                        XCTAssertEqual(error as? ValidationError, ValidationError.invalidEmail)
                        expectation.fulfill()
                    }
                },
                receiveValue: { _, _ in
                    XCTFail("Expected failure but got success")
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func testLoginValidatesPasswordLength() {
        // Given
        let shortPassword = "123"

        let expectation = XCTestExpectation(description: "Login fails with short password")

        // When
        sut.execute(email: "test@vroong.com", password: shortPassword)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        // Then
                        XCTAssertEqual(error as? ValidationError, ValidationError.passwordTooShort)
                        expectation.fulfill()
                    }
                },
                receiveValue: { _, _ in
                    XCTFail("Expected failure but got success")
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }
}

// MARK: - Mock Repository

class MockAuthRepository: AuthRepository {
    var loginResult: Result<(User, AuthToken), Error>?
    var logoutResult: Result<Void, Error>?
    var refreshTokenResult: Result<AuthToken, Error>?
    var registerResult: Result<User, Error>?
    var getUserResult: Result<User, Error>?

    func login(email: String, password: String) -> AnyPublisher<(User, AuthToken), Error> {
        guard let result = loginResult else {
            return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
        }

        switch result {
        case .success(let value):
            return Just(value)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        case .failure(let error):
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }

    func logout() -> AnyPublisher<Void, Error> {
        guard let result = logoutResult else {
            return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
        }

        switch result {
        case .success:
            return Just(())
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        case .failure(let error):
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }

    func refreshToken(refreshToken: String) -> AnyPublisher<AuthToken, Error> {
        guard let result = refreshTokenResult else {
            return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
        }

        switch result {
        case .success(let token):
            return Just(token)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        case .failure(let error):
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }

    func register(email: String, password: String, name: String, phoneNumber: String) -> AnyPublisher<User, Error> {
        guard let result = registerResult else {
            return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
        }

        switch result {
        case .success(let user):
            return Just(user)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        case .failure(let error):
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }

    func getUser() -> AnyPublisher<User, Error> {
        guard let result = getUserResult else {
            return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
        }

        switch result {
        case .success(let user):
            return Just(user)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        case .failure(let error):
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }
}

// MARK: - Validation Error

enum ValidationError: Error, Equatable {
    case invalidEmail
    case passwordTooShort
}