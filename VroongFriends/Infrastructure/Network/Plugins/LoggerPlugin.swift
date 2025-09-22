import Foundation
import Moya

/// 네트워크 로깅 플러그인
struct LoggerPlugin: PluginType {
    func willSend(_ request: RequestType, target: TargetType) {
        #if DEBUG
        guard let httpRequest = request.request else { return }
        
        Logger.debug("➜ API Request", category: .network)
        Logger.debug("URL: \(httpRequest.url?.absoluteString ?? "")", category: .network)
        Logger.debug("Method: \(httpRequest.httpMethod ?? "")", category: .network)
        
        if let headers = httpRequest.allHTTPHeaderFields {
            Logger.debug("Headers: \(headers)", category: .network)
        }
        
        if let body = httpRequest.httpBody,
           let bodyString = String(data: body, encoding: .utf8) {
            Logger.debug("Body: \(bodyString)", category: .network)
        }
        #endif
    }
    
    func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
        #if DEBUG
        switch result {
        case .success(let response):
            Logger.debug("✨ API Response [\(response.statusCode)]", category: .network)
            
            if let json = try? response.mapJSON(),
               let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
               let prettyString = String(data: jsonData, encoding: .utf8) {
                Logger.debug("Response: \(prettyString)", category: .network)
            }
            
        case .failure(let error):
            Logger.error("❌ API Error: \(error.localizedDescription)", category: .network)
            
            if case let .statusCode(response) = error,
               let json = try? response.mapJSON(),
               let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
               let prettyString = String(data: jsonData, encoding: .utf8) {
                Logger.error("Error Response: \(prettyString)", category: .network)
            }
        }
        #endif
    }
}