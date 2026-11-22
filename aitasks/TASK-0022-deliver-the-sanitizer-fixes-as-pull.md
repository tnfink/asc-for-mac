# TASK-0022: Deliver the sanitizer fixes as pull request to ASC

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0022 |
| **Short description** | Deliver the sanitizer fixes as pull request to ASC |
| **Status**        | open <!-- One of: open, in-work, waiting, done, aborted -->   |
| **External link** | none |
| **Dependencies**  | TASK-0016, TASK-0027 |

## Motivation

The sanitizer run of TASK-0016 (QA measure S2) found undefined behavior in the original ASC
code. asc-for-mac fixes it inside `thirdparty/asc/` (marked with `asc-for-mac:`, listed in
`doc/thirdparty.md`). The user decided that the fixes are also offered to the ASC project as
a pull request, so that the ASC versions for other systems get them too. This task makes sure
the pull request is not forgotten. Once ASC has merged the fixes, the local changes disappear
with the next subtree update, which keeps `thirdparty/asc/` closer to the original.

## Task description

The pull request is prepared in
`thirdparty/upstream-patches/asc-0001-fix-undefined-behavior-found-by-sanitizers.patch`.
The patch is relative to the root of the ASC repository and was made against
<https://github.com/ValHaris/asc-hq> `master` at commit `074a6ef90fcec61bb72cf0102c1928ca6151f38d`.
It contains:

1. `source/ai/base.cpp`, `AI::checkKeys()`: uses the pointer `pgApp` instead of
   `&getPGApplication()`, which dereferences a null pointer when there is no ParaGUI
   application (e.g. in `unittester`); the compiler may then remove the null check.
2. `source/astar2.h`, `hash_MapCoordinate3D`: shifts as `unsigned` instead of left-shifting
   negative values; converting back to `int` keeps the hash values unchanged.

Steps:

1. Check whether ASC `master` has changed since `074a6ef`, and whether the fixes are still
   needed or already made upstream. If the patch no longer applies, adapt it.
2. Ask the user which GitHub account to use and whether to create the fork and pull request
   with the `gh` CLI or by hand. Creating the pull request publishes it; do it only after the
   user has confirmed the final content (title, description, patch).
3. Create a branch from the current ASC `master` in the user's fork, apply the patch, commit it
   and open a pull request against `ValHaris/asc-hq` `master`. The description explains each
   fix, how it was found (Clang's UndefinedBehaviorSanitizer while running `unittester`, stack:
   `testMapResizeWithMovement` → `next_turn` → `AI::run` → `AI::checkKeys`), and that the hash
   values do not change.
4. Mention in the description, without a code change, the third finding: in
   `source/ai/service.cpp` (around line 501), `bestDistance_p*3` overflows when
   `bestDistance_p` is `maxint` (signed integer overflow, undefined behavior). asc-for-mac
   compiles the core with `-fwrapv` to keep the current behavior; a real fix would change the
   AI's decisions and is left to the ASC developers.
5. Record the pull request URL and its state in `doc/thirdparty.md` (section *Changes inside
   `thirdparty/asc/`*).

Second pull request (added by TASK-0027 and extended by TASK-0028, user requests):
`thirdparty/upstream-patches/asc-0002-macos-full-screen-with-menu-bar-and-switching.patch`,
made against the same commit. On macOS, `PG_Application::InitScreen`
(`source/libs/paragui/src/core/pgapplication.cpp`) creates a resizable window and puts it into
macOS full screen instead of creating an `SDL_WINDOW_FULLSCREEN_DESKTOP` window, for which
SDL 2 hides the menu bar completely. The window is always resizable and scaled to ASC's screen
size, so the player can switch between full screen and a window at any time (e.g. with the
green window button); the new `PG_Application::IsMacFullScreen()` and `ASC_PG_App::isFullscreen()`
(`source/paradialog.h`) report the current mode, so map scrolling at the screen edges follows
it. Other systems are unchanged. It is a separate topic, so it
is delivered as a separate pull request in the same way (steps 1 to 3 and 5; the user confirms
its title, description and patch before it is created). The description explains the cause in
SDL (`src/video/cocoa/SDL_cocoawindow.m`: `window:willUseFullScreenPresentationOptions:` and
`[NSMenu setMenuBarVisible:NO]`).

Out of scope: changes to the asc-for-mac build or code; merging the pull request (done by the
ASC developers); the subtree update after the merge.

## Acceptance criteria

- [ ] The user has confirmed the title, description and patch of the pull request before it was created.
- [ ] A pull request against `ValHaris/asc-hq` `master` exists that contains the two fixes and mentions the overflow in `source/ai/service.cpp`.
- [ ] A second pull request against `ValHaris/asc-hq` `master` exists that contains the macOS full-screen changes of `asc-0002-macos-full-screen-with-menu-bar-and-switching.patch` (its title, description and patch confirmed by the user before it was created).
- [ ] `doc/thirdparty.md` lists the URL of the pull request.

## History

<!--
  Log of all status changes, oldest first. Add a row for every change of the Status field.
  Timestamp format: ISO 8601 with time zone offset, e.g. 2026-11-11T14:30+0100
  (get it with: date +%Y-%m-%dT%H:%M%z).
  Comment: optional, but required for "waiting" and "aborted" (state the reason).
-->

| Timestamp                | Status | Comment       |
|--------------------------|--------|---------------|
| 2026-11-19T20:52+0100 | open   | Task created  |
