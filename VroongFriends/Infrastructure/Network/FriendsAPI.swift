import Foundation
import Moya

/// Friends API 엔드포인트 정의
enum FriendsAPI {
    // Authentication
    case login(username: String, password: String)
    case logout
    case refreshToken(refreshToken: String)
    case validateToken(token: String)

    // User
    case getCurrentUser
    case updateProfile(profile: UpdateProfileRequest)
    case updateUser(request: UpdateUserRequest)
    case uploadProfileImage(imageData: Data)
    case updateDriverLicense(request: UpdateDriverLicenseRequest)
    case updateVehicle(request: UpdateVehicleRequest)
    case deleteAccount

    // Orders
    case getOrders(status: OrderStatus?)
    case getOrderDetail(orderId: String)
    case acceptOrder(orderId: String)
    case declineOrder(orderId: String)
    case completeOrder(orderId: String, request: CompleteOrderRequest)

    // Location
    case updateLocation(location: LocationUpdateRequest)
    case getRoute(from: Coordinate, to: Coordinate)

    // Payment
    case getMCashBalance
    case getMCashHistory(page: Int, size: Int)
    case requestWithdrawal(amount: Decimal)
}

// MARK: - TargetType

extension FriendsAPI: TargetType {
    var baseURL: URL {
        URL(string: Environment.shared.apiBaseURL)!
    }

    var path: String {
        switch self {
        // Auth
        case .login:
            return "/api/v1/auth/login"
        case .logout:
            return "/api/v1/auth/logout"
        case .refreshToken:
            return "/api/v1/auth/refresh"
        case .validateToken:
            return "/api/v1/auth/validate"

        // User
        case .getCurrentUser:
            return "/api/v1/users/me"
        case .updateProfile, .updateUser:
            return "/api/v1/users/me"
        case .uploadProfileImage:
            return "/api/v1/users/me/profile-image"
        case .updateDriverLicense:
            return "/api/v1/users/me/driver-license"
        case .updateVehicle:
            return "/api/v1/users/me/vehicle"
        case .deleteAccount:
            return "/api/v1/users/me"

        // Orders
        case .getOrders:
            return "/api/v1/orders"
        case .getOrderDetail(let orderId):
            return "/api/v1/orders/\(orderId)"
        case .acceptOrder(let orderId):
            return "/api/v1/orders/\(orderId)/accept"
        case .declineOrder(let orderId):
            return "/api/v1/orders/\(orderId)/decline"
        case .completeOrder(let orderId, _):
            return "/api/v1/orders/\(orderId)/complete"

        // Location
        case .updateLocation:
            return "/api/v1/location/update"
        case .getRoute:
            return "/api/v1/location/route"

        // Payment
        case .getMCashBalance:
            return "/api/v1/payment/mcash/balance"
        case .getMCashHistory:
            return "/api/v1/payment/mcash/history"
        case .requestWithdrawal:
            return "/api/v1/payment/mcash/withdrawal"
        }
    }

    var method: Moya.Method {
        switch self {
        case .login, .logout, .refreshToken, .validateToken,
             .acceptOrder, .declineOrder, .completeOrder,
             .updateLocation, .requestWithdrawal,
             .uploadProfileImage:
            return .post

        case .updateProfile, .updateUser, .updateDriverLicense, .updateVehicle:
            return .put

        case .deleteAccount:
            return .delete

        case .getCurrentUser, .getOrders, .getOrderDetail,
             .getRoute, .getMCashBalance, .getMCashHistory:
            return .get
        }
    }

    var task: Task {
        switch self {
        case .login(let username, let password):
            let params = ["username": username, "password": password]
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)

        case .refreshToken(let refreshToken):
            let params = ["refreshToken": refreshToken]
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)

        case .validateToken(let token):
            let params = ["token": token]
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)

        case .updateProfile(let profile):
            return .requestJSONEncodable(profile)

        case .updateUser(let request):
            return .requestJSONEncodable(request)

        case .uploadProfileImage(let imageData):
            let formData = MultipartFormData(provider: .data(imageData), name: "image", fileName: "profile.jpg", mimeType: "image/jpeg")
            return .uploadMultipart([formData])

        case .updateDriverLicense(let request):
            return .requestJSONEncodable(request)

        case .updateVehicle(let request):
            return .requestJSONEncodable(request)

        case .getOrders(let status):
            var params: [String: Any] = [:]
            if let status = status {
                params["status"] = status.rawValue
            }
            return .requestParameters(parameters: params, encoding: URLEncoding.queryString)

        case .completeOrder(_, let request):
            return .requestJSONEncodable(request)

        case .updateLocation(let location):
            return .requestJSONEncodable(location)

        case .getRoute(let from, let to):
            let params = [
                "fromLat": from.latitude,
                "fromLng": from.longitude,
                "toLat": to.latitude,
                "toLng": to.longitude
            ]
            return .requestParameters(parameters: params, encoding: URLEncoding.queryString)

        case .getMCashHistory(let page, let size):
            let params = ["page": page, "size": size]
            return .requestParameters(parameters: params, encoding: URLEncoding.queryString)

        case .requestWithdrawal(let amount):
            let params = ["amount": amount]
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)

        case .logout, .getCurrentUser, .getOrderDetail, .acceptOrder,
             .declineOrder, .getMCashBalance, .deleteAccount:
            return .requestPlain
        }
    }

    var headers: [String: String]? {
        var headers = ["Content-Type": "application/json"]

        // Add auth header for authenticated endpoints
        switch self {
        case .login, .refreshToken:
            break // No auth header needed
        default:
            // Auth header will be added by AuthPlugin
            break
        }

        return headers
    }

    var sampleData: Data {
        // Mock data for testing
        switch self {
        case .login:
            return """
            {
                "accessToken": "mock_access_token",
                "refreshToken": "mock_refresh_token",
                "user": {
                    "id": "123",
                    "username": "testuser",
                    "displayName": "Test User"
                }
            }
            """.data(using: .utf8)!

        case .getOrders:
            return """
            {
                "orders": [
                    {
                        "id": "order1",
                        "status": "pending",
                        "pickupAddress": "서울시 강남구",
                        "deliveryAddress": "서울시 서초구",
                        "price": 15000
                    }
                ]
            }
            """.data(using: .utf8)!

        default:
            return Data()
        }
    }
}