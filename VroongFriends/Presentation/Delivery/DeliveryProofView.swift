import SwiftUI
import AVFoundation
import PhotosUI

/// 배달 증명 화면
struct DeliveryProofView: View {
    let orderId: String
    @State private var deliveryPhoto: UIImage?
    @State private var customerSignature: UIImage?
    @State private var showingCamera = false
    @State private var showingSignaturePad = false
    @State private var showingPhotoPicker = false
    @State private var isUploading = false
    @State private var completionNote = ""
    @StateObject private var uploadService = DeliveryProofViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Instructions
                    instructionCard

                    // Delivery Photo
                    photoSection

                    // Customer Signature
                    signatureSection

                    // Completion Note
                    noteSection

                    // Submit Button
                    submitButton
                }
                .padding()
            }
            .navigationTitle("배달 완료")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCamera) {
                CameraView(capturedImage: $deliveryPhoto)
            }
            .sheet(isPresented: $showingSignaturePad) {
                SignatureCaptureView(signature: $customerSignature)
            }
            .sheet(isPresented: $showingPhotoPicker) {
                PhotoPickerView(
                    selectedImages: .init(
                        get: { deliveryPhoto.map { [$0] } ?? [] },
                        set: { deliveryPhoto = $0.first }
                    ),
                    selectionLimit: 1,
                    onDismiss: { showingPhotoPicker = false }
                )
            }
            .disabled(isUploading)
            .overlay(
                Group {
                    if isUploading {
                        uploadingOverlay
                    }
                }
            )
        }
    }

    // MARK: - Instruction Card

    private var instructionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("배달 완료 확인", systemImage: "checkmark.circle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.brandPrimary)

            Text("배달 완료를 위해 아래 항목을 완료해주세요:")
                .font(.system(size: 14))
                .foregroundColor(.gray)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: deliveryPhoto != nil ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(deliveryPhoto != nil ? .green : .gray)
                        .font(.system(size: 14))
                    Text("배달 사진 촬영")
                        .font(.system(size: 13))
                }

                HStack(spacing: 8) {
                    Image(systemName: customerSignature != nil ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(customerSignature != nil ? .green : .gray)
                        .font(.system(size: 14))
                    Text("고객 서명 받기 (선택)")
                        .font(.system(size: 13))
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Photo Section

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("배달 사진", systemImage: "camera.fill")
                .font(.system(size: 14, weight: .medium))

            if let photo = deliveryPhoto {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(8)

                    Button(action: { deliveryPhoto = nil }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    .padding(8)
                }
            } else {
                HStack(spacing: 12) {
                    Button(action: { showingCamera = true }) {
                        VStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 24))
                            Text("카메라")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(AppColors.brandPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AppColors.brandPrimary, lineWidth: 1)
                        )
                    }

                    Button(action: { showingPhotoPicker = true }) {
                        VStack(spacing: 8) {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 24))
                            Text("갤러리")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(AppColors.brandPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AppColors.brandPrimary, lineWidth: 1)
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4)
    }

    // MARK: - Signature Section

    private var signatureSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("고객 서명 (선택)", systemImage: "signature")
                .font(.system(size: 14, weight: .medium))

            if let signature = customerSignature {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: signature)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 150)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )

                    Button(action: { customerSignature = nil }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    .padding(8)
                }
            } else {
                Button(action: { showingSignaturePad = true }) {
                    HStack {
                        Image(systemName: "signature")
                            .font(.system(size: 20))
                        Text("서명 받기")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(AppColors.brandPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppColors.brandPrimary, lineWidth: 1)
                    )
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4)
    }

    // MARK: - Note Section

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("완료 메모 (선택)", systemImage: "note.text")
                .font(.system(size: 14, weight: .medium))

            TextField("배달 완료 메모를 입력하세요", text: $completionNote, axis: .vertical)
                .lineLimit(3...6)
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4)
    }

    // MARK: - Submit Button

    private var submitButton: some View {
        Button(action: submitDeliveryProof) {
            if isUploading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                Text("배달 완료")
                    .font(.system(size: 16, weight: .semibold))
            }
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(
            deliveryPhoto != nil ? AppColors.brandPrimary : Color.gray
        )
        .cornerRadius(8)
        .disabled(deliveryPhoto == nil || isUploading)
    }

    // MARK: - Uploading Overlay

    private var uploadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)

                Text("업로드 중...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(40)
            .background(Color.black.opacity(0.8))
            .cornerRadius(12)
        }
    }

    // MARK: - Methods

    private func submitDeliveryProof() {
        guard let photo = deliveryPhoto else { return }

        isUploading = true

        uploadService.submitDeliveryProof(
            orderId: orderId,
            photo: photo,
            signature: customerSignature,
            note: completionNote
        ) { result in
            isUploading = false

            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                // Show error
                Logger.error("배달 증명 제출 실패: \(error)", category: .order)
            }
        }
    }
}

// MARK: - Delivery Proof ViewModel

@MainActor
class DeliveryProofViewModel: ObservableObject {
    private let uploadService = ImageUploadService.shared
    private let orderRepository = OrderRepository(provider: NetworkProvider.shared.provider)
    private var cancellables = Set<AnyCancellable>()

    func submitDeliveryProof(
        orderId: String,
        photo: UIImage,
        signature: UIImage?,
        note: String?,
        completion: @escaping (Result<Void, AppError>) -> Void
    ) {
        // Upload photo
        let photoUpload = uploadService.uploadImage(photo, type: .deliveryProof)

        // Upload signature if exists
        let signatureUpload: AnyPublisher<String?, AppError>
        if let signature = signature {
            signatureUpload = uploadService.uploadImage(signature, type: .signature)
                .map { Optional($0) }
                .eraseToAnyPublisher()
        } else {
            signatureUpload = Just<String?>(nil)
                .setFailureType(to: AppError.self)
                .eraseToAnyPublisher()
        }

        // Combine uploads and complete order
        Publishers.Zip(photoUpload, signatureUpload)
            .flatMap { [weak self] photoUrl, signatureUrl -> AnyPublisher<Order, AppError> in
                guard let self = self else {
                    return Fail(error: AppError.unknown("Service not available"))
                        .eraseToAnyPublisher()
                }

                return self.orderRepository.completeOrder(
                    id: orderId,
                    photoUrl: photoUrl,
                    signatureUrl: signatureUrl
                )
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { result in
                    if case .failure(let error) = result {
                        completion(.failure(error))
                    }
                },
                receiveValue: { _ in
                    completion(.success(()))
                }
            )
            .store(in: &cancellables)
    }
}