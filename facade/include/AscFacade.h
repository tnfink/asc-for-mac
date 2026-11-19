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

}  // namespace ascfacade

#endif  // ASCFACADE_ASCFACADE_H
