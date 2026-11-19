// AscFacade.cpp - Implementation of the facade (C++20). Calls the ASC core only through the
// adapter (AscCoreAdapter.h).

#include "AscFacade.h"

#include "AscCoreAdapter.h"

namespace ascfacade {

std::string ascVersion() {
    return ascadapter::ascVersion();
}

}  // namespace ascfacade
