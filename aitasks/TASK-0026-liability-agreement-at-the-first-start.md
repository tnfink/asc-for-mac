# TASK-0026: Liability agreement at the first start of the app

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0026 |
| **Short description** | Liability agreement at the first start of the app |
| **Status**        | open <!-- One of: open, in-work, waiting, done, aborted -->   |
| **External link** | none |
| **Dependencies**  | TASK-0025 |

## Motivation

User request: "to ensure that I will never need to pay anything if something with the
application wents wrong, the user should sign an agreements at the first start of the
application that she will never sue me for any problems and accept the application as it is."

asc-for-mac is distributed as a free download (see `doc/context.md`). The developer wants to
be protected against claims of the users if something goes wrong with the app (e.g. lost save
games or other damage). So users explicitly accept the app as it is before they use it.

## Task description

At the first start of the app, show an agreement that the user has to accept before the app
can be used. In the agreement the user agrees that they will never sue the developer for any
problems with the app and that they accept the app as it is.

1. **Wording:** the user (the developer) provides or approves the exact text of the agreement;
   the AI may propose a draft but must not decide the wording. Ask the user before
   implementing the window.
2. **Fit with the licences:** the app is distributed under GPL-2.0-or-later (TASK-0025,
   `doc/thirdparty.md`, section *Licence analysis*). The GPL already disclaims warranty and
   liability (sections 11 and 12) and forbids imposing further restrictions on the recipients'
   rights to copy, distribute and modify the program (section 6). Check the drafted text against
   this and report possible conflicts to the user; the user decides (no legal advice by the AI;
   whether such an agreement is legally effective is for the user to clarify, e.g. with a
   lawyer). Record the decision in `doc/architecture.md`.
3. **First start:** show the agreement in a SwiftUI window before the game starts (see
   `AppDelegate.swift`, `Game.swift`). With "Accept", the acceptance is stored (e.g. in
   `UserDefaults`, see `doc/architecture.md`, *Data storage*) and the game starts; on later
   starts the agreement is not shown again. With "Decline" (or closing the window), the app
   quits without starting the game.
4. **Tests:** unit tests for the logic (shown only when not yet accepted, accepted state is
   stored) and an extension of the UI test (`app/ASCforMacUITests/`); the UI test and the unit
   tests must not depend on or change the developer's stored acceptance (e.g. via a launch
   argument, like `--no-game`).
5. Document the behaviour in `doc/buildAndTest.md` (how to reset the acceptance for testing).

Out of scope: legal advice; showing the agreement again after updates of the text (propose a
follow-up task if needed).

## Acceptance criteria

- [ ] The text of the agreement was provided or approved by the user, and the user's decision
      on possible conflicts with the GPL is recorded in `doc/architecture.md`.
- [ ] At the first start, the app shows the agreement before the game starts; the game starts
      only after "Accept" (checked by a test and by the user).
- [ ] "Decline" or closing the window quits the app without starting the game (checked by a
      test).
- [ ] After accepting, the agreement is not shown on the next start (checked by a test).
- [ ] `scripts/test-app.sh`, `scripts/test-ui.sh`, `scripts/check.sh` and
      `scripts/test-coverage.sh` pass.

## History

<!--
  Log of all status changes, oldest first. Add a row for every change of the Status field.
  Timestamp format: ISO 8601 with time zone offset, e.g. 2026-11-11T14:30+0100
  (get it with: date +%Y-%m-%dT%H:%M%z).
  Comment: optional, but required for "waiting" and "aborted" (state the reason).
-->

| Timestamp                | Status | Comment       |
|--------------------------|--------|---------------|
| 2026-11-21T16:26+0100 | open   | Task created  |
