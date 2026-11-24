# TASK-0029: Publish the first release on GitHub

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0029 |
| **Short description** | Publish the first release on GitHub |
| **Status**        | in-work <!-- One of: open, in-work, waiting, done, aborted -->   |
| **External link** | none |
| **Dependencies**  | TASK-0014, TASK-0017, TASK-0030, TASK-0031 |

## Motivation

asc-for-mac is distributed as a download from GitHub, not through the App Store (see
`doc/context.md`). TASK-0014 creates the signed and notarized `.dmg`; this task publishes it as
the first GitHub Release, so that users can download and run the first playable version. It
was split off from TASK-0014 in its review (user decision), because the repository has no
GitHub remote yet and publishing is a separate, outward-facing step. The release must also
fulfil the licences of the components (TASK-0025). It ships with the app icon (TASK-0030) and
the README for players with download and install steps (TASK-0031).

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
- The project's version is already set for the first release: `MARKETING_VERSION = 2.6.99.0`
  and `CURRENT_PROJECT_VERSION = 1` in `ASCforMac.xcodeproj`, so the release version is
  `2.6.99.0-mac1`. The SBOM components still have the version `2.6.99.0-mac0`
  (`scripts/sbom-components.json`, entries `app` and `own-code`), which the licence window
  shows.
- The GitHub CLI `gh` is installed on the developer's Mac (`gh --version`), but it is not
  listed in `doc/developerInfrastructure.md`.
- No file in the git history is larger than 50 MB (GitHub rejects files over 100 MB); the
  packed repository is about 270 MB, mostly ASC's subtree history.
- vcpkg's download directory `build/vcpkg/downloads/` currently contains no library sources
  (only ninja): vcpkg restores the libraries from its binary cache (`~/.cache/vcpkg/archives`)
  without downloading their sources. The sources have to be fetched explicitly, e.g. with
  vcpkg's option for downloading only (`--only-downloads`, check `vcpkg help install`) with the
  binary cache disabled, at the vcpkg baseline of `scripts/build-core.sh`.
- `build/release/ASC-for-Mac-2.6.99.0-mac1.dmg` from TASK-0014 was built before the app icon
  and the changes after it; it must not be published.

1. **Repository:** ask the user for the GitHub repository (owner and name) and whether it
   exists already; add it as git remote and push the repository with the user's consent. If a
   tool that is not listed in `doc/developerInfrastructure.md` is needed (e.g. the GitHub CLI
   `gh`), add it there first. The GitHub login is done by the user (e.g. `gh auth login`); the
   AI does not handle credentials.
2. **Source code location and version:** replace the placeholder source location of the app
   and the own code in `scripts/licenses.json` ("The asc-for-mac repository at the tag of this
   release …") with the repository's URL, set the version of the entries `app` and `own-code`
   in `scripts/sbom-components.json` to the release version and regenerate the SBOM
   (`scripts/create-sbom.sh`), so that the app's licence window shows both.
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
5. **Release:** commit all changes, so that the working tree is clean; create the `.dmg` from
   this commit with `scripts/create-dmg.sh` (TASK-0014); tag the commit with the release
   version, push the tag, and publish
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
      and the own code; `scripts/sbom-components.json` and `doc/sbom.spdx.json` have the
      release version for `app` and `own-code`; the licence window of the released app shows
      both.
- [ ] The `.dmg` of the release was built by `scripts/create-dmg.sh` (signed, notarized,
      stapled) from the tagged commit with a clean working tree (`git status --porcelain`
      empty), after the changes above.
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
| 2026-11-24T17:13+0100 | in-work | Implementation started |
