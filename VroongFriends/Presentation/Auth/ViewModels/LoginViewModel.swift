import Foundation
import Combine
import SwiftUI

/// 로그인 뷰모델
@MainActor
final class LoginViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var username: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var isPasswordVisible: Bool = false
    @Published var state: LoginState = .initial

    // MARK: - Properties

    private let loginUseCase: LoginUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard

    private enum Keys {
        static let savedUsername = "saved_username"
        static let shouldSaveUsername = "should_save_username"
    }
    
    // MARK: - Computed Properties
    
    var isLoginButtonEnabled: Bool {
        !username.isEmpty && !password.isEmpty && !isLoading
    }
    
    var isValidUsername: Bool {
        username.isEmpty || username.count >= 4
    }
    
    var isValidPassword: Bool {
        password.isEmpty || password.count >= 6
    }
    
    // MARK: - Initialization
    
    init(loginUseCase: LoginUseCaseProtocol) {
        self.loginUseCase = loginUseCase
        loadSavedUsername()

        // 개발 환경에서 기본값 설정
        #if DEBUG
        if Environment.current != .prod && username.isEmpty {
            username = "test_user"
            password = "test1234"
        }
        #endif
    }
    
    // MARK: - Methods
    
    func login() {
        guard isValidUsername && isValidPassword else {
            let message = "아이디와 비밀번호를 확인해주세요"
            state = state.withError(message)
            showError(message: message)
            return
        }

        // Save username if enabled
        if state.isUsernameSaved {
            userDefaults.set(username, forKey: Keys.savedUsername)
        }

        isLoading = true
        state = state.withLoading(true)
        hideError()

        loginUseCase.execute(username: username, password: password)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.state = self?.state.withLoading(false) ?? .initial
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] user in
                    self?.state = self?.state.withSuccess() ?? .initial
                    self?.handleLoginSuccess(user: user)
                }
            )
            .store(in: &cancellables)
    }
    
    func togglePasswordVisibility() {
        isPasswordVisible.toggle()
    }
    
    func clearUsername() {
        username = ""
    }
    
    func clearPassword() {
        password = ""
    }

    func loadSavedUsername() {
        let shouldSave = userDefaults.bool(forKey: Keys.shouldSaveUsername)
        let savedUsername = userDefaults.string(forKey: Keys.savedUsername)

        state = LoginState(
            savedUsername: savedUsername,
            isUsernameSaved: shouldSave,
            isLoading: false,
            error: nil,
            isLoggedIn: false
        )

        if shouldSave, let savedUsername = savedUsername {
            username = savedUsername
        }
    }

    func toggleSaveUsername() {
        let newValue = !state.isUsernameSaved
        state = state.withSavedUsername(newValue ? username : nil, saved: newValue)

        userDefaults.set(newValue, forKey: Keys.shouldSaveUsername)
        if newValue {
            userDefaults.set(username, forKey: Keys.savedUsername)
        } else {
            userDefaults.removeObject(forKey: Keys.savedUsername)
        }
    }

    func clearError() {
        state = state.withError("")
        hideError()
    }

    // MARK: - Private Methods
    
    private func handleLoginSuccess(user: User) {
        Logger.info("로그인 성공: \(user.username)", category: .auth)
        
        // AppState 업데이트
        AppState.shared.currentUser = user
        AppState.shared.isAuthenticated = true
        
        // 메인 화면으로 이동
        NotificationCenter.default.post(
            name: .loginSuccess,
            object: user
        )
    }
    
    private func handleError(_ error: AppError) {
        let message: String
        switch error {
        case .invalidCredentials:
            message = "아이디 또는 비밀번호가 잘못되었습니다"
        case .noInternetConnection:
            message = "인터넷 연결을 확인해주세요"
        case .timeout:
            message = "연결 시간이 초과되었습니다. 다시 시도해주세요"
        default:
            message = error.localizedDescription
        }

        state = state.withError(message)
        showError(message: message)
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
    
    private func hideError() {
        showError = false
        errorMessage = ""
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let loginSuccess = Notification.Name("loginSuccess")
}