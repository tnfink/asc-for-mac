// MenuBarUITests.swift - UI test of the menu bar, the About window and Quit (QA measure S6,
// see doc/qameasures.md). The app is started without the game (launch argument --no-game), so
// the test does not need ASC's game window and does not touch the user's data. Quitting while
// the game runs is checked manually (see doc/buildAndTest.md).

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

    func testCommandQEndsTheApp() {
        let app = launchApp()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        app.typeKey("q", modifierFlags: .command)
        XCTAssertTrue(app.wait(for: .notRunning, timeout: 10))
    }
}
