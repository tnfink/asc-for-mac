# TASK-0018: Performance smoke test for map loading and AI turns

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0018 |
| **Short description** | Performance smoke test for map loading and AI turns |
| **Status**        | done <!-- One of: open, in-work, waiting, done, aborted -->   |
| **External link** | none |
| **Dependencies**  | TASK-0007, TASK-0013 |

## Motivation

Implements the QA measure **S5** from `doc/qameasures.md` (decided in TASK-0007). The user wants
that the user does not have to wait (quality objective *Performance efficiency*, 3) and decided
that a performance smoke test is important for regression testing. Loading maps and AI turns
need the playable game from TASK-0013.

## Task description

1. **Facade functions:** measure through facade functions (`facade/include/AscFacade.h`)
   without a window. The facade currently only has `ascVersion`, `runGame` and `requestQuit`.
   Add the functions that are missing (load a map; run AI turns, e.g. with all players set to
   AI), reusing those of TASK-0015 and TASK-0017 if they are done by then (decided when
   improving TASK-0013: TASK-0013 does not provide them; user decision when improving this
   task: TASK-0018 stays independent of TASK-0015 and TASK-0017). Design the functions so that
   TASK-0015 (loading maps and save games) and TASK-0017 (AI-only game) can reuse them, and
   record them in `doc/architecture.md` if the facade's structure changes.
2. **Maps:** propose a small set of "standard maps" from ASC's game data (e.g. a small, a
   medium and a large map that ASC ships, such as the startup map
   `thirdparty/asc/data/campaign/standard/asc001.map`) and let the user confirm the
   selection. Record it next to the time limits.
3. **Measure** for each selected map: the time to load it, and the time of one AI turn, i.e.
   one run of ASC's AI for one player (`AI::run` in `thirdparty/asc/source/ai/base.cpp`, called
   by `next_turn` in `thirdparty/asc/source/turncontrol.cpp`; `AI::run` has a parameter
   `benchMark`, check whether it helps), averaged over a few turns. Measure in the
   configuration that `scripts/test-app.sh` uses (Debug), since the limits apply there, and
   repeat the measurement to see how much the times vary.
4. **Time limits:** agree the limits with the user, based on the measured values and their
   variation (e.g. with a margin, so the test is stable), and record them, with the measured
   values, the machine they were measured on and the build configuration, in
   `doc/qameasures.md`.
5. **Tests:** add automated tests (Swift Testing in `app/ASCforMacTests/`) that fail if a limit
   is exceeded and that report the measured time. They run with `scripts/test-app.sh`.
   Document them in `doc/buildAndTest.md`.
6. Update `doc/qameasures.md` (S5: implemented).

Out of scope: making ASC faster (if a measured time is too slow for the user, propose a new
task); performance in the window (drawing, scrolling); the long-game test (TASK-0017); time
limits for other machines or for CI (TASK-0021 may adjust them).

## Acceptance criteria

- [x] The selection of standard maps was confirmed by the user and is recorded in
      `doc/qameasures.md`.
- [x] For each selected map, the time to load it and the time of an AI turn are measured
      through facade functions without a window; the measured values and the time limits agreed
      with the user (with machine and build configuration) are recorded in `doc/qameasures.md`.
- [x] Automated tests fail if a time limit is exceeded and report the measured times; they run
      with `scripts/test-app.sh` and pass.
- [x] `doc/buildAndTest.md` describes the tests and `doc/qameasures.md` marks S5 as implemented.
- [x] `scripts/check.sh` and `scripts/test-coverage.sh` pass (a new coverage baseline only with
      the user's consent).

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
| 2026-11-21T20:53+0100 | in-work | Implementation started |
| 2026-11-21T21:20+0100 | done | All acceptance criteria and the Definition of Done are fulfilled |
