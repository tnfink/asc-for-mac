# TASK-0017: Long-game test with AI against AI

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0017 |
| **Short description** | Long-game test with AI against AI |
| **Status**        | done <!-- One of: open, in-work, waiting, done, aborted -->   |
| **External link** | none |
| **Dependencies**  | TASK-0007, TASK-0013, TASK-0018 |

## Motivation

Implements the QA measure **S3** from `doc/qameasures.md` (decided in TASK-0007). The user named
a crash after a long game as a bad user experience (quality objective *Reliability*, 4). Only a
long automated game tests this, including saving and loading in between (also *Compatibility*,
4). The test needs the playable game from TASK-0013.

## Task description

Known facts:

- TASK-0018 added facade functions for running ASC without a window
  (`facade/include/AscFacade.h`): `prepareCoreWithoutWindow`, `loadMap` (loads a map as a new
  game; ASC's errors are returned as text instead of message boxes) and `runAITurn` (runs ASC's
  AI for the current player, as for computer players in the game, with the game's time limit of
  10 s per tactics search). The performance smoke test (`app/ASCforMacTests/PerformanceTests.swift`)
  uses them. There are no facade functions for saving and loading a game yet; TASK-0015 (open)
  plans them for maps and save games.
- Measured in TASK-0018 (Debug, Apple M2 Max, see `doc/qameasures.md`, S5): an average AI turn
  takes 0.005 s on `asc001.map`, 0.76 s on `railstations2.map` and 1.29 s on `asc014.map`; the
  slowest single turn took 2.03 s. A long game on a larger map therefore takes minutes.
- Terms as in TASK-0018: an *AI turn* is one player's turn; a *round* is every player's turn
  once.

1. Add the facade functions the test still needs (save and load a game), reusing those of
   TASK-0018, and those of TASK-0015 if it is done first (decided when improving TASK-0013:
   TASK-0013 does not provide them).
2. Create an automated game with AI players only on standard maps of ASC, running without a
   window, over many rounds. The maps, the number of rounds (e.g. 100) and what happens if a
   game ends earlier (e.g. a player has won) are agreed with the user.
3. Save and load the game at intervals during the run; the game must continue after loading.
4. The test fails if the game crashes, an error is reported, or saving or loading fails.
5. Provide a single documented command for the test (`doc/buildAndTest.md`); a new script in
   `scripts/` is tested in `scripts/test.sh`.
6. Measure the duration. The user decided: the test runs at least for every release, and at the
   end of each task if it is fast. Tell the user the duration and let the user decide whether
   it is fast enough; if so, add running it to `doc/aiTaskDefinitionOfDone.md`.
7. Update `doc/qameasures.md` (S3: implemented, with the decided frequency).

## Acceptance criteria

- [x] An automated AI-only game runs over the agreed number of rounds on the agreed standard maps
      without a window, with a single command documented in `doc/buildAndTest.md`.
- [x] The game is saved and loaded at intervals during the run, and the test fails on a crash,
      an error or a failed save or load.
- [x] The test passes, or each failure is recorded in a new task.
- [x] The duration is measured and the user's decision about running it at the end of each task
      is recorded in `doc/qameasures.md` (S3 marked implemented, with the decided frequency) and
      in `doc/aiTaskDefinitionOfDone.md`, if decided.
- [x] A new script for the test, if any, is tested in `scripts/test.sh`.

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
| 2026-11-24T15:44+0100 | in-work | Implementation started |
| 2026-11-24T16:15+0100 | done | All acceptance criteria and the Definition of Done are fulfilled |
