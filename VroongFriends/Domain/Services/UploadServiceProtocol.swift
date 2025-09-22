import Foundation
import Combine
import UIKit

/// 업로드 서비스 프로토콜
protocol UploadServiceProtocol {
    func uploadImage(_ image: UIImage, type: ImageType) -> AnyPublisher<String, AppError>
    func uploadImages(_ images: [UIImage], type: ImageType) -> AnyPublisher<[String], AppError>
    func deleteFile(_ url: String) -> AnyPublisher<Void, AppError>
}

/// 이미지 타입
enum ImageType: String {
    case profile = "PROFILE"
    case delivery = "DELIVERY"
    case signature = "SIGNATURE"
    case helmetPhoto = "HELMET"
    case driverLicense = "DRIVER_LICENSE"
    case criminalRecord = "CRIMINAL_RECORD"
    
    var maxSize: Int {
        switch self {
        case .profile, .helmetPhoto: 
            return 5 * 1024 * 1024 // 5MB
        case .delivery, .signature, .driverLicense, .criminalRecord: 
            return 10 * 1024 * 1024 // 10MB
        }
    }
    
    var compressionQuality: CGFloat {
        switch self {
        case .profile, .helmetPhoto: 
            return 0.8
        case .delivery, .signature: 
            return 0.7
        case .driverLicense, .criminalRecord: 
            return 0.9 // 문서는 높은 품질 유지
        }
    }
}