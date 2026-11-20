# TASK-0024: Create an SBOM of the whole application

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0024 |
| **Short description** | Create an SBOM of the whole application |
| **Status**        | done <!-- One of: open, in-work, waiting, done, aborted -->   |
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

Decisions of the user (review of this task):

- **Format:** SPDX 2.3, JSON. vcpkg already writes an SPDX 2.3 file for each library.
- **Content:** only what is part of the app. Build-only tools (Xcode, CMake, vcpkg, the
  SwiftLint plugin) are not listed; they are documented in `doc/developerInfrastructure.md`.
  Apple's system frameworks, which the app uses but does not contain, are not listed either.
- **Storage:** the SBOM is committed to the repository as `doc/sbom.spdx.json` and regenerated
  by the script after every update of ASC or a library; a check fails if it is out of date.

Known facts:

- `doc/thirdparty.md` lists ASC (subtree in `thirdparty/asc/`, GPL-2.0, `COPYING`) and the
  libraries bundled in `thirdparty/asc/source/libs/` (SDL_sound, bzlib, ParaGUI, Loki,
  getopt, rand, revel, sdlmm, triangul), partly without a separate licence file.
- The libraries from vcpkg are listed in `vcpkg.json` (versions pinned by the
  `builtin-baseline`); their transitive dependencies are installed as well. The installed ports
  are listed in `build/core/vcpkg_installed/vcpkg/info/` (one `<port>_<version>_<triplet>.list`
  per port). vcpkg writes an SPDX file (`vcpkg.spdx.json`) and the licence text (`copyright`)
  for every installed port into `build/core/vcpkg_installed/arm64-osx-asc/share/<port>/`.
  Note: `share/` also contains directories that are not ports (e.g. CMake config directories
  such as `SDL2_image`), so take the port list from `vcpkg/info/`.
- The ports `vcpkg-cmake`, `vcpkg-cmake-config` and `vcpkg-boost` are build helpers of vcpkg
  and not part of the app. The other ports are part of the app: as static libraries linked
  into `libasc_all.a` (list `ASC_VCPKG_LIBS` in `facade/CMakeLists.txt`) or as header-only
  libraries compiled into the code (e.g. most Boost ports). List every installed port except
  the build helpers; do not try to prove for each port whether its code ends up in the binary.
- The app bundle contains the game data `main.ascdat`, `asc2_dlg.zip` and `pbp.ascdat`
  (built from `thirdparty/asc/data/` and `extra-data/`, see `core/CMakeLists.txt`). The music
  is added by TASK-0023; whichever of the two tasks is done later adds it to the SBOM.
- The project's own code is in `app/` and `facade/`.

To do:

1. Record the decisions above in `doc/architecture.md`.
2. Write a script in `scripts/` (e.g. `scripts/create-sbom.sh`, which may call Python) that
   uses only the tools from `doc/developerInfrastructure.md`. It reads vcpkg's SPDX files and
   writes `doc/sbom.spdx.json`. Each component (SPDX package) has at least its name, version,
   origin (download location or homepage) and licence (SPDX licence identifier where
   possible). The output is deterministic (sorted, no timestamps that change on every run
   unless the content changes), so that the committed file only changes when components
   change.
3. Components and data whose licence cannot be determined automatically (ASC, its bundled
   libraries, the game data, the project's own code) are added from a maintained list in the
   repository (e.g. a file next to the script). Unclear licences are marked with
   `NOASSERTION` and reported to the user.
4. The script has an option `--check` that fails if `doc/sbom.spdx.json` differs from what it
   would generate; `scripts/check.sh` runs it.
5. Add tests for the script to `scripts/test.sh` and document how to create and check the SBOM
   in `doc/buildAndTest.md`.

Out of scope: the licence information shown to users and shipped with the app (TASK-0025),
resolving licence conflicts (reported to the user).

## Acceptance criteria

- [x] The decisions about format, content and storage are recorded in `doc/architecture.md`.
- [x] `doc/sbom.spdx.json` exists, is valid JSON and has the SPDX 2.3 document fields
      (`spdxVersion` "SPDX-2.3", `dataLicense`, `SPDXID`, `name`, `documentNamespace`,
      `creationInfo`, `packages`).
- [x] The SBOM has one package for every port in `build/core/vcpkg_installed/vcpkg/info/`
      except vcpkg's helper ports `vcpkg-cmake`, `vcpkg-cmake-config`, `vcpkg-boost`,
      `boost-cmake` and `boost-uninstall`, and one package each for ASC, every library in
      `thirdparty/asc/source/libs/` that is compiled into the app, the game data and the
      project's own code; each package has name, version, origin and licence (or
      `NOASSERTION`). (Changed during implementation with the user's consent: `boost-cmake` and
      `boost-uninstall` contain only CMake files, and `bzlib`, `revel` and the old `sdl_sound`
      are not compiled into the app.)
- [x] Build-only tools are not in the SBOM.
- [x] Packages with unclear licence are marked with `NOASSERTION` and were reported to the user.
- [x] Running the script twice without changes leaves `doc/sbom.spdx.json` unchanged
      (`git diff --exit-code`), and `scripts/check.sh` fails when the SBOM is out of date.
- [x] The script is documented in `doc/buildAndTest.md` and tested in `scripts/test.sh`;
      `scripts/test.sh` and `scripts/check.sh` pass.

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
| 2026-11-20T14:34+0100 | in-work | Implementation started |
| 2026-11-20T14:43+0100 | done | All acceptance criteria and the Definition of Done are fulfilled |
