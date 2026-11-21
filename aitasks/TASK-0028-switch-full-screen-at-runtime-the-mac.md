# TASK-0028: Switch full screen at runtime the Mac way

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0028 |
| **Short description** | Switch full screen at runtime the Mac way |
| **Status**        | open <!-- One of: open, in-work, waiting, done, aborted -->   |
| **External link** | none |
| **Dependencies**  | TASK-0027 |

## Motivation

Split from TASK-0027 (decision of the user in the review of TASK-0027). The user asked for a
"Mac compliant way" to reach the standard Mac menu in full-screen mode; Mac apps also let the
user switch between full screen and a window at any time. ASC's game cannot do that: it decides
once at start whether it runs in full screen or in a window. Switching the Mac way makes the app
behave like a native Mac app (quality objective Interaction capability, see
`doc/qameasures.md`, S6).

## Task description

Let the player switch the game between full screen and a window while it runs, with the
standard Mac controls: the green window button, *View › Enter Full Screen* / *Exit Full Screen*
and Ctrl+Cmd+F.

Known facts:

- ASC's game decides at start (`ScreenResolutionSetup` in `thirdparty/asc/source/sg.cpp`): full
  screen by default, a window with the option `ForceWindowedMode = true` in `asc2rc` or the
  command line option `-w`; `-f` forces full screen. In full screen, ParaGUI scales ASC's fixed
  resolution to the screen (`PG_Application::InitScreen` with `SDL_RenderSetLogicalSize` in
  `thirdparty/asc/source/libs/paragui/src/core/pgapplication.cpp`); in a window it does not
  scale.
- ASC's behaviour depends on full screen, e.g. scrolling the map when the pointer is at the
  screen edge (`MainScreenWidget::mouseScrollChecker` in `source/mainscreenwidget.cpp`, using
  `PG_Application::isFullscreen()`).
- ASC's map editor already has a runtime toggle (`toggleFullscreen()`,
  `source/maped-mainscreen.cpp`); the map editor is not part of the app.

To do:

1. Analyze how switching at runtime can work with ASC's scaling and its full-screen dependent
   behaviour, and present the options with their changes (especially in `thirdparty/asc/`) to
   the user; the user decides. Record the decision in `doc/architecture.md`.
2. Implement the decided solution: the menu *View* with *Enter Full Screen* / *Exit Full Screen*
   (Ctrl+Cmd+F), and the green window button. Changes in `thirdparty/asc/` minimal, marked
   `asc-for-mac:` and listed in `doc/thirdparty.md`.
3. Tests: unit tests and an extension of the UI test (`app/ASCforMacUITests/`) for the menu
   item where possible; switching in the game window is checked by the user.
4. Document the behaviour in `doc/buildAndTest.md` (section *Running the game*).

Out of scope: other changes of ASC's display settings or resolution handling.

## Acceptance criteria

- [ ] The options were presented to the user and the decision is recorded in
      `doc/architecture.md`.
- [ ] While the game runs, the green window button, *View › Enter Full Screen* / *Exit Full
      Screen* and Ctrl+Cmd+F switch between full screen and a window, and the game stays usable
      in both (checked by the user).
- [ ] The menu item exists and calls the switching (checked by a test).
- [ ] Changes in `thirdparty/asc/`, if any, are marked `asc-for-mac:` and listed in
      `doc/thirdparty.md`.
- [ ] `scripts/test-app.sh`, `scripts/test-ui.sh`, `scripts/check.sh` and
      `scripts/test-coverage.sh` pass.

## History

<!--
  Log of all status changes, oldest first. Add a row for every change of the Status field.
  Timestamp format: ISO 8601 with time zone offset, e.g. 2026-11-11T14:30+0100
  (get it with: date +%Y-%m-%dT%H:%M%z).
  Comment: optional, but required for "waiting" and "aborted" (state the reason).
-->

| Timestamp                | Status | Comment       |
|--------------------------|--------|---------------|
| 2026-11-21T16:39+0100 | open   | Task created  |
