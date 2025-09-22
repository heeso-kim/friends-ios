import Foundation
import UserNotifications
import Combine
import UIKit

/// 푸시 알림 서비스 프로토콜
protocol PushNotificationServiceProtocol {
    func requestAuthorization() -> AnyPublisher<Bool, Never>
    func registerForRemoteNotifications()
    func handleNotification(_ userInfo: [AnyHashable: Any])
    func scheduleLocalNotification(_ notification: LocalNotification)
    func clearAllNotifications()
    func getBadgeCount() -> Int
    func setBadgeCount(_ count: Int)
    var notificationReceived: AnyPublisher<PushNotification, Never> { get }
}

/// 푸시 알림 타입
enum PushNotificationType: String {
    case newOrder = "NEW_ORDER"
    case orderAccepted = "ORDER_ACCEPTED"
    case orderCancelled = "ORDER_CANCELLED"
    case orderCompleted = "ORDER_COMPLETED"
    case paymentReceived = "PAYMENT_RECEIVED"
    case withdrawalCompleted = "WITHDRAWAL_COMPLETED"
    case chat = "CHAT_MESSAGE"
    case announcement = "ANNOUNCEMENT"
    case promotion = "PROMOTION"
}

/// 푸시 알림 모델
struct PushNotification {
    let id: String
    let type: PushNotificationType
    let title: String
    let body: String
    let data: [String: Any]?
    let receivedAt: Date
}

/// 로컬 알림 모델
struct LocalNotification {
    let identifier: String
    let title: String
    let body: String
    let sound: UNNotificationSound?
    let badge: Int?
    let categoryIdentifier: String?
    let userInfo: [String: Any]?
    let trigger: UNNotificationTrigger?
}

/// 푸시 알림 서비스
class PushNotificationService: NSObject, PushNotificationServiceProtocol {
    static let shared = PushNotificationService()

    private let notificationCenter = UNUserNotificationCenter.current()
    private let notificationReceivedSubject = PassthroughSubject<PushNotification, Never>()
    private var cancellables = Set<AnyCancellable>()

    var notificationReceived: AnyPublisher<PushNotification, Never> {
        notificationReceivedSubject.eraseToAnyPublisher()
    }

    private override init() {
        super.init()
        notificationCenter.delegate = self
        setupNotificationCategories()
    }

    // MARK: - Authorization

