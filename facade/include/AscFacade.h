// AscFacade.h - The interface between the Swift app and the ASC core.
//
// The Swift app calls only the functions declared here, never ASC's classes directly
// (see doc/architecture.md, section "Structure of the application"). Keep this header free
// of ASC headers and of C++ features that Swift/C++ interoperability does not support.

#ifndef ASCFACADE_ASCFACADE_H
#define ASCFACADE_ASCFACADE_H

#include <string>

namespace ascfacade {

/// Returns the version of the ASC core, e.g. "2.6.99.0" (the version the game writes into save games).
std::string ascVersion();

/// The paths the game needs.
struct GamePaths {
    /// The path of the app's executable.
    std::string executablePath;
    /// The directory with the game data (main.ascdat, asc2_dlg.zip, pbp.ascdat), read only.
    std::string resourceDirectory;
    /// The existing directory for user data: ASC's configuration file asc2rc, save games,
    /// maps and log files.
    std::string userDataDirectory;
};

/// Runs the game: shows ASC's main menu in an SDL window and returns when the player quits,
/// with ASC's exit code (0 = normal end). Blocks the calling thread, which must be the main
/// thread; SDL processes the app's events (including the menu bar) meanwhile.
int runGame(const GamePaths& paths);

/// Asks the running game to quit through ASC's normal quit handling (SDL quit event).
/// Does nothing if the game is not running.
void requestQuit();

// Using the ASC core without a window, e.g. for automated tests (performance smoke test,
// TASK-0018; meant to be reused for loading maps and save games, TASK-0015, and for AI-only
// games, TASK-0017). Not to be combined with runGame in the same process.

/// Information about the map loaded with loadMap.
struct MapInfo {
    /// Empty if the map was loaded, otherwise why loading failed.
    std::string error;
    /// The size of the map in fields.
    int width = 0;
    int height = 0;
    /// The number of players on the map.
    int playerCount = 0;
};

/// Prepares the ASC core for use without a window: writes ASC's configuration file into the
/// user data directory (like runGame) and reads the game data. Returns an empty string on
/// success, otherwise the error. Only the first call per process does the work.
std::string prepareCoreWithoutWindow(const GamePaths& paths);

/// Loads a map from ASC's search paths (e.g. "asc001.map" from the game data) as the current
/// game, replacing the previous one. Needs prepareCoreWithoutWindow.
MapInfo loadMap(const std::string& fileName);

/// Runs one AI turn: ASC's AI plays the turn of the current player of the current game;
/// afterwards the next player is the current player. Returns an empty string on success,
/// otherwise the error.
std::string runAITurn();

}  // namespace ascfacade

#endif  // ASCFACADE_ASCFACADE_H
