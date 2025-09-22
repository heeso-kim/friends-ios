import XCTest

final class LoginFlowUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()

        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launchEnvironment = ["FLAVOR": "dev1"]

        // Reset app state for consistent testing
        app.launchArguments.append("--reset-state")
    }

    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }

    func testSuccessfulLogin() throws {
        // Given
        app.launch()

        // Wait for login screen
        let emailTextField = app.textFields["email_textfield"]
        XCTAssertTrue(emailTextField.waitForExistence(timeout: 5))

        // When - Enter credentials
        emailTextField.tap()
        emailTextField.typeText("test@vroong.com")

        let passwordSecureField = app.secureTextFields["password_textfield"]
        passwordSecureField.tap()
        passwordSecureField.typeText("Test1234!")

        // Hide keyboard
        app.toolbars["Toolbar"].buttons["Done"].tap()

        // Tap login button
        let loginButton = app.buttons["login_button"]
        XCTAssertTrue(loginButton.exists)
        loginButton.tap()

        // Then - Verify navigation to main screen
        let mainScreen = app.otherElements["main_container"]
        XCTAssertTrue(mainScreen.waitForExistence(timeout: 10))

        // Verify drawer menu button exists
        let drawerButton = app.buttons["drawer_menu_button"]
        XCTAssertTrue(drawerButton.exists)
    }

    func testInvalidEmailFormat() throws {
        // Given
        app.launch()

        let emailTextField = app.textFields["email_textfield"]
        XCTAssertTrue(emailTextField.waitForExistence(timeout: 5))

        // When - Enter invalid email
        emailTextField.tap()
        emailTextField.typeText("invalid-email")

        let passwordSecureField = app.secureTextFields["password_textfield"]
        passwordSecureField.tap()
        passwordSecureField.typeText("Test1234!")

        app.toolbars["Toolbar"].buttons["Done"].tap()

        let loginButton = app.buttons["login_button"]
        loginButton.tap()

        // Then - Verify error message
        let errorLabel = app.staticTexts["error_message"]
        XCTAssertTrue(errorLabel.waitForExistence(timeout: 2))
        XCTAssertTrue(errorLabel.label.contains("올바른 이메일"))
    }

    func testEmptyFieldsValidation() throws {
        // Given
        app.launch()

        // When - Tap login without entering credentials
        let loginButton = app.buttons["login_button"]
        XCTAssertTrue(loginButton.waitForExistence(timeout: 5))
        loginButton.tap()

        // Then - Verify error messages
        let emailError = app.staticTexts["email_error"]
        let passwordError = app.staticTexts["password_error"]

        XCTAssertTrue(emailError.waitForExistence(timeout: 2))
        XCTAssertTrue(passwordError.waitForExistence(timeout: 2))
    }

    func testPasswordVisibilityToggle() throws {
        // Given
        app.launch()

        let passwordSecureField = app.secureTextFields["password_textfield"]
        XCTAssertTrue(passwordSecureField.waitForExistence(timeout: 5))

        // When - Enter password
        passwordSecureField.tap()
        passwordSecureField.typeText("Test1234!")

        // Toggle visibility
        let visibilityButton = app.buttons["password_visibility_toggle"]
        XCTAssertTrue(visibilityButton.exists)
        visibilityButton.tap()

        // Then - Verify password is visible
        let passwordTextField = app.textFields["password_textfield"]
        XCTAssertTrue(passwordTextField.exists)
        XCTAssertEqual(passwordTextField.value as? String, "Test1234!")

        // Toggle back
        visibilityButton.tap()
        XCTAssertTrue(passwordSecureField.exists)
    }

    func testRememberMeCheckbox() throws {
        // Given
        app.launch()

        let rememberMeCheckbox = app.buttons["remember_me_checkbox"]
        XCTAssertTrue(rememberMeCheckbox.waitForExistence(timeout: 5))

        // When - Tap checkbox
        let initialState = rememberMeCheckbox.isSelected
        rememberMeCheckbox.tap()

        // Then - Verify state changed
        XCTAssertNotEqual(rememberMeCheckbox.isSelected, initialState)
    }

    func testForgotPasswordNavigation() throws {
        // Given
        app.launch()

        let forgotPasswordButton = app.buttons["forgot_password_button"]
        XCTAssertTrue(forgotPasswordButton.waitForExistence(timeout: 5))

        // When - Tap forgot password
        forgotPasswordButton.tap()

        // Then - Verify navigation to forgot password screen
        let forgotPasswordScreen = app.otherElements["forgot_password_screen"]
        XCTAssertTrue(forgotPasswordScreen.waitForExistence(timeout: 5))

        let resetEmailTextField = app.textFields["reset_email_textfield"]
        XCTAssertTrue(resetEmailTextField.exists)
    }

    func testLogout() throws {
        // Given - Login first
        performLogin()

        // Open drawer menu
        let drawerButton = app.buttons["drawer_menu_button"]
        XCTAssertTrue(drawerButton.waitForExistence(timeout: 5))
        drawerButton.tap()

        // When - Tap logout
        let logoutButton = app.buttons["logout_button"]
        XCTAssertTrue(logoutButton.waitForExistence(timeout: 2))
        logoutButton.tap()

        // Confirm logout
        let confirmButton = app.alerts.buttons["확인"]
        if confirmButton.waitForExistence(timeout: 2) {
            confirmButton.tap()
        }

        // Then - Verify return to login screen
        let emailTextField = app.textFields["email_textfield"]
        XCTAssertTrue(emailTextField.waitForExistence(timeout: 5))
    }

    func testBiometricLogin() throws {
        // This test requires Face ID/Touch ID enrollment in simulator
        // Settings > Face ID & Passcode > Enroll Face ID

        // Given
        app.launch()

        let biometricButton = app.buttons["biometric_login_button"]

        // Check if biometric button exists (device capability dependent)
        if biometricButton.waitForExistence(timeout: 2) {
            // When - Tap biometric login
            biometricButton.tap()

            // Simulate biometric success
            // Note: In real testing, you'd need to handle biometric prompt

            // Then - Verify navigation to main screen
            let mainScreen = app.otherElements["main_container"]
            XCTAssertTrue(mainScreen.waitForExistence(timeout: 10))
        }
    }

    // MARK: - Helper Methods

    private func performLogin() {
        app.launch()

        let emailTextField = app.textFields["email_textfield"]
        emailTextField.tap()
        emailTextField.typeText("test@vroong.com")

        let passwordSecureField = app.secureTextFields["password_textfield"]
        passwordSecureField.tap()
        passwordSecureField.typeText("Test1234!")

        app.toolbars["Toolbar"].buttons["Done"].tap()

        let loginButton = app.buttons["login_button"]
        loginButton.tap()

        // Wait for main screen
        let mainScreen = app.otherElements["main_container"]
        _ = mainScreen.waitForExistence(timeout: 10)
    }
}