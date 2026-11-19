# TASK-0006: Create core application with build system

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0006 |
| **Short description** | Create core application with build system |
| **Status**        | done <!-- One of: open, in-work, waiting, done, aborted -->   |
| **External link** | none |
| **Dependencies**  | TASK-0005, TASK-0008, TASK-0012 |

## Motivation

All further features need a working foundation: an application skeleton that follows the
defined architecture and can be built, tested and checked automatically. Creating this core
application now, using all the information gathered to define the architecture, ensures that
every following feature is developed on the same structure, with automatic tests and static
quality checks from the start.

The user split the original task: TASK-0012 builds the ASC core and `unittester` with CMake and
vcpkg; this task creates the Xcode main build, the Swift app and the facade on top of it.
Making the game playable follows in TASK-0013.

## Task description

Using all the information gathered to define the architecture, create a core application with
a build system that can be used as the foundation for further features:

- `README.md`: domain, problems and features of the application
- `doc/qualityobjectives.md`: quality objectives
- `doc/context.md`: context and constraints
- `doc/architecture.md`: the software architecture decided on by the user
- `doc/buildAndTest.md`: the CMake build of the ASC core from TASK-0012
- `doc/thirdparty.md`: the ASC subtree and the libraries provided by vcpkg

The core application must use the structure and the technologies decided in
`doc/architecture.md`, in particular:

1. **Language and runtime:** Swift 6.4 in the Swift 6 language mode for the Swift app, C++20
   for the facade; arm64 only, minimum macOS 27.
2. **Build tool:** an Xcode project as the main build. It contains the Swift app and an external
   build target that calls the CMake build from TASK-0012 (`scripts/build-core.sh`, which
   fetches vcpkg and uses the preset `macos` from `CMakePresets.json`). Add the facade to this
   CMake build as a new static library target (e.g. in its own directory next to `core/`,
   linking `asc_core`). The app target depends on the external build target, so `xcodebuild`
   (or Cmd+B in Xcode) builds everything with one command.
3. **Structure:** the Swift app calls only the facade, never ASC's classes directly. The facade
   offers at least one function that uses the ASC core (e.g. returns ASC's version), and the
   app shows its result (e.g. in the About window), which proves the whole chain
   Swift → facade → ASC core.
4. **UI skeleton:** an AppKit app delegate with a menu bar (at least About and Quit with Cmd+Q);
   the About window uses SwiftUI.
5. **Tests:** Swift Testing tests for the facade, and a Swift Testing test that starts
   `unittester` and fails if it reports an error; `xcodebuild test` runs all tests.
   `unittester` is run as `scripts/test-core.sh` does: `build/core/unittester -c asc2rc` in
   the directory `build/core/unittest-run`.
6. **Static quality check** of the project's own code only (not `thirdparty/asc/`):
   `swift format lint` and SwiftLint (as its official Swift package plugin) for the Swift code,
   clang-tidy and the Clang Static Analyzer for the facade, and compiler warnings treated as
   errors for the Swift app and the facade.

The build compiles the ASC core from `thirdparty/asc/` (added in TASK-0008). It must not
download the ASC code or data from external sources; only the libraries provided by vcpkg are
downloaded at build time (see `doc/architecture.md`).

Use stable releases of all tools and libraries. If a decided tool only works in a pre-release
version, stop and let the user decide, and record the decision in `doc/architecture.md`.

Before implementing, check that the required tools are installed (Xcode 27 and CMake are listed
in `doc/developerInfrastructure.md`). Tell the user which tools are missing before starting, so
the user can install them. clang-tidy comes from Homebrew's `llvm` package (LLVM 23.1.6 was
installed when this task was reviewed). Homebrew does not put its programs on the `PATH`, so
that they do not replace Apple's Clang: the static quality check must call clang-tidy by its
path, e.g. `$(brew --prefix llvm)/bin/clang-tidy`, instead of relying on the `PATH`.

Following the project conventions in `AGENTS.md`:

