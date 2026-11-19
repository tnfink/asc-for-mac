# TASK-0020: Measure code coverage of the Swift app and facade

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0020 |
| **Short description** | Measure code coverage of the Swift app and facade |
| **Status**        | done <!-- One of: open, in-work, waiting, done, aborted -->   |
| **External link** | none |
| **Dependencies**  | TASK-0007, TASK-0016 |

## Motivation

Implements the QA measure **S7** from `doc/qameasures.md` (decided in TASK-0007). The user
decided: it makes sense to measure the coverage early to detect regressions; there is no benefit
in adding it later. The measure should be active immediately.

## Task description

The Swift app is compiled by Xcode, whose code coverage (`-enableCodeCoverage YES`) covers it.
The facade (`facade/src/`, C++20 facade and C++11 adapter) is compiled by CMake into
`libasc_all.a` and is therefore not instrumented by Xcode; it must be compiled with Clang's
coverage options (`-fprofile-instr-generate -fcoverage-mapping`) so that its coverage appears
in the report. The ASC core (`thirdparty/asc/`) is not instrumented and not reported.

The user decided (when improving this task) to build the coverage run separately, like the
sanitizer run of TASK-0016 (see *Sanitizer run* in `doc/buildAndTest.md`), and to update the
baseline with an option of the command.

1. Add a CMake preset `macos-coverage` (build directory `build/core-coverage`) that compiles
   only the facade targets with coverage instrumentation, and an option `--coverage` for
   `scripts/build-core.sh`. Reuse the Xcode build settings `ASC_CORE_BUILD_DIR` and
   `ASC_CORE_BUILD_ARGS` so that the coverage run links `build/core-coverage/libasc_all.a`.
2. Add the command `scripts/test-coverage.sh`: it builds `build/core-coverage`, runs the Swift
   tests with `xcodebuild test -enableCodeCoverage YES` (output in a separate directory, e.g.
   `build/xcode-coverage`), and prints the line coverage of the project's own code: the Swift
   app (`app/ASCforMac/`, not the test target) and the facade (`facade/`), not `thirdparty/asc/`.
   Use only tools included in Xcode (e.g. `xcrun xccov`, `xcrun llvm-cov`).
3. Make regressions in coverage detectable: record the current coverage as baseline in a file in
   the repository; the command fails if the coverage drops below it. An option of the command
   (e.g. `--update-baseline`) writes the current coverage as new baseline. Agree the remaining
   details (e.g. tolerance, per file or in total) with the user.
4. The normal build and tests (`build/core`, `scripts/build.sh`, `scripts/test-app.sh`) stay
   without coverage instrumentation.
5. Document it in `doc/buildAndTest.md` and update `doc/qameasures.md` (S7: implemented, with the
   baseline). Add tests for the new script and options to `scripts/test.sh`.

## Acceptance criteria

- [x] `scripts/test-coverage.sh` prints the line coverage of the Swift app and the facade; files
      from `thirdparty/asc/` and the test target do not appear in the report.
- [x] The command fails if the coverage drops below the recorded baseline, as agreed with the user
      (check by temporarily raising the baseline above the current coverage; restore it
      afterwards).
- [x] `scripts/test-coverage.sh --update-baseline` (or the agreed option) writes the current
      coverage into the baseline file.
- [x] The normal build and tests are unchanged: `scripts/test-app.sh` still links
      `build/core/libasc_all.a` without coverage instrumentation (check in the build log).
- [x] `doc/buildAndTest.md` documents the command, `doc/qameasures.md` marks S7 as implemented
      with the baseline, and `scripts/test.sh` passes.

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
| 2026-11-19T21:02+0100 | in-work | Implementation started |
| 2026-11-19T21:09+0100 | done | All acceptance criteria and the Definition of Done are fulfilled |
