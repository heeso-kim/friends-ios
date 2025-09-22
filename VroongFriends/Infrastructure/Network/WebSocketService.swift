import Foundation
import Combine

/// WebSocket 서비스 프로토콜
protocol WebSocketServiceProtocol {
    func connect()
    func disconnect()
    func send<T: Encodable>(_ message: T)
    func subscribe<T: Decodable>(to type: T.Type) -> AnyPublisher<T, Never>
    var connectionState: AnyPublisher<WebSocketConnectionState, Never> { get }
}

/// WebSocket 연결 상태
enum WebSocketConnectionState {
    case disconnected
    case connecting
    case connected
    case disconnecting
    case failed(Error)
}

/// WebSocket 메시지 타입
enum WebSocketMessageType: String, Codable {
    case locationUpdate = "LOCATION_UPDATE"
    case orderStatusUpdate = "ORDER_STATUS_UPDATE"
    case newOrder = "NEW_ORDER"
    case orderAccepted = "ORDER_ACCEPTED"
    case orderCancelled = "ORDER_CANCELLED"
    case chat = "CHAT_MESSAGE"
    case notification = "NOTIFICATION"
    case ping = "PING"
    case pong = "PONG"
}

/// WebSocket 메시지 래퍼
struct WebSocketMessage<T: Codable>: Codable {
    let type: WebSocketMessageType
    let data: T
    let timestamp: Date
}

/// WebSocket 서비스 구현
class WebSocketService: NSObject, WebSocketServiceProtocol {
    private var webSocketTask: URLSessionWebSocketTask?
    private let session: URLSession
    private let url: URL
    private var pingTimer: Timer?
    private var reconnectTimer: Timer?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5

    private let connectionStateSubject = CurrentValueSubject<WebSocketConnectionState, Never>(.disconnected)
    private let messageSubject = PassthroughSubject<Data, Never>()
    private var cancellables = Set<AnyCancellable>()

    var connectionState: AnyPublisher<WebSocketConnectionState, Never> {
        connectionStateSubject.eraseToAnyPublisher()
    }

    init(environment: Environment) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 10

        self.session = URLSession(configuration: config)

        // Construct WebSocket URL based on environment
        var urlString = ""
        switch environment.flavor {
        case .dev1:
            urlString = "wss://dev1-api.vroong.com/ws"
        case .qa1:
            urlString = "wss://qa1-api.vroong.com/ws"
        case .qa2:
            urlString = "wss://qa2-api.vroong.com/ws"
        case .qa3:
            urlString = "wss://qa3-api.vroong.com/ws"
        case .qa4:
            urlString = "wss://qa4-api.vroong.com/ws"
        case .prod:
            urlString = "wss://api.vroong.com/ws"
        }

        self.url = URL(string: urlString)!

