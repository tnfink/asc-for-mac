// Game.swift - Runs the ASC game through the facade (see doc/architecture.md, "UI technology"
// and "Data storage").

import AscFacade
import CxxStdlib
import Foundation

@MainActor
enum Game {
    /// Whether the game is running; then quitting the app goes through ASC's quit handling.
    private(set) static var isRunning = false

    /// The directory for user data: ASC's configuration file, save games, maps and log files.
    static var userDataDirectory: URL {
        URL.applicationSupportDirectory.appending(path: "asc-for-mac", directoryHint: .isDirectory)
    }

    /// Whether the app runs as host of the automated tests; then the game is not started.
    static var isHostingTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    /// Runs the game until the player quits and returns ASC's exit code. ASC creates the game
    /// window with SDL; SDL processes the app's events (including the menu bar) meanwhile.
    static func run() throws -> Int32 {
        try FileManager.default.createDirectory(at: userDataDirectory, withIntermediateDirectories: true)
        let executablePath = Bundle.main.executablePath ?? CommandLine.arguments[0]
        let resourceDirectory = Bundle.main.resourcePath ?? ""
        isRunning = true
        defer { isRunning = false }
        let paths = ascfacade.GamePaths(
            executablePath: std.string(executablePath),
            resourceDirectory: std.string(resourceDirectory),
            userDataDirectory: std.string(userDataDirectory.path(percentEncoded: false))
        )
        return ascfacade.runGame(paths)
    }

    /// Asks the running game to quit through ASC's normal quit handling.
    static func requestQuit() {
        ascfacade.requestQuit()
    }
}
