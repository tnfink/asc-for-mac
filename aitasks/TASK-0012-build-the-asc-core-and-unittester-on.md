# TASK-0012: Build the ASC core and unittester on macOS with CMake and vcpkg

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0012 |
| **Short description** | Build the ASC core and unittester on macOS with CMake and vcpkg |
| **Status**        | open <!-- One of: open, in-work, waiting, done, aborted -->   |
| **External link** | none |
| **Dependencies**  | TASK-0008 |

## Motivation

The original ASC has no current macOS build (see `doc/architecture.md`, *Analysis of the
original ASC*). Before the Xcode project, the Swift app and the facade can be created in
TASK-0006, the ASC core must compile and link on macOS 27 with the decided tools. This is the
riskiest part of the port: about 265,000 lines of C++ are built with a new compiler and new
library versions for the first time. Doing it in its own task keeps it reviewable, and ASC's
`unittester` proves that the game rules and file formats still work (quality objectives
*Compatibility* and *Reliability*).

TASK-0006 was split by the user: this task builds the ASC core, TASK-0006 creates the Xcode
main build, the Swift app and the facade on top of it.

## Task description

Build the ASC core and ASC's `unittester` from `thirdparty/asc/` on macOS with CMake and vcpkg,
as decided in `doc/architecture.md`:

1. **vcpkg:** fetched by the build as a git repository (not committed to this repository), with
   the library versions pinned by a vcpkg baseline. Use the libraries listed in
   `doc/thirdparty.md`, built as static libraries for arm64 and macOS 27 (e.g. with a custom
   vcpkg triplet setting the deployment target to 27.0).
2. **CMake:** build the ASC core as a static library and `unittester` as an executable, for
   arm64 and macOS 27, with Apple Clang from Xcode 27 and the C++ standard of the original
   (C++11). Prefer project-own CMake files outside `thirdparty/asc/` that use ASC's sources.
   Changes inside `thirdparty/asc/` are kept to the minimum and marked (see
   `doc/architecture.md`); list each of them in `doc/thirdparty.md`.
   - ASC's `CMakeLists.txt` has **no `unittester` target**; it exists only in the autotools
     build (`source/unix/asc/Makefile.am`: common sources plus `source/unittests/`). Define it
     in the project-own CMake files, based on these Makefiles.
   - ASC's non-Windows CMake path finds the libraries with `pkg-config` (e.g. `lua5.1`); with
     vcpkg, use vcpkg's CMake packages instead (as ASC's Windows path does).
   - **Lua:** use the Lua version vcpkg provides, as ASC's Windows build does (ASC's Linux build
     uses Lua 5.1; the SWIG wrappers in `source/lua/` support both). Record the Lua version in
     `doc/thirdparty.md`.
3. The build compiles the ASC code from `thirdparty/asc/` and does not download it; only vcpkg
   and its libraries are downloaded at build time.
4. Run `unittester`. It needs the data archives the autotools build creates (see the script
   `thirdparty/asc/unittester/unittester`): `main.ascdat`, created from `data/` with ASC's tool
   `asc_mount` (`source/tools/linux/`, file list `data/files.txt`), and `asc2_dlg.zip`,
   created from `data/dialog/`. Build `asc_mount` and both archives with CMake (e.g. the zip
   with `cmake -E tar cf <file> --format=zip`, so no extra tool is needed). If tests fail
   for reasons that are not specific to macOS (e.g. they also fail upstream), tell the user and
   let the user decide how to handle them; record the decision in this task.
5. Tools: add the tools needed (e.g. CMake, Xcode 27) to `doc/developerInfrastructure.md`
   before using them, marking tools loaded by the build (e.g. vcpkg) as such.
6. Document the commands to build the ASC core and to run `unittester` in
   `doc/buildAndTest.md`. If a script in `scripts/` is created for this, add tests for it to
   `scripts/test.sh`.
7. Exclude the build output and vcpkg's downloads and build trees in `.gitignore`.

Out of scope: the Xcode project, the Swift app and the facade (TASK-0006); running the game
(TASK-0013).

## Acceptance criteria

- [ ] The ASC core is built as a static library and `unittester` as an executable for arm64 and
      macOS 27 from a clean checkout with a single documented command (check: `lipo -archs`
      shows only `arm64` for the library and `unittester`, and `vtool -show-build` on
      `unittester` shows `minos 27.0`).
- [ ] The libraries come from vcpkg with versions pinned by a baseline; vcpkg itself is not
      committed (check: `git ls-files` lists no vcpkg sources or build trees).
- [ ] The build does not download the ASC code or data (check by inspecting the build
      configuration).
- [ ] The data archives `main.ascdat` and `asc2_dlg.zip` needed by `unittester` are created by
      the build from `thirdparty/asc/data/`.
- [ ] `unittester` runs with a single documented command and passes, or the user has decided
      how to handle failing tests and the decision is recorded in this task.
- [ ] Every change inside `thirdparty/asc/` is marked in the code and listed in
      `doc/thirdparty.md` (check with `git diff --stat ce591bce9 -- thirdparty/asc`).
- [ ] `doc/developerInfrastructure.md` lists the tools needed for this build; tools loaded by
      the build are marked as such.
- [ ] `doc/buildAndTest.md` documents the commands to build the ASC core and run `unittester`.
- [ ] `.gitignore` excludes the build output and vcpkg's files, and `git status` shows no build
      output after a build.
- [ ] `scripts/test.sh` passes, if scripts were added or changed.

## History

<!--
  Log of all status changes, oldest first. Add a row for every change of the Status field.
  Timestamp format: ISO 8601 with time zone offset, e.g. 2026-11-11T14:30+0100
  (get it with: date +%Y-%m-%dT%H:%M%z).
  Comment: optional, but required for "waiting" and "aborted" (state the reason).
-->

| Timestamp                | Status | Comment       |
|--------------------------|--------|---------------|
| 2026-11-19T13:58+0100 | open   | Task created  |
