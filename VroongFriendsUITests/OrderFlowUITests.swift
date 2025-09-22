import XCTest

final class OrderFlowUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()

        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "--logged-in"]
        app.launchEnvironment = ["FLAVOR": "dev1"]
    }

    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }

    func testViewOrderList() throws {
        // Given
        app.launch()

        // When - Navigate to orders
        let ordersTab = app.tabBars.buttons["orders_tab"]
        if ordersTab.exists {
            ordersTab.tap()
        } else {
            // Open drawer and select orders
            openDrawerMenu()
            let ordersMenuItem = app.buttons["menu_orders"]
            ordersMenuItem.tap()
        }

        // Then - Verify order list is displayed
        let ordersList = app.tables["orders_list"]
        XCTAssertTrue(ordersList.waitForExistence(timeout: 5))

        // Verify at least one order cell exists
        let firstOrderCell = ordersList.cells.element(boundBy: 0)
        XCTAssertTrue(firstOrderCell.waitForExistence(timeout: 5))
    }

    func testFilterOrdersByStatus() throws {
        // Given
        app.launch()
        navigateToOrders()

        // When - Apply filter
        let filterButton = app.buttons["filter_button"]
        XCTAssertTrue(filterButton.waitForExistence(timeout: 5))
        filterButton.tap()

        // Select "Pending" status
        let pendingOption = app.buttons["filter_pending"]
        XCTAssertTrue(pendingOption.waitForExistence(timeout: 2))
        pendingOption.tap()

        // Apply filter
        let applyButton = app.buttons["apply_filter"]
        applyButton.tap()

        // Then - Verify filtered results
        let ordersList = app.tables["orders_list"]
        let orderCells = ordersList.cells

        // Check that all visible orders have "Pending" status
        for i in 0..<min(orderCells.count, 3) {
            let cell = orderCells.element(boundBy: i)
            if cell.exists {
                let statusLabel = cell.staticTexts.matching(identifier: "order_status").firstMatch
                XCTAssertTrue(statusLabel.label.contains("대기중") || statusLabel.label.contains("Pending"))
            }
        }
    }

    func testAcceptOrder() throws {
        // Given
        app.launch()
        navigateToOrders()

        // Find a pending order
        let ordersList = app.tables["orders_list"]
        let pendingOrderCell = ordersList.cells.containing(.staticText, identifier: "order_status_pending").firstMatch

        guard pendingOrderCell.waitForExistence(timeout: 5) else {
            XCTSkip("No pending orders available for testing")
            return
        }

        // When - Tap on the order
        pendingOrderCell.tap()

        // Accept order
        let acceptButton = app.buttons["accept_order_button"]
        XCTAssertTrue(acceptButton.waitForExistence(timeout: 5))
        acceptButton.tap()

        // Confirm acceptance
        let confirmButton = app.alerts.buttons["확인"]
        if confirmButton.waitForExistence(timeout: 2) {
            confirmButton.tap()
        }

        // Then - Verify order status changed
        let statusLabel = app.staticTexts["order_detail_status"]
        XCTAssertTrue(statusLabel.waitForExistence(timeout: 5))
        XCTAssertTrue(statusLabel.label.contains("진행중") || statusLabel.label.contains("Accepted"))
    }

    func testViewOrderDetails() throws {
        // Given
        app.launch()
        navigateToOrders()

        // When - Tap on first order
        let ordersList = app.tables["orders_list"]
        let firstOrderCell = ordersList.cells.element(boundBy: 0)
        XCTAssertTrue(firstOrderCell.waitForExistence(timeout: 5))
        firstOrderCell.tap()

        // Then - Verify order details are displayed
        let orderDetailView = app.otherElements["order_detail_view"]
        XCTAssertTrue(orderDetailView.waitForExistence(timeout: 5))

        // Verify essential elements
        XCTAssertTrue(app.staticTexts["order_number"].exists)
        XCTAssertTrue(app.staticTexts["customer_name"].exists)
        XCTAssertTrue(app.staticTexts["delivery_address"].exists)
        XCTAssertTrue(app.staticTexts["total_amount"].exists)
    }

    func testNavigateToDeliveryAddress() throws {
        // Given
        app.launch()
        navigateToOrders()

        // Open order details
        let ordersList = app.tables["orders_list"]
        let firstOrderCell = ordersList.cells.element(boundBy: 0)
        firstOrderCell.tap()

        // When - Tap navigate button
        let navigateButton = app.buttons["navigate_button"]
        XCTAssertTrue(navigateButton.waitForExistence(timeout: 5))
        navigateButton.tap()

        // Then - Verify map view is displayed
        let mapView = app.otherElements["map_view"]
        XCTAssertTrue(mapView.waitForExistence(timeout: 5))

        // Verify navigation controls
        XCTAssertTrue(app.buttons["start_navigation"].exists)
        XCTAssertTrue(app.buttons["close_map"].exists)
    }

    func testCompleteOrderWithProof() throws {
        // Given - Navigate to an accepted order
        app.launch()
        navigateToAcceptedOrder()

        // When - Start delivery completion
        let completeButton = app.buttons["complete_delivery_button"]
        XCTAssertTrue(completeButton.waitForExistence(timeout: 5))
        completeButton.tap()

        // Take photo proof
        let takePhotoButton = app.buttons["take_photo_button"]
        XCTAssertTrue(takePhotoButton.waitForExistence(timeout: 2))
        takePhotoButton.tap()

        // Handle camera permission if needed
        handleCameraPermission()

        // Simulate taking photo (in UI test, we'd use photo library)
        let usePhotoButton = app.buttons["Use Photo"]
        if usePhotoButton.waitForExistence(timeout: 5) {
            usePhotoButton.tap()
        }

        // Add signature
        let signatureView = app.otherElements["signature_pad"]
        if signatureView.waitForExistence(timeout: 2) {
            // Simulate drawing signature
            signatureView.swipeRight()
        }

        // Submit completion
        let submitButton = app.buttons["submit_completion"]
        submitButton.tap()

        // Then - Verify order marked as completed
        let statusLabel = app.staticTexts["order_detail_status"]
        XCTAssertTrue(statusLabel.waitForExistence(timeout: 5))
        XCTAssertTrue(statusLabel.label.contains("완료") || statusLabel.label.contains("Completed"))
    }

    func testSearchOrders() throws {
        // Given
        app.launch()
        navigateToOrders()

        // When - Use search
        let searchField = app.searchFields["search_orders"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("ORD-12345")

        // Then - Verify search results
        let ordersList = app.tables["orders_list"]
        let searchResults = ordersList.cells

        // Should show filtered results or "no results" message
        if searchResults.count > 0 {
            let firstResult = searchResults.element(boundBy: 0)
            XCTAssertTrue(firstResult.staticTexts.element(matching: .any, identifier: "order_number").label.contains("12345"))
        } else {
            XCTAssertTrue(app.staticTexts["no_results"].exists)
        }
    }

    func testPullToRefresh() throws {
        // Given
        app.launch()
        navigateToOrders()

        // When - Pull to refresh
        let ordersList = app.tables["orders_list"]
        let firstCell = ordersList.cells.element(boundBy: 0)

        // Perform pull to refresh gesture
        let start = firstCell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        let end = firstCell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
        start.press(forDuration: 0.1, thenDragTo: end)

        // Then - Verify refresh indicator appears and disappears
        let refreshControl = app.activityIndicators["refresh_indicator"]
        XCTAssertTrue(refreshControl.exists)

        // Wait for refresh to complete
        let refreshCompleted = NSPredicate(format: "exists == false")
        expectation(for: refreshCompleted, evaluatedWith: refreshControl, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
    }

    // MARK: - Helper Methods

    private func openDrawerMenu() {
        let drawerButton = app.buttons["drawer_menu_button"]
        if drawerButton.waitForExistence(timeout: 2) {
            drawerButton.tap()
        }
    }

    private func navigateToOrders() {
        let ordersTab = app.tabBars.buttons["orders_tab"]
        if ordersTab.exists {
            ordersTab.tap()
        } else {
            openDrawerMenu()
            let ordersMenuItem = app.buttons["menu_orders"]
            if ordersMenuItem.waitForExistence(timeout: 2) {
                ordersMenuItem.tap()
            }
        }
    }

    private func navigateToAcceptedOrder() {
        navigateToOrders()

        // Find an accepted order
        let ordersList = app.tables["orders_list"]
        let acceptedOrderCell = ordersList.cells.containing(.staticText, identifier: "order_status_accepted").firstMatch

        if acceptedOrderCell.waitForExistence(timeout: 5) {
            acceptedOrderCell.tap()
        } else {
            // If no accepted order, accept a pending one first
            let pendingOrderCell = ordersList.cells.containing(.staticText, identifier: "order_status_pending").firstMatch
            if pendingOrderCell.waitForExistence(timeout: 5) {
                pendingOrderCell.tap()
                let acceptButton = app.buttons["accept_order_button"]
                if acceptButton.waitForExistence(timeout: 2) {
                    acceptButton.tap()
                    let confirmButton = app.alerts.buttons["확인"]
                    if confirmButton.waitForExistence(timeout: 2) {
                        confirmButton.tap()
                    }
                }
            }
        }
    }

    private func handleCameraPermission() {
        let cameraPermissionAlert = app.alerts["카메라 접근 권한"]
        if cameraPermissionAlert.waitForExistence(timeout: 2) {
            cameraPermissionAlert.buttons["확인"].tap()
        }

        let systemCameraAlert = app.alerts.element(boundBy: 0)
        if systemCameraAlert.waitForExistence(timeout: 2) {
            systemCameraAlert.buttons["OK"].tap()
        }
    }
}