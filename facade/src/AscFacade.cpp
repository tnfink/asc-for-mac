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

namespace {

MapInfo toFacade(const ascadapter::MapInfo& info) {
    return {.error = info.error, .width = info.width, .height = info.height, .playerCount = info.playerCount};
}

}  // namespace

MapInfo loadMap(const std::string& fileName) {
    return toFacade(ascadapter::loadMap(fileName));
}

std::string runAITurn() {
    return ascadapter::runAITurn();
}

std::string saveGame(const std::string& fileName) {
    return ascadapter::saveGame(fileName);
}

MapInfo loadGame(const std::string& fileName) {
    return toFacade(ascadapter::loadGame(fileName));
}

int currentTurn() {
    return ascadapter::currentTurn();
}

int currentPlayerCount() {
    return ascadapter::currentPlayerCount();
}

int currentPlayer() {
    return ascadapter::currentPlayer();
}

}  // namespace ascfacade
