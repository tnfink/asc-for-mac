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
needs 3rd party artifacts: the original ASC source code, the libraries it uses, and its maps,
graphics and campaigns. This information is only used at build time. To minimize the
dependencies, all needed artifacts are copied into the repository, so the build does not
depend on external sources being available. This is the first step of the implementation,
after all initialization tasks (TASK-0001 to TASK-0007) are done.

## Task description

1. Determine which 3rd party artifacts are needed, based on `doc/context.md` (3rd party
   systems) and `doc/architecture.md`. These include at least:
   - the original ASC source code (see <https://www.asc-hq.org>),
   - the libraries ASC uses that are still needed by the decided architecture,
   - the maps, graphics and campaigns of ASC.
2. Copy all needed artifacts into the repository. Use the location for 3rd party artifacts
   decided in `doc/architecture.md`; if no location is decided there, propose one to the user
   and let the user decide.
3. Keep the license files that come with the artifacts.
4. Document the copied artifacts in `doc/`: for each artifact its origin (URL), its version and
   its license.
5. Make the build use the copied artifacts instead of downloading them from external sources.

Out of scope: changing the copied ASC source code for the port.

## Acceptance criteria

- [ ] The original ASC source code is in the repository at the decided location.
- [ ] All libraries and data (maps, graphics, campaigns) that the build of asc-for-mac needs
      from 3rd parties are in the repository.
- [ ] The license files of the copied artifacts are in the repository next to the artifacts.
- [ ] A document in `doc/` lists every copied artifact with its origin (URL), version and
      license.
- [ ] The build configuration does not download any of the copied artifacts from external
      sources (check by inspecting the build configuration).
- [ ] The repository layout in `AGENTS.md` describes the location of the 3rd party artifacts.

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
