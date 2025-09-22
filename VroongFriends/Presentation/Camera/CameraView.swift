import SwiftUI
import AVFoundation
import UIKit

/// 카메라 뷰
struct CameraView: View {
    @Binding var capturedImage: UIImage?
    @State private var isCapturing = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            CameraViewRepresentable(capturedImage: $capturedImage, isCapturing: $isCapturing)
                .ignoresSafeArea()
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("취소") {
                            dismiss()
                        }
                    }
                }
                .overlay(
                    VStack {
                        Spacer()

                        // Camera Controls
                        HStack(spacing: 50) {
                            // Gallery Button
                            Button(action: {}) {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            }

                            // Capture Button
                            Button(action: { isCapturing = true }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 70, height: 70)

                                    Circle()
                                        .stroke(Color.white, lineWidth: 3)
                                        .frame(width: 80, height: 80)
                                }
                            }

                            // Flash Button
                            Button(action: {}) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.bottom, 40)
                    }
                )
        }
    }
}

/// 카메라 뷰 UIViewControllerRepresentable
struct CameraViewRepresentable: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Binding var isCapturing: Bool
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        if isCapturing {
            uiViewController.capturePhoto()
            isCapturing = false
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, CameraViewControllerDelegate {
        let parent: CameraViewRepresentable

        init(_ parent: CameraViewRepresentable) {
            self.parent = parent
        }

        func didCapturePhoto(_ image: UIImage) {
            parent.capturedImage = image
            parent.dismiss()
        }

        func didFailWithError(_ error: Error) {
            Logger.error("카메라 오류: \(error)", category: .general)
        }
    }
}

/// 카메라 뷰 컨트롤러 델리게이트
protocol CameraViewControllerDelegate: AnyObject {
    func didCapturePhoto(_ image: UIImage)
    func didFailWithError(_ error: Error)
}

/// 카메라 뷰 컨트롤러
class CameraViewController: UIViewController {
    weak var delegate: CameraViewControllerDelegate?

    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var currentCameraPosition: AVCaptureDevice.Position = .back

    override func viewDidLoad() {
        super.viewDidLoad()
        checkCameraPermission()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    // MARK: - Camera Setup

    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.setupCamera()
                    }
                }
            }
        case .denied, .restricted:
            showCameraPermissionAlert()
        @unknown default:
            break
        }
    }

    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .high

        // Input
        guard let camera = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: currentCameraPosition
        ) else {
            delegate?.didFailWithError(CameraError.noCameraAvailable)
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession?.canAddInput(input) == true {
                captureSession?.addInput(input)
            }
        } catch {
            delegate?.didFailWithError(error)
            return
        }

        // Output
        photoOutput = AVCapturePhotoOutput()
        if let photoOutput = photoOutput,
           captureSession?.canAddOutput(photoOutput) == true {
            captureSession?.addOutput(photoOutput)
        }

        // Preview Layer
        if let captureSession = captureSession {
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.videoGravity = .resizeAspectFill
            previewLayer?.frame = view.bounds

            if let previewLayer = previewLayer {
                view.layer.insertSublayer(previewLayer, at: 0)
            }
        }
    }

    private func startSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }

    private func stopSession() {
        captureSession?.stopRunning()
    }

    // MARK: - Photo Capture

    func capturePhoto() {
        guard let photoOutput = photoOutput else { return }

        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto

        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    // MARK: - Camera Controls

    func switchCamera() {
        currentCameraPosition = currentCameraPosition == .back ? .front : .back

        captureSession?.stopRunning()
        captureSession?.inputs.forEach { captureSession?.removeInput($0) }

        setupCamera()
        startSession()
    }

    func toggleFlash() {
        guard let device = AVCaptureDevice.default(for: .video) else { return }

        do {
            try device.lockForConfiguration()
            device.torchMode = device.torchMode == .on ? .off : .on
            device.unlockForConfiguration()
        } catch {
            Logger.error("플래시 토글 실패: \(error)", category: .general)
        }
    }

    // MARK: - Permission Alert

    private func showCameraPermissionAlert() {
        let alert = UIAlertController(
            title: "카메라 권한 필요",
            message: "카메라를 사용하려면 설정에서 권한을 허용해주세요.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))

        present(alert, animated: true)
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error = error {
            delegate?.didFailWithError(error)
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            delegate?.didFailWithError(CameraError.photoProcessingFailed)
            return
        }

        // Correct orientation
        let correctedImage = image.fixedOrientation()

        delegate?.didCapturePhoto(correctedImage)
    }
}

// MARK: - Camera Error

enum CameraError: LocalizedError {
    case noCameraAvailable
    case photoProcessingFailed

    var errorDescription: String? {
        switch self {
        case .noCameraAvailable:
            return "카메라를 사용할 수 없습니다"
        case .photoProcessingFailed:
            return "사진 처리에 실패했습니다"
        }
    }
}

// MARK: - UIImage Extension

extension UIImage {
    func fixedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }

        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return normalizedImage ?? self
    }
}