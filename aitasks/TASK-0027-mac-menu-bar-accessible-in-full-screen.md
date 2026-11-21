# TASK-0027: Mac menu bar accessible in full-screen mode

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0027 |
| **Short description** | Mac menu bar accessible in full-screen mode |
| **Status**        | open <!-- One of: open, in-work, waiting, done, aborted -->   |
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
Mac apps do.

Analysis so far (not yet confirmed in the running game):

- ASC's full-screen mode creates the SDL window with `SDL_WINDOW_FULLSCREEN_DESKTOP`
  (`thirdparty/asc/source/libs/paragui/src/core/pgapplication.cpp`,
  `PG_Application::InitScreen`).
- SDL 2 supports the native macOS full-screen mode in its own Space (hint
  `SDL_HINT_VIDEO_MAC_FULLSCREEN_SPACES`, default "1"), in which the menu bar appears when the
  pointer reaches the top edge. Probably SDL uses it only for windows that allow full screen
  (resizable windows); ASC's window is not resizable, so SDL falls back to its own full-screen
  mode, which hides the menu bar completely.

To do:

1. Confirm the cause in the running game (the user checks the game window; screenshots only
   as allowed for this project).
2. Use the native macOS full-screen mode (own Space), so that the menu bar with About,
   Licenses… and Quit appears when the pointer is moved to the top edge of the screen.
   Prefer a solution in the Swift app or the facade (e.g. allowing native full screen for
   SDL's window, or setting an SDL hint before the window is created). Changes in
   `thirdparty/asc/` only if unavoidable: minimal, marked `asc-for-mac:` and listed in
   `doc/thirdparty.md`.
3. Offer the standard Mac controls for full screen: the green window button,
   *View › Enter Full Screen* / *Exit Full Screen* and Ctrl+Cmd+F, consistent with ASC's own
   full-screen setting. If they conflict with ASC's setting or its fixed screen size, report
   to the user and let the user decide.
4. Add automated tests where possible (e.g. unit tests of the menu, an extension of the UI
   test `app/ASCforMacUITests/` for the menu items that work without the game); the behaviour
   in the game window is checked by the user.
5. Document the behaviour in `doc/buildAndTest.md` (section *Running the game*) and, if a
   decision is taken, in `doc/architecture.md`.

Out of scope: other changes of ASC's display settings or resolution handling.

## Acceptance criteria

- [ ] The cause of the hidden menu bar is confirmed and documented.
- [ ] In full-screen mode, moving the pointer to the top edge of the screen shows the menu bar,
      and About, Licenses… and Quit work from it (checked by the user).
- [ ] Full screen can be entered and left with the green window button,
      *View › Enter Full Screen* and Ctrl+Cmd+F (checked by the user; the menu item checked by
      a test).
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
| 2026-11-21T16:35+0100 | open   | Task created  |
