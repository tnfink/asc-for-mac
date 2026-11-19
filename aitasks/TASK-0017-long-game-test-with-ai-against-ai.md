# TASK-0017: Long-game test with AI against AI

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0017 |
| **Short description** | Long-game test with AI against AI |
| **Status**        | open <!-- One of: open, in-work, waiting, done, aborted -->   |
| **External link** | none |
| **Dependencies**  | TASK-0007, TASK-0013 |

## Motivation

Implements the QA measure **S3** from `doc/qameasures.md` (decided in TASK-0007). The user named
a crash after a long game as a bad user experience (quality objective *Reliability*, 4). Only a
long automated game tests this, including saving and loading in between (also *Compatibility*,
4). The test needs the playable game from TASK-0013.

## Task description

1. Add the facade functions the test needs (e.g. start an AI-only game without a window, run
   turns, save and load), reusing those of TASK-0015 where they exist (decided when improving
   TASK-0013: TASK-0013 does not provide them).
2. Create an automated game with AI players only on standard maps of ASC, running without a
   window, over many turns (the number of turns agreed with the user, e.g. 100).
3. Save and load the game at intervals during the run; the game must continue after loading.
4. The test fails if the game crashes, an error is reported, or saving or loading fails.
5. Provide a single documented command for the test (`doc/buildAndTest.md`).
6. Measure the duration. The user decided: the test runs at least for every release, and at the
   end of each task if it is fast. Tell the user the duration and let the user decide whether
   it is fast enough; if so, add running it to `doc/aiTaskDefinitionOfDone.md`.
7. Update `doc/qameasures.md` (S3: implemented, with the decided frequency).

## Acceptance criteria

- [ ] An automated AI-only game runs over the agreed number of turns on standard maps without a
      window, with a single documented command.
- [ ] The game is saved and loaded at intervals during the run, and the test fails on a crash,
      an error or a failed save or load.
- [ ] The test passes, or each failure is recorded in a new task.
- [ ] The duration is measured and the user's decision about running it at the end of each task
      is recorded in `doc/qameasures.md` (and in `doc/aiTaskDefinitionOfDone.md`, if decided).

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
