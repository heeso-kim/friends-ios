import Foundation
import Combine
import Moya

/// 주문 리포지토리 구현체
final class OrderRepository: OrderRepositoryProtocol {
    private let provider: MoyaProvider<FriendsAPI>
    
    init(provider: MoyaProvider<FriendsAPI>) {
        self.provider = provider
    }
    
    func getOrders(filter: OrderFilter?) -> AnyPublisher<[Order], AppError> {
        var parameters: [String: Any] = [:]
        
        if let filter = filter {
            if let status = filter.status {
                parameters["status"] = status.rawValue
            }
            if let type = filter.type {
                parameters["type"] = type.rawValue
            }
            if let startDate = filter.startDate {
                parameters["startDate"] = ISO8601DateFormatter().string(from: startDate)
            }
            if let endDate = filter.endDate {
                parameters["endDate"] = ISO8601DateFormatter().string(from: endDate)
            }
            if let searchText = filter.searchText {
                parameters["search"] = searchText
            }
        }
        
        return provider.requestPublisher(.getOrders(parameters: parameters))
            .map([OrderDTO].self)
            .map { $0.map { $0.toEntity() } }
            .mapError(mapMoyaError)
            .eraseToAnyPublisher()
    }
    
    func getOrdersWithPagination(page: Int, size: Int, filter: OrderFilter?) -> AnyPublisher<OrderPage, AppError> {
        var parameters: [String: Any] = [
            "page": page,
            "size": size
        ]
        
        if let filter = filter {
            if let status = filter.status {
                parameters["status"] = status.rawValue
            }
            if let type = filter.type {
                parameters["type"] = type.rawValue
            }
        }
        
        return provider.requestPublisher(.getOrders(parameters: parameters))
            .map(PageDTO<OrderDTO>.self)
            .map { pageDTO in
                OrderPage(
                    content: pageDTO.content.map { $0.toEntity() },
                    page: pageDTO.page,
                    size: pageDTO.size,
                    totalElements: pageDTO.totalElements,
                    totalPages: pageDTO.totalPages,
                    isLast: pageDTO.isLast,
                    isFirst: pageDTO.isFirst
                )
            }
            .mapError(mapMoyaError)
            .eraseToAnyPublisher()
    }
    
    func getOrder(id: String) -> AnyPublisher<Order, AppError> {
        return provider.requestPublisher(.getOrder(id: id))
            .map(OrderDTO.self)
            .map { $0.toEntity() }
            .mapError { error in
                if let moyaError = error as? MoyaError,
                   case .statusCode(let response) = moyaError,
                   response.statusCode == 404 {
                    return AppError.orderNotFound
                }
                return self.mapMoyaError(error)
            }
            .eraseToAnyPublisher()
    }
    
    func acceptOrder(id: String) -> AnyPublisher<Order, AppError> {
        return provider.requestPublisher(.acceptOrder(id: id))
            .map(OrderDTO.self)
            .map { $0.toEntity() }
            .mapError { error in
                if let moyaError = error as? MoyaError,
                   case .statusCode(let response) = moyaError {
                    if response.statusCode == 409 {
                        return AppError.orderAlreadyAccepted
                    }
                    if response.statusCode == 404 {
                        return AppError.orderNotFound
                    }
                }
                return self.mapMoyaError(error)
            }
            .eraseToAnyPublisher()
    }
    
    func rejectOrder(id: String, reason: String) -> AnyPublisher<Void, AppError> {
        return provider.requestPublisher(.rejectOrder(id: id, reason: reason))
            .map { _ in () }
            .mapError(mapMoyaError)
            .eraseToAnyPublisher()
    }
    
    func startPickup(id: String) -> AnyPublisher<Order, AppError> {
        return provider.requestPublisher(.updateOrderStatus(id: id, status: "PICKING_UP"))
            .map(OrderDTO.self)
            .map { $0.toEntity() }
            .mapError(mapMoyaError)
            .eraseToAnyPublisher()
    }
    
