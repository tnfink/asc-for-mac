# Software Architecture

This document describes the software architecture of **asc-for-mac**, the macOS port of
Advanced Strategic Command (ASC). It is based on `README.md`, `doc/qualityobjectives.md` and
`doc/context.md`. Every implementation must follow this document (see `AGENTS.md`).

The architecture was decided topic by topic by the project owner. For each topic, the decision,
the discussed alternatives and the rationale are given. A rationale marked *"proposed by the AI,
accepted by the user"* consists of the arguments of the AI's proposal, which the user accepted
without a reason of their own.

## Overview

| Topic | Decision |
|-------|----------|
| Reuse of the original ASC code | B+: keep the C++ core with a thin Swift layer first, convert to Swift step by step later |
| Structure | Swift app → C++ facade → unchanged ASC core; game data in the app bundle |
| Language and runtime | Swift 6.4 (Swift 6 language mode); C++11 for the ASC core, C++20 for the facade; macOS 27, Apple Silicon only |
| Server-side framework | Not applicable |
| UI technology | In-game UI unchanged (ParaGUI on SDL2); AppKit for app and menu bar, SwiftUI for separate windows |
| Data storage | ASC file formats unchanged; user data in `~/Library/Application Support/asc-for-mac/`; Swift settings in `UserDefaults` |
| 3rd party integration | Libraries via vcpkg at build time, linked statically; SDL2 |
| Location of 3rd party artifacts | `thirdparty/asc/` via `git subtree` |
| SBOM | SPDX 2.3 JSON of the app's content, committed as `doc/sbom.spdx.json` |
| Licences | Own code and the app as a whole GPL-2.0-or-later; licence information of all components generated from the SBOM, shown in the window "Licenses…" |
| Deployment and operation | Developer ID signing, notarization, `.dmg` as GitHub Release, no automatic updates |
| Build, tests, static checks | Xcode as main build calling CMake; Swift Testing plus ASC's `unittester`; swift-format, SwiftLint, clang-tidy, Clang Static Analyzer, warnings as errors |
| Network games | Decided in TASK-0009 |

## Analysis of the original ASC

Analyzed in TASK-0005 (2026-11-18) from the repository <https://github.com/ValHaris/asc-hq>
(branch `master`, commit `074a6ef`, 2026-11-06; ASC version 2.6.99.0) and the
website <https://www.asc-hq.org>.

- **Language and size:** C++11, about 265,000 lines in about 1,000 `.cpp`/`.h` files,
  including bundled libraries.
- **License:** GNU GPL version 2.
- **Build:** CMake 3.16 (`CMakeLists.txt`) and an older autotools build. Windows uses vcpkg
  (`vcpkg.json`). The only macOS support is an outdated script for the Fink package manager
  (`mac_configure`); there is no current macOS build.
- **External libraries** (from `vcpkg.json` and `CMakeLists.txt`): SDL2, SDL2_image,
  SDL2_mixer, Lua 5.1, libsigc++ 2, FreeType, Boost (regex, filesystem, system), Expat, bzip2,
  libpng, PhysFS, fmt.
- **Bundled libraries** (`source/libs`): ParaGUI (the complete in-game UI, drawn on SDL),
  SDL_sound, Loki, bzlib, revel, sdlmm, triangul.
- **Data:** about 59 MB of game data (`data/`) and 19 MB of extra data (`extra-data/`): maps,
  graphics, sounds, campaigns.
- **Multiplayer:** single player against the computer, and sequential multiplayer (hot-seat
  and play-by-email, PBEM). The PBEM server interaction is only a dummy in the current build
  (`source/network/pbem-server-dummy.cpp`).
- **Tests:** the test program `unittester` (`source/unittests`, about 20 test modules for
  game rules, AI, map loading and stream encoding).

## Reuse of the original ASC code

**Decision: B+.** First, the C++ core of ASC is kept and a thin Swift layer is added for the
macOS-specific parts (app start, menu bar, file locations, About window, Retina settings).
Game logic, file formats and drawing (SDL2/ParaGUI) stay unchanged. After the first working Mac
version, the C++ code is converted to Swift step by step, module by module, secured by
comparison tests that run the C++ and the Swift version with the same inputs (maps, save
games, moves) and require identical results.

**Alternatives discussed:**

- **A: build the original as it is** (C++, SDL2, no Swift): least effort and risk, but no
  Swift and the app feels only partly like a Mac app.
