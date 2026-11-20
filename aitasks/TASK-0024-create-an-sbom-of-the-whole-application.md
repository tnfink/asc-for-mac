# TASK-0024: Create an SBOM of the whole application

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0024 |
| **Short description** | Create an SBOM of the whole application |
| **Status**        | open <!-- One of: open, in-work, waiting, done, aborted -->   |
| **External link** | none |
| **Dependencies**  | TASK-0013 |

## Motivation

Part of handling the licence issues of asc-for-mac (user request). The app combines the ASC
core (GNU GPL version 2), the libraries bundled in ASC's source code, the libraries from vcpkg,
ASC's game data and the project's own Swift and C++ code. A Software Bill of Materials (SBOM)
of the whole application lists all these components with their versions, origins and licences.
It is the basis for the licence-compliant information about all components (TASK-0025) and
shows which components are affected when a library or ASC itself is updated.

## Task description

Create an SBOM of the whole application, i.e. of everything contained in the app bundle built
by `scripts/build.sh --release`.

Known facts:

- `doc/thirdparty.md` lists ASC (subtree in `thirdparty/asc/`, GPL-2.0, `COPYING`) and the
  libraries bundled in `thirdparty/asc/source/libs/` (SDL_sound, bzlib, ParaGUI, Loki,
  getopt, rand, revel, sdlmm, triangul), partly without a separate licence file.
- The libraries from vcpkg are listed in `vcpkg.json` (versions pinned by the
  `builtin-baseline`); their transitive dependencies are installed as well. vcpkg writes an
  SPDX file (`vcpkg.spdx.json`) and the licence text (`copyright`) for every installed port
  into `build/core/vcpkg_installed/arm64-osx-asc/share/<port>/`.
- The app bundle contains the game data `main.ascdat`, `asc2_dlg.zip` and `pbp.ascdat`
  (built from `thirdparty/asc/data/` and `extra-data/`), and later the music (TASK-0023).
- The project's own code is in `app/` and `facade/`.

To do:

1. Choose the SBOM format with the user (e.g. SPDX or CycloneDX, JSON) and record the
   decision in `doc/architecture.md`.
2. Create the SBOM with a script in `scripts/` that uses only the tools from
   `doc/developerInfrastructure.md` (e.g. Python reading vcpkg's SPDX files), so that it can
   be regenerated after every update of ASC or a library. Each component has at least its
   name, version, origin (URL) and licence (SPDX licence identifier where possible).
3. Components and data whose licence cannot be determined automatically (e.g. ASC's bundled
   libraries without a licence file, the game data) are added from a maintained list in the
   repository; unclear licences are marked as such and reported to the user.
4. Decide with the user whether build-only tools that are not part of the app (e.g. Xcode,
   CMake, vcpkg, the SwiftLint plugin) are listed in the SBOM.
5. Add tests for the script to `scripts/test.sh` and document how to create the SBOM in
   `doc/buildAndTest.md` and where it is stored.

Out of scope: the licence information shown to users and shipped with the app (TASK-0025),
resolving licence conflicts (reported to the user).

## Acceptance criteria

- [ ] The SBOM format is decided by the user and recorded in `doc/architecture.md`.
- [ ] A script in `scripts/` creates the SBOM; it is documented in `doc/buildAndTest.md` and
      tested in `scripts/test.sh`.
- [ ] The SBOM is valid JSON in the chosen format and lists every library installed by vcpkg
      for the app (compared with the ports in `build/core/vcpkg_installed/arm64-osx-asc/share/`),
      ASC, each library in `thirdparty/asc/source/libs/`, the game data and the project's own
      code, each with name, version, origin and licence.
- [ ] Components with an unclear licence are marked in the SBOM and were reported to the user.
- [ ] The user's decision about build-only tools is implemented and documented.

## History

<!--
  Log of all status changes, oldest first. Add a row for every change of the Status field.
  Timestamp format: ISO 8601 with time zone offset, e.g. 2026-11-11T14:30+0100
  (get it with: date +%Y-%m-%dT%H:%M%z).
  Comment: optional, but required for "waiting" and "aborted" (state the reason).
-->

| Timestamp                | Status | Comment       |
|--------------------------|--------|---------------|
| 2026-11-20T14:24+0100 | open   | Task created  |
