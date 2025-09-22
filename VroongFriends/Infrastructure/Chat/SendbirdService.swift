import Foundation
import Combine
// import SendBirdSDK  // Uncomment after pod install

/// Sendbird 채팅 서비스 프로토콜
protocol SendbirdServiceProtocol {
    func initialize(appId: String, userId: String, nickname: String?, accessToken: String?)
    func connect() -> AnyPublisher<Bool, AppError>
    func disconnect() -> AnyPublisher<Void, Never>
    func createChannel(with userId: String, orderId: String) -> AnyPublisher<ChatChannel, AppError>
    func getChannel(channelUrl: String) -> AnyPublisher<ChatChannel, AppError>
    func getChannelList() -> AnyPublisher<[ChatChannel], AppError>
    func sendMessage(channelUrl: String, message: String) -> AnyPublisher<ChatMessage, AppError>
    func loadMessages(channelUrl: String, limit: Int) -> AnyPublisher<[ChatMessage], AppError>
    func markAsRead(channelUrl: String) -> AnyPublisher<Void, AppError>
    func startTyping(channelUrl: String)
    func endTyping(channelUrl: String)
    var messageReceived: AnyPublisher<ChatMessage, Never> { get }
    var typingStatusChanged: AnyPublisher<TypingStatus, Never> { get }
}

/// 타이핑 상태
struct TypingStatus {
    let channelUrl: String
    let userId: String
    let isTyping: Bool
}

/// Sendbird 채팅 서비스
class SendbirdService: NSObject, SendbirdServiceProtocol {
    private var appId: String?
    private var userId: String?
    private var currentUser: User?

    private let messageReceivedSubject = PassthroughSubject<ChatMessage, Never>()
    private let typingStatusSubject = PassthroughSubject<TypingStatus, Never>()
    private var cancellables = Set<AnyCancellable>()

    var messageReceived: AnyPublisher<ChatMessage, Never> {
        messageReceivedSubject.eraseToAnyPublisher()
    }

    var typingStatusChanged: AnyPublisher<TypingStatus, Never> {
        typingStatusSubject.eraseToAnyPublisher()
    }

    override init() {
        super.init()
    }

    func initialize(appId: String, userId: String, nickname: String? = nil, accessToken: String? = nil) {
        self.appId = appId
        self.userId = userId

        // TODO: Sendbird SDK 초기화
        /*
        SBDMain.initWithApplicationId(appId)
        SBDMain.add(self as SBDChannelDelegate, identifier: "ChatService")
        SBDMain.add(self as SBDConnectionDelegate, identifier: "ChatService")

        SBDOptions.setAuthenticationTimeout(30)
        SBDOptions.setConnectionTimeout(10)
        */

        Logger.info("Sendbird 초기화: \(appId)", category: .general)
    }

    func connect() -> AnyPublisher<Bool, AppError> {
        Future<Bool, AppError> { promise in
            guard let userId = self.userId else {
                promise(.failure(AppError.unauthorized))
                return
            }

            // TODO: Sendbird 연결
            /*
            SBDMain.connect(withUserId: userId) { user, error in
                if let error = error {
                    Logger.error("Sendbird 연결 실패: \(error)", category: .general)
                    promise(.failure(AppError.networkError(error.localizedDescription)))
                    return
                }

                self.currentUser = user
                Logger.info("Sendbird 연결 성공: \(user?.nickname ?? userId)", category: .general)
                promise(.success(true))
            }
            */

            // Mock success for now
            promise(.success(true))
        }
        .eraseToAnyPublisher()
    }

    func disconnect() -> AnyPublisher<Void, Never> {
        Future<Void, Never> { promise in
            // TODO: Sendbird 연결 해제
            /*
            SBDMain.disconnect {
                Logger.info("Sendbird 연결 해제", category: .general)
                promise(.success(()))
            }
            */

            promise(.success(()))
        }
        .eraseToAnyPublisher()
    }

    func createChannel(with userId: String, orderId: String) -> AnyPublisher<ChatChannel, AppError> {
        Future<ChatChannel, AppError> { promise in
            // TODO: Sendbird 채널 생성
            /*
            let params = SBDGroupChannelParams()
            params.isDistinct = true
            params.userIds = [self.userId!, userId]
            params.name = "Order: \(orderId)"
            params.customType = "order_chat"
            params.data = orderId

            SBDGroupChannel.createChannel(with: params) { channel, error in
                if let error = error {
                    Logger.error("채널 생성 실패: \(error)", category: .general)
                    promise(.failure(AppError.networkError(error.localizedDescription)))
                    return
                }

                guard let channel = channel else {
                    promise(.failure(AppError.unknown("채널 생성 실패")))
                    return
                }

                let chatChannel = self.convertToChatChannel(channel)
                promise(.success(chatChannel))
            }
            */

            // Mock channel for now
            let mockChannel = ChatChannel(
                channelUrl: "mock_channel_\(orderId)",
                name: "Order: \(orderId)",
                coverImageUrl: nil,
                memberCount: 2,
                lastMessage: nil,
                lastMessageTime: nil,
                unreadMessageCount: 0,
                customType: "order_chat",
                data: orderId,
                members: []
            )
            promise(.success(mockChannel))
        }
        .eraseToAnyPublisher()
    }

