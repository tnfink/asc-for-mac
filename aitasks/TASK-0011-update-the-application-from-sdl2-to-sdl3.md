# TASK-0011: Update the application from SDL2 to SDL3

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0011 |
| **Short description** | Update the application from SDL2 to SDL3 |
| **Status**        | open <!-- One of: open, in-work, waiting, done, aborted -->   |
| **External link** | none |
| **Dependencies**  | TASK-0008 |

## Motivation

The original ASC is written for SDL2. For the first working Mac version, the user decided in
TASK-0005 to keep SDL2, so the C++ core needs no changes (see `doc/architecture.md`). SDL2
only gets maintenance updates; its successor SDL3 is actively developed. Updating to SDL3
keeps the application on a supported library and fits the later step of improving and
modernizing the port (see `README.md`).

## Task description

Do this task only after the first working Mac version of asc-for-mac exists.

1. Analyze which parts of the ASC code copied into the repository (TASK-0008) use SDL2, SDL2_image
   and SDL2_mixer, including the bundled libraries in `source/libs` (e.g. ParaGUI, SDL_sound).
2. Update the code to SDL3, SDL3_image and SDL3_mixer, and switch the vcpkg dependencies from
   the SDL2 packages to the SDL3 packages.
3. Keep the behavior of the game unchanged: maps, save games and PBEM files must stay compatible
   with ASC on other systems (quality objective *Compatibility* in `doc/qualityobjectives.md`).
4. Update `doc/architecture.md` (SDL version) and the document in `doc/` that lists the 3rd
   party artifacts (created in TASK-0008).

Out of scope: other modernizations, e.g. replacing ParaGUI or converting C++ code to Swift.

## Acceptance criteria

- [ ] The application builds and links only against SDL3, SDL3_image and SDL3_mixer; no SDL2
      package remains in the vcpkg manifest (check with `grep -i sdl2 vcpkg.json`).
- [ ] The application starts on macOS 27, and a map can be loaded and played.
- [ ] Existing save games and maps can still be loaded.
- [ ] All automated tests pass.
- [ ] `doc/architecture.md` names SDL3 as the SDL version.

## History

<!--
  Log of all status changes, oldest first. Add a row for every change of the Status field.
  Timestamp format: ISO 8601 with time zone offset, e.g. 2026-11-11T14:30+0100
  (get it with: date +%Y-%m-%dT%H:%M%z).
  Comment: optional, but required for "waiting" and "aborted" (state the reason).
-->

| Timestamp                | Status | Comment       |
|--------------------------|--------|---------------|
| 2026-11-19T12:37+0100 | open   | Task created  |
