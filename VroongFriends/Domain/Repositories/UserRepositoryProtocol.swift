import Foundation
import Combine

/// 사용자 리포지토리 프로토콜
protocol UserRepositoryProtocol {
    func getCurrentUser() -> AnyPublisher<User, AppError>
    func updateUser(_ user: User) -> AnyPublisher<User, AppError>
    func updateProfileImage(_ image: Data) -> AnyPublisher<String, AppError>
    func updateDriverLicense(_ license: DriverLicense) -> AnyPublisher<User, AppError>
    func updateVehicle(_ vehicle: Vehicle) -> AnyPublisher<User, AppError>
    func deleteAccount() -> AnyPublisher<Void, AppError>
}