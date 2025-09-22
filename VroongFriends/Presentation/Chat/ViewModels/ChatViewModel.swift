import Foundation
import Combine
import PhotosUI

/// 채팅 뷰모델
@MainActor
final class ChatViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var messages: [ChatMessage] = []
    @Published var messageText: String = ""
    @Published var isLoading: Bool = false
    @Published var isTyping: Bool = false
    @Published var otherUserTyping: Bool = false
    @Published var showImagePicker: Bool = false
    @Published var selectedImage: UIImage?
    @Published var errorMessage: String?

    // MARK: - Properties

    private let chatService: SendbirdServiceProtocol
    private let orderId: String
    private let customerId: String
    private var channelUrl: String?
    private var cancellables = Set<AnyCancellable>()
    private var typingTimer: Timer?

    // MARK: - Initialization

    init(
        orderId: String,
        customerId: String,
        chatService: SendbirdServiceProtocol = SendbirdService()
    ) {
        self.orderId = orderId
        self.customerId = customerId
        self.chatService = chatService

        setupChat()
        setupSubscriptions()
    }

    // MARK: - Setup

    private func setupChat() {
        // Initialize Sendbird
        if let user = AppState.shared.currentUser {
            chatService.initialize(
                appId: Environment.shared.sendbirdAppId,
                userId: user.id,
                nickname: user.displayName,
                accessToken: nil
            )

            connectToChat()
        }
    }

    private func setupSubscriptions() {
        // 메시지 수신 구독
        chatService.messageReceived
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let self = self,
                      message.channelUrl == self.channelUrl else { return }
                self.messages.append(message)
                self.markAsRead()
            }
            .store(in: &cancellables)

        // 타이핑 상태 구독
        chatService.typingStatusChanged
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self,
                      status.channelUrl == self.channelUrl,
                      status.userId != AppState.shared.currentUser?.id else { return }
                self.otherUserTyping = status.isTyping
            }
            .store(in: &cancellables)

        // 메시지 입력 감지
        $messageText
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] text in
                if !text.isEmpty {
                    self?.startTyping()
                } else {
                    self?.endTyping()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Methods

    private func connectToChat() {
        isLoading = true
        errorMessage = nil

        chatService.connect()
            .flatMap { [weak self] _ -> AnyPublisher<ChatChannel, AppError> in
                guard let self = self else {
                    return Fail(error: AppError.unknown("Self is nil"))
                        .eraseToAnyPublisher()
                }
                return self.chatService.createChannel(with: self.customerId, orderId: self.orderId)
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] channel in
                    self?.channelUrl = channel.channelUrl
                    self?.loadMessages()
                }
            )
            .store(in: &cancellables)
    }

    func loadMessages() {
        guard let channelUrl = channelUrl else { return }

        isLoading = true

        chatService.loadMessages(channelUrl: channelUrl, limit: 50)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] messages in
                    self?.messages = messages.reversed()
                    self?.markAsRead()
                }
            )
            .store(in: &cancellables)
    }

    func sendMessage() {
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty,
              let channelUrl = channelUrl else { return }

        let tempMessage = messageText
        messageText = ""
        endTyping()

        chatService.sendMessage(channelUrl: channelUrl, message: tempMessage)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.messageText = tempMessage // Restore message on failure
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] message in
                    self?.messages.append(message)
                }
            )
            .store(in: &cancellables)
    }

    func sendImage(_ image: UIImage) {
        // TODO: 이미지 업로드 및 전송
        selectedImage = image
        Logger.debug("이미지 전송: \(image.size)", category: .general)
    }

    func refreshMessages() {
        loadMessages()
    }

    private func markAsRead() {
        guard let channelUrl = channelUrl else { return }

        chatService.markAsRead(channelUrl: channelUrl)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }

    private func startTyping() {
        guard let channelUrl = channelUrl, !isTyping else { return }

        isTyping = true
        chatService.startTyping(channelUrl: channelUrl)

        // 자동 종료 타이머
        typingTimer?.invalidate()
        typingTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            self?.endTyping()
        }
    }

    private func endTyping() {
        guard let channelUrl = channelUrl, isTyping else { return }

        isTyping = false
        chatService.endTyping(channelUrl: channelUrl)

        typingTimer?.invalidate()
        typingTimer = nil
    }

    private func handleError(_ error: AppError) {
        Logger.error("채팅 오류: \(error)", category: .general)

        switch error {
        case .noInternetConnection:
            errorMessage = "인터넷 연결을 확인해주세요"
        case .unauthorized:
            errorMessage = "인증이 필요합니다"
        default:
            errorMessage = "채팅 연결 중 오류가 발생했습니다"
        }
    }

    // MARK: - Deinit

    deinit {
        typingTimer?.invalidate()
        chatService.disconnect()
            .sink(receiveValue: { _ in })
            .store(in: &cancellables)
    }
}