# TASK-0008: Add the ASC code and data to the repository with git subtree

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0008 |
| **Short description** | Add the ASC code and data to the repository with git subtree |
| **Status**        | in-work <!-- One of: open, in-work, waiting, done, aborted -->   |
| **External link** | none |
| **Dependencies**  | TASK-0005 |

## Motivation

asc-for-mac ports the existing open-source game Advanced Strategic Command (ASC). The port
needs the original ASC source code, including its bundled libraries, and its maps, graphics and
campaigns. This information is only used at build time. So that the build does not rely on
external websites for which it is not clear how they are funded, the ASC code and data are
copied into the repository. The other libraries ASC uses are provided by vcpkg at build time
and are not copied (see `doc/architecture.md`, decided in TASK-0005). This task is done before
TASK-0006, because the build created there compiles the ASC core from `thirdparty/asc/`.

## Task description

1. Add the ASC repository <https://github.com/ValHaris/asc-hq> (branch `master`) to
   `thirdparty/asc/` with `git subtree add`, as decided in `doc/architecture.md` (section
   *Location of the 3rd party artifacts*). Keep ASC's full history: do not use `--squash`
   (this adds about 290 MB to the repository). This includes the ASC source code, its bundled
   libraries (`source/libs`), its game data (`data/`, `extra-data/`) and its license files.
2. Do not copy the libraries provided by vcpkg (SDL2, SDL2_image, SDL2_mixer, Lua, libsigc++,
   FreeType, Boost, Expat, bzip2, libpng, PhysFS, fmt) into the repository.
3. Document the 3rd party artifacts in `doc/thirdparty.md`: for the ASC subtree its origin
   (URL), branch, commit and license; for each library provided by vcpkg its name and
   license. Describe how the subtree is updated from upstream with `git subtree pull` (also
   without `--squash`).
4. Add `thirdparty/` to the repository layout in `AGENTS.md`, and note in
   `doc/developerInfrastructure.md` that the project uses `git subtree`, which is part of Git.

Out of scope:
- changing the copied ASC source code for the port,
- building the ASC code: the build created in TASK-0006 compiles the ASC core from
  `thirdparty/asc/` without downloading it.

## Acceptance criteria

- [ ] `thirdparty/asc/` contains the ASC source code, its bundled libraries and its game data
      (check: `thirdparty/asc/source`, `thirdparty/asc/data` and `thirdparty/asc/extra-data`
      exist).
- [ ] The ASC code was added with `git subtree` and its full history (check: `git log --oneline
      -- thirdparty/asc` shows the subtree commit, and `git cat-file -e <ASC commit>^{commit}`
      succeeds for the ASC commit recorded in `doc/thirdparty.md`).
- [ ] The license files of ASC (e.g. `thirdparty/asc/COPYING`) are in the repository.
- [ ] None of the libraries provided by vcpkg is copied into the repository outside
      `thirdparty/asc/`.
- [ ] `doc/thirdparty.md` lists the ASC subtree with origin, branch, commit and license, the
      libraries provided by vcpkg with their licenses, and describes how to update the subtree.
- [ ] The repository layout in `AGENTS.md` describes `thirdparty/`.
- [ ] `doc/developerInfrastructure.md` mentions that the project uses `git subtree`.

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
| 2026-11-19T13:54+0100 | in-work | Implementation started |
