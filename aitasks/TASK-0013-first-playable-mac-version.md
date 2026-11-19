# TASK-0013: First playable Mac version

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0013 |
| **Short description** | First playable Mac version |
| **Status**        | open <!-- One of: open, in-work, waiting, done, aborted -->   |
| **External link** | none |
| **Dependencies**  | TASK-0006 |

## Motivation

The first goal of asc-for-mac is a working Mac version of ASC (see `README.md`; the user
decided "a working Mac version first" in TASK-0005). TASK-0006 creates the foundation: the
Xcode main build, the Swift app and the facade to the ASC core, but the game itself does not
run yet. This task makes the game playable on the Mac.

## Task description

Make ASC playable in the asc-for-mac app, following `doc/architecture.md`:

1. Start the game from the Swift app through the facade; SDL2 creates the game window and the
   in-game UI (ParaGUI) stays unchanged.
2. Add the menu bar with AppKit (at least About and Quit with Cmd+Q), attached to SDL's window
   and event loop; the About window uses SwiftUI.
3. Bundle the game data from `thirdparty/asc/data/` (and the needed parts of
   `thirdparty/asc/extra-data/`) read-only into the app (`Contents/Resources`).
4. Store user data (save games, PBEM files, own maps, ASC configuration) in ASC's unchanged file
   formats in `~/Library/Application Support/asc-for-mac/`, with the path set through the
   facade.
5. Keep the C++ core unchanged except for minimal, marked changes listed in
   `doc/thirdparty.md`.

Out of scope: network games (TASK-0009), the update to SDL3 (TASK-0011), signing with the
Developer ID, notarization and the `.dmg` (needs TASK-0010).

## Acceptance criteria

- [ ] The app starts with a single documented command and shows ASC's main menu in an SDL
      window.
- [ ] A single player game on a standard map can be started, a turn can be played, saved and
      loaded again.
- [ ] Existing maps and save games created with ASC on another system (e.g. Linux) can be
      loaded (check with at least one map and one save game; note their origin in the task).
- [ ] The menu bar offers About (SwiftUI window) and Quit (Cmd+Q).
- [ ] The game data is inside the app bundle (`Contents/Resources`), and the app writes user
      data only to `~/Library/Application Support/asc-for-mac/`.
- [ ] All automated tests and the static quality check pass.

## History

<!--
  Log of all status changes, oldest first. Add a row for every change of the Status field.
  Timestamp format: ISO 8601 with time zone offset, e.g. 2026-11-11T14:30+0100
  (get it with: date +%Y-%m-%dT%H:%M%z).
  Comment: optional, but required for "waiting" and "aborted" (state the reason).
-->

| Timestamp                | Status | Comment       |
|--------------------------|--------|---------------|
| 2026-11-19T13:58+0100 | open   | Task created  |
