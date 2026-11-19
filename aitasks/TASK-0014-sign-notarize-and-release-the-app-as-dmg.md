# TASK-0014: Sign, notarize and release the app as .dmg on GitHub

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0014 |
| **Short description** | Sign, notarize and release the app as .dmg on GitHub |
| **Status**        | open <!-- One of: open, in-work, waiting, done, aborted -->   |
| **External link** | none |
| **Dependencies**  | TASK-0010, TASK-0013 |

## Motivation

asc-for-mac is distributed as a download from GitHub, not through the App Store (see
`doc/context.md`). For macOS to open a downloaded app without security warnings, it must be
signed with an Apple Developer ID and notarized by Apple. TASK-0006 and TASK-0013 only sign the
app ad hoc for local use. This task covers signing, notarization and the `.dmg` release as
decided in `doc/architecture.md` (section *Deployment and operation*), so that users can
download and run the first playable version. It needs the Apple Developer ID (TASK-0010) and
the first playable Mac version (TASK-0013).

## Task description

Following `doc/architecture.md`, section *Deployment and operation*:

1. **Signing:** sign the `.app` with the Apple Developer ID from TASK-0010, with the hardened
   runtime enabled.
2. **Notarization:** notarize the app with Apple's `notarytool` and staple the ticket to the
   app. Store the notarization credentials outside the repository (e.g. in the keychain with
   `xcrun notarytool store-credentials`); never commit secrets such as passwords, certificates
   or private keys.
3. **Package:** create a `.dmg` disk image containing the app and a link to the Applications
   folder.
4. **Release:** publish the `.dmg` as a GitHub Release of the project's repository, with
   release notes. The version number follows ASC's version plus a suffix for the Mac port,
   e.g. `2.6.99.0-mac1`. If the repository has no GitHub remote yet, ask the user. If a tool
   that is not listed in `doc/developerInfrastructure.md` is needed (e.g. the GitHub CLI
   `gh`), add it there first.
5. Make building, signing, notarizing and packaging reproducible with a single documented
   command, documented in `doc/buildAndTest.md`. If scripts in `scripts/` are created for this,
   add tests for them to `scripts/test.sh`.

Out of scope: automatic updates (e.g. Sparkle; decided against in `doc/architecture.md`) and
distribution through the App Store.

## Acceptance criteria

- [ ] The app is signed with the Developer ID and the hardened runtime (check:
      `codesign --verify --deep --strict --verbose=2 <app>` succeeds and
      `codesign -d --verbose=2 <app>` shows the Developer ID authority and the runtime flag).
- [ ] The app is notarized and the ticket is stapled (check: `xcrun stapler validate <app>`
      succeeds and `spctl --assess --type execute --verbose <app>` reports "Notarized
      Developer ID").
- [ ] The `.dmg` contains the app and a link to the Applications folder, and the `.dmg` itself
      is signed and notarized (check: `spctl --assess --type open --context
      context:primary-signature --verbose <dmg>` accepts it).
- [ ] A GitHub Release with a version like `2.6.99.0-mac1`, release notes and the `.dmg` as
      download exists in the project's repository.
- [ ] Building, signing, notarizing and packaging run with a single command documented in
      `doc/buildAndTest.md`.
- [ ] No secrets are in the repository (check with
      `git grep -i -E 'password|BEGIN .*PRIVATE KEY'`).

## History

<!--
  Log of all status changes, oldest first. Add a row for every change of the Status field.
  Timestamp format: ISO 8601 with time zone offset, e.g. 2026-11-11T14:30+0100
  (get it with: date +%Y-%m-%dT%H:%M%z).
  Comment: optional, but required for "waiting" and "aborted" (state the reason).
-->

| Timestamp                | Status | Comment       |
|--------------------------|--------|---------------|
| 2026-11-19T14:04+0100 | open   | Task created  |