    func getChannel(channelUrl: String) -> AnyPublisher<ChatChannel, AppError> {
        Future<ChatChannel, AppError> { promise in
            // TODO: Sendbird 채널 조회
            /*
            SBDGroupChannel.getWithUrl(channelUrl) { channel, error in
                if let error = error {
                    Logger.error("채널 조회 실패: \(error)", category: .general)
                    promise(.failure(AppError.networkError(error.localizedDescription)))
                    return
                }

                guard let channel = channel else {
                    promise(.failure(AppError.dataNotFound))
                    return
                }

                let chatChannel = self.convertToChatChannel(channel)
                promise(.success(chatChannel))
            }
            */

            // Mock channel for now
            let mockChannel = ChatChannel(
                channelUrl: channelUrl,
                name: "Mock Channel",
                coverImageUrl: nil,
                memberCount: 2,
                lastMessage: nil,
                lastMessageTime: nil,
                unreadMessageCount: 0,
                customType: "order_chat",
                data: nil,
                members: []
            )
            promise(.success(mockChannel))
        }
        .eraseToAnyPublisher()
    }

    func getChannelList() -> AnyPublisher<[ChatChannel], AppError> {
        Future<[ChatChannel], AppError> { promise in
            // TODO: Sendbird 채널 목록 조회
            /*
            let query = SBDGroupChannel.createMyGroupChannelListQuery()
            query?.includeEmptyChannel = true
            query?.order = .latestLastMessage
            query?.limit = 30

            query?.loadNextPage { channels, error in
                if let error = error {
                    Logger.error("채널 목록 조회 실패: \(error)", category: .general)
                    promise(.failure(AppError.networkError(error.localizedDescription)))
                    return
                }

                let chatChannels = channels?.map { self.convertToChatChannel($0) } ?? []
                promise(.success(chatChannels))
            }
            */

            // Mock empty list for now
            promise(.success([]))
        }
        .eraseToAnyPublisher()
    }

    func sendMessage(channelUrl: String, message: String) -> AnyPublisher<ChatMessage, AppError> {
        Future<ChatMessage, AppError> { promise in
            // TODO: Sendbird 메시지 전송
            /*
            SBDGroupChannel.getWithUrl(channelUrl) { channel, error in
                if let error = error {
                    promise(.failure(AppError.networkError(error.localizedDescription)))
                    return
                }

                guard let channel = channel else {
                    promise(.failure(AppError.dataNotFound))
                    return
                }

                let params = SBDUserMessageParams(message: message)
                params.customType = "text"
                params.data = nil

                channel.sendUserMessage(with: params) { userMessage, error in
                    if let error = error {
                        Logger.error("메시지 전송 실패: \(error)", category: .general)
                        promise(.failure(AppError.networkError(error.localizedDescription)))
                        return
                    }

                    guard let userMessage = userMessage else {
                        promise(.failure(AppError.unknown("메시지 전송 실패")))
                        return
                    }

                    let chatMessage = self.convertToChatMessage(userMessage)
                    promise(.success(chatMessage))
                }
            }
            */

            // Mock message for now
            let mockMessage = ChatMessage(
                messageId: UUID().hashValue,
                message: message,
                senderId: userId ?? "",
                senderNickname: "Me",
                senderProfileUrl: nil,
                createdAt: Date().millisecondsSince1970,
                customType: "text",
                data: nil,
                channelUrl: channelUrl
            )
            promise(.success(mockMessage))
        }
        .eraseToAnyPublisher()
    }

    func loadMessages(channelUrl: String, limit: Int = 30) -> AnyPublisher<[ChatMessage], AppError> {
        Future<[ChatMessage], AppError> { promise in
            // TODO: Sendbird 메시지 로드
            /*
            SBDGroupChannel.getWithUrl(channelUrl) { channel, error in
                if let error = error {
                    promise(.failure(AppError.networkError(error.localizedDescription)))
                    return
                }

                guard let channel = channel else {
                    promise(.failure(AppError.dataNotFound))
                    return
                }

                let query = channel.createPreviousMessageListQuery()
                query?.limit = UInt(limit)
                query?.includeMetaArray = true
                query?.includeReactions = true

                query?.loadPreviousMessages { messages, error in
                    if let error = error {
                        Logger.error("메시지 로드 실패: \(error)", category: .general)
                        promise(.failure(AppError.networkError(error.localizedDescription)))
                        return
                    }

                    let chatMessages = messages?.map { self.convertToChatMessage($0) } ?? []
                    promise(.success(chatMessages))
                }
            }
            */

            // Mock messages for now
            promise(.success([]))
        }
        .eraseToAnyPublisher()
    }

