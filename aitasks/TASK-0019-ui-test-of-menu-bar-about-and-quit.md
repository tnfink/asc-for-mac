# TASK-0019: UI test of menu bar, About and Quit

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0019 |
| **Short description** | UI test of menu bar, About and Quit |
| **Status**        | done <!-- One of: open, in-work, waiting, done, aborted -->   |
| **External link** | none |
| **Dependencies**  | TASK-0007, TASK-0013 |

## Motivation

Implements the QA measure **S6** from `doc/qameasures.md` (decided in TASK-0007). The app
should behave like a native Mac app (quality objective *Interaction capability*, 3). A UI test
checks the menu bar, About and Quit automatically. The user decided that it is done in its own
task.

## Task description

Current state (TASK-0013): the menu bar is built in `app/ASCforMac/MainMenu.swift` (app menu
with "About ASC for Mac" and "Quit ASC for Mac", Cmd+Q). The About window is
`app/ASCforMac/AboutView.swift`; its ASC core version text has the accessibility identifier
`ascCoreVersion`. After launching, `AppDelegate.applicationDidFinishLaunching` starts ASC's game
in full screen; it is skipped only when the app hosts the unit tests (`Game.isHostingTests`),
which is not the case for an app launched by a UI test.

1. Add a launch argument that makes the app start without the game (user decision in the
   review of this task), e.g. checked next to `Game.isHostingTests`. Without the game, Cmd+Q
   ends the app immediately (`applicationShouldTerminate` returns `.terminateNow` when the game
   is not running). Document the argument in `doc/buildAndTest.md`.
2. Add a UI test target (XCTest UI testing) to the Xcode project, e.g. `ASCforMacUITests` in
   `app/ASCforMacUITests/`.
3. The UI test starts the app with that launch argument and checks: the app menu has About and
   Quit; About opens a window that shows the ASC core version (`AppInfo.ascVersion`); Quit
   (Cmd+Q) ends the app.
4. UI tests on macOS need a one-time permission for UI automation; document how to grant it in
   `doc/developerInfrastructure.md` and tell the user before running it.
5. Run the UI test with its own script `scripts/test-ui.sh` (user decision in the review of this
   task: UI tests take over mouse and keyboard). `scripts/test-app.sh`,
   `scripts/test-sanitizers.sh` and `scripts/test-coverage.sh` do not run the UI test. Add
   tests for the new script to `scripts/test.sh` (e.g. `--help` and unknown arguments) and
   document the command in `doc/buildAndTest.md`.
6. Update `doc/qameasures.md` (S6: implemented).

Out of scope: testing Quit while the game runs (the "Quit anyway?" question); it stays a manual
check, as done in TASK-0013.

## Acceptance criteria

- [x] Started with the new launch argument, the app does not start the game; without it, the
      game starts as before (checked by the UI test or by inspection, and by the user once).
- [x] A UI test target exists and checks the app menu (About, Quit), the About window with the
      ASC core version, and Quit with Cmd+Q.
- [x] `scripts/test-ui.sh` runs the UI test and passes; it is documented in
      `doc/buildAndTest.md` and tested in `scripts/test.sh`.
- [x] `scripts/test-app.sh`, `scripts/test-sanitizers.sh` and `scripts/test-coverage.sh` do not
      run the UI test, and still pass.
- [x] The permission needed for UI automation is documented in `doc/developerInfrastructure.md`.
- [x] `doc/qameasures.md` marks S6 as implemented.

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
| 2026-11-20T11:40+0100 | in-work | Implementation started |
| 2026-11-20T12:10+0100 | done | All acceptance criteria and the Definition of Done are fulfilled |