- **B: C++ core with a thin Swift layer, no planned conversion:** protects compatibility, but
  the code base stays C++.
- **C: convert everything to Swift right away** (with AI support): fully native, but writing
  the code is not the bottleneck; proving that about 200,000 converted lines behave exactly
  like the original (binary file formats, game rules, PBEM replays) is. ParaGUI would have to
  be redesigned, not converted, and a playable version would only exist at the end.

**Rationale (user):** a working Mac version first is more important.

## Structure of the application

**Decision:** the application consists of three parts:

1. **ASC core:** the original C++ code and its bundled libraries in `thirdparty/asc/`, built
   unchanged (except for minimal, marked changes) as a static library.
2. **Facade:** a thin C++ interface that offers exactly the functions the Swift app needs
   (e.g. start the game, load and save, settings, menu actions). The Swift app calls only the
   facade; Swift/C++ interoperability is limited to it. In the later conversion, modules are
   replaced behind the facade, and the comparison tests use it for both versions.
   Besides running the game, the facade can use the core without a window, for automated tests
   (TASK-0018): `prepareCoreWithoutWindow` (configuration and game data, like ASC's
   `unittester`), `loadMap` and `runAITurn`. They are meant to be reused for loading maps and
   save games (TASK-0015) and AI-only games (TASK-0017), and are not combined with `runGame` in
   the same process.
3. **Swift app:** the macOS-specific parts (see *UI technology*).

The game data (maps, graphics, sounds, campaigns) is bundled into the `.app`.

**Alternatives discussed:**

- **Swift uses the existing C++ classes directly:** no extra layer, but Swift becomes tied to
  ASC's internal classes, some of them cannot be imported into Swift (templates, libsigc++
  signals, Boost), and the later conversion has no clear boundary.

**Rationale (user):** the facade keeps the interoperability simple.

## Programming language and runtime

**Decision:**

- **Swift 6.4** in the Swift 6 language mode (strict concurrency checking) for the Swift app.
- **C++** with Apple Clang from **Xcode 27**: the ASC core keeps the standard of the original
  (**C++11**); the facade uses **C++20**.
  - Clarification from TASK-0006: ASC's headers cannot be compiled with C++20 (e.g. they use
    `std::auto_ptr`, removed in C++17). Therefore the facade has a small internal adapter
    (`facade/src/AscCoreAdapter.cpp`), the only part that includes ASC's headers, compiled with
    C++11. The facade's interface and implementation, which the Swift app sees, use C++20;
    facade and adapter exchange only standard types.
- **Minimum macOS version: macOS 27**, **Apple Silicon (arm64) only**. Intel Macs are not
  supported.

Versions at the time of the decision: macOS 27.2.1, Xcode 27.2, Swift 6.4.2, Apple Clang 21.

**Alternatives discussed:**

- **macOS 26 as universal binary (Apple Silicon and Intel):** more users, but two
  architectures and two macOS versions to build and test, and new APIs only with fallbacks.
- **Compile the whole C++ core with C++20:** one standard everywhere, but the original code
  would need changes (e.g. removed `register` and `std::auto_ptr`), which makes upstream merges
  harder and risks changed behavior.

**Rationale:**

- Minimum macOS 27, Apple Silicon only (user): macOS 27 is the minimum; Intel Macs do not need
  to be supported.
- Swift 6.4, C++11 for the core, C++20 for the facade: *proposed by the AI, accepted by the
  user.* The core compiles unchanged and stays easy to merge with upstream (Compatibility); the
  facade uses the modern standard for Swift/C++ interoperability; one platform to build and
  test (Reliability); only current, non-deprecated APIs (Flexibility).

## Server-side framework

**Not applicable.** ASC has no server component: single player, hot-seat and PBEM run on the
player's computer. Whether network games need a server is decided in TASK-0009 (see
*Network games*).

## UI technology

**Decision:**

- The **in-game UI** (map, dialogs, buttons) stays unchanged: ParaGUI draws it on SDL2, which
  renders with Metal on macOS.
- **AppKit** for the app delegate and the menu bar, attached to the window and event loop that
  SDL creates.
- **SwiftUI** for separate windows (e.g. About, Settings), hosted in AppKit windows.

**Alternatives discussed:**

- **AppKit only:** one framework that fits SDL directly, but more verbose and not the direction
  Apple is going.