    func markAsRead(channelUrl: String) -> AnyPublisher<Void, AppError> {
        Future<Void, AppError> { promise in
            // TODO: Sendbird 메시지 읽음 처리
            /*
            SBDGroupChannel.getWithUrl(channelUrl) { channel, error in
                if let error = error {
                    promise(.failure(AppError.networkError(error.localizedDescription)))
                    return
                }

                guard let channel = channel else {
                    promise(.failure(AppError.dataNotFound))
                    return
                }

                channel.markAsRead()
                promise(.success(()))
            }
            */

            promise(.success(()))
        }
        .eraseToAnyPublisher()
    }

    func startTyping(channelUrl: String) {
        // TODO: Sendbird 타이핑 시작
        /*
        SBDGroupChannel.getWithUrl(channelUrl) { channel, error in
            guard let channel = channel else { return }
            channel.startTyping()
        }
        */
    }

    func endTyping(channelUrl: String) {
        // TODO: Sendbird 타이핑 종료
        /*
        SBDGroupChannel.getWithUrl(channelUrl) { channel, error in
            guard let channel = channel else { return }
            channel.endTyping()
        }
        */
    }
}

// MARK: - Helper Methods

extension SendbirdService {
    /*
    private func convertToChatChannel(_ channel: SBDGroupChannel) -> ChatChannel {
        ChatChannel(
            channelUrl: channel.channelUrl,
            name: channel.name ?? "",
            coverImageUrl: channel.coverUrl,
            memberCount: Int(channel.memberCount),
            lastMessage: channel.lastMessage?.message,
            lastMessageTime: channel.lastMessage?.createdAt != 0 ? Date(milliseconds: channel.lastMessage!.createdAt) : nil,
            unreadMessageCount: Int(channel.unreadMessageCount),
            customType: channel.customType,
            data: channel.data,
            members: channel.members?.map { member in
                ChatMember(
                    userId: member.userId,
                    nickname: member.nickname ?? "",
                    profileUrl: member.profileUrl,
                    connectionStatus: member.connectionStatus.rawValue,
                    lastSeenAt: member.lastSeenAt != 0 ? Date(milliseconds: member.lastSeenAt) : nil
                )
            } ?? []
        )
    }

    private func convertToChatMessage(_ message: SBDBaseMessage) -> ChatMessage {
        ChatMessage(
            messageId: message.messageId,
            message: (message as? SBDUserMessage)?.message ?? "",
            senderId: message.sender?.userId ?? "",
            senderNickname: message.sender?.nickname ?? "",
            senderProfileUrl: message.sender?.profileUrl,
            createdAt: message.createdAt,
            customType: message.customType,
            data: message.data,
            channelUrl: message.channelUrl ?? ""
        )
    }
    */
}

// MARK: - Sendbird Delegates

/*
extension SendbirdService: SBDChannelDelegate {
    func channel(_ sender: SBDBaseChannel, didReceive message: SBDBaseMessage) {
        let chatMessage = convertToChatMessage(message)
        messageReceivedSubject.send(chatMessage)
    }

    func channel(_ sender: SBDGroupChannel, userDidStartTyping user: SBDUser) {
        let status = TypingStatus(
            channelUrl: sender.channelUrl,
            userId: user.userId,
            isTyping: true
        )
        typingStatusSubject.send(status)
    }

    func channel(_ sender: SBDGroupChannel, userDidStopTyping user: SBDUser) {
        let status = TypingStatus(
            channelUrl: sender.channelUrl,
            userId: user.userId,
            isTyping: false
        )
        typingStatusSubject.send(status)
    }
}

extension SendbirdService: SBDConnectionDelegate {
    func didStartReconnection() {
        Logger.info("Sendbird 재연결 시작", category: .general)
    }

    func didSucceedReconnection() {
        Logger.info("Sendbird 재연결 성공", category: .general)
    }

    func didFailReconnection() {
        Logger.error("Sendbird 재연결 실패", category: .general)
    }
}
*/

// MARK: - Date Extension

extension Date {
    var millisecondsSince1970: Int64 {
        Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }

    init(milliseconds: Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}