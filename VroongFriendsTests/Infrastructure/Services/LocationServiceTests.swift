import XCTest
import CoreLocation
import Combine
@testable import VroongFriends

final class LocationServiceTests: XCTestCase {
    private var sut: LocationTrackingService!
    private var mockLocationManager: MockCLLocationManager!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockLocationManager = MockCLLocationManager()
        sut = LocationTrackingService()
        // Replace the internal location manager with mock
        sut.setValue(mockLocationManager, forKey: "locationManager")
        cancellables = []
    }

    override func tearDown() {
        sut = nil
        mockLocationManager = nil
        cancellables = nil
        super.tearDown()
    }

    func testRequestAuthorization() {
        // Given
        mockLocationManager.authorizationStatus = .notDetermined

        let expectation = XCTestExpectation(description: "Authorization requested")

        // When
        sut.requestAuthorization()
            .sink { authorized in
                // Then
                XCTAssertTrue(mockLocationManager.didRequestAuthorization)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Simulate authorization granted
        mockLocationManager.authorizationStatus = .authorizedAlways
        mockLocationManager.delegate?.locationManagerDidChangeAuthorization?(mockLocationManager)

        wait(for: [expectation], timeout: 1.0)
    }

    func testStartTracking() {
        // Given
        mockLocationManager.authorizationStatus = .authorizedAlways

        // When
        sut.startTracking()

        // Then
        XCTAssertTrue(mockLocationManager.isUpdatingLocation)
        XCTAssertTrue(mockLocationManager.allowsBackgroundLocationUpdates)
        XCTAssertTrue(mockLocationManager.pausesLocationUpdatesAutomatically == false)
    }

    func testStopTracking() {
        // Given
        sut.startTracking()

        // When
        sut.stopTracking()

        // Then
        XCTAssertFalse(mockLocationManager.isUpdatingLocation)
    }

    func testLocationUpdatePublisher() {
        // Given
        let expectedLocation = CLLocation(
            latitude: 37.5665,
            longitude: 126.9780
        )

        let expectation = XCTestExpectation(description: "Location update received")

        // When
        sut.$currentLocation
            .dropFirst() // Skip initial nil value
            .sink { location in
                // Then
                XCTAssertEqual(location?.coordinate.latitude, expectedLocation.coordinate.latitude)
                XCTAssertEqual(location?.coordinate.longitude, expectedLocation.coordinate.longitude)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Simulate location update
        mockLocationManager.delegate?.locationManager?(
            mockLocationManager,
            didUpdateLocations: [expectedLocation]
        )

        wait(for: [expectation], timeout: 1.0)
    }

    func testLocationError() {
        // Given
        let expectedError = CLError(.locationUnknown)

        let expectation = XCTestExpectation(description: "Location error received")

        // When
        sut.$locationError
            .dropFirst() // Skip initial nil value
            .sink { error in
                // Then
                XCTAssertNotNil(error)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Simulate location error
        mockLocationManager.delegate?.locationManager?(
            mockLocationManager,
            didFailWithError: expectedError
        )

        wait(for: [expectation], timeout: 1.0)
    }

    func testSignificantLocationChanges() {
        // Given
        mockLocationManager.authorizationStatus = .authorizedAlways

        // When
        sut.startMonitoringSignificantLocationChanges()

        // Then
        XCTAssertTrue(mockLocationManager.isMonitoringSignificantLocationChanges)

        // When
        sut.stopMonitoringSignificantLocationChanges()

        // Then
        XCTAssertFalse(mockLocationManager.isMonitoringSignificantLocationChanges)
    }

    func testAuthorizationStatusChanges() {
        // Given
        let expectation = XCTestExpectation(description: "Authorization status changed")

        // When
        sut.$authorizationStatus
            .dropFirst() // Skip initial value
            .sink { status in
                // Then
                XCTAssertEqual(status, .authorizedWhenInUse)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Simulate authorization change
        mockLocationManager.authorizationStatus = .authorizedWhenInUse
        mockLocationManager.delegate?.locationManagerDidChangeAuthorization?(mockLocationManager)

        wait(for: [expectation], timeout: 1.0)
    }

    func testLocationAccuracy() {
        // When
        sut.setDesiredAccuracy(.best)

        // Then
        XCTAssertEqual(mockLocationManager.desiredAccuracy, kCLLocationAccuracyBest)

        // When
        sut.setDesiredAccuracy(.navigation)

        // Then
        XCTAssertEqual(mockLocationManager.desiredAccuracy, kCLLocationAccuracyBestForNavigation)
    }

    func testDistanceFilter() {
        // When
        sut.setDistanceFilter(10.0)

        // Then
        XCTAssertEqual(mockLocationManager.distanceFilter, 10.0)

        // When
        sut.setDistanceFilter(kCLDistanceFilterNone)

        // Then
        XCTAssertEqual(mockLocationManager.distanceFilter, kCLDistanceFilterNone)
    }
}

// MARK: - Mock CLLocationManager

class MockCLLocationManager: CLLocationManager {
    var didRequestAuthorization = false
    var isUpdatingLocation = false
    var isMonitoringSignificantLocationChanges = false
    var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override var allowsBackgroundLocationUpdates: Bool {
        didSet {
            // Track the value change
        }
    }

    override var pausesLocationUpdatesAutomatically: Bool {
        didSet {
            // Track the value change
        }
    }

    override func requestAlwaysAuthorization() {
        didRequestAuthorization = true
    }

    override func requestWhenInUseAuthorization() {
        didRequestAuthorization = true
    }

    override func startUpdatingLocation() {
        isUpdatingLocation = true
    }

    override func stopUpdatingLocation() {
        isUpdatingLocation = false
    }

    override func startMonitoringSignificantLocationChanges() {
        isMonitoringSignificantLocationChanges = true
    }

    override func stopMonitoringSignificantLocationChanges() {
        isMonitoringSignificantLocationChanges = false
    }
}