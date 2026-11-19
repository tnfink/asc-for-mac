// AscCoreAdapter.cpp - Calls into the ASC core. Compiled with C++11 (see AscCoreAdapter.h).

#include "AscCoreAdapter.h"

#include "strtmesg.h"

namespace ascadapter {

std::string ascVersion() {
    return getVersionString();
}

}  // namespace ascadapter