- Tools that are not listed in `doc/developerInfrastructure.md` must be added there before they
  are used. The document distinguishes:
  - **required tools** that every developer installs (Xcode 27 and CMake are already listed;
    add clang-tidy from Homebrew's `llvm` package, with how the check finds it),
  - **tools loaded by the build** (e.g. vcpkg and its libraries, the SwiftLint plugin), which do
    not have to be installed,
  - **optional tools**, if any.
- The commands to build, test, run the static quality check and start the application locally
  are documented in `doc/buildAndTest.md`, which already describes the ASC core build from
  TASK-0012; extend it. If scripts in `scripts/` are created for this, add
  tests for them to `scripts/test.sh`.
- The section "About this project" in `AGENTS.md` names the tech stack and refers to
  `doc/buildAndTest.md` for the commands; the section "Development" in `README.md` refers to
  it as well.
- The build output is excluded in `.gitignore` (`build/` already is, from TASK-0012; add e.g.
  Xcode's `DerivedData` if it is placed in the repository, and Xcode's per-user files such as
  `xcuserdata/`).

Out of scope:
- running the game (SDL window, bundled game data, user data folder): TASK-0013,
- signing with the Developer ID, notarization and the `.dmg`: local builds are signed ad hoc
  ("Sign to Run Locally"),
- actual features of the application; they are added in later tasks.

## Acceptance criteria

- [x] The structure of the core application and the technologies it uses follow
      `doc/architecture.md`, including Swift 6.4 (Swift 6 language mode), C++20 for the facade,
      arm64 only and the minimum macOS version 27.
- [x] All tools and libraries are stable releases, or the user has decided on a pre-release
      and the decision is recorded in `doc/architecture.md`.
- [x] The Xcode project is the main build: `xcodebuild` builds the app and, through the external
      build target, the ASC core and the facade with CMake, from a clean checkout with a single
      documented command.
- [x] The build compiles the ASC core from `thirdparty/asc/` and does not download the ASC code
      or data from external sources (check by inspecting the build configuration).
- [x] The Swift app calls only the facade (check: no Swift file imports ASC headers other than
      the facade), and the app shows a result the facade obtained from the ASC core (e.g. ASC's
      version in the About window).
- [x] The app has a menu bar with About (SwiftUI window) and Quit (Cmd+Q).
- [x] Automatic tests can be run with a single documented command (`xcodebuild test`): at least
      one Swift Testing test of the facade exists and passes, and the test that runs
      `unittester` passes.
- [x] The static quality check (`swift format lint`, SwiftLint, clang-tidy, Clang Static
      Analyzer, warnings as errors) covers only the project's own code, can be run with a single
      documented command and passes without findings.
- [x] The application can be started locally with a single documented command.
- [x] All tools required for building, testing and the static quality check are listed in
      `doc/developerInfrastructure.md`; tools loaded by the build and optional tools are
      marked as such.
- [x] The commands for building, testing, the static quality check and starting the
      application are documented in `doc/buildAndTest.md`.
- [x] The section "About this project" in `AGENTS.md` names the tech stack and refers to
      `doc/buildAndTest.md`; the section "Development" in `README.md` refers to it as well.
- [x] `.gitignore` excludes the build output, and `git status` shows no build output after a
      build.

## History

<!--
  Log of all status changes, oldest first. Add a row for every change of the Status field.
  Timestamp format: ISO 8601 with time zone offset, e.g. 2026-11-11T14:30+0100
  (get it with: date +%Y-%m-%dT%H:%M%z).
  Comment: optional, but required for "waiting" and "aborted" (state the reason).
-->

| Timestamp                | Status | Comment       |
|--------------------------|--------|---------------|
| 2026-11-11T17:24+0100 | open   | Task created  |
| 2026-11-19T15:31+0100 | in-work | Implementation started |
| 2026-11-19T16:16+0100 | done | All acceptance criteria and the Definition of Done are fulfilled |
