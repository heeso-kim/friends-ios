import SwiftUI
import Combine

/// 앱 전역 상태 관리 (iOS 17+ @Observable)
@MainActor
class AppState: ObservableObject {
    // MARK: - Published Properties

    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var error: AppError?

    // MARK: - Navigation State

    @Published var selectedTab = 0
    @Published var navigationPath = NavigationPath()

    // MARK: - Services

    private let authService: AuthService
    private let userService: UserService
    private let keychainService: KeychainService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        authService: AuthService = AppContainer.shared.resolve(AuthService.self)!,
        userService: UserService = AppContainer.shared.resolve(UserService.self)!,
        keychainService: KeychainService = AppContainer.shared.resolve(KeychainService.self)!
    ) {
        self.authService = authService
        self.userService = userService
        self.keychainService = keychainService

        setupBindings()
    }

    // MARK: - Setup

    private func setupBindings() {
        // Auth 상태 변화 감지
        authService.isAuthenticatedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuthenticated in
                self?.isAuthenticated = isAuthenticated
                if !isAuthenticated {
                    self?.currentUser = nil
                }
            }
            .store(in: &cancellables)

        // 사용자 정보 변화 감지
        userService.currentUserPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.currentUser = user
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    func checkAuthenticationStatus() {
        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                // Keychain에서 토큰 확인
                if let _ = try keychainService.getAccessToken() {
                    // 토큰이 있으면 사용자 정보 로드
                    try await loadCurrentUser()
                    isAuthenticated = true
                } else {
                    isAuthenticated = false
                }
            } catch {
                print("❌ Authentication check failed: \(error)")
                isAuthenticated = false
            }
        }
    }

    func login(username: String, password: String) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            try await authService.login(username: username, password: password)
            try await loadCurrentUser()
            isAuthenticated = true
        } catch let authError as AppError {
            error = authError
            throw authError
        } catch {
            let appError = AppError.unknown(error.localizedDescription)
            self.error = appError
            throw appError
        }
    }

    func logout() {
        Task {
            do {
                try await authService.logout()
                currentUser = nil
                isAuthenticated = false
                navigationPath = NavigationPath() // Reset navigation
            } catch {
                print("❌ Logout failed: \(error)")
            }
        }
    }

    // MARK: - Private Methods

    private func loadCurrentUser() async throws {
        let user = try await userService.getCurrentUser()
        currentUser = user
    }

    // MARK: - Navigation Helpers

    func navigateToLogin() {
        selectedTab = 0
        navigationPath = NavigationPath()
    }

    func navigateToHome() {
        selectedTab = 0
        navigationPath = NavigationPath()
    }

    func navigateToOrder(_ orderId: String) {
        selectedTab = 1 // Orders tab
        navigationPath.append(orderId)
    }
}