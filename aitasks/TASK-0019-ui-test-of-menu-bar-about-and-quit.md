# TASK-0019: UI test of menu bar, About and Quit

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0019 |
| **Short description** | UI test of menu bar, About and Quit |
| **Status**        | open <!-- One of: open, in-work, waiting, done, aborted -->   |
| **External link** | none |
| **Dependencies**  | TASK-0007 |

## Motivation

Implements the QA measure **S6** from `doc/qameasures.md` (decided in TASK-0007). The app
should behave like a native Mac app (quality objective *Interaction capability*, 3). A UI test
checks the menu bar, About and Quit automatically. The user decided that it is done in its own
task.

## Task description

1. Add a UI test target (XCTest UI testing) to the Xcode project.
2. The UI test starts the app and checks: the app menu has About and Quit; About opens a window
   that shows the ASC core version; Quit (Cmd+Q) ends the app.
3. UI tests on macOS need a one-time permission for UI automation; document how to grant it in
   `doc/developerInfrastructure.md` and tell the user before running it.
4. Run the UI test with the automated tests (`scripts/test-app.sh`) or document a separate
   single command in `doc/buildAndTest.md`.
5. Update `doc/qameasures.md` (S6: implemented).

## Acceptance criteria

- [ ] A UI test target exists and checks the app menu (About, Quit), the About window with the
      ASC core version, and Quit with Cmd+Q.
- [ ] The UI test runs with a single documented command and passes.
- [ ] The permission needed for UI automation is documented in `doc/developerInfrastructure.md`.
- [ ] `doc/qameasures.md` marks S6 as implemented.

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
