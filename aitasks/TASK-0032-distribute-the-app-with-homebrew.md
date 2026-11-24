# TASK-0032: Distribute the app with Homebrew

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0032 |
| **Short description** | Distribute the app with Homebrew |
| **Status**        | open <!-- One of: open, in-work, waiting, done, aborted -->   |
| **External link** | none |
| **Dependencies**  | TASK-0029 |

## Motivation

User request: "In addition to download a release from the Github-Site, this game should also be
distributed using HomeBrew."

Many Mac users install apps with Homebrew (`brew install --cask …`), which also makes updates
easy (`brew upgrade`). Offering ASC for Mac through Homebrew, in addition to the download from
the GitHub Releases page (TASK-0029), makes the game easier to find, install and update.

## Task description

Known facts:

- Releases are published as a signed and notarized `.dmg` on the GitHub Releases page of
  <https://github.com/tnfink/asc-for-mac> (TASK-0014: `scripts/create-dmg.sh`, file name
  `ASC-for-Mac-<version>.dmg`, e.g. `ASC-for-Mac-2.6.99.0-mac1.dmg`; TASK-0029: the release).
  The app in the `.dmg` is `ASCforMac.app`; it needs macOS 27 on Apple Silicon.
- Homebrew distributes macOS apps as *casks*. A cask can be offered in an own *tap* (a GitHub
  repository named `homebrew-<name>`, e.g. `tnfink/homebrew-asc-for-mac`, installed with
  `brew install --cask tnfink/asc-for-mac/<cask>`) or be submitted to Homebrew's official
  `homebrew/cask` repository, which has acceptance rules (e.g. how well known the project is).
- The current distribution decision is in `doc/architecture.md`, section *Deployment and
  operation* (GitHub Releases, no automatic updates).

1. **Decide with the user** how the cask is offered (own tap or official `homebrew/cask`) and
   its name (e.g. `asc-for-mac`). Record the decision as an addition to *Deployment and
   operation* in `doc/architecture.md`.
2. **Create the cask** for the current release: it downloads the `.dmg` from the GitHub Release
   (with its SHA-256 checksum), installs `ASCforMac.app`, states the requirements (macOS 27,
   Apple Silicon) and removes the app's user data on `brew uninstall --zap`
   (`~/Library/Application Support/asc-for-mac/` and the app's preferences
   `de.tofimusrom.ASCforMac`).
3. **Check the cask** with Homebrew's own tools (`brew audit` and `brew style` for the cask) and
   by installing, starting and uninstalling the app with it.
4. **Publish** the cask (push the tap repository, or open the pull request to `homebrew/cask`)
   only after the user has confirmed; these are outward-facing actions. The GitHub login is done
   by the user; the AI does not handle credentials.
5. **Updates of the cask:** document in `doc/buildAndTest.md` how the cask is updated for a new
   release (version and checksum), as part of the release procedure of TASK-0029. If a script in
   `scripts/` is created for this, add tests for it to `scripts/test.sh`.
6. Add Homebrew (`brew`) to `doc/developerInfrastructure.md` if it is needed for these steps
   (it is so far only mentioned as one way to install other tools), and add the installation
   with Homebrew to the section *Install and start* of `README.md`.

Out of scope: automatic updates inside the app (decided against in `doc/architecture.md`), the
Mac App Store, and an automatic update of the cask by CI (TASK-0021 may take this up).

## Acceptance criteria

- [ ] The user's decision on how the cask is offered (own tap or `homebrew/cask`) and its name
      is recorded in `doc/architecture.md`, section *Deployment and operation*.
- [ ] The cask installs `ASCforMac.app` from the `.dmg` of the current GitHub Release, verified
      by its SHA-256 checksum, and states the requirements macOS 27 and Apple Silicon.
- [ ] `brew audit` and `brew style` pass for the cask.
- [ ] Installing the app with the cask, starting it and uninstalling it (`brew uninstall --zap`,
      which removes the user data) work (installation and start checked by the user).
- [ ] The cask is published as decided, after the user's confirmation, and
      `brew install --cask <cask>` works for others as documented.
- [ ] `README.md` (*Install and start*) describes the installation with Homebrew, and
      `doc/buildAndTest.md` describes how to update the cask for a new release.

## History

<!--
  Log of all status changes, oldest first. Add a row for every change of the Status field.
  Timestamp format: ISO 8601 with time zone offset, e.g. 2026-11-11T14:30+0100
  (get it with: date +%Y-%m-%dT%H:%M%z).
  Comment: optional, but required for "waiting" and "aborted" (state the reason).
-->

| Timestamp                | Status | Comment       |
|--------------------------|--------|---------------|
| 2026-11-24T17:19+0100 | open   | Task created  |