        super.init()
    }

    func connect() {
        guard connectionStateSubject.value != .connected &&
              connectionStateSubject.value != .connecting else {
            return
        }

        connectionStateSubject.send(.connecting)

        var request = URLRequest(url: url)
        request.timeoutInterval = 10

        // Add authentication token if available
        if let token = try? KeychainService.shared.getToken() {
            request.setValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")
        }

        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.delegate = self
        webSocketTask?.resume()

        receiveMessage()
        startPingTimer()

        Logger.info("WebSocket 연결 시작", category: .network)
    }

    func disconnect() {
        guard connectionStateSubject.value != .disconnected else {
            return
        }

        connectionStateSubject.send(.disconnecting)

        stopPingTimer()
        stopReconnectTimer()

        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil

        connectionStateSubject.send(.disconnected)

        Logger.info("WebSocket 연결 종료", category: .network)
    }

    func send<T: Encodable>(_ message: T) {
        guard connectionStateSubject.value == .connected,
              let webSocketTask = webSocketTask else {
            Logger.warning("WebSocket이 연결되지 않음", category: .network)
            return
        }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(message)
            let message = URLSessionWebSocketTask.Message.data(data)

            webSocketTask.send(message) { error in
                if let error = error {
                    Logger.error("WebSocket 메시지 전송 실패: \(error)", category: .network)
                } else {
                    Logger.debug("WebSocket 메시지 전송 성공", category: .network)
                }
            }
        } catch {
            Logger.error("WebSocket 메시지 인코딩 실패: \(error)", category: .network)
        }
    }

    func subscribe<T: Decodable>(to type: T.Type) -> AnyPublisher<T, Never> {
        messageSubject
            .compactMap { data -> T? in
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    return try decoder.decode(T.self, from: data)
                } catch {
                    Logger.error("WebSocket 메시지 디코딩 실패: \(error)", category: .network)
                    return nil
                }
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Private Methods

    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    self.handleMessage(data)
                case .string(let string):
                    if let data = string.data(using: .utf8) {
                        self.handleMessage(data)
                    }
                @unknown default:
                    break
                }

                // Continue receiving messages
                self.receiveMessage()

            case .failure(let error):
                Logger.error("WebSocket 메시지 수신 실패: \(error)", category: .network)
                self.handleDisconnection()
            }
        }
    }

    private func handleMessage(_ data: Data) {
        messageSubject.send(data)

        // Handle ping/pong
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            if let message = try? decoder.decode(WebSocketMessage<String>.self, from: data),
               message.type == .ping {
                sendPong()
            }
        } catch {
            // Not a ping message, continue
        }
    }

    private func handleDisconnection() {
        connectionStateSubject.send(.disconnected)
        stopPingTimer()
        attemptReconnect()
    }

    private func attemptReconnect() {
        guard reconnectAttempts < maxReconnectAttempts else {
            Logger.error("WebSocket 재연결 최대 시도 횟수 초과", category: .network)
            connectionStateSubject.send(.failed(AppError.networkError("재연결 실패")))
            return
        }

        reconnectAttempts += 1
        let delay = TimeInterval(min(pow(2, Double(reconnectAttempts)), 30))

        Logger.info("WebSocket 재연결 시도 (\(reconnectAttempts)/\(maxReconnectAttempts)) - \(delay)초 후", category: .network)

        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.connect()
        }
    }

    private func startPingTimer() {
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }

    private func stopPingTimer() {
        pingTimer?.invalidate()
        pingTimer = nil
    }

    private func stopReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        reconnectAttempts = 0
    }

    private func sendPing() {
        let message = WebSocketMessage(
            type: .ping,
            data: "ping",
            timestamp: Date()
        )
        send(message)
    }

    private func sendPong() {
        let message = WebSocketMessage(
            type: .pong,
            data: "pong",
            timestamp: Date()
        )
        send(message)
    }
}

// MARK: - URLSessionWebSocketDelegate

extension WebSocketService: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        Logger.info("WebSocket 연결 성공", category: .network)
        connectionStateSubject.send(.connected)
        reconnectAttempts = 0
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        Logger.info("WebSocket 연결 종료: \(closeCode)", category: .network)
        handleDisconnection()
    }
}

// MARK: - WebSocket Event Models

/// 위치 업데이트 이벤트
struct LocationUpdateEvent: Codable {
    let agentId: String
    let latitude: Double
    let longitude: Double
    let accuracy: Double
    let speed: Double?
    let heading: Double?
    let timestamp: Date
}

/// 주문 상태 업데이트 이벤트
struct OrderStatusUpdateEvent: Codable {
    let orderId: String
    let status: String
    let updatedBy: String
    let timestamp: Date
}

/// 새 주문 이벤트
struct NewOrderEvent: Codable {
    let order: OrderDTO
    let timestamp: Date
}

/// 채팅 메시지 이벤트
struct ChatMessageEvent: Codable {
    let orderId: String
    let senderId: String
    let message: String
    let timestamp: Date
}