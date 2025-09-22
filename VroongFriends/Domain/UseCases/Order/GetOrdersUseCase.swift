import Foundation
import Combine

/// 주문 목록 조회 유스케이스
protocol GetOrdersUseCaseProtocol {
    func execute(filter: OrderFilter?) -> AnyPublisher<[Order], AppError>
    func executeWithPagination(page: Int, size: Int, filter: OrderFilter?) -> AnyPublisher<OrderPage, AppError>
}

final class GetOrdersUseCase: GetOrdersUseCaseProtocol {
    private let orderRepository: OrderRepositoryProtocol
    
    init(orderRepository: OrderRepositoryProtocol) {
        self.orderRepository = orderRepository
    }
    
    func execute(filter: OrderFilter?) -> AnyPublisher<[Order], AppError> {
        return orderRepository.getOrders(filter: filter)
            .handleEvents(receiveOutput: { orders in
                Logger.info("주문 \(orders.count)개 조회", category: .order)
            })
            .eraseToAnyPublisher()
    }
    
    func executeWithPagination(page: Int, size: Int, filter: OrderFilter?) -> AnyPublisher<OrderPage, AppError> {
        guard page >= 0 else {
            return Fail(error: AppError.invalidInput(field: "페이지", reason: "페이지는 0 이상이어야 합니다"))
                .eraseToAnyPublisher()
        }
        
        guard size > 0 && size <= 100 else {
            return Fail(error: AppError.invalidInput(field: "크기", reason: "크기는 1-100 사이여야 합니다"))
                .eraseToAnyPublisher()
        }
        
        return orderRepository.getOrdersWithPagination(page: page, size: size, filter: filter)
            .handleEvents(receiveOutput: { page in
                Logger.info("주문 페이지 조회: \(page.page + 1)/\(page.totalPages)", category: .order)
            })
            .eraseToAnyPublisher()
    }
}

// MARK: - Order Filter

struct OrderFilter: Equatable {
    let status: OrderStatus?
    let type: OrderType?
    let startDate: Date?
    let endDate: Date?
    let searchText: String?
    
    var isEmpty: Bool {
        status == nil && type == nil && startDate == nil && endDate == nil && (searchText?.isEmpty ?? true)
    }
}

// MARK: - Order Page

struct OrderPage: Equatable {
    let content: [Order]
    let page: Int
    let size: Int
    let totalElements: Int
    let totalPages: Int
    let isLast: Bool
    let isFirst: Bool
    
    var hasNext: Bool {
        !isLast
    }
    
    var hasPrevious: Bool {
        !isFirst
    }
}