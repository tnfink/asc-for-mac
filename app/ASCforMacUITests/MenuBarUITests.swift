// MenuBarUITests.swift - UI test of the menu bar (app and View menu), the About and Licenses
// windows, the agreement of the first start and Quit (QA measure S6, see doc/qameasures.md).
// The app is started without the game (launch argument --no-game), so the test does not need
// ASC's game window and does not touch the user's data; the agreement is shown with
// --show-agreement, which does not store an acceptance.
// Quitting while the game runs is checked manually (see doc/buildAndTest.md).

import XCTest

@MainActor
final class MenuBarUITests: XCTestCase {
    private let appName = "ASC for Mac"

    override func setUp() async throws {
        continueAfterFailure = false
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--no-game"]
        app.launch()
        return app
    }

    /// Opens the app menu, the first menu after the Apple menu.
    private func openAppMenu(of app: XCUIApplication) {
        app.menuBars.menuBarItems.element(boundBy: 1).click()
    }

    func testAppMenuHasAboutAndQuit() {
        let app = launchApp()
        openAppMenu(of: app)
        XCTAssertTrue(app.menuItems["About \(appName)"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.menuItems["Quit \(appName)"].exists)
        app.typeKey(.escape, modifierFlags: [])
        app.terminate()
    }

    func testAboutWindowShowsTheAscCoreVersion() throws {
        let app = launchApp()
        openAppMenu(of: app)
        app.menuItems["About \(appName)"].click()

        let window = app.windows["About \(appName)"]
        XCTAssertTrue(window.waitForExistence(timeout: 5))
        let versionText = window.staticTexts["ascCoreVersion"]
        XCTAssertTrue(versionText.exists)
        // The ASC core in thirdparty/asc/ has a version like 2.6.99.0 (see doc/thirdparty.md).
        // On macOS, the text of a SwiftUI Text is the value of the static text, not its label.
        let text = try XCTUnwrap(versionText.value as? String)
        XCTAssertTrue(text.hasPrefix("ASC core version "), text)
        let version = try XCTUnwrap(text.split(separator: " ").last.map(String.init))
        XCTAssertTrue(version.hasPrefix("2."), text)
        XCTAssertGreaterThanOrEqual(version.split(separator: ".").count, 3, text)
        app.terminate()
    }

    func testAboutWindowShowsTheAppIcon() {
        let app = launchApp()
        openAppMenu(of: app)
        app.menuItems["About \(appName)"].click()

        let window = app.windows["About \(appName)"]
        XCTAssertTrue(window.waitForExistence(timeout: 5))
        let icon = window.images["appIcon"]
        XCTAssertTrue(icon.exists)
        XCTAssertEqual(icon.frame.size, CGSize(width: 128, height: 128))
        app.terminate()
    }

    func testAboutWindowShowsTheAppVersionAndBuildNumber() throws {
        let app = launchApp()
        openAppMenu(of: app)
        app.menuItems["About \(appName)"].click()

        let window = app.windows["About \(appName)"]
        XCTAssertTrue(window.waitForExistence(timeout: 5))
        let versionText = window.staticTexts["appVersion"]
        XCTAssertTrue(versionText.exists)
        let text = try XCTUnwrap(versionText.value as? String)
        XCTAssertEqual(text, "App version 2.6.99.0 (build 1)")
        app.terminate()
    }

    func testLicensesWindowListsTheComponents() throws {
        let app = launchApp()
        openAppMenu(of: app)
        app.menuItems["Licenses…"].click()

        let window = app.windows["Licenses"]
        XCTAssertTrue(window.waitForExistence(timeout: 5))
        XCTAssertTrue(window.staticTexts["appLicense"].exists)
        let ascRow = window.outlines["licensePackages"].staticTexts["Advanced Strategic Command (ASC)"]
        XCTAssertTrue(ascRow.waitForExistence(timeout: 5))
        ascRow.click()

        let name = window.staticTexts["licensePackageName"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        XCTAssertEqual(name.value as? String, "Advanced Strategic Command (ASC)")
        let license = try XCTUnwrap(window.staticTexts["licensePackageLicense"].value as? String)
        XCTAssertEqual(license, "Licence: GPL-2.0-or-later")
        app.terminate()
    }

    func testViewMenuHasTheFullScreenItem() {
        let app = launchApp()
        let viewMenu = app.menuBars.menuBarItems["View"]
        XCTAssertTrue(viewMenu.waitForExistence(timeout: 5))
        viewMenu.click()
        // Switching itself needs the game window and is checked manually (TASK-0028).
        XCTAssertTrue(app.menuItems["Enter Full Screen"].waitForExistence(timeout: 5))
        app.typeKey(.escape, modifierFlags: [])
        app.terminate()
    }

    /// Starts the app with the agreement of the first start (TASK-0026), without the game and
    /// without storing an acceptance.
    private func launchAppWithAgreement() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--no-game", "--show-agreement"]
        app.launch()
        return app
    }

    func testAgreementShowsTheGPLWithOneClick() {
        let app = launchAppWithAgreement()
        let window = app.windows["Before you play \(appName)"]
        XCTAssertTrue(window.waitForExistence(timeout: 5))
        XCTAssertTrue(window.staticTexts["agreementText"].exists)
        window.buttons["Show Licence"].click()
        let licenses = app.windows["Licenses"]
        XCTAssertTrue(licenses.waitForExistence(timeout: 5))
        XCTAssertTrue(licenses.staticTexts["licensePackageName"].waitForExistence(timeout: 5))
        XCTAssertEqual(licenses.staticTexts["licensePackageName"].value as? String, appName)
        app.terminate()
    }

    func testDecliningTheAgreementEndsTheApp() {
        let app = launchAppWithAgreement()
        let window = app.windows["Before you play \(appName)"]
        XCTAssertTrue(window.waitForExistence(timeout: 5))
        window.buttons["Decline"].click()
        XCTAssertTrue(app.wait(for: .notRunning, timeout: 10))
    }

    func testClosingTheAgreementEndsTheApp() {
        let app = launchAppWithAgreement()
        let window = app.windows["Before you play \(appName)"]
        XCTAssertTrue(window.waitForExistence(timeout: 5))
        window.buttons[XCUIIdentifierCloseWindow].click()
        XCTAssertTrue(app.wait(for: .notRunning, timeout: 10))
    }

    func testAcceptingTheAgreementClosesItAndKeepsTheAppRunning() {
        let app = launchAppWithAgreement()
        let window = app.windows["Before you play \(appName)"]
        XCTAssertTrue(window.waitForExistence(timeout: 5))
        window.buttons["Accept"].click()
        XCTAssertTrue(window.waitForNonExistence(timeout: 5))
        // Without the game (--no-game), the app keeps running with its menu bar.
        XCTAssertEqual(app.state, .runningForeground)
        app.terminate()
    }

    func testCommandQEndsTheApp() {
        let app = launchApp()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        app.typeKey("q", modifierFlags: .command)
        XCTAssertTrue(app.wait(for: .notRunning, timeout: 10))
    }
}
