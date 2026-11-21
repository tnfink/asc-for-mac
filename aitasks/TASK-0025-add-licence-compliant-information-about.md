# TASK-0025: Add licence-compliant information about all components

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0025 |
| **Short description** | Add licence-compliant information about all components |
| **Status**        | done <!-- One of: open, in-work, waiting, done, aborted -->   |
| **External link** | none |
| **Dependencies**  | TASK-0024 |

## Motivation

Part of handling the licence issues of asc-for-mac (user request). asc-for-mac distributes the
ASC core (GNU GPL version 2) together with many libraries in one app bundle as a download
(see `doc/context.md`). Their licences require that the users get the licence texts, the
copyright notices and, for the GPL and LGPL, access to the corresponding source code. Without
this information the app must not be distributed (TASK-0014).

## Task description

Add licence-compliant information about all used components, based on the SBOM from TASK-0024.

Decisions of the user (review of this task):

- **Licence of the project's own code** (`app/`, `facade/`, `scripts/`, `core/`, `cmake/`):
  **GPL-2.0-or-later**, the same as ASC's source files.
- **Presentation:** a menu item "Licenses…" in the app menu opens a SwiftUI window with the
  list of components on the left and the selected component's licence information on the
  right.
- The task is not split.

Current state (TASK-0024):

- `doc/sbom.spdx.json` (SPDX 2.3, created by `scripts/create-sbom.sh` from vcpkg's SPDX files
  and `scripts/sbom-components.json`) lists 76 packages. Their licences: BSL-1.0 (44 Boost
  ports), Zlib, MIT, BSD-2-Clause, BSD-3-Clause, IJG, libpng-2.0, bzip2-1.0.6, CC0-1.0,
  FTL OR GPL-2.0-or-later (FreeType), GPL-2.0-or-later (ASC, getopt, SDLmm),
  LGPL-2.0-or-later (ParaGUI), LGPL-2.1-or-later (libsigc++, mpg123, rand_r),
  LGPL-2.1-only OR Artistic-1.0-Perl (TiMidity), `LicenseRef-Loki`,
  `LicenseRef-PublicDomain-libmodplug`.
- `NOASSERTION` (unclear, see `doc/thirdparty.md`, section *SBOM*): the ASC game data, triangul,
  the project's own code and the app as a whole.
- vcpkg's licence texts are in
  `build/core/vcpkg_installed/arm64-osx-asc/share/<port>/copyright`. Licence texts of the
  bundled libraries are partly in `thirdparty/asc/` (e.g. `COPYING`,
  `source/libs/SDL_sound-2.0.4/LICENSE.txt`, `src/timidity/COPYING*`), partly only in the
  source file headers.

To do:

1. **Licence analysis:** check the licences of all components in the SBOM for what they
   require when the app is distributed in binary form (e.g. licence text, copyright notice,
   source code offer for GPL-2.0 and LGPL components; for the LGPL libraries, which are linked
   statically, how users can relink them, e.g. through the published source code of the whole
   app), and whether they are compatible with distributing them together with ASC under
   GPL-2.0-or-later. Document the result in `doc/thirdparty.md`. Report conflicts and the
   unclear cases (ASC game data, triangul) to the user and record the user's decisions; do not
   resolve them on your own.
2. **Own licence:** add `LICENSE` at the repository root with the text of the GPL version 2
   (as in `thirdparty/asc/COPYING`), state the licence in `README.md`, set the licence of the
   project's own code and of the app as a whole in `scripts/sbom-components.json` (the app's
   licence as found in step 1) and regenerate `doc/sbom.spdx.json`.
3. **Licence information for users:** generate it with a script in `scripts/` from the SBOM,
   vcpkg's licence texts and licence texts kept in the repository: for every package in the
   SBOM its name, version, copyright notice, full licence text, and, for GPL and LGPL
   components, where the source code can be obtained (for the app: the repository at the
   release's tag). Licence texts that are neither in vcpkg's `copyright` files nor in
   `thirdparty/asc/` are committed to the repository (e.g. `thirdparty/licenses/`). The build
   copies the generated information into the app bundle (e.g. as a build phase like "Copy ASC
   game data").
4. **Window in the app:** add the menu item "Licenses…" and the SwiftUI window (see decisions
   above), reading the information from the app bundle. Extend the UI test
   (`app/ASCforMacUITests/`) to open the window, and add unit tests for the new app code.
5. Document the licence information, the script and how to update it in
   `doc/buildAndTest.md`. The `.dmg` and the release notes of TASK-0014 can then refer to it.
6. Add tests for new scripts to `scripts/test.sh`.

If the music (TASK-0023) is added before this task is done, it is covered like every other
package of the SBOM.

Out of scope: legal advice; the AI documents the requirements as stated in the licences, and
the user decides in unclear cases. Signing and releasing the app (TASK-0014).

## Acceptance criteria

- [x] `doc/thirdparty.md` lists for every licence in the SBOM what it requires for binary
      distribution and whether it is compatible with GPL-2.0-or-later; conflicts and the
      unclear cases (ASC game data, triangul) were reported to the user and the user's
      decisions are recorded.
- [x] `LICENSE` at the repository root contains the GPL version 2, and `README.md` states that
      the project's own code is licensed under GPL-2.0-or-later.
- [x] In `doc/sbom.spdx.json`, the project's own code is `GPL-2.0-or-later` and the app has the
      licence found in the analysis; `scripts/create-sbom.sh --check` passes.
- [x] The app bundle contains the licence information for every package in the SBOM (name,
      version, copyright notice, full licence text, source code location for GPL and LGPL
      components); a test compares the packages in the information with the SBOM.
- [x] The app menu has "Licenses…", which opens the licence window (checked by the UI test and
      by the user).
- [x] `scripts/test.sh`, `scripts/test-app.sh`, `scripts/test-ui.sh`, `scripts/check.sh` and
      `scripts/test-coverage.sh` pass (a new coverage baseline only with the user's consent).

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
| 2026-11-20T19:27+0100 | in-work | Implementation started |
| 2026-11-21T16:26+0100 | waiting | Waiting for the user to check the Licenses window |
| 2026-11-21T16:46+0100 | done | All acceptance criteria and the Definition of Done are fulfilled |
