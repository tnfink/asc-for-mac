# TASK-0008: Copy all needed 3rd party artifacts into the repository

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0008 |
| **Short description** | Copy all needed 3rd party artifacts into the repository |
| **Status**        | open <!-- One of: open, in-work, waiting, done, aborted -->   |
| **External link** | none |
| **Dependencies**  | TASK-0007 |

## Motivation

asc-for-mac ports the existing open-source game Advanced Strategic Command (ASC). The port
needs the original ASC source code, including its bundled libraries, and its maps, graphics and
campaigns. This information is only used at build time. So that the build does not rely on
external websites for which it is not clear how they are funded, the ASC code and data are
copied into the repository. The other libraries ASC uses are provided by vcpkg at build time
and are not copied (see `doc/architecture.md`, decided in TASK-0005). This is the first step
of the implementation, after all initialization tasks (TASK-0001 to TASK-0007) are done.

## Task description

1. Add the ASC repository <https://github.com/ValHaris/asc-hq> (branch `master`) to
   `thirdparty/asc/` with `git subtree`, as decided in `doc/architecture.md` (section
   *Location of the 3rd party artifacts*). This includes the ASC source code, its bundled
   libraries (`source/libs`), its game data (`data/`, `extra-data/`) and its license files.
2. Do not copy the libraries provided by vcpkg (SDL2, SDL2_image, SDL2_mixer, Lua, libsigc++,
   FreeType, Boost, Expat, bzip2, libpng, PhysFS, fmt) into the repository.
3. Document the 3rd party artifacts in `doc/thirdparty.md`: for the ASC subtree its origin
   (URL), branch, commit and license; for each library provided by vcpkg its name and
   license. Describe how the subtree is updated from upstream with `git subtree pull`.
4. Make the build use the ASC code and data from `thirdparty/asc/` instead of downloading them
   from external sources.

Out of scope: changing the copied ASC source code for the port.

## Acceptance criteria

- [ ] `thirdparty/asc/` contains the ASC source code, its bundled libraries and its game data,
      added with `git subtree` (check: `git log --oneline -- thirdparty/asc` shows the subtree
      commit, and `thirdparty/asc/source`, `thirdparty/asc/data` and
      `thirdparty/asc/extra-data` exist).
- [ ] The license files of ASC (e.g. `thirdparty/asc/COPYING`) are in the repository.
- [ ] None of the libraries provided by vcpkg is copied into the repository outside
      `thirdparty/asc/`.
- [ ] `doc/thirdparty.md` lists the ASC subtree with origin, branch, commit and license, the
      libraries provided by vcpkg with their licenses, and describes how to update the subtree.
- [ ] The build configuration does not download the ASC code or data from external sources
      (check by inspecting the build configuration).
- [ ] The repository layout in `AGENTS.md` describes `thirdparty/`.

## History

<!--
  Log of all status changes, oldest first. Add a row for every change of the Status field.
  Timestamp format: ISO 8601 with time zone offset, e.g. 2026-11-11T14:30+0100
  (get it with: date +%Y-%m-%dT%H:%M%z).
  Comment: optional, but required for "waiting" and "aborted" (state the reason).
-->

| Timestamp                | Status | Comment       |
|--------------------------|--------|---------------|
| 2026-11-18T14:09+0100 | open   | Task created  |
