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

}  // namespace ascfacade

#endif  // ASCFACADE_ASCFACADE_H
