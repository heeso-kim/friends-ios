import Foundation
import os.log

/// 앱 전역 로거
enum Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.vroong.friends"

    // MARK: - Log Categories

    private static let network = OSLog(subsystem: subsystem, category: "Network")
    private static let auth = OSLog(subsystem: subsystem, category: "Auth")
    private static let order = OSLog(subsystem: subsystem, category: "Order")
    private static let location = OSLog(subsystem: subsystem, category: "Location")
    private static let general = OSLog(subsystem: subsystem, category: "General")

    // MARK: - Log Levels

    enum Level {
        case debug
        case info
        case warning
        case error

        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .default
            case .error: return .error
            }
        }

        var emoji: String {
            switch self {
            case .debug: return "🔍"
            case .info: return "ℹ️"
            case .warning: return "⚠️"
            case .error: return "❌"
            }
        }
    }

    enum Category {
        case network
        case auth
        case order
        case location
        case general

        var osLog: OSLog {
            switch self {
            case .network: return Logger.network
            case .auth: return Logger.auth
            case .order: return Logger.order
            case .location: return Logger.location
            case .general: return Logger.general
            }
        }
    }

    // MARK: - Public Methods

    static func log(
        _ message: String,
        level: Level = .info,
        category: Category = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "\(level.emoji) [\(fileName):\(line)] \(function) - \(message)"
        print(logMessage)
        #endif

        os_log(
            "%{public}@",
            log: category.osLog,
            type: level.osLogType,
            message
        )
    }

    // MARK: - Convenience Methods

    static func debug(
        _ message: String,
        category: Category = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .debug, category: category, file: file, function: function, line: line)
    }

    static func info(
        _ message: String,
        category: Category = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .info, category: category, file: file, function: function, line: line)
    }

    static func warning(
        _ message: String,
        category: Category = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .warning, category: category, file: file, function: function, line: line)
    }

    static func error(
        _ message: String,
        category: Category = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .error, category: category, file: file, function: function, line: line)
    }

    // MARK: - Network Logging

    static func networkRequest(_ request: URLRequest) {
        #if DEBUG
        var message = "→ \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")"

        if let headers = request.allHTTPHeaderFields {
            message += "\nHeaders: \(headers)"
        }

        if let body = request.httpBody,
           let bodyString = String(data: body, encoding: .utf8) {
            message += "\nBody: \(bodyString)"
        }

        log(message, level: .debug, category: .network)
        #endif
    }

    static func networkResponse(_ response: URLResponse?, data: Data?, error: Error?) {
        #if DEBUG
        var message = "← Response"

        if let httpResponse = response as? HTTPURLResponse {
            message += " [\(httpResponse.statusCode)]"
        }

        if let data = data,
           let jsonString = String(data: data, encoding: .utf8) {
            message += "\nData: \(jsonString)"
        }

        if let error = error {
            message += "\nError: \(error.localizedDescription)"
        }

        log(message, level: error != nil ? .error : .debug, category: .network)
        #endif
    }
}