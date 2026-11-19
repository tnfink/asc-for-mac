# TASK-0016: Run the tests with AddressSanitizer and UBSan

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0016 |
| **Short description** | Run the tests with AddressSanitizer and UBSan |
| **Status**        | open <!-- One of: open, in-work, waiting, done, aborted -->   |
| **External link** | none |
| **Dependencies**  | TASK-0007 |

## Motivation

Implements the QA measure **S2** from `doc/qameasures.md` (decided in TASK-0007). The C++
core of ASC runs with a new compiler on arm64 for the first time. AddressSanitizer and
UndefinedBehaviorSanitizer find memory errors and undefined behavior at runtime, like the
alignment problem found in TASK-0012, before they cause crashes (quality objective
*Reliability*, 4). The user decided that this measure must be active immediately.

## Task description

1. Make it possible to build the ASC core, the facade and `unittester` with AddressSanitizer
   and UndefinedBehaviorSanitizer (e.g. a separate CMake preset or build directory, so the
   normal build stays unchanged), and run `unittester` with them.
2. Run the Swift tests with the sanitizers enabled (e.g. a test plan or scheme option in the
   Xcode project).
3. Provide a single documented command that runs all tests with the sanitizers (e.g. a script in
   `scripts/`, with tests in `scripts/test.sh`), and document it in `doc/buildAndTest.md`.
4. If the sanitizers report errors in the ASC core, tell the user; fixes inside `thirdparty/asc/`
   follow the rules in `doc/architecture.md` (minimal, marked, listed in `doc/thirdparty.md`)
   and may be split into new tasks with the user's consent.
5. Update `doc/qameasures.md` (S2: implemented).

## Acceptance criteria

- [ ] `unittester` and the Swift tests run with AddressSanitizer and UndefinedBehaviorSanitizer
      with a single documented command.
- [ ] The run reports no sanitizer errors, or every reported error is recorded in a new task
      agreed with the user.
- [ ] The normal build and tests are not slowed down by the sanitizers (they use a separate
      build).
- [ ] `doc/buildAndTest.md` documents the command, `doc/qameasures.md` marks S2 as implemented,
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
