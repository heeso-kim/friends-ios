import Foundation
import Combine

/// 주문 목록 화면 뷰모델
@MainActor
final class OrderListViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var orders: [Order] = []
    @Published var filteredOrders: [Order] = []
    @Published var isLoading: Bool = false
    @Published var hasMorePages: Bool = true
    @Published var selectedFilter: OrderStatus? = nil
    @Published var selectedOrder: Order? = nil
    @Published var showOrderDetail: Bool = false
    @Published var errorMessage: String? = nil

    // MARK: - Properties

    private var cancellables = Set<AnyCancellable>()
    private let orderRepository: OrderRepositoryProtocol
    private var currentPage = 0
    private let pageSize = 20

    // MARK: - Initialization

    init(orderRepository: OrderRepositoryProtocol = OrderRepository(provider: NetworkProvider.shared.provider)) {
        self.orderRepository = orderRepository
        setupSubscriptions()
        loadOrders()
    }

    // MARK: - Setup

    private func setupSubscriptions() {
        // 필터 변경 감지
        $selectedFilter
            .sink { [weak self] filter in
                self?.applyFilter(filter)
            }
            .store(in: &cancellables)

        // 현재 진행 중인 주문 업데이트
        AppState.shared.$currentOrder
            .compactMap { $0 }
            .sink { [weak self] updatedOrder in
                self?.updateOrderInList(updatedOrder)
            }
            .store(in: &cancellables)
    }

    // MARK: - Methods

    func loadOrders(refresh: Bool = false) {
        guard !isLoading else { return }

        if refresh {
            currentPage = 0
            hasMorePages = true
            orders.removeAll()
        }

        guard hasMorePages else { return }

        isLoading = true
        errorMessage = nil

        let filter = OrderFilter(
            status: selectedFilter,
            type: nil,
            startDate: nil,
            endDate: nil,
            searchText: nil
        )

        orderRepository.getOrdersWithPagination(
            page: currentPage,
            size: pageSize,
            filter: filter
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            },
            receiveValue: { [weak self] page in
                guard let self = self else { return }

                if refresh {
                    self.orders = page.content
                } else {
                    self.orders.append(contentsOf: page.content)
                }

                self.filteredOrders = self.orders
                self.hasMorePages = !page.isLast
                self.currentPage += 1
            }
        )
        .store(in: &cancellables)
    }

    func loadMoreIfNeeded(currentItem: Order) {
        let thresholdIndex = orders.index(orders.endIndex, offsetBy: -5)
        if let index = orders.firstIndex(where: { $0.id == currentItem.id }),
           index >= thresholdIndex {
            loadOrders()
        }
    }

    func refreshOrders() {
        loadOrders(refresh: true)
    }

    func selectOrder(_ order: Order) {
        selectedOrder = order
        showOrderDetail = true
    }

    func acceptOrder(_ order: Order) {
        orderRepository.acceptOrder(id: order.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] acceptedOrder in
                    self?.updateOrderInList(acceptedOrder)
                    AppState.shared.currentOrder = acceptedOrder
                    Logger.info("주문 수락: \(acceptedOrder.orderNumber)", category: .order)
                }
            )
            .store(in: &cancellables)
    }

    func rejectOrder(_ order: Order, reason: String) {
        orderRepository.rejectOrder(id: order.id, reason: reason)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.removeOrderFromList(order)
                    Logger.info("주문 거절: \(order.orderNumber)", category: .order)
                }
            )
            .store(in: &cancellables)
    }

    // MARK: - Private Methods

    private func applyFilter(_ status: OrderStatus?) {
        if let status = status {
            filteredOrders = orders.filter { $0.status == status }
        } else {
            filteredOrders = orders
        }
    }

    private func updateOrderInList(_ order: Order) {
        if let index = orders.firstIndex(where: { $0.id == order.id }) {
            orders[index] = order
            applyFilter(selectedFilter)
        }
    }

    private func removeOrderFromList(_ order: Order) {
        orders.removeAll { $0.id == order.id }
        applyFilter(selectedFilter)
    }

    private func handleError(_ error: AppError) {
        Logger.error("주문 목록 로드 실패: \(error)", category: .order)

        switch error {
        case .noInternetConnection:
            errorMessage = "인터넷 연결을 확인해주세요"
        case .unauthorized:
            errorMessage = "인증이 필요합니다"
        case .serverError(_, let message):
            errorMessage = message ?? "서버 오류가 발생했습니다"
        default:
            errorMessage = "주문을 불러오는 중 오류가 발생했습니다"
        }
    }
}