- **SwiftUI app lifecycle (`@main App`) with the game in a SwiftUI view:** most modern, but
  conflicts with ASC's own blocking main loop on SDL and would need deep changes to the C++
  core.

**Rationale (user):** it fits SDL, feels native, and prepares the future design with a pure
SwiftUI GUI layer.

**Clarifications from TASK-0013:**

- The app sets up `NSApplication` and the menu bar first and then runs ASC's unchanged main
  program through the facade on the main thread (blocking); SDL uses the app's `NSApplication`
  and menu instead of creating its own. The SDL game window replaces the SwiftUI main window of
  TASK-0006 (user decision).
- Quit (Cmd+Q) sends SDL's quit event, so ASC ends the game itself. ASC ignores it while one of
  its modal dialogs is open; then the app asks whether to quit anyway (user decision; the
  alternatives were keeping ASC's behavior or changing ParaGUI's modal dialogs).

**Clarifications from TASK-0027:**

- Full screen is macOS's own full screen, so the menu bar appears at the top edge of the
  screen. SDL 2 hides the menu bar of its `SDL_WINDOW_FULLSCREEN_DESKTOP` windows completely,
  so ParaGUI's `PG_Application::InitScreen` creates a resizable window on macOS and puts it
  into macOS full screen (a marked change in `thirdparty/asc/`, also offered to ASC; user
  decision). The alternatives were a patch of SDL (vcpkg overlay port) and replacing SDL's
  behaviour at runtime from Swift; setting the app's presentation options from Swift was tried
  and has no effect against SDL.
- ASC's map scrolling at the screen edges stays unchanged in full screen, also at the top edge,
  where the menu bar appears (user decision; the alternative was no scrolling at the top edge
  on macOS).

## Data storage

**Decision:**

- **Game data** (graphics, units, standard maps, campaigns): read-only in the app bundle
  (`Contents/Resources`).
- **User data** (save games, PBEM files, own maps, ASC configuration): in ASC's own, unchanged
  file formats in `~/Library/Application Support/asc-for-mac/`. The path is set through the
  facade.
- **Settings of the Swift app:** in `UserDefaults`.

**Alternatives discussed:**

- **Keep `~/.asc` as on Linux:** no change to the core, but hidden folders in the home
  directory are unusual on macOS and save games are hard to find.
- **Save games in `~/Documents/ASC`:** easy to find, but apps writing into Documents are often
  unwelcome and macOS may ask for permission.

**Clarification from TASK-0013:** ASC finds its files through the search paths in its
configuration file `asc2rc`. The facade keeps this file in the user data directory, sets the
search paths to the user data directory (written first) and the bundle's resources before each
start, and starts ASC with `-c <file>`, so the core needs no change.

**Rationale:** *proposed by the AI, accepted by the user.* Save games and maps stay
byte-for-byte compatible with Linux and Windows (Compatibility); the app follows the macOS
conventions for data locations (Interaction capability) with official APIs (Flexibility); the
app bundle is never written to, as code signing requires.

## Integration of the 3rd party systems

**Decision:**

- **Libraries** (SDL2, SDL2_image, SDL2_mixer, Lua 5.1, libsigc++ 2, FreeType, Boost, Expat,
  bzip2, libpng, PhysFS, fmt) are provided by the package manager **vcpkg** at build time, in
  versions pinned by the vcpkg baseline, built as static libraries for arm64 and macOS 27.
  vcpkg is fetched by the build as a git repository. The library sources are not copied into
  the repository.
- The packaged application contains all needed libraries except the macOS system libraries,
  so there are **no dependencies at runtime**.
- The **ASC source code and game data** are copied into the repository (see *Location of the
  3rd party artifacts*), so the build does not rely on external websites for them.
- **SDL version: SDL2** (latest 2.x release) for the first step. The update to SDL3 is planned
  in TASK-0011.

**Alternatives discussed:**

- **Library sources in the repository, built with the app:** fully independent of external
  sources, but a larger repository and longer first build.
- **Prebuilt binaries in the repository** (e.g. `.xcframework`): fast builds, but binaries in
  git are hard to check and update.
- **Homebrew instead of vcpkg:** widely used on the Mac, but builds for the host system
  instead of a chosen minimum version, cannot pin versions, and its dynamic libraries have to
  be bundled, re-linked and signed afterwards.
