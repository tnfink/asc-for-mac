# Build and Test

This document describes how to build and test asc-for-mac. The architecture of the build is
decided in `doc/architecture.md` (section *Build tool, test framework and static quality
check*); the required tools are listed in `doc/developerInfrastructure.md`.

So far, the build covers the ASC core (TASK-0012). The Xcode main build, the Swift app and the
facade follow in TASK-0006.

## ASC core

| What | Command |
|------|---------|
| Build the ASC core, `asc_mount`, the data archives and `unittester` | `scripts/build-core.sh` |
| Build again from scratch (keeps vcpkg and its libraries) | `scripts/build-core.sh --clean` |
| Run ASC's `unittester` | `scripts/test-core.sh` |

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
