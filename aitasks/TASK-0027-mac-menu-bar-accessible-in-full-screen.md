# TASK-0027: Mac menu bar accessible in full-screen mode

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0027 |
| **Short description** | Mac menu bar accessible in full-screen mode |
| **Status**        | waiting <!-- One of: open, in-work, waiting, done, aborted -->   |
| **External link** | none |
| **Dependencies**  | TASK-0013, TASK-0025 |

## Motivation

User report: "In full-screen mode I cannot access the Mac menu anymore. This means, I cannot
access the about ore licences menu item. There should be a Mac compliant way to access the
standard Mac menu."

When ASC runs in full-screen mode, the macOS menu bar is hidden completely, so the menu items
About, Licenses… (TASK-0025) and Quit cannot be reached. Mac apps in full-screen mode show the
menu bar when the pointer is moved to the top edge of the screen; asc-for-mac should behave
like a native Mac app (quality objective Interaction capability, see `doc/qameasures.md`, S6).

## Task description

Make the standard Mac menu bar accessible while the game runs in full-screen mode, in the way
Mac apps do: the menu bar appears when the pointer is moved to the top edge of the screen.

Decision of the user (review of this task): this task only makes the menu bar reachable.
Switching between full screen and a window at runtime (green window button,
*View › Enter Full Screen*, Ctrl+Cmd+F) is TASK-0028.

Analysis so far (not yet confirmed in the running game):

- ASC's game runs in full screen by default; it decides once at start
  (`ScreenResolutionSetup` in `thirdparty/asc/source/sg.cpp`; a window with
  `ForceWindowedMode = true` in `asc2rc` or the command line option `-w`, see
  `doc/buildAndTest.md`, section *Running the game*).
- Full screen creates the SDL window with `SDL_WINDOW_FULLSCREEN_DESKTOP`
  (`thirdparty/asc/source/libs/paragui/src/core/pgapplication.cpp`,
  `PG_Application::InitScreen`).
- SDL 2 supports the native macOS full-screen mode in its own Space (hint
  `SDL_HINT_VIDEO_MAC_FULLSCREEN_SPACES`, default "1"), in which the menu bar appears when the
  pointer reaches the top edge. Probably SDL uses it only for windows that allow full screen
  (resizable windows); ASC's window is not resizable, so SDL falls back to its own full-screen
  mode, which hides the menu bar completely.
- In full screen, ASC scrolls the map when the pointer is at the screen edge, also at the top
  edge (`MainScreenWidget::mouseScrollChecker` in `thirdparty/asc/source/mainscreenwidget.cpp`).
  Moving the pointer to the top edge to reach the menu bar therefore also scrolls the map.

To do:

1. Confirm the cause in the running game (the user checks the game window; screenshots only
   as allowed for this project).
2. Use the native macOS full-screen mode (own Space), so that the menu bar with About,
   Licenses… and Quit appears when the pointer is moved to the top edge of the screen, while
   ASC keeps its full-screen behaviour (scaling, map scrolling). Prefer a solution in the Swift
   app or the facade (e.g. allowing native full screen for SDL's window, or setting an SDL hint
   before the window is created). Changes in `thirdparty/asc/` only if unavoidable: minimal,
   marked `asc-for-mac:` and listed in `doc/thirdparty.md`.
3. Check with the user whether the map scrolling at the top edge disturbs reaching the menu
   bar; if so, present options and let the user decide (no change of ASC's scrolling without
   the user's decision).
4. Add automated tests where possible (e.g. a unit test of the code that enables the native
   full-screen mode); the behaviour in the game window is checked by the user. The existing UI
   test (`scripts/test-ui.sh`) runs without the game and must keep passing.
5. Document the behaviour and the cause in `doc/buildAndTest.md` (section *Running the game*)
   and, if a decision is taken, in `doc/architecture.md`.

Out of scope: switching full screen at runtime (TASK-0028); other changes of ASC's display
settings or resolution handling.

## Acceptance criteria

- [x] The cause of the hidden menu bar is confirmed and documented in `doc/buildAndTest.md`.
- [x] In full-screen mode, moving the pointer to the top edge of the screen shows the menu bar,
      and About, Licenses… and Quit work from it (checked by the user).
- [x] In full-screen mode, the game still fills the screen with ASC's scaling, and the game in
      a window (`ForceWindowedMode`) is unchanged (checked by the user).
- [x] The user was asked about the map scrolling at the top edge, and the decision is recorded.
- [x] Changes in `thirdparty/asc/`, if any, are marked `asc-for-mac:` and listed in
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
| 2026-11-21T16:35+0100 | open   | Task created  |
| 2026-11-21T16:46+0100 | in-work | Implementation started |
| 2026-11-21T16:49+0100 | waiting | Waiting for the user to check the menu bar in the full-screen game |
