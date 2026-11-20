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

}  // namespace ascfacade
