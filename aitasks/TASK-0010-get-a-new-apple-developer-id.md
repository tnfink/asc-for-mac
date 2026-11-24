# TASK-0010: Get a new Apple Developer ID

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0010 |
| **Short description** | Get a new Apple Developer ID |
| **Status**        | done <!-- One of: open, in-work, waiting, done, aborted -->   |
| **External link** | none |
| **Dependencies**  | none |

## Motivation

asc-for-mac is distributed as a download from a website, not through Apple's App Store (see
`doc/context.md`). For macOS to run a downloaded app without security warnings, the app must be
signed and notarized with an Apple Developer ID. The user decided in TASK-0004 that a new Apple
Developer ID will be needed. Without it, the app cannot be published properly. Signing and
notarizing (TASK-0014) also need the final bundle identifier of the app instead of the
placeholder `local.ascformac.ASCforMac`.

## Task description

The Apple Developer ID consists of a membership in the Apple Developer Program and a
"Developer ID Application" certificate (with its private key) in the user's keychain, which
signs the app (user decision in the review of this task).

1. Remind the user that a new Apple Developer ID is needed: the membership in the Apple
   Developer Program and the "Developer ID Application" certificate in the login keychain. The
   user registers and creates both with Apple; the AI cannot do this and does not handle any
   credentials or payment data.
2. Set the status to `waiting` with the reason "Waiting for the user to register the Apple
   Developer ID" until the user confirms that the Developer ID exists.
3. Check that the certificate is available for signing:
   `security find-identity -v -p codesigning` lists a valid identity
   "Developer ID Application: <name> (<Team ID>)". This shows no secrets.
4. Ask the user for the **Team ID** (10 characters; also shown in the identity in step 3) and
   record it in `doc/context.md` (section *Operations, distribution and hosting*) together with
   the fact that the Apple Developer ID exists (user decision in the review of this task: the
   Team ID is not secret, it is visible in every signed app). Do not record secrets such as
   passwords, certificates or private keys in the repository.
5. Ask the user for the final **bundle identifier** of the app (a reverse-DNS name, e.g. based
   on a domain or GitHub account the user owns; user decision in the review of this task:
   chosen together with the Developer ID). Replace the placeholder in all targets of
   `ASCforMac.xcodeproj` (`PRODUCT_BUNDLE_IDENTIFIER`, Debug and Release):
   `local.ascformac.ASCforMac` by the new identifier, and `local.ascformac.ASCforMacTests` and
   `local.ascformac.ASCforMacUITests` by the new identifier with the suffixes `Tests` and
   `UITests`. Record the bundle identifier in `doc/context.md` next to the Team ID.
6. Run `scripts/test-app.sh` and `scripts/check.sh` after the change of the bundle identifier,
   and `scripts/test-ui.sh` (tell the user before, it takes over mouse and keyboard).

Out of scope: signing and notarizing the app, and setting the Team ID in the Xcode project
(both TASK-0014).

## Acceptance criteria

- [x] The user has confirmed that the membership in the Apple Developer Program exists.
- [x] `security find-identity -v -p codesigning` lists a valid "Developer ID Application"
      identity.
- [x] `doc/context.md` states that the Apple Developer ID exists and names the Team ID and the
      bundle identifier.
- [x] `git grep -n "local\.ascformac" -- ':!thirdparty' ':!aitasks'` finds nothing; the Xcode
      project uses the new bundle identifier (with the suffixes `Tests` and `UITests` for the
      test targets).
- [x] `scripts/test-app.sh`, `scripts/check.sh` and `scripts/test-ui.sh` pass.
- [x] No secrets of the Apple Developer ID are in the repository:
      `git grep -l -E 'BEGIN .*PRIVATE KEY' -- ':!aitasks'` finds nothing (the task files
      contain the pattern itself), and
      `git ls-files '*.p12' '*.p8' '*.cer' '*.certSigningRequest'` lists nothing.

## History

<!--
  Log of all status changes, oldest first. Add a row for every change of the Status field.
  Timestamp format: ISO 8601 with time zone offset, e.g. 2026-11-11T14:30+0100
  (get it with: date +%Y-%m-%dT%H:%M%z).
  Comment: optional, but required for "waiting" and "aborted" (state the reason).
-->

| Timestamp                | Status | Comment       |
|--------------------------|--------|---------------|
| 2026-11-18T15:36+0100 | open   | Task created  |
| 2026-11-20T13:59+0100 | in-work | Implementation started |
| 2026-11-20T14:00+0100 | waiting | Waiting for the user to register the Apple Developer ID |
| 2026-11-24T16:10+0100 | in-work | Developer ID Application identity for team KYSS6YD767 is in the login keychain |
| 2026-11-24T16:18+0100 | done | All acceptance criteria and the Definition of Done are fulfilled |
