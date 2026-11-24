// LongGameTests.swift - Long-game test (QA measure S3, TASK-0017): an AI-only game over many
// rounds on standard maps without a window, saved and loaded at intervals. It takes minutes, so
// it runs only when requested (scripts/test-long-game.sh, see doc/buildAndTest.md). The maps,
// the number of rounds, the save interval and the handling of an early end were agreed with
// the user (see doc/qameasures.md, S3).

import AscFacade
import CxxStdlib
import Foundation
import Testing

/// The settings of the long-game test.
enum LongGame {
    /// The environment variable that requests the test; scripts/test-long-game.sh sets it
    /// through xcodebuild as `TEST_RUNNER_ASC_LONG_GAME=1`.
    static let requestVariable = "ASC_LONG_GAME"

    static var isRequested: Bool {
        ProcessInfo.processInfo.environment[requestVariable] == "1"
    }

    /// The standard maps of the performance smoke test (S5).
    static let maps = StandardMap.all.map(\.fileName)

    /// The number of rounds per map (every player's turn once per round).
    static let rounds = 100

    /// The game is saved and loaded after every this many rounds.
    static let saveInterval = 10

    /// Without a window, a game has ended when fewer than this many players are left (see
    /// `currentPlayerCount` in AscFacade.h). An earlier end passes the test and is reported.
    static let minimumPlayers = 2
}

/// The ASC core is global state, so the tests run one after the other.
@Suite(.serialized, .enabled(if: LongGame.isRequested, "only with scripts/test-long-game.sh"))
struct LongGameTests {
    private let clock = ContinuousClock()

    @Test(arguments: LongGame.maps)
    func aiOnlyGameRunsOverManyRoundsWithSavingAndLoading(map: String) throws {
        try #require(PreparedCore.error.isEmpty, "\(PreparedCore.error)")
        let start = clock.now
        let info = ascfacade.loadMap(std.string(map))
        try #require(String(info.error).isEmpty, "\(map): \(String(info.error))")
        let saveGame = "long-game-\(map).sav"
        var savesAndLoads = 0

        var round = 0
        roundLoop: while round < LongGame.rounds {
            let turn = ascfacade.currentTurn()
            while ascfacade.currentTurn() == turn {
                let error = String(ascfacade.runAITurn())
                if ascfacade.currentPlayerCount() < LongGame.minimumPlayers {
                    break roundLoop
                }
                try #require(error.isEmpty, "\(map), round \(round + 1): \(error)")
            }
            round += 1

            if round.isMultiple(of: LongGame.saveInterval) {
                let turnBefore = ascfacade.currentTurn()
                let playerBefore = ascfacade.currentPlayer()
                let playersBefore = ascfacade.currentPlayerCount()
                let saveError = String(ascfacade.saveGame(std.string(saveGame)))
                try #require(saveError.isEmpty, "\(map), saving after round \(round): \(saveError)")
                let loadError = String(ascfacade.loadGame(std.string(saveGame)).error)
                try #require(loadError.isEmpty, "\(map), loading after round \(round): \(loadError)")
                try #require(ascfacade.currentTurn() == turnBefore, "\(map): turn after loading")
                try #require(ascfacade.currentPlayer() == playerBefore, "\(map): player after loading")
                try #require(ascfacade.currentPlayerCount() == playersBefore, "\(map): players after loading")
                savesAndLoads += 1
            }
        }

        let result =
            round < LongGame.rounds
            ? "the game ended in round \(round + 1) with \(ascfacade.currentPlayerCount()) player(s) left"
            : "\(round) rounds, \(ascfacade.currentPlayerCount()) players left"
        print(
            "Long-game test: \(map) (\(info.width)x\(info.height), \(info.playerCount) players): \(result), "
                + "saved and loaded \(savesAndLoads) times, \(clock.now - start)")
    }
}
