import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // Initialize services
        setupServices()

        // Check authentication status
        let isAuthenticated = checkAuthenticationStatus()

        // Create root view
        let rootView: AnyView
        if isAuthenticated {
            rootView = AnyView(MainContainerView())
        } else {
            rootView = AnyView(LoginView())
        }

        // Create window
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = UIHostingController(rootView: rootView)
        window?.makeKeyAndVisible()

        // Apply appearance
        setupAppearance()

        // Handle launch options
        handleLaunchOptions(connectionOptions)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Save any pending data
        AppState.shared.saveState()
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Clear badge count when app becomes active
        UIApplication.shared.applicationIconBadgeNumber = 0

        // Resume location tracking if needed
        if AppState.shared.isOnline {
            LocationManager.shared.startTracking()
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Pause any ongoing activities
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Refresh data when returning to foreground
        refreshAppData()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Save app state
        AppState.shared.saveState()

        // Schedule background tasks if needed
        scheduleBackgroundTasks()
    }

    // MARK: - Deep Linking

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        handleDeepLink(url)
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        handleUserActivity(userActivity)
    }

    // MARK: - Private Methods

    private func setupServices() {
        // Initialize push notification service
        PushNotificationService.shared.requestAuthorization()
            .sink { granted in
                if granted {
                    PushNotificationService.shared.registerForRemoteNotifications()
                }
            }
            .store(in: &AppState.shared.cancellables)

        // Initialize location service
        LocationManager.shared.requestAuthorization()

        // Initialize Sendbird
        if let user = AppState.shared.currentUser {
            let chatService = SendbirdService()
            chatService.initialize(
                appId: Environment.shared.sendbirdAppId,
                userId: user.id,
                nickname: user.displayName,
                accessToken: nil
            )
        }

        // Start network monitoring
        NetworkMonitor.shared.startMonitoring()

        Logger.info("서비스 초기화 완료", category: .general)
    }

    private func checkAuthenticationStatus() -> Bool {
        // Check if we have a valid token
        if let token = try? KeychainService.shared.getToken() {
            // Verify token is not expired
            let expiryDate = token.issuedAt.addingTimeInterval(TimeInterval(token.expiresIn))
            if expiryDate > Date() {
                AppState.shared.authToken = token
                return true
            }
        }
        return false
    }

    private func setupAppearance() {
        // Navigation Bar Appearance
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(AppColors.brandPrimary)
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().tintColor = .white

        // Tab Bar Appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = .white

        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance

        // Other UI Elements
        UITextField.appearance().tintColor = UIColor(AppColors.brandPrimary)
        UITextView.appearance().tintColor = UIColor(AppColors.brandPrimary)
    }

    private func handleLaunchOptions(_ connectionOptions: UIScene.ConnectionOptions) {
        // Handle push notification launch
        if let notification = connectionOptions.notificationResponse {
            PushNotificationService.shared.handleNotification(notification.notification.request.content.userInfo)
        }

        // Handle URL launch
        if let url = connectionOptions.urlContexts.first?.url {
            handleDeepLink(url)
        }

        // Handle user activity
        if let userActivity = connectionOptions.userActivities.first {
            handleUserActivity(userActivity)
        }
    }

    private func handleDeepLink(_ url: URL) {
        // Handle deep links like vroongfriends://order/123
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }

        switch components.host {
        case "order":
            if let orderId = components.path.components(separatedBy: "/").last {
                navigateToOrder(orderId)
            }
        case "chat":
            if let channelUrl = components.path.components(separatedBy: "/").last {
                navigateToChat(channelUrl)
            }
        default:
            break
        }
    }

    private func handleUserActivity(_ userActivity: NSUserActivity) {
        switch userActivity.activityType {
        case "com.vroong.friends.order.details":
            if let orderId = userActivity.userInfo?["orderId"] as? String {
                navigateToOrder(orderId)
            }
        case "com.vroong.friends.chat":
            if let channelUrl = userActivity.userInfo?["channelUrl"] as? String {
                navigateToChat(channelUrl)
            }
        default:
            break
        }
    }

    private func navigateToOrder(_ orderId: String) {
        NotificationCenter.default.post(
            name: .navigateToOrder,
            object: orderId
        )
    }

    private func navigateToChat(_ channelUrl: String) {
        NotificationCenter.default.post(
            name: .navigateToChat,
            object: channelUrl
        )
    }

    private func refreshAppData() {
        // Refresh user data
        if AppState.shared.currentUser != nil {
            AppState.shared.refreshUserData()
        }

        // Check for new orders if online
        if AppState.shared.isOnline {
            AppState.shared.checkForNewOrders()
        }
    }

    private func scheduleBackgroundTasks() {
        // Schedule background location updates
        if AppState.shared.isOnline {
            // Background task scheduling would go here
        }
    }
}

// MARK: - Notification Names Extension

extension Notification.Name {
    static let navigateToOrder = Notification.Name("navigateToOrder")
    static let navigateToChat = Notification.Name("navigateToChat")
}