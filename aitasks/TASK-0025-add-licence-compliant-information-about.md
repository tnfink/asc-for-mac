# TASK-0025: Add licence-compliant information about all components

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0025 |
| **Short description** | Add licence-compliant information about all components |
| **Status**        | open <!-- One of: open, in-work, waiting, done, aborted -->   |
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

1. Check the licences of all components in the SBOM for what they require when the app is
   distributed in binary form (e.g. licence text, copyright notice, source code offer for
   GPL-2.0 and LGPL components), and whether they are compatible with distributing them
   together with ASC under GPL-2.0. Document the result in `doc/thirdparty.md`. Report
   conflicts or unclear cases to the user and do not resolve them on your own.
2. Decide the licence of the project's own code (`app/`, `facade/`, scripts) with the user,
   if it is not already decided, and add a licence file to the repository.
3. Create the licence information for users, generated from the SBOM and vcpkg's licence
   texts (`build/core/vcpkg_installed/arm64-osx-asc/share/<port>/copyright`) where possible:
   for every component its name, version, copyright notice and full licence text, and where
   the source code can be obtained (for GPL-2.0 and LGPL components).
4. Make the information available in the app (e.g. a file in the app bundle and a way to open
   it from the app's menu or the About window; decide the presentation with the user) and
   document it in `doc/buildAndTest.md`. The `.dmg` and the release notes of TASK-0014 can
   then refer to it.
5. Add tests for new scripts to `scripts/test.sh`, and automated tests for new app code.

Out of scope: legal advice; the AI documents the requirements as stated in the licences, and
the user decides in unclear cases. Signing and releasing the app (TASK-0014).

## Acceptance criteria

- [ ] `doc/thirdparty.md` lists for every licence in the SBOM what it requires for binary
      distribution and whether it is compatible with GPL-2.0; conflicts and unclear cases were
      reported to the user and the user's decisions are recorded.
- [ ] The repository contains a licence file for the project's own code, as decided by the user.
- [ ] The app bundle contains the licence information for every component in the SBOM (name,
      version, copyright notice, full licence text, source code location for GPL and LGPL
      components); a test or script check compares the components with the SBOM.
- [ ] The user can open the licence information from the app, as decided with the user
      (checked by the user).
- [ ] `scripts/test.sh`, `scripts/test-app.sh` and `scripts/check.sh` pass.

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
