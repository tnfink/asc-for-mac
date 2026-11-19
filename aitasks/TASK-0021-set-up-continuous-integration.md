# TASK-0021: Set up continuous integration

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0021 |
| **Short description** | Set up continuous integration |
| **Status**        | open <!-- One of: open, in-work, waiting, done, aborted -->   |
| **External link** | none |
| **Dependencies**  | TASK-0007 |

## Motivation

Decided in TASK-0007 (see `doc/qameasures.md`, measure *CI*): build, automated tests and static
checks should run automatically for every push, so that all QA measures actually run. The user
decided that this is done by a continuous integration (CI) instead of a local git hook (S4).

## Task description

1. The repository needs a remote on a platform with CI (e.g. GitHub, see `doc/context.md`). If
   there is none yet, set the status to `waiting` with the reason and ask the user.
2. Choose the CI service together with the user (e.g. GitHub Actions). The CI must provide macOS
   27 on Apple Silicon and Xcode 27 (see `doc/architecture.md`); check this before starting and
   tell the user if it is not available.
3. Set up a CI workflow that runs for every push: `scripts/build.sh`, `scripts/test-app.sh`,
   `scripts/check.sh` and `scripts/test.sh`, and the measures that are active by then (e.g.
   sanitizers, coverage).
4. Cache vcpkg's binary cache between runs, so the libraries are not rebuilt every time.
5. Document the CI in `doc/buildAndTest.md` and update `doc/qameasures.md` (CI: implemented).

## Acceptance criteria

- [ ] The CI service has been chosen with the user, and it provides macOS 27 on Apple Silicon
      and Xcode 27.
- [ ] A CI workflow runs build, automated tests, static checks and the script tests for every
      push, and a run on the current state succeeds.
- [ ] vcpkg's binary cache is reused between CI runs.
- [ ] `doc/buildAndTest.md` describes the CI and `doc/qameasures.md` marks it as implemented.

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
