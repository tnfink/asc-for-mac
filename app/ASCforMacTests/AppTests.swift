// AppTests.swift - Tests of the app's parts that run without the game window. Starting and
// quitting the game itself is checked manually (see doc/buildAndTest.md).

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

    @Test func requestingQuitWithoutRunningGameDoesNothing() {
        Game.requestQuit()
        #expect(!Game.isRunning)
    }
}
