# Build and Test

This document describes how to build and test asc-for-mac. The architecture of the build is
decided in `doc/architecture.md` (section *Build tool, test framework and static quality
check*); the required tools are listed in `doc/developerInfrastructure.md`.

The **Xcode project `ASCforMac.xcodeproj` is the main build**. Its external build target
`AscCore` runs the CMake build (`scripts/build-core.sh`), which builds the ASC core, the facade
and the libraries from vcpkg; then Xcode builds the Swift app.

## Commands

| What | Command |
|------|---------|
| Build everything (Debug) | `scripts/build.sh` (`--release` for Release) |
| Run all automated tests | `scripts/test-app.sh` |
| Run the UI test (takes over mouse and keyboard) | `scripts/test-ui.sh` |
| Run all automated tests with AddressSanitizer and UndefinedBehaviorSanitizer | `scripts/test-sanitizers.sh` |
| Measure the code coverage and check it against the baseline | `scripts/test-coverage.sh` (`--update-baseline` writes a new baseline) |
| Run the static quality check | `scripts/check.sh` |
| Start the app (the game) | `scripts/run.sh` (`--build` builds it first) |
| Start the app without the game | `build/xcode/Build/Products/Debug/ASCforMac.app/Contents/MacOS/ASCforMac --no-game` |
| Run the tests of the scripts in `scripts/` | `scripts/test.sh` |

In Xcode, open `ASCforMac.xcodeproj` and use the scheme `ASCforMac`: Cmd+B builds, Cmd+U
tests, Cmd+R runs. Xcode asks once to trust the SwiftLint plugin ("Trust & Enable"); the
scripts pass `-skipPackagePluginValidation` instead.

## The app (Xcode)

