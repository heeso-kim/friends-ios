import XCTest
import Combine
@testable import VroongFriends

final class OrderUseCaseTests: XCTestCase {
    private var sut: GetOrdersUseCaseImpl!
    private var mockRepository: MockOrderRepository!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockRepository = MockOrderRepository()
        sut = GetOrdersUseCaseImpl(orderRepository: mockRepository)
        cancellables = []
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        cancellables = nil
        super.tearDown()
    }

    func testGetOrdersSuccess() {
        // Given
        let expectedOrders = [
            createMockOrder(id: "1", status: .pending),
            createMockOrder(id: "2", status: .accepted),
            createMockOrder(id: "3", status: .completed)
        ]

        mockRepository.getOrdersResult = .success(expectedOrders)

        let expectation = XCTestExpectation(description: "Get orders succeeds")

        // When
        sut.execute(status: nil)
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        XCTFail("Expected success but got failure")
                    }
                },
                receiveValue: { orders in
                    // Then
                    XCTAssertEqual(orders.count, 3)
                    XCTAssertEqual(orders[0].id, "1")
                    XCTAssertEqual(orders[1].status, .accepted)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func testGetOrdersWithStatusFilter() {
        // Given
        let allOrders = [
            createMockOrder(id: "1", status: .pending),
            createMockOrder(id: "2", status: .accepted),
            createMockOrder(id: "3", status: .completed)
        ]

        mockRepository.getOrdersResult = .success(allOrders)
        mockRepository.shouldFilterByStatus = true

        let expectation = XCTestExpectation(description: "Get orders with status filter")

        // When
        sut.execute(status: .pending)
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        XCTFail("Expected success but got failure")
                    }
                },
                receiveValue: { orders in
                    // Then
                    let filteredOrders = orders.filter { $0.status == .pending }
                    XCTAssertEqual(filteredOrders.count, 1)
                    XCTAssertEqual(filteredOrders[0].status, .pending)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func testGetOrdersNetworkError() {
        // Given
        mockRepository.getOrdersResult = .failure(NetworkError.noInternetConnection)

        let expectation = XCTestExpectation(description: "Get orders fails with network error")

        // When
        sut.execute(status: nil)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        // Then
                        XCTAssertEqual(error as? NetworkError, NetworkError.noInternetConnection)
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in
                    XCTFail("Expected failure but got success")
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func testAcceptOrderSuccess() {
        // Given
        let acceptUseCase = AcceptOrderUseCaseImpl(orderRepository: mockRepository)
        let orderId = "123"
        let expectedOrder = createMockOrder(id: orderId, status: .accepted)

        mockRepository.acceptOrderResult = .success(expectedOrder)

        let expectation = XCTestExpectation(description: "Accept order succeeds")

        // When
        acceptUseCase.execute(orderId: orderId)
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        XCTFail("Expected success but got failure")
                    }
                },
                receiveValue: { order in
                    // Then
                    XCTAssertEqual(order.id, orderId)
                    XCTAssertEqual(order.status, .accepted)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func testCompleteOrderWithProof() {
        // Given
        let completeUseCase = CompleteOrderUseCaseImpl(orderRepository: mockRepository)
        let orderId = "123"
        let proofImageData = Data("mock_image_data".utf8)
        let expectedOrder = createMockOrder(id: orderId, status: .completed)

        mockRepository.completeOrderResult = .success(expectedOrder)

        let expectation = XCTestExpectation(description: "Complete order with proof succeeds")

        // When
        completeUseCase.execute(orderId: orderId, proofImage: proofImageData)
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        XCTFail("Expected success but got failure")
                    }
                },
                receiveValue: { order in
                    // Then
                    XCTAssertEqual(order.id, orderId)
                    XCTAssertEqual(order.status, .completed)
                    XCTAssertNotNil(mockRepository.lastProofImage)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Helper Methods

    private func createMockOrder(id: String, status: OrderStatus) -> Order {
        Order(
            id: id,
            orderNumber: "ORD-\(id)",
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
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// MARK: - Mock Order Repository

class MockOrderRepository: OrderRepository {
    var getOrdersResult: Result<[Order], Error>?
    var getOrderResult: Result<Order, Error>?
    var acceptOrderResult: Result<Order, Error>?
    var completeOrderResult: Result<Order, Error>?
    var cancelOrderResult: Result<Void, Error>?
    var updateOrderStatusResult: Result<Order, Error>?
    var shouldFilterByStatus = false
    var lastProofImage: Data?

    func getOrders(status: OrderStatus?, page: Int, limit: Int) -> AnyPublisher<[Order], Error> {
        guard let result = getOrdersResult else {
            return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
        }

        switch result {
        case .success(let orders):
            var filteredOrders = orders
            if shouldFilterByStatus, let status = status {
                filteredOrders = orders.filter { $0.status == status }
            }
            return Just(filteredOrders)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        case .failure(let error):
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }

    func getOrder(id: String) -> AnyPublisher<Order, Error> {
        guard let result = getOrderResult else {
            return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
        }

        switch result {
        case .success(let order):
            return Just(order)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        case .failure(let error):
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }

    func acceptOrder(id: String) -> AnyPublisher<Order, Error> {
        guard let result = acceptOrderResult else {
            return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
        }

        switch result {
        case .success(let order):
            return Just(order)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        case .failure(let error):
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }

    func completeOrder(id: String, proofImage: Data?) -> AnyPublisher<Order, Error> {
        lastProofImage = proofImage

        guard let result = completeOrderResult else {
            return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
        }

        switch result {
        case .success(let order):
            return Just(order)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        case .failure(let error):
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }

    func cancelOrder(id: String, reason: String) -> AnyPublisher<Void, Error> {
        guard let result = cancelOrderResult else {
            return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
        }

        switch result {
        case .success:
            return Just(())
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        case .failure(let error):
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }

    func updateOrderStatus(id: String, status: OrderStatus) -> AnyPublisher<Order, Error> {
        guard let result = updateOrderStatusResult else {
            return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
        }

        switch result {
        case .success(let order):
            return Just(order)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        case .failure(let error):
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }
}