    func completePickup(id: String) -> AnyPublisher<Order, AppError> {
        return provider.requestPublisher(.updateOrderStatus(id: id, status: "DELIVERING"))
            .map(OrderDTO.self)
            .map { $0.toEntity() }
            .mapError(mapMoyaError)
            .eraseToAnyPublisher()
    }
    
    func startDelivery(id: String) -> AnyPublisher<Order, AppError> {
        return provider.requestPublisher(.updateOrderStatus(id: id, status: "DELIVERING"))
            .map(OrderDTO.self)
            .map { $0.toEntity() }
            .mapError(mapMoyaError)
            .eraseToAnyPublisher()
    }
    
    func completeOrder(id: String, photoUrl: String?, signatureUrl: String?) -> AnyPublisher<Order, AppError> {
        let request = CompleteOrderRequest(
            photoUrl: photoUrl,
            signatureUrl: signatureUrl
        )
        
        return provider.requestPublisher(.completeOrder(id: id, request: request))
            .map(OrderDTO.self)
            .map { $0.toEntity() }
            .mapError(mapMoyaError)
            .eraseToAnyPublisher()
    }
    
    func cancelOrder(id: String, reason: String) -> AnyPublisher<Void, AppError> {
        return provider.requestPublisher(.cancelOrder(id: id, reason: reason))
            .map { _ in () }
            .mapError(mapMoyaError)
            .eraseToAnyPublisher()
    }
    
    func getOrderHistory(days: Int) -> AnyPublisher<[Order], AppError> {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        
        let filter = OrderFilter(
            status: nil,
            type: nil,
            startDate: startDate,
            endDate: endDate,
            searchText: nil
        )
        
        return getOrders(filter: filter)
    }
    
    func getOrderStatistics(startDate: Date, endDate: Date) -> AnyPublisher<OrderStatistics, AppError> {
        let parameters: [String: Any] = [
            "startDate": ISO8601DateFormatter().string(from: startDate),
            "endDate": ISO8601DateFormatter().string(from: endDate)
        ]
        
        return provider.requestPublisher(.getOrderStatistics(parameters: parameters))
            .map(OrderStatisticsDTO.self)
            .map { dto in
                OrderStatistics(
                    totalOrders: dto.totalOrders,
                    completedOrders: dto.completedOrders,
                    cancelledOrders: dto.cancelledOrders,
                    totalRevenue: Decimal(dto.totalRevenue),
                    averageDeliveryTime: TimeInterval(dto.averageDeliveryTime),
                    averageRating: dto.averageRating
                )
            }
            .mapError(mapMoyaError)
            .eraseToAnyPublisher()
    }
    
    private func mapMoyaError(_ error: Error) -> AppError {
        if let moyaError = error as? MoyaError {
            switch moyaError {
            case .statusCode(let response):
                if response.statusCode == 401 {
                    return AppError.unauthorized
                }
                return AppError.serverError(code: response.statusCode, message: nil)
            case .underlying(let underlyingError, _):
                if (underlyingError as NSError).code == NSURLErrorNotConnectedToInternet {
                    return AppError.noInternetConnection
                }
                return AppError.networkError(underlyingError.localizedDescription)
            default:
                return AppError.networkError(moyaError.localizedDescription)
            }
        }
        return AppError.unknown(error.localizedDescription)
    }
}

// MARK: - DTOs

struct OrderDTO: Codable {
    let id: String
    let orderNumber: String
    let status: String
    let type: String
    let customer: CustomerDTO
    let pickupLocation: LocationDTO
    let pickupTime: Date?
    let pickupNote: String?
    let deliveryLocation: LocationDTO
    let deliveryTime: Date?
    let deliveryNote: String?
    let items: [OrderItemDTO]
    let payment: PaymentDTO
    let assignedAgent: AgentDTO?
    let assignedAt: Date?
    let acceptedAt: Date?
    let completedAt: Date?
    let estimatedDistance: Double?
    let estimatedDuration: Int?
    let actualDistance: Double?
    let actualDuration: Int?
    let createdAt: Date
    let updatedAt: Date
    
