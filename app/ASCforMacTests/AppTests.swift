// AppTests.swift - Tests of the app's parts that run without the game window. Starting and
// quitting the game itself is checked manually (see doc/buildAndTest.md).

import AppKit
import AscFacade
import Foundation
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

    @Test func requestingQuitWithoutRunningGameDoesNothing() {
        Game.requestQuit()
        #expect(!Game.isRunning)
    }
}
