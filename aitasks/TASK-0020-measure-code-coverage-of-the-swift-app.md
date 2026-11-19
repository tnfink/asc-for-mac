# TASK-0020: Measure code coverage of the Swift app and facade

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0020 |
| **Short description** | Measure code coverage of the Swift app and facade |
| **Status**        | open <!-- One of: open, in-work, waiting, done, aborted -->   |
| **External link** | none |
| **Dependencies**  | TASK-0007 |

## Motivation

Implements the QA measure **S7** from `doc/qameasures.md` (decided in TASK-0007). The user
decided: it makes sense to measure the coverage early to detect regressions; there is no benefit
in adding it later. The measure should be active immediately.

## Task description

1. Enable code coverage for the Swift app and the facade in the automated tests (Xcode's code
   coverage, e.g. in the scheme or a test plan).
2. Provide a single documented command that runs the tests and prints the coverage of the
   project's own code (Swift app and facade, not `thirdparty/asc/`), e.g. with `xcrun xccov`.
3. Make regressions in coverage detectable: record the current coverage as baseline (e.g. in a
   file in the repository) and let the command fail if the coverage drops below it; agree the
   details (e.g. tolerance, per file or in total) with the user.
4. Document it in `doc/buildAndTest.md` and update `doc/qameasures.md` (S7: implemented, with the
   baseline). If scripts are added, add tests for them to `scripts/test.sh`.

## Acceptance criteria

- [ ] The automated tests measure the code coverage of the Swift app and the facade (not
      `thirdparty/asc/`).
- [ ] A single documented command prints the coverage and fails if it drops below the recorded
      baseline, as agreed with the user.
- [ ] `doc/buildAndTest.md` documents the command, `doc/qameasures.md` marks S7 as implemented
      with the baseline, and `scripts/test.sh` passes if scripts were added.

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
