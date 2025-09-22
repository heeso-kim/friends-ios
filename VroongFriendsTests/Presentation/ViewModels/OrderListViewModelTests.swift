import XCTest
import Combine
@testable import VroongFriends

@MainActor
final class OrderListViewModelTests: XCTestCase {
    private var sut: OrderListViewModel!
    private var mockUseCase: MockGetOrdersUseCase!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() async throws {
        try await super.setUp()
        mockUseCase = MockGetOrdersUseCase()
        sut = OrderListViewModel(getOrdersUseCase: mockUseCase)
        cancellables = []
    }

    override func tearDown() async throws {
        sut = nil
        mockUseCase = nil
        cancellables = nil
        try await super.tearDown()
    }

    func testLoadOrdersSuccess() async {
        // Given
        let expectedOrders = [
            createMockOrder(id: "1", status: .pending),
            createMockOrder(id: "2", status: .accepted),
            createMockOrder(id: "3", status: .completed)
        ]

        mockUseCase.executeResult = .success(expectedOrders)

        // When
        await sut.loadOrders()

        // Then
        XCTAssertEqual(sut.orders.count, 3)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    func testLoadOrdersFailure() async {
        // Given
        mockUseCase.executeResult = .failure(NetworkError.noInternetConnection)

        // When
        await sut.loadOrders()

        // Then
        XCTAssertTrue(sut.orders.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertEqual(sut.errorMessage, "인터넷 연결을 확인해주세요")
    }

    func testFilterOrdersByStatus() async {
        // Given
        let orders = [
            createMockOrder(id: "1", status: .pending),
            createMockOrder(id: "2", status: .accepted),
            createMockOrder(id: "3", status: .completed),
            createMockOrder(id: "4", status: .pending)
        ]

        mockUseCase.executeResult = .success(orders)

        // When
        await sut.loadOrders()
        sut.selectedStatus = .pending

        // Then
        let filteredOrders = sut.filteredOrders
        XCTAssertEqual(filteredOrders.count, 2)
        XCTAssertTrue(filteredOrders.allSatisfy { $0.status == .pending })
    }

    func testRefreshOrders() async {
        // Given
        let initialOrders = [createMockOrder(id: "1", status: .pending)]
        let refreshedOrders = [
            createMockOrder(id: "1", status: .accepted),
            createMockOrder(id: "2", status: .pending)
        ]

        mockUseCase.executeResult = .success(initialOrders)
        await sut.loadOrders()

        mockUseCase.executeResult = .success(refreshedOrders)

        // When
        await sut.refreshOrders()

        // Then
        XCTAssertEqual(sut.orders.count, 2)
        XCTAssertEqual(sut.orders[0].status, .accepted)
        XCTAssertFalse(sut.isRefreshing)
    }

    func testPaginationLoadMore() async {
        // Given
        let firstPageOrders = Array(1...10).map { createMockOrder(id: "\($0)", status: .pending) }
        let secondPageOrders = Array(11...20).map { createMockOrder(id: "\($0)", status: .pending) }

        mockUseCase.executeResult = .success(firstPageOrders)
        await sut.loadOrders()

        mockUseCase.executeResult = .success(secondPageOrders)

        // When
        await sut.loadMoreOrdersIfNeeded(currentOrder: sut.orders.last!)

        // Then
        XCTAssertEqual(sut.orders.count, 20)
        XCTAssertEqual(sut.currentPage, 2)
        XCTAssertFalse(sut.isLoadingMore)
    }

    func testNoMorePagination() async {
        // Given
        let orders = Array(1...5).map { createMockOrder(id: "\($0)", status: .pending) }

        mockUseCase.executeResult = .success(orders)
        await sut.loadOrders()

        mockUseCase.executeResult = .success([])

        // When
        await sut.loadMoreOrdersIfNeeded(currentOrder: sut.orders.last!)

        // Then
        XCTAssertEqual(sut.orders.count, 5)
        XCTAssertTrue(sut.hasReachedEnd)
        XCTAssertFalse(sut.isLoadingMore)
    }

    func testSearchOrders() async {
        // Given
        let orders = [
            createMockOrder(id: "1", status: .pending, orderNumber: "ORD-12345"),
            createMockOrder(id: "2", status: .accepted, orderNumber: "ORD-67890"),
            createMockOrder(id: "3", status: .completed, orderNumber: "ORD-54321")
        ]

        mockUseCase.executeResult = .success(orders)
        await sut.loadOrders()

        // When
        sut.searchText = "123"

        // Then
        let searchResults = sut.filteredOrders
        XCTAssertEqual(searchResults.count, 1)
        XCTAssertEqual(searchResults[0].orderNumber, "ORD-12345")
    }

    func testSortOrders() async {
        // Given
        let orders = [
            createMockOrder(id: "1", status: .pending, createdAt: Date().addingTimeInterval(-7200)),
            createMockOrder(id: "2", status: .accepted, createdAt: Date().addingTimeInterval(-3600)),
            createMockOrder(id: "3", status: .completed, createdAt: Date())
        ]

        mockUseCase.executeResult = .success(orders)
        await sut.loadOrders()

        // When
        sut.sortOption = .dateDescending

        // Then
        let sortedOrders = sut.filteredOrders
        XCTAssertEqual(sortedOrders[0].id, "3")
        XCTAssertEqual(sortedOrders[2].id, "1")
    }

    // MARK: - Helper Methods

    private func createMockOrder(
        id: String,
        status: OrderStatus,
        orderNumber: String? = nil,
        createdAt: Date = Date()
    ) -> Order {
        Order(
            id: id,
            orderNumber: orderNumber ?? "ORD-\(id)",
            status: status,
            customerId: "customer-\(id)",
            deliveryId: nil,
            pickupAddress: Address(
                street: "123 Pickup St",
                city: "Seoul",
                state: "Seoul",
                postalCode: "12345",
                coordinate: Coordinate(latitude: 37.5665, longitude: 126.9780)
            ),
            deliveryAddress: Address(
                street: "456 Delivery Ave",
                city: "Seoul",
                state: "Seoul",
                postalCode: "67890",
                coordinate: Coordinate(latitude: 37.5765, longitude: 126.9880)
            ),
            items: [
                OrderItem(
                    id: "item-1",
                    name: "Product 1",
                    quantity: 2,
                    price: 10000,
                    imageUrl: nil
                )
            ],
            totalAmount: 20000,
            deliveryFee: 3000,
            tip: 1000,
            paymentMethod: .card,
            paymentStatus: .paid,
            notes: nil,
            estimatedDeliveryTime: Date().addingTimeInterval(3600),
            actualDeliveryTime: nil,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }
}

// MARK: - Mock UseCase

class MockGetOrdersUseCase: GetOrdersUseCase {
    var executeResult: Result<[Order], Error>?
    var executeCalled = false
    var lastStatusFilter: OrderStatus?

    func execute(status: OrderStatus?) -> AnyPublisher<[Order], Error> {
        executeCalled = true
        lastStatusFilter = status

        guard let result = executeResult else {
            return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
        }

        switch result {
        case .success(let orders):
            return Just(orders)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        case .failure(let error):
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }
}