// AscFacade.cpp - Implementation of the facade (C++20). Calls the ASC core only through the
// adapter (AscCoreAdapter.h).

#include "AscFacade.h"

#include "AscCoreAdapter.h"

namespace ascfacade {

std::string ascVersion() {
    return ascadapter::ascVersion();
}

int runGame(const GamePaths& paths) {
    return ascadapter::runGame({.executablePath = paths.executablePath,
                                .resourceDirectory = paths.resourceDirectory,
                                .userDataDirectory = paths.userDataDirectory,});
}

void requestQuit() {
    ascadapter::requestQuit();
}

std::string prepareCoreWithoutWindow(const GamePaths& paths) {
    return ascadapter::prepareCoreWithoutWindow({.executablePath = paths.executablePath,
                                                 .resourceDirectory = paths.resourceDirectory,
                                                 .userDataDirectory = paths.userDataDirectory,});
}

MapInfo loadMap(const std::string& fileName) {
    const ascadapter::MapInfo info = ascadapter::loadMap(fileName);
    return {.error = info.error, .width = info.width, .height = info.height, .playerCount = info.playerCount};
}

std::string runAITurn() {
    return ascadapter::runAITurn();
}

}  // namespace ascfacade