    func requestAuthorization() -> AnyPublisher<Bool, Never> {
        Future<Bool, Never> { [weak self] promise in
            self?.notificationCenter.requestAuthorization(
                options: [.alert, .badge, .sound, .provisional]
            ) { granted, error in
                if let error = error {
                    Logger.error("푸시 알림 권한 요청 실패: \(error)", category: .general)
                    promise(.success(false))
                } else {
                    Logger.info("푸시 알림 권한: \(granted ? "허용" : "거부")", category: .general)
                    promise(.success(granted))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func registerForRemoteNotifications() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    // MARK: - Notification Handling

    func handleNotification(_ userInfo: [AnyHashable: Any]) {
        guard let typeString = userInfo["type"] as? String,
              let type = PushNotificationType(rawValue: typeString) else {
            Logger.warning("알 수 없는 알림 타입", category: .general)
            return
        }

        let notification = PushNotification(
            id: userInfo["id"] as? String ?? UUID().uuidString,
            type: type,
            title: userInfo["title"] as? String ?? "",
            body: userInfo["body"] as? String ?? "",
            data: userInfo["data"] as? [String: Any],
            receivedAt: Date()
        )

        notificationReceivedSubject.send(notification)
        handleNotificationAction(notification)
    }

    private func handleNotificationAction(_ notification: PushNotification) {
        switch notification.type {
        case .newOrder:
            handleNewOrderNotification(notification)
        case .orderAccepted:
            handleOrderAcceptedNotification(notification)
        case .chat:
            handleChatNotification(notification)
        case .paymentReceived:
            handlePaymentNotification(notification)
        default:
            Logger.debug("알림 처리: \(notification.type)", category: .general)
        }
    }

    private func handleNewOrderNotification(_ notification: PushNotification) {
        guard let orderId = notification.data?["orderId"] as? String else { return }

        // 새 주문 알림 전파
        NotificationCenter.default.post(
            name: .newOrderAvailable,
            object: orderId
        )

        // 사운드 재생
        playNotificationSound()

        Logger.info("새 주문 알림: \(orderId)", category: .order)
    }

    private func handleOrderAcceptedNotification(_ notification: PushNotification) {
        guard let orderId = notification.data?["orderId"] as? String else { return }

        NotificationCenter.default.post(
            name: .orderAccepted,
            object: orderId
        )

        Logger.info("주문 수락 알림: \(orderId)", category: .order)
    }

    private func handleChatNotification(_ notification: PushNotification) {
        guard let channelUrl = notification.data?["channelUrl"] as? String else { return }

        NotificationCenter.default.post(
            name: .newChatMessage,
            object: channelUrl
        )

        Logger.info("채팅 알림: \(channelUrl)", category: .general)
    }

    private func handlePaymentNotification(_ notification: PushNotification) {
        guard let amount = notification.data?["amount"] as? Double else { return }

        NotificationCenter.default.post(
            name: .paymentReceived,
            object: amount
        )

        Logger.info("결제 알림: \(amount)", category: .payment)
    }

    // MARK: - Local Notifications

    func scheduleLocalNotification(_ notification: LocalNotification) {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body

        if let sound = notification.sound {
            content.sound = sound
        }

        if let badge = notification.badge {
            content.badge = NSNumber(value: badge)
        }

        if let categoryIdentifier = notification.categoryIdentifier {
            content.categoryIdentifier = categoryIdentifier
        }

        if let userInfo = notification.userInfo {
            content.userInfo = userInfo
        }

        let trigger = notification.trigger ?? UNTimeIntervalNotificationTrigger(
            timeInterval: 1,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: notification.identifier,
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                Logger.error("로컬 알림 스케줄 실패: \(error)", category: .general)
            } else {
                Logger.debug("로컬 알림 스케줄 성공: \(notification.identifier)", category: .general)
            }
        }
    }

    func clearAllNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
        notificationCenter.removeAllPendingNotificationRequests()
        setBadgeCount(0)
    }

    // MARK: - Badge Management

    func getBadgeCount() -> Int {
        return UIApplication.shared.applicationIconBadgeNumber
    }

    func setBadgeCount(_ count: Int) {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = count
        }
    }

    // MARK: - Setup

    private func setupNotificationCategories() {
        // 주문 카테고리
        let acceptAction = UNNotificationAction(
            identifier: "ACCEPT_ORDER",
            title: "수락",
            options: [.foreground]
        )

        let rejectAction = UNNotificationAction(
            identifier: "REJECT_ORDER",
            title: "거절",
            options: [.destructive]
        )

        let orderCategory = UNNotificationCategory(
            identifier: "ORDER_CATEGORY",
            actions: [acceptAction, rejectAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        // 채팅 카테고리
        let replyAction = UNTextInputNotificationAction(
            identifier: "REPLY_MESSAGE",
            title: "답장",
            options: [],
            textInputButtonTitle: "전송",
            textInputPlaceholder: "메시지 입력..."
        )

        let chatCategory = UNNotificationCategory(
            identifier: "CHAT_CATEGORY",
            actions: [replyAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        notificationCenter.setNotificationCategories([orderCategory, chatCategory])
    }

    private func playNotificationSound() {
        // 커스텀 사운드 재생
        // AudioServicesPlaySystemSound(1007) // SMS 수신음
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension PushNotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // 앱이 포그라운드에 있을 때 알림 표시
        handleNotification(notification.request.content.userInfo)

        // iOS 14+
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge, .list])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // 알림 액션 처리
        let userInfo = response.notification.request.content.userInfo
        handleNotification(userInfo)

        switch response.actionIdentifier {
        case "ACCEPT_ORDER":
            handleAcceptOrderAction(userInfo)
        case "REJECT_ORDER":
            handleRejectOrderAction(userInfo)
        case "REPLY_MESSAGE":
            if let textResponse = response as? UNTextInputNotificationResponse {
                handleReplyMessageAction(userInfo, message: textResponse.userText)
            }
        case UNNotificationDefaultActionIdentifier:
            // 알림 탭
            handleDefaultAction(userInfo)
        case UNNotificationDismissActionIdentifier:
            // 알림 스와이프 제거
            break
        default:
            break
        }

        completionHandler()
    }

    private func handleAcceptOrderAction(_ userInfo: [AnyHashable: Any]) {
        guard let orderId = userInfo["orderId"] as? String else { return }
        NotificationCenter.default.post(name: .acceptOrderFromNotification, object: orderId)
    }

    private func handleRejectOrderAction(_ userInfo: [AnyHashable: Any]) {
        guard let orderId = userInfo["orderId"] as? String else { return }
        NotificationCenter.default.post(name: .rejectOrderFromNotification, object: orderId)
    }

    private func handleReplyMessageAction(_ userInfo: [AnyHashable: Any], message: String) {
        guard let channelUrl = userInfo["channelUrl"] as? String else { return }
        NotificationCenter.default.post(
            name: .replyMessageFromNotification,
            object: ["channelUrl": channelUrl, "message": message]
        )
    }

    private func handleDefaultAction(_ userInfo: [AnyHashable: Any]) {
        // 알림 탭 시 해당 화면으로 이동
        if let typeString = userInfo["type"] as? String,
           let type = PushNotificationType(rawValue: typeString) {
            NotificationCenter.default.post(
                name: .navigateFromNotification,
                object: type
            )
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let newOrderAvailable = Notification.Name("newOrderAvailable")
    static let orderAccepted = Notification.Name("orderAccepted")
    static let newChatMessage = Notification.Name("newChatMessage")
    static let paymentReceived = Notification.Name("paymentReceived")
    static let acceptOrderFromNotification = Notification.Name("acceptOrderFromNotification")
    static let rejectOrderFromNotification = Notification.Name("rejectOrderFromNotification")
    static let replyMessageFromNotification = Notification.Name("replyMessageFromNotification")
    static let navigateFromNotification = Notification.Name("navigateFromNotification")
}