# TASK-0013: First playable Mac version

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0013 |
| **Short description** | First playable Mac version |
| **Status**        | done <!-- One of: open, in-work, waiting, done, aborted -->   |
| **External link** | none |
| **Dependencies**  | TASK-0006 |

## Motivation

The first goal of asc-for-mac is a working Mac version of ASC (see `README.md`; the user
decided "a working Mac version first" in TASK-0005). TASK-0006 created the foundation: the
Xcode main build, the Swift app (menu bar with About and Quit, a SwiftUI main window showing the
ASC core version) and the facade to the ASC core, but the game itself does not run yet. This
task makes the game playable on the Mac.

## Task description

Make ASC playable in the asc-for-mac app, following `doc/architecture.md` (sections *UI
technology*, *Data storage*, *Structure of the application*):

1. **Start the game** from the Swift app through a new facade function; SDL2 creates the game
   window and the in-game UI (ParaGUI) stays unchanged. The SDL game window **replaces** the
   SwiftUI main window of TASK-0006 (`app/ASCforMac/MainView.swift`); the ASC core version stays
   visible in the About window (user decision when improving this task).
   - ASC's start-up code is in `thirdparty/asc/source/sg.cpp` (`main`) and
     `source/gamedialog.cpp`, which the core build (`core/asc-sources.cmake`) currently leaves
     out. Reuse this code instead of rewriting it; prefer build-level solutions (e.g. compile
     definitions) over source changes.
2. **Menu bar:** keep the AppKit menu bar of TASK-0006 (About, Quit with Cmd+Q) working while
   SDL's event loop runs: SDL must use the app's `NSApplication` and menu instead of creating
   its own. Quit (Cmd+Q) ends the game through ASC's normal quit handling (e.g. as SDL quit
   event), not by killing the process. The About window stays a SwiftUI window.
3. **Game data:** bundle the game data read-only into the app (`Contents/Resources`), as ASC's
   autotools install does (`thirdparty/asc/data/Makefile.am`, `extra-data/Makefile.am`):
   `main.ascdat` (from `data/`, built with `asc_mount`), the dialog theme `asc2_dlg.zip` (from
   `data/dialog/`), `pbp.ascdat` (from `extra-data/`) and the music (`data/music/`). The build
   already creates `main.ascdat` and `asc2_dlg.zip` for `unittester` (`core/CMakeLists.txt`).
4. **User data:** store user data (save games, PBEM files, own maps, ASC configuration) in ASC's
   unchanged file formats in `~/Library/Application Support/asc-for-mac/`, with the path set
   through the facade. ASC looks for its configuration file in `~/.asc/` by default; it can be
   redirected without code changes, e.g. with the environment variable `ASC_CONFIGFILE`
   (`source/sgstream.cpp`) and the search paths in the configuration file.
5. Keep the C++ core unchanged except for minimal, marked changes listed in
   `doc/thirdparty.md`.
6. Update `doc/buildAndTest.md` (how to start the game, where the data is) and
   `doc/architecture.md` if the implementation clarifies a decision.

Out of scope:

- Network games (TASK-0009), the update to SDL3 (TASK-0011), signing with the Developer ID,
  notarization and the `.dmg` (TASK-0014).
- Facade functions for loading and saving maps and save games or running games without a window
  for automated tests; the test tasks add the functions they need (TASK-0015, TASK-0017,
  TASK-0018; user decision when improving this task).

## Acceptance criteria

- [x] `scripts/run.sh --build` starts the app, which shows ASC's main menu in an SDL window; the
      SwiftUI main window of TASK-0006 is gone.
- [x] A single player game on a standard map can be started, a turn can be played, saved and
      loaded again (checked manually by the user).
- [x] ~~Existing maps and save games created with ASC on another system (e.g. Linux) can be
      loaded~~ — moved to TASK-0015 (user decision during implementation: no files from other
      systems available yet).
- [x] The menu bar offers About (SwiftUI window, shows the ASC core version) and Quit (Cmd+Q),
      both working while the game runs; Quit ends the game through ASC's quit handling.
- [x] The game data (`main.ascdat`, `asc2_dlg.zip`, `pbp.ascdat`, music; note from the
      implementation: the music files are not part of the ASC repository, so there is no music
      to bundle) is inside the app bundle
      (`Contents/Resources`), and the app writes user data only to
      `~/Library/Application Support/asc-for-mac/` (check that `~/.asc/` is not created and the
      bundle is unchanged after playing).
- [x] All automated tests and checks pass: `scripts/test-app.sh`, `scripts/check.sh`,
      `scripts/test-sanitizers.sh`, `scripts/test-coverage.sh` (a new coverage baseline only
      with the user's consent) and `scripts/test.sh`.

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
| 2026-11-19T21:21+0100 | in-work | Implementation started |
| 2026-11-19T21:35+0100 | waiting | Waiting for the user's manual check of the game (start, play, save/load, About, Cmd+Q) |
| 2026-11-19T22:09+0100 | done | All acceptance criteria and the Definition of Done are fulfilled; check with data from other systems moved to TASK-0015 |
