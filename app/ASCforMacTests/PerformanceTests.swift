// PerformanceTests.swift - Performance smoke test (QA measure S5, TASK-0018): time limits for
// loading the standard maps and for AI turns, measured through the facade without a window.
// The maps and limits were agreed with the user (see doc/qameasures.md, S5). The suite also
// holds the quick tests of saving and loading a game (TASK-0017), because the ASC core is
// global state and its tests must not run in parallel.

import AscFacade
import CxxStdlib
import Foundation
import Testing

/// The ASC core, prepared once per test process for use without a window.
enum PreparedCore {
    /// Empty if the core is prepared, otherwise the error.
    static let error: String = {
        let userData = FileManager.default.temporaryDirectory
            .appending(path: "asc-for-mac-tests-\(ProcessInfo.processInfo.processIdentifier)")
        do {
            try FileManager.default.createDirectory(at: userData, withIntermediateDirectories: true)
        } catch {
            return "could not create \(userData.path()): \(error)"
        }
        let paths = ascfacade.GamePaths(
            executablePath: std.string(Bundle.main.executablePath ?? ""),
            resourceDirectory: std.string(Bundle.main.resourcePath ?? ""),
            userDataDirectory: std.string(userData.path(percentEncoded: false))
        )
        return String(ascfacade.prepareCoreWithoutWindow(paths))
    }()
}

/// A standard map of the performance smoke test with its time limits (Debug build).
struct StandardMap: CustomTestStringConvertible, Sendable {
    let fileName: String
    /// The limit for loading the map.
    let loadLimit: Duration
    /// The limit for the average AI turn over one round (every player's turn once).
    let averageAITurnLimit: Duration

    var testDescription: String { fileName }

    /// Measured on an Apple M2 Max (Debug): asc001 0.003 s / 0.005 s, railstations2
    /// 0.006 s / 0.78 s, asc014 0.010 s / 1.31 s (load / average AI turn); the limits are about
    /// three times the measured values (user decision).
    static let small = StandardMap(
        fileName: "asc001.map", loadLimit: .milliseconds(100), averageAITurnLimit: .milliseconds(100))
    static let medium = StandardMap(
        fileName: "railstations2.map", loadLimit: .milliseconds(100), averageAITurnLimit: .seconds(2.5))
    static let large = StandardMap(
        fileName: "asc014.map", loadLimit: .milliseconds(100), averageAITurnLimit: .seconds(4))
    static let all = [small, medium, large]
}

/// The ASC core is global state, so the tests run one after the other.
@Suite(.serialized)
struct PerformanceTests {
    private let clock = ContinuousClock()

    @Test(.timeLimit(.minutes(2)), arguments: StandardMap.all)
    func standardMapLoadsAndAITurnsStayWithinTheirTimeLimits(map: StandardMap) throws {
        try #require(PreparedCore.error.isEmpty, "\(PreparedCore.error)")

        var info = ascfacade.MapInfo()
        let loadTime = clock.measure { info = ascfacade.loadMap(std.string(map.fileName)) }
        try #require(String(info.error).isEmpty, "\(map.fileName): \(String(info.error))")
        try #require(info.playerCount > 0)

        var turnTimes: [Duration] = []
        for _ in 0..<info.playerCount {
            var error = ""
            turnTimes.append(clock.measure { error = String(ascfacade.runAITurn()) })
            try #require(error.isEmpty, "\(map.fileName): \(error)")
        }
        let averageTurnTime = turnTimes.reduce(.zero, +) / turnTimes.count

        let report =
            "\(map.fileName) (\(info.width)x\(info.height), \(info.playerCount) players): "
            + "load \(loadTime) (limit \(map.loadLimit)), average AI turn \(averageTurnTime) "
            + "(limit \(map.averageAITurnLimit))"
        print("Performance smoke test: \(report)")
        #expect(loadTime <= map.loadLimit, "\(report)")
        #expect(averageTurnTime <= map.averageAITurnLimit, "\(report)")
    }

    @Test func loadingAMissingMapReportsAnErrorAndLeavesNoGame() throws {
        try #require(PreparedCore.error.isEmpty, "\(PreparedCore.error)")
        let info = ascfacade.loadMap(std.string("no-such-map.map"))
        #expect(!String(info.error).isEmpty)
        #expect(!String(ascfacade.runAITurn()).isEmpty)
        #expect(!String(ascfacade.saveGame(std.string("no-game.sav"))).isEmpty)
        #expect(ascfacade.currentTurn() == 0)
        #expect(ascfacade.currentPlayer() == -1)
        #expect(ascfacade.currentPlayerCount() == 0)
    }

    @Test func aSavedGameContinuesAfterLoading() throws {
        try #require(PreparedCore.error.isEmpty, "\(PreparedCore.error)")
        let info = ascfacade.loadMap(std.string(StandardMap.small.fileName))
        try #require(String(info.error).isEmpty, "\(String(info.error))")
        for _ in 0..<info.playerCount {
            try #require(String(ascfacade.runAITurn()).isEmpty)
        }
        let turn = ascfacade.currentTurn()
        let player = ascfacade.currentPlayer()
        #expect(turn == 2)

        try #require(String(ascfacade.saveGame(std.string("quick-test.sav"))).isEmpty)
        let loaded = ascfacade.loadGame(std.string("quick-test.sav"))
        try #require(String(loaded.error).isEmpty, "\(String(loaded.error))")
        #expect(loaded.playerCount == info.playerCount)
        #expect(ascfacade.currentPlayerCount() == info.playerCount)
        #expect(ascfacade.currentTurn() == turn)
        #expect(ascfacade.currentPlayer() == player)
        #expect(String(ascfacade.runAITurn()).isEmpty)
    }

    @Test func loadingAMissingSaveGameReportsAnError() throws {
        try #require(PreparedCore.error.isEmpty, "\(PreparedCore.error)")
        #expect(!String(ascfacade.loadGame(std.string("no-such-game.sav")).error).isEmpty)
        #expect(ascfacade.currentTurn() == 0)
    }
}
