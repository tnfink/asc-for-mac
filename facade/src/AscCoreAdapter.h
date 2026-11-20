// AscCoreAdapter.h - Internal interface between the facade (C++20) and the ASC core (C++11).
//
// ASC's headers cannot be compiled with C++20 (e.g. they use std::auto_ptr, removed in
// C++17). Only AscCoreAdapter.cpp includes them and is compiled with C++11, like the ASC core.
// This header uses only standard types, so it compiles with both standards.

#ifndef ASCFACADE_ASCCOREADAPTER_H
#define ASCFACADE_ASCCOREADAPTER_H

#include <string>

// A flat namespace, because nested namespace definitions (a::b) need C++17.
namespace ascadapter {

std::string ascVersion();

// The paths the game needs (see ascfacade::GamePaths in AscFacade.h).
struct GamePaths {
    std::string executablePath;
    std::string resourceDirectory;
    std::string userDataDirectory;
};

int runGame(const GamePaths& paths);

void requestQuit();

}  // namespace ascadapter

#endif  // ASCFACADE_ASCCOREADAPTER_H
