import Foundation
import Combine
import UIKit

/// 주문 완료 유스케이스
protocol CompleteOrderUseCaseProtocol {
    func execute(orderId: String, photo: UIImage?, signature: UIImage?) -> AnyPublisher<Order, AppError>
}

final class CompleteOrderUseCase: CompleteOrderUseCaseProtocol {
    private let orderRepository: OrderRepositoryProtocol
    private let uploadService: UploadServiceProtocol
    
    init(
        orderRepository: OrderRepositoryProtocol,
        uploadService: UploadServiceProtocol
    ) {
        self.orderRepository = orderRepository
        self.uploadService = uploadService
    }
    
    func execute(orderId: String, photo: UIImage?, signature: UIImage?) -> AnyPublisher<Order, AppError> {
        guard !orderId.isEmpty else {
            return Fail(error: AppError.missingRequiredField(field: "주문 ID"))
                .eraseToAnyPublisher()
        }
        
        // 주문 조회
        return orderRepository.getOrder(id: orderId)
            .flatMap { [weak self] order -> AnyPublisher<Order, AppError> in
                guard let self = self else {
                    return Fail(error: AppError.unknown("예상치 못한 오류"))
                        .eraseToAnyPublisher()
                }
                
                // 주문 상태 확인
                guard order.isInProgress else {
                    return Fail(error: AppError.orderCannotBeModified)
                        .eraseToAnyPublisher()
                }
                
                // 이미지 업로드
                var photoUrlPublisher: AnyPublisher<String?, Never> = Just(nil).eraseToAnyPublisher()
                var signatureUrlPublisher: AnyPublisher<String?, Never> = Just(nil).eraseToAnyPublisher()
                
                if let photo = photo {
                    photoUrlPublisher = self.uploadService.uploadImage(photo, type: .delivery)
                        .map { Optional($0) }
                        .replaceError(with: nil)
                        .eraseToAnyPublisher()
                }
                
                if let signature = signature {
                    signatureUrlPublisher = self.uploadService.uploadImage(signature, type: .signature)
                        .map { Optional($0) }
                        .replaceError(with: nil)
                        .eraseToAnyPublisher()
                }
                
                // 이미지 업로드 완료 후 주문 완료
                return Publishers.Zip(photoUrlPublisher, signatureUrlPublisher)
                    .flatMap { photoUrl, signatureUrl -> AnyPublisher<Order, AppError> in
                        self.orderRepository.completeOrder(
                            id: orderId,
                            photoUrl: photoUrl,
                            signatureUrl: signatureUrl
                        )
                    }
                    .eraseToAnyPublisher()
            }
            .handleEvents(receiveOutput: { order in
                Logger.info("주문 완료: \(order.orderNumber)", category: .order)
            })
            .eraseToAnyPublisher()
    }
}