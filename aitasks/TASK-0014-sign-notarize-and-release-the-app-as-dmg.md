# TASK-0014: Sign, notarize and package the app as .dmg

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0014 |
| **Short description** | Sign, notarize and package the app as .dmg |
| **Status**        | done <!-- One of: open, in-work, waiting, done, aborted -->   |
| **External link** | none |
| **Dependencies**  | TASK-0010, TASK-0013, TASK-0025, TASK-0026 |

## Motivation

asc-for-mac is distributed as a download from GitHub, not through the App Store (see
`doc/context.md`). For macOS to open a downloaded app without security warnings, it must be
signed with an Apple Developer ID and notarized by Apple. TASK-0006 and TASK-0013 only sign the
app ad hoc for local use. This task covers signing, notarization and the `.dmg` as decided in
`doc/architecture.md` (section *Deployment and operation*). Publishing the `.dmg` as a GitHub
Release was split off into TASK-0029 in the review of this task (user decision).

## Task description

Known facts:

- The Apple Developer ID exists (TASK-0010, see `doc/context.md`, section *Operations,
  distribution and hosting*): Team ID `KYSS6YD767`, a "Developer ID Application" identity in
  the user's login keychain (`security find-identity -v -p codesigning`), bundle identifier
  `de.tofimusrom.ASCforMac`. TASK-0010 left setting the Team ID in the Xcode project to this
  task.
- The Xcode project signs ad hoc (`CODE_SIGN_IDENTITY = "-"`, `CODE_SIGN_STYLE = Manual`), has
  no entitlements file and does not enable the hardened runtime. The app's version is
  `MARKETING_VERSION = 2.6.99.0` (shown in About, checked by `AppTests`),
  `CURRENT_PROJECT_VERSION = 0`. `scripts/build.sh --release` builds the Release configuration.
- Version (user decision in the review of this task): macOS allows only digits and periods in
  the app's version (`CFBundleShortVersionString`), so the suffix for the Mac port appears only
  in the release tag, the release name and the `.dmg` file name, e.g. `2.6.99.0-mac1`. The app
  keeps `2.6.99.0` as version and gets the Mac counter as build number (`CFBundleVersion`,
  `CURRENT_PROJECT_VERSION = 1`), which About shows too.
- Tools: `codesign`, `xcrun notarytool` and `xcrun stapler` come with Xcode, `hdiutil` (for the
  `.dmg`) and `spctl` with macOS, so no tool beyond `doc/developerInfrastructure.md` is needed;
  mention them there under Xcode. Notarization needs a network connection and usually takes a
  few minutes. When `codesign` first uses the private key, macOS may ask for access to it in
  the keychain; the user confirms this dialog.

Following `doc/architecture.md`, section *Deployment and operation*:

1. **Signing:** sign the `.app` of the Release configuration with the Apple Developer ID from
   TASK-0010 (Team ID in the Xcode project for the Release configuration), with the hardened
   runtime enabled. Local Debug builds and the tests may keep the ad-hoc signature.
2. **Notarization:** notarize the app with Apple's `notarytool` and staple the ticket to the
   app. The notarization credentials are stored outside the repository in the keychain with
   `xcrun notarytool store-credentials`; the user runs this command (it asks for an
   app-specific password), e.g. with `! xcrun notarytool store-credentials …` in the session.
   The AI does not handle Apple credentials and never commits secrets such as passwords,
   certificates or private keys.
3. **Version:** set the build number as decided above and show it in About. The UI test
   checks the About window, so run `scripts/test-ui.sh` afterwards (ask the user first, it
   takes over mouse and keyboard).
4. **Package:** create a `.dmg` disk image named with the release version (e.g.
   `ASC-for-Mac-2.6.99.0-mac1.dmg`), containing the app and a link to the Applications folder;
   sign and notarize the `.dmg` too.
5. Make building, signing, notarizing and packaging reproducible with a single documented
   command, documented in `doc/buildAndTest.md`. If scripts in `scripts/` are created for this,
   add tests for them to `scripts/test.sh`. The `.dmg` is build output and is not committed.

Out of scope: publishing the `.dmg` as a GitHub Release, the source archive and the source
location in `scripts/licenses.json` (TASK-0029); automatic updates (e.g. Sparkle; decided
against in `doc/architecture.md`) and distribution through the App Store.

## Acceptance criteria

- [x] The app is signed with the Developer ID and the hardened runtime (check:
      `codesign --verify --deep --strict --verbose=2 <app>` succeeds and
      `codesign -d --verbose=2 <app>` shows the Developer ID authority with Team ID
      `KYSS6YD767` and the runtime flag).
- [x] The app is notarized and the ticket is stapled (check: `xcrun stapler validate <app>`
      succeeds and `spctl --assess --type execute --verbose <app>` reports "Notarized
      Developer ID").
- [x] The app's version is `2.6.99.0` with build number `1`, and About shows both (checked by
      a test).
- [x] The `.dmg` is named with the release version, contains the app and a link to the
      Applications folder, and is itself signed and notarized (check: `spctl --assess --type
      open --context context:primary-signature --verbose <dmg>` accepts it).
- [x] The app from the `.dmg` starts the game on the user's Mac without a security warning
      (checked by the user).
- [x] Building, signing, notarizing and packaging run with a single command documented in
      `doc/buildAndTest.md`; new scripts, if any, are tested in `scripts/test.sh`.
- [x] `scripts/test-app.sh`, `scripts/check.sh` and `scripts/test-ui.sh` pass.
- [x] No secrets are in the repository: `git grep -l -E 'BEGIN .*PRIVATE KEY' -- ':!aitasks'`
      finds nothing and `git ls-files '*.p12' '*.p8' '*.cer' '*.certSigningRequest'` lists
      nothing.

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
| 2026-11-24T16:27+0100 | in-work | Implementation started |
| 2026-11-24T16:46+0100 | done | All acceptance criteria and the Definition of Done are fulfilled |
