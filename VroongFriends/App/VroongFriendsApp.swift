import SwiftUI
import FirebaseCore
import Swinject

@main
struct VroongFriendsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var appState = AppState()

    init() {
        setupDependencyInjection()
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear {
                    appState.checkAuthenticationStatus()
                }
        }
    }

    private func setupDependencyInjection() {
        AppContainer.shared.registerDependencies()
    }

    private func configureAppearance() {
        // Navigation Bar appearance
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor.systemBackground
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance

        // Tab Bar appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor.systemBackground
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }
}

// MARK: - AppDelegate

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Firebase 초기화
        FirebaseApp.configure()

        // 네이버 맵 초기화 (API 키는 환경 변수에서)
        // NMFAuthManager.shared().clientId = Environment.naverMapClientId

        // 카카오 맵 초기화
        // KakaoMapSDK.shared().initialize(appKey: Environment.kakaoMapAppKey)

        // 푸시 알림 설정
        setupPushNotifications(application)

        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // FCM 토큰 처리
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("📱 Device Token: \(token)")
    }

    private func setupPushNotifications(_ application: UIApplication) {
        UNUserNotificationCenter.current().delegate = self

        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions
        ) { granted, _ in
            print("📮 Push notification permission granted: \(granted)")
        }

        application.registerForRemoteNotifications()
    }
}

// MARK: - Push Notification Delegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .badge, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // 푸시 알림 탭 처리
        completionHandler()
    }
}