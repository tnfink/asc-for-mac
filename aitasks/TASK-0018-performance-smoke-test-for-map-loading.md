# TASK-0018: Performance smoke test for map loading and AI turns

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0018 |
| **Short description** | Performance smoke test for map loading and AI turns |
| **Status**        | open <!-- One of: open, in-work, waiting, done, aborted -->   |
| **External link** | none |
| **Dependencies**  | TASK-0007, TASK-0013 |

## Motivation

Implements the QA measure **S5** from `doc/qameasures.md` (decided in TASK-0007). The user wants
that the user does not have to wait (quality objective *Performance efficiency*, 3) and decided
that a performance smoke test is important for regression testing. Loading maps and AI turns
need the playable game from TASK-0013.

## Task description

1. Measure the time for loading standard maps and for AI turns on standard maps, through facade
   functions; add the ones that are missing, reusing those of TASK-0015 and TASK-0017 where they
   exist (decided when improving TASK-0013: TASK-0013 does not provide them).
2. Agree time limits with the user, based on the measured values (e.g. with a margin, so the
   test is stable), and record them in `doc/qameasures.md`.
3. Add automated tests that fail if a limit is exceeded, run with the automated tests
   (`scripts/test-app.sh`), and document them in `doc/buildAndTest.md`.
4. Update `doc/qameasures.md` (S5: implemented).

## Acceptance criteria

- [ ] The times for loading standard maps and for AI turns are measured, and the time limits
      agreed with the user are recorded in `doc/qameasures.md`.
- [ ] Automated tests fail if a time limit is exceeded; they run with `scripts/test-app.sh` and
      pass.
- [ ] `doc/buildAndTest.md` describes the tests and `doc/qameasures.md` marks S5 as implemented.

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
