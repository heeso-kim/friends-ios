import Foundation
import Combine

/// 주문 리포지토리 프로토콜
protocol OrderRepositoryProtocol {
    func getOrders(filter: OrderFilter?) -> AnyPublisher<[Order], AppError>
    func getOrdersWithPagination(page: Int, size: Int, filter: OrderFilter?) -> AnyPublisher<OrderPage, AppError>
    func getOrder(id: String) -> AnyPublisher<Order, AppError>
    func acceptOrder(id: String) -> AnyPublisher<Order, AppError>
    func rejectOrder(id: String, reason: String) -> AnyPublisher<Void, AppError>
    func startPickup(id: String) -> AnyPublisher<Order, AppError>
    func completePickup(id: String) -> AnyPublisher<Order, AppError>
    func startDelivery(id: String) -> AnyPublisher<Order, AppError>
    func completeOrder(id: String, photoUrl: String?, signatureUrl: String?) -> AnyPublisher<Order, AppError>
    func cancelOrder(id: String, reason: String) -> AnyPublisher<Void, AppError>
    func getOrderHistory(days: Int) -> AnyPublisher<[Order], AppError>
    func getOrderStatistics(startDate: Date, endDate: Date) -> AnyPublisher<OrderStatistics, AppError>
}

/// 주문 통계
struct OrderStatistics: Codable, Equatable {
    let totalOrders: Int
    let completedOrders: Int
    let cancelledOrders: Int
    let totalRevenue: Decimal
    let averageDeliveryTime: TimeInterval
    let averageRating: Double?