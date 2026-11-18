# TASK-0010: Get a new Apple Developer ID

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0010 |
| **Short description** | Get a new Apple Developer ID |
| **Status**        | open <!-- One of: open, in-work, waiting, done, aborted -->   |
| **External link** | none |
| **Dependencies**  | none |

## Motivation

asc-for-mac is distributed as a download from a website, not through Apple's App Store (see
`doc/context.md`). For macOS to run a downloaded app without security warnings, the app must be
signed and notarized with an Apple Developer ID. The user decided in TASK-0004 that a new Apple
Developer ID will be needed. Without it, the app cannot be published properly.

## Task description

1. Remind the user that a new Apple Developer ID is needed. The user registers it with Apple;
   the AI cannot do this and does not handle any credentials or payment data.
2. Set the status to `waiting` with the reason "Waiting for the user to register the Apple
   Developer ID" until the user confirms that the Developer ID exists.
3. Record in `doc/context.md` (section on operations, distribution and hosting) that the Apple
   Developer ID exists. Do not record secrets such as passwords, certificates or private keys
   in the repository.

Out of scope: signing and notarizing the app.

## Acceptance criteria

- [ ] The user has confirmed that the new Apple Developer ID exists.
- [ ] `doc/context.md` states that the Apple Developer ID exists.
- [ ] No secrets (passwords, certificates, private keys) of the Apple Developer ID are in the
      repository (check with `git grep -i -E 'password|BEGIN .*PRIVATE KEY'`).

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
