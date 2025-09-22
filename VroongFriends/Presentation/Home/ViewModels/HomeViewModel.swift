import Foundation
import Combine
import CoreLocation

/// 홈 화면 뷰모델
@MainActor
final class HomeViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var isOnline: Bool = false
    @Published var isToggling: Bool = false
    @Published var currentOrder: Order?
    @Published var nearbyOrders: [Order] = []
    @Published var completedOrdersToday: Int = 0
    @Published var earningsToday: Decimal = 0
    @Published var showOrderDetail: Bool = false
    @Published var showNotifications: Bool = false
    @Published var unreadNotificationCount: Int = 0
    
    // MARK: - Properties
    
    var cancellables = Set<AnyCancellable>()
    private let orderRepository: OrderRepositoryProtocol
    private let locationRepository: LocationRepositoryProtocol
    private let paymentRepository: PaymentRepositoryProtocol
    private let acceptOrderUseCase: AcceptOrderUseCaseProtocol
    private let updateLocationUseCase: UpdateLocationUseCaseProtocol
    
    private var locationUpdateTimer: Timer?
    
    // MARK: - Initialization
    
    init(
        orderRepository: OrderRepositoryProtocol = OrderRepository(provider: NetworkProvider.shared.provider),
        locationRepository: LocationRepositoryProtocol = LocationRepository(provider: NetworkProvider.shared.provider),
        paymentRepository: PaymentRepositoryProtocol = PaymentRepository(provider: NetworkProvider.shared.provider),
        acceptOrderUseCase: AcceptOrderUseCaseProtocol? = nil,
        updateLocationUseCase: UpdateLocationUseCaseProtocol? = nil
    ) {
        self.orderRepository = orderRepository
        self.locationRepository = locationRepository
        self.paymentRepository = paymentRepository
        
        // Use Case 주입 (의존성 주입을 위해 nil 허용)
        self.acceptOrderUseCase = acceptOrderUseCase ?? AcceptOrderUseCase(
            orderRepository: orderRepository,
            userRepository: UserRepository(provider: NetworkProvider.shared.provider)
        )
        self.updateLocationUseCase = updateLocationUseCase ?? UpdateLocationUseCase(
            locationRepository: locationRepository,
            userRepository: UserRepository(provider: NetworkProvider.shared.provider)
        )
        
        setupSubscriptions()
        loadTodayStats()
    }
    
    // MARK: - Setup
    
    private func setupSubscriptions() {
        // AppState 구독
        AppState.shared.$isOnline
            .sink { [weak self] isOnline in
                self?.isOnline = isOnline
                if isOnline {
                    self?.startLocationTracking()
                } else {
                    self?.stopLocationTracking()
                }
            }
            .store(in: &cancellables)
        
        // 현재 진행 주문 구독
        AppState.shared.$currentOrder
            .sink { [weak self] order in
                self?.currentOrder = order
            }
            .store(in: &cancellables)
        
        // 위치 업데이트 구독
        LocationManager.shared.$currentLocation
            .compactMap { $0 }
            .throttle(for: .seconds(10), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] location in
                self?.updateLocation(location)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Methods
    
    func toggleOnlineStatus() {
        isToggling = true
        
        if isOnline {
            // 운행 종료
            stopOnlineMode()
        } else {
            // 운행 시작
            startOnlineMode()
        }
    }
    
    func startLocationTracking() {
        LocationManager.shared.startTracking()
        
        // 30초마다 위치 업데이트
        locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            if let location = LocationManager.shared.currentLocation {
                self?.updateLocation(location)
            }
        }
    }
    
    func stopLocationTracking() {
        LocationManager.shared.stopTracking()
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = nil
    }
    
    func acceptOrder(_ order: Order) {
        acceptOrderUseCase.execute(orderId: order.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        Logger.error("주문 수락 실패: \(error)", category: .order)
                        self?.showError(error)
                    }
                },
                receiveValue: { [weak self] acceptedOrder in
                    Logger.info("주문 수락 성공: \(acceptedOrder.orderNumber)", category: .order)
                    self?.currentOrder = acceptedOrder
                    AppState.shared.currentOrder = acceptedOrder
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Private Methods
    
    private func startOnlineMode() {
        updateLocationUseCase.startTracking()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isToggling = false
                    if case .failure(let error) = completion {
                        Logger.error("운행 시작 실패: \(error)", category: .location)
                        self?.showError(error)
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.isOnline = true
                    AppState.shared.isOnline = true
                    Logger.info("운행 시작", category: .location)
                }
            )
            .store(in: &cancellables)
    }
    
    private func stopOnlineMode() {
        updateLocationUseCase.stopTracking()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isToggling = false
                    if case .failure(let error) = completion {
                        Logger.error("운행 종료 실패: \(error)", category: .location)
                        self?.showError(error)
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.isOnline = false
                    AppState.shared.isOnline = false
                    Logger.info("운행 종료", category: .location)
                }
            )
            .store(in: &cancellables)
    }
    
    private func updateLocation(_ location: CLLocation) {
        guard isOnline else { return }
        
        updateLocationUseCase.execute(location: location)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        Logger.error("위치 업데이트 실패: \(error)", category: .location)
                    }
                },
                receiveValue: { _ in
                    Logger.debug("위치 업데이트 성공", category: .location)
                }
            )
            .store(in: &cancellables)
        
        // 주변 주문 로드
        loadNearbyOrders(location: location)
    }
    
    private func loadNearbyOrders(location: CLLocation) {
        // TODO: 주변 주문 API 호출
        // 현재는 모든 pending 주문을 가져오는 것으로 대체
        let filter = OrderFilter(
            status: .pending,
            type: nil,
            startDate: nil,
            endDate: nil,
            searchText: nil
        )
        
        orderRepository.getOrders(filter: filter)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] orders in
                    self?.nearbyOrders = Array(orders.prefix(5)) // 최대 5개만 표시
                }
            )
            .store(in: &cancellables)
    }
    
    private func loadTodayStats() {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
        
        // 오늘 통계 로드
        orderRepository.getOrderStatistics(startDate: startOfDay, endDate: endOfDay)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] stats in
                    self?.completedOrdersToday = stats.completedOrders
                }
            )
            .store(in: &cancellables)
        
        // 오늘 수익 로드
        paymentRepository.getEarnings(startDate: startOfDay, endDate: endOfDay)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] earnings in
                    self?.earningsToday = earnings.totalEarnings
                }
            )
            .store(in: &cancellables)
    }
    
    private func showError(_ error: AppError) {
        // TODO: 에러 처리 UI 구현
        Logger.error("에러 발생: \(error.localizedDescription)", category: .general)
    }
}