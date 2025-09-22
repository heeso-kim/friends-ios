import Foundation

/// 로그인 상태 모델
struct LoginState: Equatable {
    let savedUsername: String?
    let isUsernameSaved: Bool
    let isLoading: Bool
    let error: String?
    let isLoggedIn: Bool

    init(
        savedUsername: String? = nil,
        isUsernameSaved: Bool = false,
        isLoading: Bool = false,
        error: String? = nil,
        isLoggedIn: Bool = false
    ) {
        self.savedUsername = savedUsername
        self.isUsernameSaved = isUsernameSaved
        self.isLoading = isLoading
        self.error = error
        self.isLoggedIn = isLoggedIn
    }

    // Helper methods for state updates
    func withLoading(_ isLoading: Bool) -> LoginState {
        LoginState(
            savedUsername: savedUsername,
            isUsernameSaved: isUsernameSaved,
            isLoading: isLoading,
            error: nil,
            isLoggedIn: isLoggedIn
        )
    }

    func withError(_ error: String) -> LoginState {
        LoginState(
            savedUsername: savedUsername,
            isUsernameSaved: isUsernameSaved,
            isLoading: false,
            error: error,
            isLoggedIn: false
        )
    }

    func withSuccess() -> LoginState {
        LoginState(
            savedUsername: savedUsername,
            isUsernameSaved: isUsernameSaved,
            isLoading: false,
            error: nil,
            isLoggedIn: true
        )
    }

    func withSavedUsername(_ username: String?, saved: Bool) -> LoginState {
        LoginState(
            savedUsername: username,
            isUsernameSaved: saved,
            isLoading: isLoading,
            error: error,
            isLoggedIn: isLoggedIn
        )
    }
}

// MARK: - Static Initializers

extension LoginState {
    static let initial = LoginState()

    static func withSavedUsername(_ username: String?) -> LoginState {
        LoginState(
            savedUsername: username,
            isUsernameSaved: username != nil
        )
    }
}