    func toEntity() -> Order {
        Order(
            id: id,
            orderNumber: orderNumber,
            status: OrderStatus(rawValue: status) ?? .pending,
            type: OrderType(rawValue: type) ?? .normal,
            customer: customer.toEntity(),
            pickupLocation: pickupLocation.toEntity(),
            pickupTime: pickupTime,
            pickupNote: pickupNote,
            deliveryLocation: deliveryLocation.toEntity(),
            deliveryTime: deliveryTime,
            deliveryNote: deliveryNote,
            items: items.map { $0.toEntity() },
            payment: payment.toEntity(),
            assignedAgent: assignedAgent?.toEntity(),
            assignedAt: assignedAt,
            acceptedAt: acceptedAt,
            completedAt: completedAt,
            estimatedDistance: estimatedDistance,
            estimatedDuration: estimatedDuration,
            actualDistance: actualDistance,
            actualDuration: actualDuration,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

struct CustomerDTO: Codable {
    let id: String
    let name: String
    let phoneNumber: String
    let email: String?
    let isVip: Bool
    
    func toEntity() -> Customer {
        Customer(
            id: id,
            name: name,
            phoneNumber: phoneNumber,
            email: email,
            isVip: isVip
        )
    }
}

struct LocationDTO: Codable {
    let id: String?
    let address: String
    let detailAddress: String?
    let latitude: Double
    let longitude: Double
    let note: String?
    let contactName: String?
    let contactPhone: String?
    
    func toEntity() -> Location {
        Location(
            id: id,
            address: address,
            detailAddress: detailAddress,
            coordinate: Coordinate(
                latitude: latitude,
                longitude: longitude
            ),
            note: note,
            contactName: contactName,
            contactPhone: contactPhone
        )
    }
}

struct OrderItemDTO: Codable {
    let id: String
    let name: String
    let description: String?
    let quantity: Int
    let price: Double
    let imageUrl: String?
    
    func toEntity() -> OrderItem {
        OrderItem(
            id: id,
            name: name,
            description: description,
            quantity: quantity,
            price: Decimal(price),
            imageUrl: imageUrl
        )
    }
}

struct PaymentDTO: Codable {
    let method: String
    let baseAmount: Double
    let deliveryFee: Double
    let tip: Double
    let discount: Double
    let totalAmount: Double
    let isPaid: Bool
    let paidAt: Date?
    
    func toEntity() -> Payment {
        Payment(
            method: Payment.PaymentMethod(rawValue: method) ?? .cash,
            baseAmount: Decimal(baseAmount),
            deliveryFee: Decimal(deliveryFee),
            tip: Decimal(tip),
            discount: Decimal(discount),
            totalAmount: Decimal(totalAmount),
            isPaid: isPaid,
            paidAt: paidAt
        )
    }
}

struct AgentDTO: Codable {
    let id: String
    let name: String
    let phoneNumber: String
    let vehicleType: String
    let profileImageUrl: String?
    
    func toEntity() -> Agent {
        Agent(
            id: id,
            name: name,
            phoneNumber: phoneNumber,
            vehicleType: Vehicle.VehicleType(rawValue: vehicleType) ?? .motorcycle,
            profileImageUrl: profileImageUrl
        )
    }
}

struct CompleteOrderRequest: Encodable {
    let photoUrl: String?
    let signatureUrl: String?
}

struct OrderStatisticsDTO: Codable {
    let totalOrders: Int
    let completedOrders: Int
    let cancelledOrders: Int
    let totalRevenue: Double
    let averageDeliveryTime: Double
    let averageRating: Double?
}

struct PageDTO<T: Codable>: Codable {
    let content: [T]
    let page: Int
    let size: Int
    let totalElements: Int
    let totalPages: Int
    let isLast: Bool
    let isFirst: Bool
}