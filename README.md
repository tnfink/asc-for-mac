# asc-for-mac

**ASC for Mac** is a macOS port of **Advanced Strategic Command (ASC)**, the existing
open-source turn-based strategy game (website: <https://www.asc-hq.org>).

## Why this port

ASC is a free, turn-based strategy game in the tradition of the classic *Battle Isle* series,
with units on land, at sea and in the air. It can be played against the computer in several
campaigns, or by several players one after the other (hot seat or play by e-mail). It runs on
Windows and Linux, but there has been no version for the Mac. ASC for Mac brings the original
game to current Macs as a native app, with the Mac's menu bar, full screen and a signed and
notarized download, without changing the game itself. It is distributed outside Apple's App
Store, under the same open-source licence as ASC (GPL).

## Install and start

**Requirements:** a Mac with Apple Silicon and macOS 27 or newer.

1. Download the disk image `ASC-for-Mac-<version>.dmg` (e.g.
   `ASC-for-Mac-2.6.99.0-mac1.dmg`) from the
   [Releases page](https://github.com/tnfink/asc-for-mac/releases).
2. Open the `.dmg`. Its window shows the app `ASCforMac` and a link to *Applications*.
3. Drag `ASCforMac` onto *Applications*, then eject the disk image.
4. Start `ASCforMac` from the Applications folder.

At the first start:

- macOS asks once whether to open an app downloaded from the internet; choose *Open*. The app
  is signed and notarized by Apple, so there is no other warning.
- The app shows a short agreement: ASC for Mac is free software under the GNU General Public
  License and comes without warranty. *Show Licence* shows the licence, *Accept* starts the game,
  *Decline* quits.

The game then starts in full screen with ASC's start map and menu bar (*Ctrl+Cmd+F* or
*View › Enter Full Screen* switches between full screen and a window). Save games and settings are stored in
`~/Library/Application Support/asc-for-mac/`.

## Built with Claude

ASC for Mac was built with the AI coding assistant **Claude** (Claude Code), using the project
template [ai-assisted-project-template](https://github.com/tnfink/ai-assisted-project-template).
The template's process (tasks in `aitasks/`, documentation in `doc/`, quality checks and tests)
is described in *Development* below.

## Domain

The project builds the game Advanced Strategic Command, abbreviated ASC, for macOS. It ports the
existing open-source ASC to the Mac; it does not create a new game.

## Problems solved

There is currently no macOS version of ASC available.

## Features

**First step: port**

- The existing open-source ASC runs as a macOS application.
- The app uses current macOS technologies.
- The app is available as a download from a website. It is not distributed through Apple's
  App Store, to avoid conflicts between ASC's open-source license and Apple's App Store terms.

**Second step: improvement**

- After the port, the app can be improved or modernized. The details are not defined yet.

## License

The project's own code (`app/`, `facade/`, `scripts/`, `core/`, `cmake/`) is licensed under
the GNU General Public License, version 2 or (at your option) any later version
(GPL-2.0-or-later), the same as ASC; the license text is in [`LICENSE`](LICENSE). The app as a
whole, including ASC and the libraries it contains, is distributed under GPL-2.0-or-later. The
licenses of all components are listed in the app (menu *ASC for Mac › Licenses…*) and in
[`doc/thirdparty.md`](doc/thirdparty.md).

## Development

### Prerequisites

The required tools and their setup are described in
[`doc/developerInfrastructure.md`](doc/developerInfrastructure.md). In addition, you need an
**AI coding assistant** (e.g. Claude Code, Codex, Copilot or Cursor). Its instructions are in
[`AGENTS.md`](AGENTS.md).

### Build, test and run

Build, test, check and start the app with the scripts in `scripts/`, e.g. `scripts/build.sh`,
`scripts/test-app.sh`, `scripts/check.sh` and `scripts/run.sh`. All commands are described in
[`doc/buildAndTest.md`](doc/buildAndTest.md).

### Working with tasks

Work is planned as tasks in [`aitasks/`](aitasks/) and follows the process in
[`doc/swDevelopmentProcess.md`](doc/swDevelopmentProcess.md):

1. **Create tasks** from a requirement with the skill `add-task`: `/add-task <what needs to be done>`.
2. **Review a task** before implementing it with the skill `improve-task`:
   `/improve-task TASK-<NNNN>`.
3. **Implement it** with the skill `implement-task`: `/implement-task TASK-<NNNN>`. The AI checks
   the Definition of Ready, works on the task, verifies the acceptance criteria and the
   Definition of Done, and marks it `done`.
4. **Review the results** and repeat.

In assistants without slash commands, ask e.g. "implement TASK-0003".

Show the current tasks and change their status:

```bash
scripts/tasks.sh list          # all tasks
scripts/tasks.sh list open     # only open tasks
scripts/tasks.sh list -deps    # all tasks with their dependencies
scripts/tasks.sh new "Short description"
                               # create a new task
scripts/tasks.sh status TASK-0003 waiting "Waiting for the user's ratings"
                               # change the status (recorded in the task's history)
scripts/tasks.sh help          # all commands
```

Each task has a status (`open`, `in-work`, `waiting`, `done`, `aborted`) and a history of all
status changes. Task numbers never change; the order of the tasks is defined by their
dependencies.
