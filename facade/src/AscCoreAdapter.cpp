// AscCoreAdapter.cpp - Calls into the ASC core. Compiled with C++11 (see AscCoreAdapter.h).

#include "AscCoreAdapter.h"

#include <SDL.h>

#include <vector>

#include "basestrm.h"
#include "gameoptions.h"
#include "sgstream.h"
#include "strtmesg.h"

// ASC's main program (thirdparty/asc/source/sg.cpp), renamed by a compile definition in
// core/CMakeLists.txt.
int asc_game_main(int argc, char** argv);

namespace ascadapter {

namespace {

std::string withTrailingSlash(const std::string& path) {
    if (!path.empty() && path.back() != '/') {
        return path + "/";
    }
    return path;
}

// Writes ASC's configuration file in the user data directory, with the search paths ASC
// reads and writes its files from: first the user data directory (save games, maps, log),
// then the game data in the app bundle. The other options of an existing file are kept;
// the search paths are set at every start, because the app bundle may have moved.
void prepareConfiguration(const std::string& configFile, const GamePaths& paths) {
    CGameOptions* options = CGameOptions::Instance();
    if (exist(configFile)) {
        options->load(configFile);
    }
    options->searchPathNum = 0;
    options->addSearchPath(withTrailingSlash(paths.userDataDirectory));
    options->addSearchPath(withTrailingSlash(paths.resourceDirectory));
    options->setChanged();
    writegameoptions(configFile);
}

}  // namespace

std::string ascVersion() {
    return getVersionString();
}

int runGame(const GamePaths& paths) {
    const std::string configFile = withTrailingSlash(paths.userDataDirectory) + "asc2rc";
    prepareConfiguration(configFile, paths);

    // The same command line as "asc -c <configuration file>".
    std::vector<std::string> arguments = {paths.executablePath, "-c", configFile};
    std::vector<char*> argv;
    argv.reserve(arguments.size() + 1);
    for (std::string& argument : arguments) {
        argv.push_back(&argument.front());
    }
    argv.push_back(nullptr);
    return asc_game_main(static_cast<int>(arguments.size()), argv.data());
}

void requestQuit() {
    // ASC quits through its normal quit handling when it receives SDL's quit event.
    if (SDL_WasInit(SDL_INIT_EVENTS) != 0) {
        SDL_Event event;
        SDL_zero(event);
        event.type = SDL_QUIT;
        SDL_PushEvent(&event);
    }
}

}  // namespace ascadapter
