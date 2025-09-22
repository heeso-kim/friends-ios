import Foundation
import UIKit
import Combine
import Photos
import PhotosUI

/// 이미지 업로드 서비스 프로토콜
protocol ImageUploadServiceProtocol {
    func uploadImage(_ image: UIImage, type: ImageType) -> AnyPublisher<String, AppError>
    func uploadImages(_ images: [UIImage], type: ImageType) -> AnyPublisher<[String], AppError>
    func uploadFile(at url: URL) -> AnyPublisher<String, AppError>
    func deleteImage(at url: String) -> AnyPublisher<Void, AppError>
    func compressImage(_ image: UIImage, quality: CGFloat) -> Data?
}

/// 이미지 타입
enum ImageType {
    case profile
    case deliveryProof
    case signature
    case chat
    case document

    var folder: String {
        switch self {
        case .profile: return "profiles"
        case .deliveryProof: return "delivery_proofs"
        case .signature: return "signatures"
        case .chat: return "chat_images"
        case .document: return "documents"
        }
    }

    var maxSize: Int {
        switch self {
        case .profile: return 2 * 1024 * 1024 // 2MB
        case .deliveryProof: return 5 * 1024 * 1024 // 5MB
        case .signature: return 1 * 1024 * 1024 // 1MB
        case .chat: return 10 * 1024 * 1024 // 10MB
        case .document: return 20 * 1024 * 1024 // 20MB
        }
    }

    var compressionQuality: CGFloat {
        switch self {
        case .profile: return 0.8
        case .deliveryProof: return 0.7
        case .signature: return 0.5
        case .chat: return 0.6
        case .document: return 0.9
        }
    }
}

/// 이미지 업로드 서비스
class ImageUploadService: ImageUploadServiceProtocol {
    static let shared = ImageUploadService()

    private let baseURL: String
    private let session: URLSession

    private init() {
        // 환경에 따른 업로드 서버 URL
        switch Environment.shared.flavor {
        case .dev1:
            self.baseURL = "https://dev1-upload.vroong.com"
        case .qa1, .qa2, .qa3, .qa4:
            self.baseURL = "https://qa-upload.vroong.com"
        case .prod:
            self.baseURL = "https://upload.vroong.com"
        }

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
    }

    // MARK: - Upload Methods

