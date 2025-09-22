import Foundation
import Combine
import Moya

/// 사용자 리포지토리 구현체
final class UserRepository: UserRepositoryProtocol {
    private let provider: MoyaProvider<FriendsAPI>
    private var currentUserCache: User?
    private let cacheExpiration: TimeInterval = 300 // 5분
    private var lastCacheTime: Date?
    
    init(provider: MoyaProvider<FriendsAPI>) {
        self.provider = provider
    }
    
    func getCurrentUser() -> AnyPublisher<User, AppError> {
        // 캐시 확인
        if let cachedUser = currentUserCache,
           let lastTime = lastCacheTime,
           Date().timeIntervalSince(lastTime) < cacheExpiration {
            return Just(cachedUser)
                .setFailureType(to: AppError.self)
                .eraseToAnyPublisher()
        }
        
        return provider.requestPublisher(.getCurrentUser)
            .map(UserDTO.self)
            .map { [weak self] dto in
                let user = dto.toEntity()
                self?.currentUserCache = user
                self?.lastCacheTime = Date()
                return user
            }
            .mapError { error in
                if let moyaError = error as? MoyaError,
                   case .statusCode(let response) = moyaError,
                   response.statusCode == 401 {
                    return AppError.unauthorized
                }
                return AppError.networkError(error.localizedDescription)
            }
            .eraseToAnyPublisher()
    }
    
    func updateUser(_ user: User) -> AnyPublisher<User, AppError> {
        let request = UpdateUserRequest(
            displayName: user.displayName,
            phoneNumber: user.phoneNumber,
            email: user.email
        )
        
        return provider.requestPublisher(.updateUser(request))
            .map(UserDTO.self)
            .map { [weak self] dto in
                let updatedUser = dto.toEntity()
                self?.currentUserCache = updatedUser
                self?.lastCacheTime = Date()
                return updatedUser
            }
            .mapError { _ in AppError.unknown("사용자 정보 업데이트 실패") }
            .eraseToAnyPublisher()
    }
    
    func updateProfileImage(_ image: Data) -> AnyPublisher<String, AppError> {
        return provider.requestPublisher(.uploadProfileImage(image))
            .map(UploadResponseDTO.self)
            .map { $0.url }
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.invalidateCache()
            })
            .mapError { _ in AppError.unknown("프로필 이미지 업로드 실패") }
            .eraseToAnyPublisher()
    }
    
    func updateDriverLicense(_ license: DriverLicense) -> AnyPublisher<User, AppError> {
        let request = UpdateDriverLicenseRequest(
            licenseNumber: license.licenseNumber,
            licenseType: license.licenseType.rawValue,
            expiryDate: license.expiryDate
        )
        
        return provider.requestPublisher(.updateDriverLicense(request))
            .map(UserDTO.self)
            .map { [weak self] dto in
                let updatedUser = dto.toEntity()
                self?.currentUserCache = updatedUser
                self?.lastCacheTime = Date()
                return updatedUser
            }
            .mapError { _ in AppError.unknown("운전면허 정보 업데이트 실패") }
            .eraseToAnyPublisher()
    }
    
    func updateVehicle(_ vehicle: Vehicle) -> AnyPublisher<User, AppError> {
        let request = UpdateVehicleRequest(
            type: vehicle.type.rawValue,
            licensePlate: vehicle.licensePlate,
            manufacturer: vehicle.manufacturer,
            model: vehicle.model,
            year: vehicle.year,
            color: vehicle.color
        )
        
        return provider.requestPublisher(.updateVehicle(request))
            .map(UserDTO.self)
            .map { [weak self] dto in
                let updatedUser = dto.toEntity()
                self?.currentUserCache = updatedUser
                self?.lastCacheTime = Date()
                return updatedUser
            }
            .mapError { _ in AppError.unknown("차량 정보 업데이트 실패") }
            .eraseToAnyPublisher()
    }
    
    func deleteAccount() -> AnyPublisher<Void, AppError> {
        return provider.requestPublisher(.deleteAccount)
            .map { _ in () }
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.invalidateCache()
            })
            .mapError { _ in AppError.unknown("계정 삭제 실패") }
            .eraseToAnyPublisher()
    }
    
    private func invalidateCache() {
        currentUserCache = nil
        lastCacheTime = nil
    }
}

// MARK: - DTOs

struct UserDTO: Codable {
    let id: String
    let username: String
    let displayName: String
    let email: String?
    let phoneNumber: String?
    let profileImageUrl: String?
    let agentId: String?
    let agentStatus: String
    let employmentStatus: String
    let driverLicense: DriverLicenseDTO?
    let vehicle: VehicleDTO?
    let permissions: [String]
    let createdAt: Date
    let updatedAt: Date
    
    func toEntity() -> User {
        User(
            id: id,
            username: username,
            displayName: displayName,
            email: email,
            phoneNumber: phoneNumber,
            profileImageUrl: profileImageUrl,
            agentId: agentId,
            agentStatus: AgentStatus(rawValue: agentStatus) ?? .pending,
            employmentStatus: EmploymentStatus(rawValue: employmentStatus) ?? .fullTime,
            createdAt: createdAt,
            updatedAt: updatedAt,
            driverLicense: driverLicense?.toEntity(),
            vehicle: vehicle?.toEntity(),
            permissions: Set(permissions.compactMap { Permission(rawValue: $0) })
        )
    }
}

struct DriverLicenseDTO: Codable {
    let licenseNumber: String
    let licenseType: String
    let issuedDate: Date
    let expiryDate: Date
    let isVerified: Bool
    
    func toEntity() -> DriverLicense {
        DriverLicense(
            licenseNumber: licenseNumber,
            licenseType: DriverLicense.LicenseType(rawValue: licenseType) ?? .type2,
            issuedDate: issuedDate,
            expiryDate: expiryDate,
            isVerified: isVerified
        )
    }
}

struct VehicleDTO: Codable {
    let id: String
    let type: String
    let licensePlate: String
    let manufacturer: String?
    let model: String?
    let year: Int?
    let color: String?
    let isVerified: Bool
    
    func toEntity() -> Vehicle {
        Vehicle(
            id: id,
            type: Vehicle.VehicleType(rawValue: type) ?? .motorcycle,
            licensePlate: licensePlate,
            manufacturer: manufacturer,
            model: model,
            year: year,
            color: color,
            isVerified: isVerified
        )
    }
}

struct UpdateUserRequest: Encodable {
    let displayName: String
    let phoneNumber: String?
    let email: String?
}

struct UpdateDriverLicenseRequest: Encodable {
    let licenseNumber: String
    let licenseType: String
    let expiryDate: Date
}

struct UpdateVehicleRequest: Encodable {
    let type: String
    let licensePlate: String
    let manufacturer: String?
    let model: String?
    let year: Int?
    let color: String?
}

struct UploadResponseDTO: Codable {
    let url: String
    let fileName: String?
}