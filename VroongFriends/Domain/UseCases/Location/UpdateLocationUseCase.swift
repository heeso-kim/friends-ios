import Foundation
import Combine
import CoreLocation

/// 위치 업데이트 유스케이스
protocol UpdateLocationUseCaseProtocol {
    func execute(location: CLLocation) -> AnyPublisher<Void, AppError>
    func startTracking() -> AnyPublisher<Void, AppError>
    func stopTracking() -> AnyPublisher<Void, AppError>
}

final class UpdateLocationUseCase: UpdateLocationUseCaseProtocol {
    private let locationRepository: LocationRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    
    init(
        locationRepository: LocationRepositoryProtocol,
        userRepository: UserRepositoryProtocol
    ) {
        self.locationRepository = locationRepository
        self.userRepository = userRepository
    }
    
    func execute(location: CLLocation) -> AnyPublisher<Void, AppError> {
        // 위치 유효성 확인
        guard location.coordinate.latitude >= -90 && location.coordinate.latitude <= 90,
              location.coordinate.longitude >= -180 && location.coordinate.longitude <= 180 else {
            return Fail(error: AppError.invalidInput(field: "위치", reason: "유효하지 않은 좌표"))
                .eraseToAnyPublisher()
        }
        
        // 사용자 상태 확인
        return userRepository.getCurrentUser()
            .flatMap { [weak self] user -> AnyPublisher<Void, AppError> in
                guard let self = self else {
                    return Fail(error: AppError.unknown("예상치 못한 오류"))
                        .eraseToAnyPublisher()
                }
                
                // 활성 상태인 경우에만 위치 업데이트
                guard user.isActive else {
                    Logger.warning("비활성 상태에서 위치 업데이트 시도", category: .location)
                    return Just(()).setFailureType(to: AppError.self).eraseToAnyPublisher()
                }
                
                // 위치 업데이트
                return self.locationRepository.updateLocation(location)
            }
            .handleEvents(receiveOutput: { _ in
                Logger.debug("위치 업데이트: \(location.coordinate.latitude), \(location.coordinate.longitude)", category: .location)
            })
            .eraseToAnyPublisher()
    }
    
    func startTracking() -> AnyPublisher<Void, AppError> {
        return locationRepository.startLocationTracking()
            .handleEvents(receiveOutput: { _ in
                Logger.info("위치 추적 시작", category: .location)
            })
            .eraseToAnyPublisher()
    }
    
    func stopTracking() -> AnyPublisher<Void, AppError> {
        return locationRepository.stopLocationTracking()
            .handleEvents(receiveOutput: { _ in
                Logger.info("위치 추적 종료", category: .location)
            })
            .eraseToAnyPublisher()
    }
}