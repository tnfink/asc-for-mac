# TASK-0028: Switch full screen at runtime the Mac way

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0028 |
| **Short description** | Switch full screen at runtime the Mac way |
| **Status**        | done <!-- One of: open, in-work, waiting, done, aborted -->   |
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
- Since TASK-0027, full screen on macOS is no longer SDL's `SDL_WINDOW_FULLSCREEN_DESKTOP`:
  `PG_Application::InitScreen` creates a resizable window of the size of the screen
  (`SDL_WINDOW_RESIZABLE`) and puts it into macOS full screen with `toggleFullScreen:`
  (`EnterMacFullScreen`, marked `asc-for-mac:`). The green window button is therefore already
  active after a full-screen start; what happens when it is used (window size, scaling, value of
  `isFullscreen()`) is to be analyzed in step 1. After a windowed start (`-w` or
  `ForceWindowedMode`), the window is created without `SDL_WINDOW_RESIZABLE` and without
  scaling.
- The app's menu bar (`app/ASCforMac/MainMenu.swift`) has only the app menu (About, Licenses…,
  Quit); there is no *View* menu yet. In AppKit, a menu item with the action `toggleFullScreen:`
  is sent to the key window and gets the titles *Enter Full Screen* / *Exit Full Screen*
  automatically.
- The UI test (`app/ASCforMacUITests/MenuBarUITests.swift`, run with `scripts/test-ui.sh`)
  starts the app with `--no-game`, i.e. without the game window. It takes over mouse and
  keyboard, so ask the user before running it.
- ASC's map editor has no working runtime toggle: the call `toggleFullscreen()` in
  `source/maped-mainscreen.cpp` is commented out (and the map editor is not part of the app).

To do:

1. Analyze how switching at runtime can work with ASC's scaling and its full-screen dependent
   behaviour, and present the options with their changes (especially in `thirdparty/asc/`) to
   the user; the user decides. Record the decision in `doc/architecture.md`.
2. Implement the decided solution: the menu *View* in `app/ASCforMac/MainMenu.swift` with
   *Enter Full Screen* / *Exit Full Screen* (Ctrl+Cmd+F), and the green window button, for
   both a full-screen and a windowed start. Changes in `thirdparty/asc/` minimal, marked
   `asc-for-mac:` and listed in `doc/thirdparty.md`.
3. Tests: a unit test (`app/ASCforMacTests/`) that the *View* menu contains the item with its
   action and Ctrl+Cmd+F, and an extension of the UI test (`MenuBarUITests.swift`) that the
   item exists in the menu bar (without the game); switching in the game window is checked by
   the user.
4. Document the behaviour in `doc/buildAndTest.md` (section *Running the game*, including the
   bullet *Full screen and the menu bar* from TASK-0027).

Out of scope: other changes of ASC's display settings or resolution handling.

## Acceptance criteria

- [x] The options were presented to the user and the decision is recorded in
      `doc/architecture.md`.
- [x] While the game runs, the green window button, *View › Enter Full Screen* / *Exit Full
      Screen* and Ctrl+Cmd+F switch between full screen and a window, after a full-screen start
      and after a windowed start, and the game stays usable in both (checked by the user).
- [x] A unit test checks that the *View* menu contains the full-screen item with its action and
      the key equivalent Ctrl+Cmd+F; the UI test checks that the item exists in the menu bar.
- [x] `doc/buildAndTest.md` describes switching full screen at runtime.
- [x] Changes in `thirdparty/asc/`, if any, are marked `asc-for-mac:` and listed in
      `doc/thirdparty.md`.
- [x] `scripts/test-app.sh`, `scripts/test-ui.sh`, `scripts/check.sh` and
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
| 2026-11-22T20:25+0100 | in-work | Implementation started |
| 2026-11-22T20:31+0100 | waiting | Waiting for the user's check in the game window and permission to run the UI test |
| 2026-11-22T20:41+0100 | done | All acceptance criteria and the Definition of Done are fulfilled |
