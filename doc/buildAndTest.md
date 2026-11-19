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
| Run all automated tests with AddressSanitizer and UndefinedBehaviorSanitizer | `scripts/test-sanitizers.sh` |
| Run the static quality check | `scripts/check.sh` |
| Start the app | `scripts/run.sh` (`--build` builds it first) |
| Run the tests of the scripts in `scripts/` | `scripts/test.sh` |

In Xcode, open `ASCforMac.xcodeproj` and use the scheme `ASCforMac`: Cmd+B builds, Cmd+U
tests, Cmd+R runs. Xcode asks once to trust the SwiftLint plugin ("Trust & Enable"); the
scripts pass `-skipPackagePluginValidation` instead.

## The app (Xcode)

- **Project:** `ASCforMac.xcodeproj`, shared scheme `ASCforMac`; build output of the scripts in
  `build/xcode` (Xcode's DerivedData for this project).
- **Targets:**
  - `AscCore`: external build target, runs `scripts/build-core.sh`.
  - `ASCforMac`: the Swift app (`app/ASCforMac/`), Swift 6.4 in the Swift 6 language mode,
    arm64, macOS 27. It depends on `AscCore`, imports the facade as Clang module `AscFacade`
    (`facade/include/module.modulemap`, Swift/C++ interoperability) and links
    `$(ASC_CORE_BUILD_DIR)/libasc_all.a`. The build setting `ASC_CORE_BUILD_DIR` is
    `build/core`; `ASC_CORE_BUILD_ARGS` (empty) is passed to `scripts/build-core.sh`. The
    sanitizer run overrides both (see *Sanitizer run*). Local builds are signed ad hoc ("Sign to Run Locally").
  - `ASCforMacTests`: Swift Testing tests (`app/ASCforMacTests/`), hosted in the app.
- **Result:** `build/xcode/Build/Products/Debug/ASCforMac.app` (Release: `.../Release/`).

## Facade

The facade (`facade/`) is built by the CMake build as static library: `asc_facade` (C++20,
warnings as errors; `facade/include/AscFacade.h` is the only header the Swift app sees) and
`asc_facade_adapter` (C++11; the only file that includes ASC's headers, which cannot be
compiled with C++20). The CMake target `asc_all` combines the facade, the ASC core and the
needed libraries from vcpkg into `build/core/libasc_all.a`, which the Xcode project links.

## Tests

`scripts/test-app.sh` runs `xcodebuild test`:

- `FacadeTests`: tests of the facade, e.g. that the ASC version comes from the ASC core.
- `UnittesterTests`: runs ASC's `unittester` like `scripts/test-core.sh` (see below) and fails
  if it reports an error. It runs the `unittester` in `build/core`, or in the directory given by
  the environment variable `ASC_CORE_BUILD_DIR`.

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
   - `build/core/unittester`: ASC's test program.

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
