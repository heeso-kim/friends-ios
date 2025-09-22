import Foundation
import Combine

/// 주문 수락 유스케이스
protocol AcceptOrderUseCaseProtocol {
    func execute(orderId: String) -> AnyPublisher<Order, AppError>
}

final class AcceptOrderUseCase: AcceptOrderUseCaseProtocol {
    private let orderRepository: OrderRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    
    init(
        orderRepository: OrderRepositoryProtocol,
        userRepository: UserRepositoryProtocol
    ) {
        self.orderRepository = orderRepository
        self.userRepository = userRepository
    }
    
    func execute(orderId: String) -> AnyPublisher<Order, AppError> {
        guard !orderId.isEmpty else {
            return Fail(error: AppError.missingRequiredField(field: "주문 ID"))
                .eraseToAnyPublisher()
        }
        
        // 먼저 사용자 상태 확인
        return userRepository.getCurrentUser()
            .flatMap { [weak self] user -> AnyPublisher<Order, AppError> in
                guard let self = self else {
                    return Fail(error: AppError.unknown("예상치 못한 오류"))
                        .eraseToAnyPublisher()
                }
                
                // 사용자가 주문을 수락할 수 있는지 확인
                guard user.canAcceptOrders else {
                    return Fail(error: AppError.unauthorized)
                        .eraseToAnyPublisher()
                }
                
                // 주문 조회
                return self.orderRepository.getOrder(id: orderId)
            }
            .flatMap { [weak self] order -> AnyPublisher<Order, AppError> in
                guard let self = self else {
                    return Fail(error: AppError.unknown("예상치 못한 오류"))
                        .eraseToAnyPublisher()
                }
                
                // 주문 상태 확인
                guard order.isAcceptable else {
                    if order.status == .accepted || order.status == .pickingUp || order.status == .delivering {
                        return Fail(error: AppError.orderAlreadyAccepted)
                            .eraseToAnyPublisher()
                    } else {
                        return Fail(error: AppError.orderCannotBeModified)
                            .eraseToAnyPublisher()
                    }
                }
                
                // 주문 수락
                return self.orderRepository.acceptOrder(id: orderId)
            }
            .handleEvents(receiveOutput: { order in
                Logger.info("주문 수락 성공: \(order.orderNumber)", category: .order)
            }, receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("주문 수락 실패: \(error.localizedDescription)", category: .order)
                }
            })
            .eraseToAnyPublisher()
    }
}