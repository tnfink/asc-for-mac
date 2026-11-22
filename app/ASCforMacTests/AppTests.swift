// AppTests.swift - Tests of the app's parts that run without the game window. Starting and
// quitting the game itself is checked manually (see doc/buildAndTest.md).

import AppKit
import AscFacade
import Foundation
import SwiftUI
import Testing

@testable import ASCforMac

@MainActor
struct AppTests {
    @Test func appInfoShowsTheVersions() {
        #expect(AppInfo.ascVersion == String(ascfacade.ascVersion()))
        #expect(AppInfo.appVersion == "2.6.99.0")
    }

    @Test func userDataIsStoredInApplicationSupport() {
        let directory = Game.userDataDirectory.path(percentEncoded: false)
        #expect(directory.hasSuffix("/Library/Application Support/asc-for-mac/"))
    }

    @Test func theGameIsNotStartedWhenHostingTests() {
        #expect(Game.isHostingTests)
        #expect(!Game.isRunning)
    }

    @Test func theGameStartsOnlyWithoutNoGameArgumentAndOutsideTests() {
        #expect(Game.shouldStart(arguments: ["ASCforMac"], isHostingTests: false))
        #expect(!Game.shouldStart(arguments: ["ASCforMac", "--no-game"], isHostingTests: false))
        #expect(!Game.shouldStart(arguments: ["ASCforMac"], isHostingTests: true))
        #expect(!Game.shouldStart())
    }

    @Test func theViewMenuSwitchesFullScreenWithControlCommandF() throws {
        let mainMenu = MainMenu.make(appDelegate: AppDelegate())
        let viewMenu = try #require(mainMenu.items.compactMap(\.submenu).first { $0.title == MainMenu.viewMenuTitle })
        let item = try #require(viewMenu.items.first { $0.action == #selector(NSWindow.toggleFullScreen(_:)) })
        #expect(item.title == "Enter Full Screen")
        #expect(item.keyEquivalent == "f")
        #expect(item.keyEquivalentModifierMask == [.control, .command])
        // Sent to the key window (the game window), not to a fixed target.
        #expect(item.target == nil)
    }

    /// Runs `body` with empty `UserDefaults` of its own, so the tests neither depend on nor
    /// change the developer's stored acceptance of the agreement.
    private func withTemporaryDefaults(_ body: (UserDefaults) throws -> Void) throws {
        let suiteName = "asc-for-mac-tests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        try body(defaults)
    }

    @Test func theAgreementIsShownBeforeTheGameUntilItIsAccepted() throws {
        try withTemporaryDefaults { defaults in
            let arguments = ["ASCforMac"]
            #expect(
                LicenseAgreement.startAction(shouldStartGame: true, defaults: defaults, arguments: arguments)
                    == .showAgreement)
            #expect(!LicenseAgreement.isAccepted(in: defaults))

            // "Accept" stores the acceptance and starts the game.
            #expect(LicenseAgreement.accept(shouldStartGame: true, defaults: defaults, arguments: arguments))
            #expect(LicenseAgreement.isAccepted(in: defaults))

            // On the next start, the game starts without the agreement.
            #expect(
                LicenseAgreement.startAction(shouldStartGame: true, defaults: defaults, arguments: arguments)
                    == .startGame)
        }
    }

    @Test func withoutGameTheAgreementIsNotShown() throws {
        try withTemporaryDefaults { defaults in
            #expect(
                LicenseAgreement.startAction(shouldStartGame: false, defaults: defaults, arguments: ["ASCforMac"])
                    == .nothing)
        }
    }

    @Test func theShowAgreementArgumentShowsItWithoutStoringTheAcceptance() throws {
        try withTemporaryDefaults { defaults in
            defaults.set(true, forKey: LicenseAgreement.acceptedKey)
            let arguments = ["ASCforMac", Game.noGameArgument, LicenseAgreement.showAgreementArgument]
            #expect(
                LicenseAgreement.startAction(shouldStartGame: false, defaults: defaults, arguments: arguments)
                    == .showAgreement)
            defaults.removeObject(forKey: LicenseAgreement.acceptedKey)
            #expect(!LicenseAgreement.accept(shouldStartGame: false, defaults: defaults, arguments: arguments))
            #expect(!LicenseAgreement.isAccepted(in: defaults))
        }
    }

    @Test func theAgreementTextRefersToTheGPL() {
        #expect(LicenseAgreement.text.contains("GNU General Public License, version 2 or later"))
        #expect(LicenseAgreement.text.contains("sections 11 and 12"))
        #expect(LicenseAgreement.text.contains("\"Accept\""))
    }

    @Test func theAgreementViewCanBeShown() {
        let view = LicenseAgreementView(onShowLicence: {}, onDecline: {}, onAccept: {})
        let controller = NSHostingController(rootView: view)
        #expect(controller.view.fittingSize.width > 0)
    }

    @Test func showLicenceOpensTheLicensesWindowWithTheGPLSelected() throws {
        let delegate = AppDelegate()
        delegate.showLicensesWindow(selecting: LicenseInfo.appPackageID)
        let window = try #require(NSApplication.shared.windows.first { $0.title == "Licenses" && $0.isVisible })
        #expect(window.contentViewController is NSHostingController<LicensesView>)
        window.close()
    }

    @Test func requestingQuitWithoutRunningGameDoesNothing() {
        Game.requestQuit()
        #expect(!Game.isRunning)
    }
}
