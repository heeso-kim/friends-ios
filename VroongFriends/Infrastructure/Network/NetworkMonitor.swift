import Foundation
import Network
import Combine

/// 네트워크 상태 모니터링
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "NetworkMonitor")

    @Published var isConnected: Bool = false
    @Published var connectionType: ConnectionType = .unknown

    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
    }

    private init() {
        monitor = NWPathMonitor()
    }

    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = self?.getConnectionType(from: path) ?? .unknown

                if !path.status.isSatisfied {
                    Logger.warning("네트워크 연결 끊김", category: .network)
                } else {
                    Logger.info("네트워크 연결됨: \(self?.connectionType ?? .unknown)", category: .network)
                }
            }
        }

        monitor.start(queue: queue)
    }

    func stopMonitoring() {
        monitor.cancel()
    }

    private func getConnectionType(from path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else {
            return .unknown
        }
    }
}

// MARK: - NWPath.Status Extension

extension NWPath.Status {
    var isSatisfied: Bool {
        return self == .satisfied
    }
}