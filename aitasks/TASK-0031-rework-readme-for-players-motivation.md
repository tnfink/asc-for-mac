# TASK-0031: Rework README for players: motivation, install, start

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0031 |
| **Short description** | Rework README for players: motivation, install, start |
| **Status**        | done <!-- One of: open, in-work, waiting, done, aborted -->   |
| **External link** | none |
| **Dependencies**  | TASK-0014 |

## Motivation

The `README.md` is the first page visitors of the repository see. Today it describes the
project's domain, features, licence and development process, but it does not tell a player why
this port exists or how to get the game running. A README that motivates the port of the game
and gives a short introduction on how to install and start it helps players to try ASC on the
Mac. It should also mention that the app was built with Claude using the project template
<https://github.com/tnfink/ai-assisted-project-template>, which shows how the project was made.

## Task description

User request: "create a readme, that motivates this port of the game, gives a short
introduction on how to install and start it, and mention that it was built with Claude using
this project template: https://github.com/tnfink/ai-assisted-project-template".

Rework the existing top-level `README.md` (it is not replaced by a second file):

1. **Motivation:** why this port of the game exists: ASC is an existing open-source strategy
   game (<https://www.asc-hq.org>), and there is no macOS version of it so far (see the current
   sections *Domain*, *Problems solved* and *Features* and `doc/context.md`).
2. **Install and start:** a short introduction for players: download the `.dmg` from the
   project's GitHub Releases page (`ASC-for-Mac-<version>.dmg`, e.g.
   `ASC-for-Mac-2.6.99.0-mac1.dmg`), open it, drag the app to the Applications folder (in the
   `.dmg` it is the file `ASCforMac.app`, shown as "ASCforMac" in Finder, next to a link to
   Applications), start it, and what happens at the first start (macOS asks once whether to open an app downloaded
   from the internet; the licence agreement of TASK-0026; then the game starts). Give the
   system requirements (macOS 27 on Apple Silicon, see `doc/architecture.md`). Base the steps on
   the real `.dmg` of TASK-0014 (`scripts/create-dmg.sh`, see `doc/buildAndTest.md`, *Release
   package*). The repository has no GitHub remote yet; TASK-0029 publishes the first release.
   If the URL of the Releases page is not known when implementing, ask the user.
3. **Built with Claude:** mention that the app was built with Claude using the project
   template <https://github.com/tnfink/ai-assisted-project-template>.
4. Keep the existing information that is still correct (features, licence, development with
   the task workflow), shortened or moved further down where it helps the reader. Keep the
   sections *Domain*, *Problems solved* and *Features* under these names: `AGENTS.md`,
   `doc/context.md`, `doc/qualityobjectives.md`, `doc/architecture.md` and
   `doc/swDevelopmentProcess.md` refer to the README for the domain, problems and features.

Out of scope: publishing the release (TASK-0029) and the app icon (TASK-0030).

## Acceptance criteria

- [x] `README.md` has a section that motivates the port of ASC to the Mac.
- [x] `README.md` has a short introduction on how to install and start the app, matching the
      real `.dmg` (name, content) and the first start (question of macOS, licence agreement),
      with the system requirements and a link to the project's GitHub Releases page.
- [x] `README.md` mentions that the app was built with Claude using
      <https://github.com/tnfink/ai-assisted-project-template> (check: `grep -n
      "ai-assisted-project-template" README.md`).
- [x] The sections *Domain*, *Problems solved*, *Features*, *License* and *Development* of the
      current `README.md` are still present (check: `grep -n "^## " README.md`) and correct.

## History

<!--
  Log of all status changes, oldest first. Add a row for every change of the Status field.
  Timestamp format: ISO 8601 with time zone offset, e.g. 2026-11-11T14:30+0100
  (get it with: date +%Y-%m-%dT%H:%M%z).
  Comment: optional, but required for "waiting" and "aborted" (state the reason).
-->

| Timestamp                | Status | Comment       |
|--------------------------|--------|---------------|
| 2026-11-24T16:49+0100 | open   | Task created  |
| 2026-11-24T17:09+0100 | in-work | Implementation started |
| 2026-11-24T17:11+0100 | done | All acceptance criteria and the Definition of Done are fulfilled |
