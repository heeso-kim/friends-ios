import Foundation
import Combine
import CoreLocation
import PhotosUI

/// 주문 상세 화면 뷰모델
@MainActor
final class OrderDetailViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var order: Order?
    @Published var isLoading: Bool = false
    @Published var currentStatus: OrderStatus = .pending
    @Published var showingActionSheet: Bool = false
    @Published var showingCamera: Bool = false
    @Published var showingSignaturePad: Bool = false
    @Published var deliveryPhoto: UIImage?
    @Published var customerSignature: UIImage?
    @Published var errorMessage: String?
    @Published var showingMap: Bool = false
    @Published var showingChat: Bool = false

    // MARK: - Properties

    private var cancellables = Set<AnyCancellable>()
    private let orderRepository: OrderRepositoryProtocol
    private let locationRepository: LocationRepositoryProtocol
    private let orderId: String

    // MARK: - Initialization

    init(
        orderId: String,
        orderRepository: OrderRepositoryProtocol = OrderRepository(provider: NetworkProvider.shared.provider),
        locationRepository: LocationRepositoryProtocol = LocationRepository(provider: NetworkProvider.shared.provider)
    ) {
        self.orderId = orderId
        self.orderRepository = orderRepository
        self.locationRepository = locationRepository

        loadOrder()
        setupSubscriptions()
    }

    // MARK: - Setup

    private func setupSubscriptions() {
        // 앱 상태에서 현재 주문 업데이트 감지
        AppState.shared.$currentOrder
            .compactMap { $0 }
            .filter { [weak self] order in order.id == self?.orderId }
            .sink { [weak self] updatedOrder in
                self?.order = updatedOrder
                self?.currentStatus = updatedOrder.status
            }
            .store(in: &cancellables)
    }

    // MARK: - Methods

    func loadOrder() {
        isLoading = true
        errorMessage = nil

        orderRepository.getOrder(id: orderId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] order in
                    self?.order = order
                    self?.currentStatus = order.status

                    // 현재 진행 중인 주문이면 앱 상태 업데이트
                    if order.status == .accepted || order.status == .pickingUp || order.status == .delivering {
                        AppState.shared.currentOrder = order
                    }
                }
            )
            .store(in: &cancellables)
    }

    func acceptOrder() {
        guard let order = order else { return }

        isLoading = true
        errorMessage = nil

        orderRepository.acceptOrder(id: order.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] acceptedOrder in
                    self?.order = acceptedOrder
                    self?.currentStatus = acceptedOrder.status
                    AppState.shared.currentOrder = acceptedOrder
                    Logger.info("주문 수락: \(acceptedOrder.orderNumber)", category: .order)
                }
            )
            .store(in: &cancellables)
    }

    func rejectOrder(reason: String) {
        guard let order = order else { return }

        isLoading = true
        errorMessage = nil

        orderRepository.rejectOrder(id: order.id, reason: reason)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] _ in
                    Logger.info("주문 거절: \(order.orderNumber)", category: .order)
                    // 주문 거절 후 화면 닫기는 View에서 처리
                }
            )
            .store(in: &cancellables)
    }

    func startPickup() {
        guard let order = order else { return }

        isLoading = true
        errorMessage = nil

        orderRepository.startPickup(id: order.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] updatedOrder in
                    self?.order = updatedOrder
                    self?.currentStatus = updatedOrder.status
                    AppState.shared.currentOrder = updatedOrder
                    Logger.info("픽업 시작: \(updatedOrder.orderNumber)", category: .order)
                }
            )
            .store(in: &cancellables)
    }

    func completePickup() {
        guard let order = order else { return }

        isLoading = true
        errorMessage = nil

        orderRepository.completePickup(id: order.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] updatedOrder in
                    self?.order = updatedOrder
                    self?.currentStatus = updatedOrder.status
                    AppState.shared.currentOrder = updatedOrder
                    Logger.info("픽업 완료: \(updatedOrder.orderNumber)", category: .order)
                }
            )
            .store(in: &cancellables)
    }

    func startDelivery() {
        guard let order = order else { return }

        isLoading = true
        errorMessage = nil

        orderRepository.startDelivery(id: order.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] updatedOrder in
                    self?.order = updatedOrder
                    self?.currentStatus = updatedOrder.status
                    AppState.shared.currentOrder = updatedOrder
                    Logger.info("배달 시작: \(updatedOrder.orderNumber)", category: .order)
                }
            )
            .store(in: &cancellables)
    }

    func completeOrder() {
        guard let order = order else { return }

        isLoading = true
        errorMessage = nil

        // 사진/서명 업로드 로직 필요
        let photoUrl: String? = nil // TODO: 사진 업로드 후 URL
        let signatureUrl: String? = nil // TODO: 서명 업로드 후 URL

        orderRepository.completeOrder(
            id: order.id,
            photoUrl: photoUrl,
            signatureUrl: signatureUrl
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            },
            receiveValue: { [weak self] completedOrder in
                self?.order = completedOrder
                self?.currentStatus = completedOrder.status
                AppState.shared.currentOrder = nil
                Logger.info("주문 완료: \(completedOrder.orderNumber)", category: .order)
            }
        )
        .store(in: &cancellables)
    }

    func cancelOrder(reason: String) {
        guard let order = order else { return }

        isLoading = true
        errorMessage = nil

        orderRepository.cancelOrder(id: order.id, reason: reason)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] _ in
                    AppState.shared.currentOrder = nil
                    Logger.info("주문 취소: \(order.orderNumber)", category: .order)
                    // 주문 취소 후 화면 닫기는 View에서 처리
                }
            )
            .store(in: &cancellables)
    }

    func openMap() {
        showingMap = true
    }

    func callCustomer() {
        guard let order = order,
              let phoneNumber = order.customer.phoneNumber.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "tel://\(phoneNumber)") else { return }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    func openChat() {
        showingChat = true
    }

    func takeDeliveryPhoto() {
        showingCamera = true
    }

    func requestSignature() {
        showingSignaturePad = true
    }

    // MARK: - Private Methods

    private func handleError(_ error: AppError) {
        Logger.error("주문 상세 오류: \(error)", category: .order)

        switch error {
        case .orderNotFound:
            errorMessage = "주문을 찾을 수 없습니다"
        case .orderAlreadyAccepted:
            errorMessage = "이미 다른 라이더가 수락한 주문입니다"
        case .noInternetConnection:
            errorMessage = "인터넷 연결을 확인해주세요"
        case .unauthorized:
            errorMessage = "인증이 필요합니다"
        default:
            errorMessage = "오류가 발생했습니다"
        }
    }

    // MARK: - Computed Properties

    var canAccept: Bool {
        order?.status == .pending
    }

    var canStartPickup: Bool {
        order?.status == .accepted
    }

    var canCompletePickup: Bool {
        order?.status == .pickingUp
    }

    var canStartDelivery: Bool {
        order?.status == .pickingUp
    }

    var canCompleteOrder: Bool {
        order?.status == .delivering
    }

    var statusProgressValue: Double {
        switch currentStatus {
        case .pending: return 0.0
        case .accepted: return 0.25
        case .pickingUp: return 0.5
        case .delivering: return 0.75
        case .completed: return 1.0
        case .cancelled, .rejected: return 0.0
        }
    }

    var statusText: String {
        switch currentStatus {
        case .pending: return "대기중"
        case .accepted: return "수락됨"
        case .pickingUp: return "픽업중"
        case .delivering: return "배달중"
        case .completed: return "완료됨"
        case .cancelled: return "취소됨"
        case .rejected: return "거절됨"
        }
    }
}