- **vcpkg asset caching:** would make builds independent of the download sites of the
  libraries; not used.
- **SDL3:** current and actively developed, but the ASC core would need changes at many places.

**Rationale (user):**

- Package manager at build time: no need to copy the library sources into the repository; the
  packaged app contains all libraries, so there are no dependencies at runtime.
- vcpkg: it fits ASC and is actively supported. It is backed by Microsoft, so the user trusts
  that it will stay available; downloading the library sources from external sites at build
  time is accepted.
- ASC code and data copied into the repository: the build must not rely on external websites
  for which it is not clear how they are funded.
- SDL2: no code changes for the first working version; SDL3 follows in TASK-0011.

## Location of the 3rd party artifacts

**Decision:** the ASC source code, its bundled libraries (`source/libs`) and its game data
(`data/`, `extra-data/`) are stored in **`thirdparty/asc/`**, added and updated with
**`git subtree`** from <https://github.com/ValHaris/asc-hq>, so ASC's history is part of the
repository. Changes inside `thirdparty/asc/` are kept to the minimum and marked. The project's
own code (Swift app, facade) lives outside `thirdparty/`. The copy is made in TASK-0008.

**Alternatives discussed:**

- **Plain copy in `thirdparty/asc/`** with a file recording the source commit: simple, but
  upstream updates have to be merged by hand.
- **ASC directly at the repository root:** paths match the original, but ASC and the project's
  own files are mixed.

**Rationale (user):** `git subtree` makes merging upstream updates easier, and the AI can
handle the git operations.

**Clarification from TASK-0023:** ASC's music files are not in ASC's repository. They are
downloaded once from <https://www.asc-hq.org/music/> and committed to
**`thirdparty/asc-music/`**, outside the subtree (user decision; alternatives were a download
script with checksum check, which makes builds depend on the website, and committing them into
`thirdparty/asc/data/music/`, which changes the subtree). Details in `doc/thirdparty.md`.

## SBOM

**Decision (user, TASK-0024):**

- **Format:** SPDX 2.3, JSON. vcpkg already writes an SPDX 2.3 file for each library it
  installs; `scripts/create-sbom.sh` combines them with the components that do not come from
  vcpkg (`scripts/sbom-components.json`).
- **Content:** only what is part of the app: the libraries from vcpkg, ASC, the libraries
  bundled in ASC's source code that are compiled into the app, the game data and the project's
  own code. Build-only tools (Xcode, CMake, vcpkg and its helper ports, the SwiftLint plugin)
  are not listed; they are documented in `doc/developerInfrastructure.md`. Apple's system
  frameworks, which the app uses but does not contain, are not listed either.
- **Storage:** committed to the repository as `doc/sbom.spdx.json`, so changes of components
  show up in the git history and in reviews; `scripts/check.sh` fails if it is out of date.

**Alternatives discussed:**

- **CycloneDX JSON:** focused on security and vulnerability tracking; the vcpkg data would have
  to be converted.
- **Listing build tools as well:** documents the full supply chain, but their licences do not
  apply to the shipped app.
- **Only as build output:** not reviewed and not visible in the history.

## Licences

**Decision (user, TASK-0025):**

- **Licence of the own code:** GPL-2.0-or-later, the same as ASC's source files (`LICENSE` at
  the repository root). The app as a whole is distributed under GPL-2.0-or-later; the licence
  analysis of all components is in `doc/thirdparty.md`.
- **Presentation:** the app menu has the item "Licenses…", which opens a SwiftUI window with
  the components on the left and the selected component's licence information (version,
  licence, copyright notice, source code location, full licence texts) on the right.

**Implementation (TASK-0025):** the licence information is generated from the SBOM by
`scripts/create-licenses.sh` during the build (`Licenses.json` in the app bundle, see
`doc/buildAndTest.md`), so it always matches the SBOM and the installed libraries. It is not
committed: it consists mostly of licence texts that are in vcpkg's files and in `thirdparty/`.

## Deployment and operation

**Decision:**

- **Signing:** the `.app` is signed with the Apple **Developer ID** (TASK-0010), with the
  hardened runtime.
- **Notarization:** with Apple's `notarytool`, and the ticket is stapled to the app.
- **Package:** a **`.dmg`** disk image with the app and a link to the Applications folder.
- **Publishing:** as a **GitHub Release** of the project's repository, with release notes.
  Version numbers follow ASC's version plus a suffix for the Mac port, e.g. `2.6.99.0-mac1`.