    func uploadImage(_ image: UIImage, type: ImageType) -> AnyPublisher<String, AppError> {
        Future<String, AppError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(AppError.unknown("Service not available")))
                return
            }

            // 이미지 압축
            guard let imageData = self.compressImage(image, quality: type.compressionQuality) else {
                promise(.failure(AppError.unknown("이미지 압축 실패")))
                return
            }

            // 파일 크기 체크
            guard imageData.count <= type.maxSize else {
                promise(.failure(AppError.fileTooLarge))
                return
            }

            // 업로드 요청 생성
            let fileName = "\(UUID().uuidString).jpg"
            let uploadURL = URL(string: "\(self.baseURL)/upload/\(type.folder)")!

            var request = URLRequest(url: uploadURL)
            request.httpMethod = "POST"

            // 멀티파트 폼 데이터 생성
            let boundary = "Boundary-\(UUID().uuidString)"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

            // 인증 토큰 추가
            if let token = try? KeychainService.shared.getToken() {
                request.setValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")
            }

            // 바디 생성
            var body = Data()

            // 파일 파트
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)

            // 타입 파트
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"type\"\r\n\r\n".data(using: .utf8)!)
            body.append(type.folder.data(using: .utf8)!)
            body.append("\r\n".data(using: .utf8)!)

            body.append("--\(boundary)--\r\n".data(using: .utf8)!)

            request.httpBody = body

            // 업로드 실행
            self.session.dataTask(with: request) { data, response, error in
                if let error = error {
                    Logger.error("이미지 업로드 실패: \(error)", category: .network)
                    promise(.failure(AppError.networkError(error.localizedDescription)))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    Logger.error("이미지 업로드 HTTP 오류", category: .network)
                    promise(.failure(AppError.uploadFailed))
                    return
                }

                guard let data = data,
                      let result = try? JSONDecoder().decode(UploadResponse.self, from: data) else {
                    promise(.failure(AppError.uploadFailed))
                    return
                }

                Logger.info("이미지 업로드 성공: \(result.url)", category: .network)
                promise(.success(result.url))
            }.resume()
        }
        .eraseToAnyPublisher()
    }

    func uploadImages(_ images: [UIImage], type: ImageType) -> AnyPublisher<[String], AppError> {
        let uploads = images.map { uploadImage($0, type: type) }
        return Publishers.MergeMany(uploads)
            .collect()
            .eraseToAnyPublisher()
    }

    func uploadFile(at url: URL) -> AnyPublisher<String, AppError> {
        Future<String, AppError> { promise in
            // TODO: 파일 업로드 구현
            promise(.success("https://example.com/file.pdf"))
        }
        .eraseToAnyPublisher()
    }

    func deleteImage(at url: String) -> AnyPublisher<Void, AppError> {
        Future<Void, AppError> { promise in
            // TODO: 이미지 삭제 구현
            promise(.success(()))
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Image Compression

    func compressImage(_ image: UIImage, quality: CGFloat) -> Data? {
        // JPEG 압축 시도
        if let jpegData = image.jpegData(compressionQuality: quality) {
            return jpegData
        }

        // PNG로 폴백
        return image.pngData()
    }
}

// MARK: - Upload Response

struct UploadResponse: Codable {
    let success: Bool
    let url: String
    let fileName: String?
    let fileSize: Int64?
    let mimeType: String?
}

// MARK: - Signature Capture View

import SwiftUI
import PencilKit

/// 서명 캡처 뷰
struct SignatureCaptureView: View {
    @Binding var signature: UIImage?
    @State private var canvas = PKCanvasView()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                // Canvas
                CanvasView(canvas: $canvas)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .padding()

                // Buttons
                HStack(spacing: 20) {
                    Button(action: clearCanvas) {
                        Label("지우기", systemImage: "trash")
                            .foregroundColor(.red)
                    }

                    Spacer()

                    Button(action: saveSignature) {
                        Label("저장", systemImage: "checkmark")
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(AppColors.brandPrimary)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("서명")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }
            }
            .background(Color(UIColor.systemGray6))
        }
    }

    private func clearCanvas() {
        canvas.drawing = PKDrawing()
    }

    private func saveSignature() {
        let renderer = UIGraphicsImageRenderer(bounds: canvas.bounds)
        let image = renderer.image { context in
            canvas.layer.render(in: context.cgContext)
        }

        // 배경 제거 및 크롭
        if let croppedImage = cropSignature(image) {
            signature = croppedImage
            dismiss()
        }
    }

    private func cropSignature(_ image: UIImage) -> UIImage? {
        // TODO: 서명 영역만 크롭
        return image
    }
}

/// Canvas 뷰 (UIViewRepresentable)
struct CanvasView: UIViewRepresentable {
    @Binding var canvas: PKCanvasView

    func makeUIView(context: Context) -> PKCanvasView {
        canvas.tool = PKInkingTool(.pen, color: .black, width: 3)
        canvas.backgroundColor = .white
        canvas.isOpaque = false
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Update if needed
    }
}

// MARK: - Photo Picker View

/// 사진 선택 뷰
struct PhotoPickerView: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    let selectionLimit: Int
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = selectionLimit
        configuration.preferredAssetRepresentationMode = .compatible

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // Update if needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPickerView

        init(_ parent: PhotoPickerView) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.selectedImages.removeAll()

            let group = DispatchGroup()

            for result in results {
                group.enter()

                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                        if let image = image as? UIImage {
                            DispatchQueue.main.async {
                                self?.parent.selectedImages.append(image)
                            }
                        }
                        group.leave()
                    }
                } else {
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                self.parent.onDismiss()
                picker.dismiss(animated: true)
            }
        }
    }
}