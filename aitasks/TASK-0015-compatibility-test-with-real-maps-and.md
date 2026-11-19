# TASK-0015: Compatibility test with real maps and save games

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0015 |
| **Short description** | Compatibility test with real maps and save games |
| **Status**        | open <!-- One of: open, in-work, waiting, done, aborted -->   |
| **External link** | none |
| **Dependencies**  | TASK-0007, TASK-0013 |

## Motivation

Implements the QA measure **S1** from `doc/qameasures.md` (decided in TASK-0007).
Compatibility is the highest-rated quality objective (4, together with Reliability): maps and
save games from ASC on other systems must work in asc-for-mac (`doc/qualityobjectives.md`). Only
real files created on those systems show whether they do. The test needs the facade functions
for loading and saving maps and save games from TASK-0013.

## Task description

1. Collect a set of test files created with ASC on Linux (and on Windows, if available): at
   least one map and one save game per system, including a PBEM file if available. Ask the user
   for the files or how to create them; record the origin of each file (system, ASC version) in
   a README next to them. Store them in the repository (e.g. under `app/ASCforMacTests/` or a
   test data directory), not in `thirdparty/asc/`.
2. Add automated tests (Swift Testing, run by `scripts/test-app.sh`) that load each map and save
   game through the facade without errors.
3. For save games, additionally save the loaded game again and compare it with the original, and
   document what has to be identical (e.g. byte-for-byte or after loading again).
4. Update `doc/qameasures.md` (S1: implemented) and `doc/buildAndTest.md`.

Out of scope: fixing compatibility problems the test finds; propose new tasks for them.

## Acceptance criteria

- [ ] The test files from Linux (and Windows, if available) are in the repository, with their
      origin recorded next to them.
- [ ] Automated tests load every test map and save game through the facade;
      `scripts/test-app.sh` runs them and they pass, or each failure is recorded in a new task.
- [ ] Save games are saved again and compared with the original as documented.
- [ ] `doc/qameasures.md` marks S1 as implemented and `doc/buildAndTest.md` describes the test.

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
