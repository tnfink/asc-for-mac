// AscCoreAdapter.cpp - Calls into the ASC core. Compiled with C++11 (see AscCoreAdapter.h).

#include "AscCoreAdapter.h"

#include <SDL.h>

#include <memory>
#include <vector>

#include "ai/ai.h"
#include "applicationstarter.h"
#include "autotraining.h"
#include "basestrm.h"
#include "dlg_box.h"
#include "gamemap.h"
#include "gameoptions.h"
#include "loaders.h"
#include "pgfilearchive.h"
#include "researchexecution.h"
#include "resourcenet.h"
#include "sdl/sound.h"
#include "sgstream.h"
#include "strtmesg.h"
#include "tasks/taskcontainer.h"
#include "turncontrol.h"
#include "viewcalculation.h"

// ASC's main program (thirdparty/asc/source/sg.cpp), renamed by a compile definition in
// core/CMakeLists.txt.
int asc_game_main(int argc, char** argv);

// Runs ASC's AI for the current player (thirdparty/asc/source/turncontrol.cpp, not declared
// in a header); the game calls it for every computer player.
void runai(GameMap* actmap, int playerView, MapDisplayInterface* display);

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

// The state of the ASC core used without a window (prepareCoreWithoutWindow), kept for the
// lifetime of the process.
struct CoreState {
    bool prepared = false;
    std::unique_ptr<GameMap> currentMap;
};

CoreState& coreState() {
    static CoreState state;
    return state;
}

// Runs an action of the ASC core and turns ASC's exceptions into an error message (empty if
// the action succeeded).
template <typename Action>
std::string catchingAscErrors(Action action) {
    try {
        action();
        return {};
    } catch (const ASCmsgException& e) {
        return e.getMessage();
    } catch (const tfileerror& e) {
        return "error accessing file " + e.getFileName();
    } catch (const ActionResult& e) {
        return "action failed: " + e.getMessage();
    } catch (const ShutDownMap&) {
        return "the game ended (no player left to play)";
    } catch (const NoMapLoaded&) {
        return "the game ended (no map loaded)";
    } catch (const ASCexception&) {
        return "error in the ASC core";
    } catch (const std::exception& e) {
        return e.what();
    } catch (...) {
        return "unknown error in the ASC core";
    }
}

void runResearchOfPlayer(Player& player) {
    runResearch(player, nullptr, nullptr);
}

// What happens at the start of a player's turn in a loaded map, as in ASC's unittester
// (deployMapPlayingHooks in unittests/main.cpp) without the replay logging; the game's
// version in sg.cpp also connects its user interface.
void deployMapPlayingHooks(GameMap* map) {
    map->sigPlayerTurnBegins.connect(sigc::ptr_fun(&transfer_all_outstanding_tribute));
    map->sigPlayerTurnBegins.connect(sigc::ptr_fun(&runResearchOfPlayer));
}

