# TASK-0029: Publish the first release on GitHub

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0029 |
| **Short description** | Publish the first release on GitHub |
| **Status**        | open <!-- One of: open, in-work, waiting, done, aborted -->   |
| **External link** | none |
| **Dependencies**  | TASK-0014, TASK-0017 |

## Motivation

asc-for-mac is distributed as a download from GitHub, not through the App Store (see
`doc/context.md`). TASK-0014 creates the signed and notarized `.dmg`; this task publishes it as
the first GitHub Release, so that users can download and run the first playable version. It
was split off from TASK-0014 in its review (user decision), because the repository has no
GitHub remote yet and publishing is a separate, outward-facing step. The release must also
fulfil the licences of the components (TASK-0025).

## Task description

Following `doc/architecture.md`, section *Deployment and operation*:

Known facts:

- The repository has no git remote yet (`git remote -v` lists nothing). Publishing a release
  and pushing the repository are outward-facing actions; do them only after the user has
  confirmed.
- The version is decided (user decision in the review of TASK-0014): the release tag, the
  release name and the `.dmg` file name use ASC's version plus a suffix for the Mac port, e.g.
  `2.6.99.0-mac1`; the app itself keeps `2.6.99.0` as version and the Mac counter as build
  number (set up in TASK-0014).
- The long-game test (QA measure S3, `scripts/test-long-game.sh`) runs for every release
  (user decision, see `doc/qameasures.md`).

1. **Repository:** ask the user for the GitHub repository (owner and name) and whether it
   exists already; add it as git remote and push the repository with the user's consent. If a
   tool that is not listed in `doc/developerInfrastructure.md` is needed (e.g. the GitHub CLI
   `gh`), add it there first. The GitHub login is done by the user (e.g. `gh auth login`); the
   AI does not handle credentials.
2. **Source code location:** replace the placeholder source location of the app and the own
   code in `scripts/licenses.json` ("The asc-for-mac repository at the tag of this release …")
   with the repository's URL, and create the `.dmg` with TASK-0014's command afterwards, so that
   the app's licence window shows it.
3. **Checks before the release:** run the automated tests (`scripts/test-app.sh`), the static
   check (`scripts/check.sh`) and the long-game test (`scripts/test-long-game.sh`); they must
   pass.
4. **Source code for the licences** (decision of the user in TASK-0025, see
   `doc/thirdparty.md`, section *Licence analysis*): GPL-2.0 §3 and LGPL §6a require the
   complete corresponding source code from the same place as the binary. The tag of the
   release contains the own code and ASC, but not the library sources vcpkg downloads.
   Therefore attach to the release a source archive of the vcpkg library sources the app was
   built from (e.g. from vcpkg's download directory, at least of all ports in the SBOM), and
   refer to the tag and the archive in the release notes.
5. **Release:** tag the commit the `.dmg` was built from with the release version and publish
   the `.dmg` and the source archive as a GitHub Release of the repository, with release notes
   that refer to the tag, the source archive and the licence window (*ASC for Mac ›
   Licenses…*, see `doc/buildAndTest.md`).
6. Document the release procedure (steps, commands, version scheme) in `doc/buildAndTest.md`.
   If scripts in `scripts/` are created for it, add tests for them to `scripts/test.sh`.

Out of scope: signing, notarizing and the `.dmg` (TASK-0014), automatic updates (decided
against in `doc/architecture.md`), distribution through the App Store, and continuous
integration (TASK-0021).

## Acceptance criteria

- [ ] The repository is on GitHub (`git remote -v` lists it) and the release tag, e.g.
      `2.6.99.0-mac1`, is pushed.
- [ ] `scripts/licenses.json` names the repository's URL as source code location of the app
      and the own code, and the `.dmg` of the release was built afterwards.
- [ ] `scripts/test-app.sh`, `scripts/check.sh` and `scripts/test-long-game.sh` passed for the
      release commit.
- [ ] A GitHub Release with the release version as name, release notes, the `.dmg` and a
      source archive of the vcpkg library sources exists; the release notes refer to the tag,
      the source archive and the licence window.
- [ ] The release procedure is documented in `doc/buildAndTest.md`; new scripts, if any, are
      tested in `scripts/test.sh`.

## History

<!--
  Log of all status changes, oldest first. Add a row for every change of the Status field.
  Timestamp format: ISO 8601 with time zone offset, e.g. 2026-11-11T14:30+0100
  (get it with: date +%Y-%m-%dT%H:%M%z).
  Comment: optional, but required for "waiting" and "aborted" (state the reason).
-->

| Timestamp                | Status | Comment       |
|--------------------------|--------|---------------|
| 2026-11-24T16:24+0100 | open   | Task created  |
