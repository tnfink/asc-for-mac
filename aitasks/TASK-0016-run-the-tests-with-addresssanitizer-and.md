# TASK-0016: Run the tests with AddressSanitizer and UBSan

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0016 |
| **Short description** | Run the tests with AddressSanitizer and UBSan |
| **Status**        | done <!-- One of: open, in-work, waiting, done, aborted -->   |
| **External link** | none |
| **Dependencies**  | TASK-0007 |

## Motivation

Implements the QA measure **S2** from `doc/qameasures.md` (decided in TASK-0007). The C++
core of ASC runs with a new compiler on arm64 for the first time. AddressSanitizer and
UndefinedBehaviorSanitizer find memory errors and undefined behavior at runtime, like the
alignment problem found in TASK-0012, before they cause crashes (quality objective
*Reliability*, 4). The user decided that this measure must be active immediately.

## Task description

1. Make it possible to build the ASC core, the facade, `unittester` and `libasc_all.a` with
   AddressSanitizer and UndefinedBehaviorSanitizer in a separate build directory (e.g. a CMake
   preset `macos-sanitizers` with the binary directory `build/core-sanitizers`), so the normal
   build (`build/core`, `scripts/build-core.sh`) stays unchanged. Use debug information and low
   optimization (e.g. `-O1 -g`) for readable reports. The libraries from vcpkg are not
   instrumented.
2. Every sanitizer finding must fail the run: UndefinedBehaviorSanitizer only prints its
   findings by default, so compile with `-fno-sanitize-recover=all` (or equivalent).
3. Run `unittester` from the sanitizer build (in its `unittest-run` directory, as
   `scripts/test-core.sh` does).
4. Run the Swift tests with the sanitizers enabled (e.g. a test plan or scheme option in the
   Xcode project). They must link the instrumented `libasc_all.a`, not the one from
   `build/core`: the Xcode project currently links `$(PROJECT_DIR)/build/core/libasc_all.a`
   with a fixed path, so make the CMake build directory selectable (e.g. a build setting used in
   the link path and by the external build target). In Swift code, only AddressSanitizer applies;
   UndefinedBehaviorSanitizer covers the C/C++ code (ASC core and facade).
5. Provide a single documented command that runs all tests with the sanitizers (e.g. a script in
   `scripts/`, with tests in `scripts/test.sh`), and document it in `doc/buildAndTest.md`.
6. If the sanitizers report errors in the ASC core, tell the user; fixes inside `thirdparty/asc/`
   follow the rules in `doc/architecture.md` (minimal, marked, listed in `doc/thirdparty.md`)
   and may be split into new tasks with the user's consent.
7. Update `doc/qameasures.md` (S2: implemented).

## Acceptance criteria

- [x] `unittester` and the Swift tests run with AddressSanitizer and UndefinedBehaviorSanitizer
      with a single documented command.
- [x] Any sanitizer finding makes the run fail (check with a deliberately inserted error, e.g. an
      out-of-bounds access in a temporary test, which must be reported and fail the run; remove
      it afterwards).
- [x] The Swift tests in the sanitizer run link the instrumented `libasc_all.a` from the
      sanitizer build directory (check in the build log).
- [x] The run reports no sanitizer errors, or every reported error is recorded in a new task
      agreed with the user.
- [x] The normal build and tests are unchanged: `scripts/build.sh` and `scripts/test-app.sh` still
      use `build/core` without sanitizers (check in the build log).
- [x] `doc/buildAndTest.md` documents the command, `doc/qameasures.md` marks S2 as implemented,
      and `scripts/test.sh` passes if scripts were added.

## History

<!--
  Log of all status changes, oldest first. Add a row for every change of the Status field.
  Timestamp format: ISO 8601 with time zone offset, e.g. 2026-11-11T14:30+0100
  (get it with: date +%Y-%m-%dT%H:%M%z).
  Comment: optional, but required for "waiting" and "aborted" (state the reason).
-->

| Timestamp                | Status | Comment       |
|--------------------------|--------|---------------|
| 2026-11-19T17:12+0100 | open   | Task created  |
| 2026-11-19T17:28+0100 | in-work | Implementation started |
| 2026-11-19T20:53+0100 | done | All acceptance criteria and the Definition of Done are fulfilled |