- **Updates:** no automatic updates in the first step; users download new versions from
  GitHub Releases.

**Alternatives discussed:**

- **Automatic updates with Sparkle:** users are informed about new versions, but an extra
  library, a server contacted at runtime, and signing keys and a feed to maintain.
- **`.zip` instead of `.dmg`:** simpler to create, but less familiar for Mac users.

**Rationale:** *proposed by the AI, accepted by the user.* Only Apple's official tools
(Flexibility); no server contact at runtime (Security); simple and quick to set up, in line
with "a working Mac version first".

## Build tool, test framework and static quality check

### Build tool

**Decision:** **Xcode is the main build system** for the whole project. The Xcode project
contains the Swift app and an external build target that calls **CMake** (with vcpkg) to build
the ASC core, the facade and the libraries as static libraries for arm64 and macOS 27. The app
target depends on it, so one command builds everything: `xcodebuild` on the command line, or
Cmd+B in Xcode.

**Alternatives discussed:**

- **CMake as the only build system** (Swift app built by CMake, Xcode project generated): one
  build close to ASC, but CMake's Swift support is less polished than Xcode's.
- **CMake as main build calling `xcodebuild`:** Cmd+B in Xcode would not rebuild the C++ part.
- **A build script as main entry:** simple, but without incremental builds, and the same
  problem in Xcode.
- **Swift Package Manager:** cannot properly create a signed `.app` with resources.
- **Bazel:** powerful, but far too heavy for this project.
- Note: XcodeGen or Tuist could generate the Xcode project from a reviewable text file later,
  if the project file becomes a problem.

**Rationale (user):** one main build system for the whole project, with CMake for all C/C++
parts and Xcode for the Swift parts. Further arguments, *proposed by the AI, accepted by the
user:* working in Xcode always builds everything; signing and notarization are standard in
Xcode.

### Test framework

**Decision:**

- **Swift Testing** for the Swift app and the facade (and later for the comparison tests of
  the conversion).
- ASC's existing **`unittester`** for the C++ core, built by CMake and kept unchanged.
- A Swift Testing test starts `unittester` and fails if it reports an error, so
  `xcodebuild test` (Cmd+U in Xcode) runs all tests. No CTest.
- Clarification from TASK-0019: the **UI test** (QA measure S6, decided by the user in
  TASK-0007 as "XCTest UI testing") uses XCTest, because Swift Testing has no UI testing. It
  has its own scheme `ASCforMacUITests` and command `scripts/test-ui.sh`, since it takes over
  mouse and keyboard; `xcodebuild test` with the scheme `ASCforMac` does not run it.

**Alternatives discussed:**

- **CTest as common test runner:** not needed with Xcode as main build.
- **XCTest instead of Swift Testing:** older; Apple's focus is on Swift Testing.
- **Convert ASC's tests to Swift Testing:** one framework, but changes upstream code; belongs
  to the later conversion.

**Rationale:** *proposed by the AI, accepted by the user.* `unittester` is the most valuable
safety net for the game rules and file formats (Compatibility, Reliability); one test command
without a second test runner.

### Static quality check

**Decision:** only the project's own code (Swift app and facade) is checked; the ASC core in
`thirdparty/asc/` is not.

- **Swift code:** `swift format lint` (included in Xcode) and **SwiftLint**, integrated as its
  official Swift package plugin, so Xcode loads it with the build in a pinned version.
- **Facade:** **clang-tidy** (from Homebrew's `llvm` package, installed by every developer) and
  the **Clang Static Analyzer** (included in Xcode).
- **Compiler warnings are treated as errors** for the Swift app and the facade.

**Alternatives discussed:**

- **Only the tools included in Xcode** (`swift format lint`, Clang Static Analyzer, warnings
  as errors): nothing to install, but fewer rules.
- **SwiftLint from Homebrew:** one installation source for both tools, but outside the Apple
  development ecosystem.

**Rationale (user):** the additional tools offer additional checks, and static checks catch
errors at compile time. SwiftLint as a Swift package plugin stays in the Apple development
ecosystem.

## Network games

**Not decided here.** How network games are handled (e.g. whether a server or service is
needed at runtime) was postponed to **TASK-0009**, which records its decision in this document.