- **Project:** `ASCforMac.xcodeproj`, shared schemes `ASCforMac` and `ASCforMacUITests` (only the
  UI test, see below); build output of the scripts in
  `build/xcode` (Xcode's DerivedData for this project).
- **Targets:**
  - `AscCore`: external build target, runs `scripts/build-core.sh`.
  - `ASCforMac`: the Swift app (`app/ASCforMac/`), Swift 6.4 in the Swift 6 language mode,
    arm64, macOS 27. It depends on `AscCore`, imports the facade as Clang module `AscFacade`
    (`facade/include/module.modulemap`, Swift/C++ interoperability) and links
    `$(ASC_CORE_BUILD_DIR)/libasc_all.a`. The build setting `ASC_CORE_BUILD_DIR` is
    `build/core`; `ASC_CORE_BUILD_ARGS` (empty) is passed to `scripts/build-core.sh`. The
    sanitizer run and the coverage run override both (see *Sanitizer run* and *Code coverage*).
    The build phase "Copy ASC game data" copies `main.ascdat`, `asc2_dlg.zip` and `pbp.ascdat`
    from `$(ASC_CORE_BUILD_DIR)/game-data/` into `Contents/Resources`. Local builds are signed
    ad hoc ("Sign to Run Locally").
  - `ASCforMacTests`: Swift Testing tests (`app/ASCforMacTests/`), hosted in the app.
- **Result:** `build/xcode/Build/Products/Debug/ASCforMac.app` (Release: `.../Release/`).

## Running the game

`scripts/run.sh` opens the app, which starts the game (TASK-0013):

- The app sets up its AppKit menu bar and then calls the facade function `runGame`, which runs
  ASC's unchanged main program (`asc_game_main`, see *ASC core*) on the main thread. ASC creates
  the game window with SDL2 (in full screen by default; `ForceWindowedMode = true` in `asc2rc`
  starts it in a window) and shows its startup map (`asc001.map`) with ASC's own menu bar; a new
  game is started through ASC's menu **Game**. SDL uses the app's `NSApplication` and
  menu bar, so About and Quit work while the game runs. When the game ends, the app quits.
- **Data:** the game data is read from the app bundle (`Contents/Resources`). User data is in
  `~/Library/Application Support/asc-for-mac/`: ASC's configuration file `asc2rc`, save games,
  maps and `log.txt`. Before each start, the facade writes the two search paths into `asc2rc`
  (first the user data directory, then the bundle's resources, because the bundle may move) and
  starts ASC as `asc -c <that file>`; ASC's other settings in the file are kept. `~/.asc/` is not
  used.
- **Quit (Cmd+Q):** sends SDL's quit event, so ASC ends the game through its own quit handling.
  ASC ignores the event while one of its dialogs is open (e.g. the tip shown at the start); then
  the app asks after one second whether to quit anyway (user decision in TASK-0013). The game
  is started and the question is scheduled with run loop timers (`perform(_:with:afterDelay:)`),
  not with the main dispatch queue: while the game runs, it blocks the main queue.
- **Tests:** the test target is hosted in the app; while it hosts the tests (environment variable
  `XCTestConfigurationFilePath`), the app does not start the game.
- **Without the game:** started with the launch argument `--no-game`, the app does not start the
  game; only the menu bar and the app's own windows (About) are available, and Cmd+Q ends the
  app immediately. The UI test uses it (TASK-0019).
- **Music:** ASC's music files (`data/music/Makefile.am`) are not part of the ASC repository, so
  the app has no music.

## Facade

The facade (`facade/`) is built by the CMake build as static library: `asc_facade` (C++20,
warnings as errors; `facade/include/AscFacade.h` is the only header the Swift app sees) and
`asc_facade_adapter` (C++11; the only file that includes ASC's headers, which cannot be
compiled with C++20). The CMake target `asc_all` combines the facade, the ASC core and the
needed libraries from vcpkg into `build/core/libasc_all.a`, which the Xcode project links.

## Tests

`scripts/test-app.sh` runs `xcodebuild test`:

- `FacadeTests`: tests of the facade, e.g. that the ASC version comes from the ASC core.
- `AppTests`: tests of the app's parts that run without the game window (versions, user data
  directory, no game start while hosting tests or with `--no-game`). Starting, playing and
  quitting the game are checked manually.
- `UnittesterTests`: runs ASC's `unittester` like `scripts/test-core.sh` (see below) and fails
  if it reports an error. It runs the `unittester` in `build/core`, or in the directory given by
  the environment variable `ASC_CORE_BUILD_DIR`.

## UI test

`scripts/test-ui.sh` runs the UI test target `ASCforMacUITests` (`app/ASCforMacUITests/`,
XCTest UI testing) with its own scheme `ASCforMacUITests` (QA measure S6). It starts the app
with `--no-game` and checks that the app menu has About and Quit, that About opens a window
showing the ASC core version, and that Cmd+Q ends the app. Quitting while the game runs (the
question "Quit anyway?") is checked manually.

- The UI test takes over mouse and keyboard while it runs (about half a minute); do not use the
  computer meanwhile. Therefore it is not part of `scripts/test-app.sh`,
  `scripts/test-sanitizers.sh` or `scripts/test-coverage.sh`, which use the scheme `ASCforMac`.
- macOS asks once for the permission for UI automation, see
  `doc/developerInfrastructure.md`.
- In Xcode, select the scheme `ASCforMacUITests` and press Cmd+U.

## Sanitizer run

`scripts/test-sanitizers.sh` runs all automated tests with AddressSanitizer (memory errors)
and UndefinedBehaviorSanitizer (undefined behavior), QA measure S2 (`doc/qameasures.md`):

1. `scripts/build-core.sh --sanitizers` builds the ASC core, the facade and `unittester` with
   the CMake preset `macos-sanitizers` into `build/core-sanitizers` (CMake option
   `ASC_SANITIZERS`: `-fsanitize=address,undefined -fno-sanitize-recover=all
   -fno-omit-frame-pointer -O1 -g`). The libraries from vcpkg are not instrumented.
2. `scripts/test-core.sh --sanitizers` runs this `unittester`.
3. `xcodebuild test` with `-enableAddressSanitizer YES -enableUndefinedBehaviorSanitizer YES`
   and `ASC_CORE_BUILD_DIR=build/core-sanitizers`, `ASC_CORE_BUILD_ARGS=--sanitizers` (output
   in `build/xcode-sanitizers`); the unittester test gets the directory via
   `TEST_RUNNER_ASC_CORE_BUILD_DIR`. In Swift code, only AddressSanitizer applies.

Every finding aborts the program with a report (`ERROR: AddressSanitizer: ...` or
`runtime error: ...`, with the source location) and makes the script fail. The normal build
(`build/core`, `build/xcode`) is not touched.

**Diagnosis:** to list all UndefinedBehaviorSanitizer findings of one run instead of stopping
at the first one, configure a separate build directory with the CMake option
`ASC_SANITIZER_RECOVER`:

```bash
VCPKG_ROOT=build/vcpkg cmake --preset macos-sanitizers -B build/core-san-recover -DASC_SANITIZER_RECOVER=ON
cmake --build build/core-san-recover --parallel
cd build/core-san-recover/unittest-run && ../unittester -c asc2rc 2>&1 | grep "runtime error"
```

## Code coverage

`scripts/test-coverage.sh` measures the line coverage of the project's own code, QA measure S7
(`doc/qameasures.md`):

1. `scripts/build-core.sh --coverage` builds with the CMake preset `macos-coverage` into
   `build/core-coverage`; the CMake option `ASC_COVERAGE` compiles the facade
   (`asc_facade`, `asc_facade_adapter`) with `-fprofile-instr-generate -fcoverage-mapping`. The
   ASC core is not instrumented.
2. `xcodebuild test -enableCodeCoverage YES` with `ASC_CORE_BUILD_DIR=build/core-coverage`,
   `ASC_CORE_BUILD_ARGS=--coverage` (output in `build/xcode-coverage`). Xcode instruments the
   Swift app and links the profile runtime.
3. `xcrun llvm-cov export` reads Xcode's coverage data (`build/xcode-coverage/Build/ProfileData`)
   and the app binary. Xcode's own report (`xcrun xccov`) does not show the facade, because
   Xcode did not compile it. The script prints the line coverage per file and in total for
   `app/ASCforMac/` and `facade/`; `thirdparty/asc/` (including ASC headers inlined into the
   adapter) and the test target are not counted.
4. The values are compared with the baseline in `scripts/coverage-baseline.txt` (covered lines,
   total lines, file; last line `TOTAL`). The script fails if the total or any file's coverage
   is lower than in the baseline (no tolerance; the measurement is deterministic), or if files
   were added or removed since the baseline was written.

When the coverage rises, or a drop or a new file is intended, write a new baseline with
`scripts/test-coverage.sh --update-baseline` and commit `scripts/coverage-baseline.txt`. The
normal build (`build/core`, `build/xcode`) is not instrumented.

## Static quality check

`scripts/check.sh` checks only the project's own code (`app/`, `facade/`), not
`thirdparty/asc/`, and fails on any finding:

1. `swift format lint --strict` (included in Xcode), configured in `.swift-format`,
2. clang-tidy for the facade, configured in `facade/.clang-tidy`; the script finds it via
   `brew --prefix llvm`, or via the environment variable `CLANG_TIDY`,
3. the Clang Static Analyzer (`clang++ --analyze`, included in Xcode) for the facade,
4. the Xcode build, in which SwiftLint runs as package plugin (configured in `.swiftlint.yml`,
   `strict: true`) and compiler warnings are errors for the Swift app and the facade.

## ASC core

| What | Command |
|------|---------|
| Build the ASC core, `asc_mount`, the data archives and `unittester` | `scripts/build-core.sh` |
| Build again from scratch (keeps vcpkg and its libraries) | `scripts/build-core.sh --clean` |
| Run ASC's `unittester` | `scripts/test-core.sh` |
| Build and run with sanitizers (in `build/core-sanitizers`) | `scripts/build-core.sh --sanitizers`, `scripts/test-core.sh --sanitizers` |
| Build with code coverage of the facade (in `build/core-coverage`) | `scripts/build-core.sh --coverage` |

The first build fetches vcpkg and builds all libraries, which takes a while; later builds use
vcpkg's binary cache and only rebuild what changed.

### What the build does

1. `scripts/build-core.sh` fetches vcpkg into `build/vcpkg` at the commit pinned as
   `builtin-baseline` in `vcpkg.json` and bootstraps it.
2. CMake is configured with the preset `macos` (`CMakePresets.json`): vcpkg builds the
   libraries from `vcpkg.json` as static libraries with the triplet `arm64-osx-asc`
   (`cmake/triplets/`: arm64, macOS 27).
3. CMake builds, from `thirdparty/asc/` (`core/CMakeLists.txt`, source lists in
   `core/asc-sources.cmake`):
   - `build/core/core/libasc_core.a`: the ASC core as a static library (C++11, all of ASC's game
     code except its `main` program, including the bundled libraries such as ParaGUI),
   - `build/core/asc_mount`: ASC's tool that packs data files into an archive,
   - `build/core/unittest-run/unittest-data/main.ascdat` (created with `asc_mount` from
     `thirdparty/asc/data/`, file list `data/files.txt`) and `asc2_dlg.zip` (the dialog theme
     from `data/dialog/`),
   - `build/core/unittester`: ASC's test program,
   - `build/core/core/libasc_game.a`: ASC's main program `source/sg.cpp` and its start dialogs
     `source/gamedialog.cpp`, unchanged; a compile definition renames `main()` in `sg.cpp` to
     `asc_game_main()`, which the facade calls,
   - `build/core/game-data/`: the game data for the app bundle, as ASC's autotools build
     installs it: `main.ascdat` and `asc2_dlg.zip` (copied from `unittest-data`) and
     `pbp.ascdat` (created with `asc_mount` from `thirdparty/asc/extra-data/`, file list
     `files_pbp.txt`). `unittest-data` does not contain `pbp.ascdat`, so `unittester` sees only
     the data it was written for.

   The ASC core is compiled with `-fwrapv`: signed integer overflow wraps around, as ASC's
   code expects (e.g. in `source/ai/service.cpp`), so that the optimizer cannot change the
   AI's behavior compared to ASC on other systems (decided in TASK-0016).

The ASC code and data are never downloaded; only vcpkg and its libraries are. All build output
is in `build/`, which is excluded in `.gitignore`.

### unittester

`scripts/test-core.sh` runs `unittester` in `build/core/unittest-run` with the configuration
file `asc2rc` (ASC's `unittester/asc2rc`, with the path to the test maps in
`thirdparty/asc/data/unittests/`). It prints `unittests completed successfully` and exits with
0 if all tests pass. The `libpng warning: bKGD: invalid color` lines come from images in ASC's
data and do not mean a failure.

### Checking the results

```bash
lipo -archs build/core/core/libasc_core.a   # arm64
lipo -archs build/core/unittester            # arm64
vtool -show-build build/core/unittester      # platform MACOS, minos 27.0
```

## Script tests

The scripts in `scripts/` are tested with `scripts/test.sh` (see `AGENTS.md`).