int existingPlayers(const GameMap& map) {
    int count = 0;
    for (int i = 0; i < map.getPlayerCount(); ++i) {
        if (map.getPlayer(i).exist()) {
            ++count;
        }
    }
    return count;
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

std::string prepareCoreWithoutWindow(const GamePaths& paths) {
    CoreState& state = coreState();
    if (state.prepared) {
        return {};
    }
    const std::string configFile = withTrailingSlash(paths.userDataDirectory) + "asc2rc";
    // The same steps as ASC's unittester (thirdparty/asc/source/unittests/main.cpp):
    // configuration and search paths, sound switched off, the hooks of the game (also set by
    // ASC's main program in sg.cpp), ParaGUI's file archive, palette and game data.
    std::string error = catchingAscErrors([&] {
        prepareConfiguration(configFile, paths);
        initFileIO(configFile);
        static const SoundSystem soundSystem(true, true, true);
        tspfldloaders::mapLoaded.connect(sigc::ptr_fun(&deployMapPlayingHooks));
        TaskContainer::registerHooks();
        GameMap::sigPlayerTurnEndsStatic.connect(sigc::ptr_fun(&automaticTrainig));
        static const std::string executablePath = paths.executablePath;
        static const PG_FileArchive archive(executablePath.c_str());
        loadpalette();
        virtualscreenbuf.init();
        loaddata();
    });
    if (error.empty()) {
        state.prepared = true;
    }
    return error;
}

namespace {

// Loads a map or a save game with ASC's loader as the current game, replacing the previous
// one (loadMap, loadGame).
template <typename Loader>
MapInfo loadAsCurrentGame(const std::string& fileName, Loader loader) {
    CoreState& state = coreState();
    MapInfo info = {std::string(), 0, 0, 0};
    if (!state.prepared) {
        info.error = "the ASC core is not prepared (prepareCoreWithoutWindow)";
        return info;
    }
    state.currentMap.reset();
    std::unique_ptr<GameMap> map;
    info.error = catchingAscErrors([&] {
        // Like startMap() of ASC's unittester (unittests/unittestutil.cpp) and loadGameFromFile()
        // in sg.cpp, but without mapLoadingExceptionChecker, which reports errors in a message
        // box: ASC's exceptions are returned as the error. No replay is recorded.
        map.reset(loader(fileName));
        if (!map) {
            return;
        }
        map->levelfinished = 0;
        std::unique_ptr<GameMap::ReplayInfo>(map->replayinfo).reset();
        map->replayinfo = nullptr;
        computeview(map.get());
        if (map->actplayer == -1) {
            try {
                next_turn(map.get(), NextTurnStrategy_Abort(), nullptr, -1);
            } catch (const NoMapLoaded&) {
                // next_turn has deleted the map.
                const GameMap* const deletedByNextTurn = map.release();
                static_cast<void>(deletedByNextTurn);
                throw;
            }
        }
    });
    if (info.error.empty() && !map) {
        info.error = "could not load " + fileName;
    }
    if (!info.error.empty()) {
        return info;
    }
    info.width = map->xsize;
    info.height = map->ysize;
    info.playerCount = existingPlayers(*map);
    state.currentMap = std::move(map);
    return info;
}

GameMap* loadMapFile(const std::string& fileName) {
    return tmaploaders::loadmap(fileName);
}

GameMap* loadSaveGameFile(const std::string& fileName) {
    return tsavegameloaders::loadGameFromFile(fileName);
}

}  // namespace

MapInfo loadMap(const std::string& fileName) {
    return loadAsCurrentGame(fileName, &loadMapFile);
}

std::string saveGame(const std::string& fileName) {
    GameMap* map = coreState().currentMap.get();
    if (map == nullptr) {
        return "no game loaded (loadMap, loadGame)";
    }
    return catchingAscErrors([&] {
        // What savegame() in loaders.cpp does, without its message box on errors.
        tsavegameloaders loader;
        loader.savegame(map, fileName);
    });
}

MapInfo loadGame(const std::string& fileName) {
    return loadAsCurrentGame(fileName, &loadSaveGameFile);
}

int currentTurn() {
    const GameMap* map = coreState().currentMap.get();
    return map == nullptr ? 0 : map->time.turn();
}

int currentPlayerCount() {
    const GameMap* map = coreState().currentMap.get();
    return map == nullptr ? 0 : existingPlayers(*map);
}

int currentPlayer() {
    const GameMap* map = coreState().currentMap.get();
    return map == nullptr ? -1 : map->actplayer;
}

std::string runAITurn() {
    GameMap* map = coreState().currentMap.get();
    if (map == nullptr) {
        return "no game loaded (loadMap, loadGame)";
    }
    return catchingAscErrors([&] {
        // What iterateToNextPlayer() in turncontrol.cpp does for a computer player, without a
        // display; then the next player whose turn it is becomes the current player.
        const int player = map->getCurrentPlayer().getPosition();
        map->beginTurn();
        runai(map, player, nullptr);
        map->endTurn();
        const int nextPlayer = findNextPlayer(map);
        if (nextPlayer <= player) {
            map->endRound();
        }
        map->actplayer = static_cast<decltype(map->actplayer)>(nextPlayer);
    });
}

}  // namespace ascadapter
