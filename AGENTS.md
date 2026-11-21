# AGENTS.md

Guidance for AI coding assistants (Claude Code, Codex, Copilot, Cursor, etc.) working in this repository.

## About this project

This is the project **asc-for-mac**: a macOS port of the existing open-source game
Advanced Strategic Command (ASC, <https://www.asc-hq.org>). There is currently no macOS
version of ASC; the port uses current macOS technologies and is to be distributed as a
download from a website (not through Apple's App Store, because of license conflicts).
It was created from a template for software development projects that rely heavily on an
AI coding assistant.
The domain, the problems solved and the features of the application are described in
`README.md`.

**Tech stack** (see `doc/architecture.md`): a Swift 6.4 app (AppKit, SwiftUI) for macOS 27 on
Apple Silicon, calling the original ASC C++ core (`thirdparty/asc/`, C++11, SDL2, ParaGUI)
only through a C++20 facade (`facade/`). Xcode (`ASCforMac.xcodeproj`) is the main build; it
calls CMake for the C/C++ parts, with libraries from vcpkg. Tests: Swift Testing, an XCTest UI test and ASC's
`unittester`, also with AddressSanitizer and UndefinedBehaviorSanitizer; code coverage with a
baseline. Static checks: swift-format, SwiftLint, clang-tidy, Clang Static Analyzer, warnings
as errors. SBOM in SPDX 2.3 JSON (`doc/sbom.spdx.json`); the licence information shown in the app is
generated from it. Licence: GPL-2.0-or-later (`LICENSE`).

The commands to build, test, check and run the app are in
[`doc/buildAndTest.md`](doc/buildAndTest.md). Keep this section up to date with
project-specific information.

## Repository layout

| Directory   | Purpose                                                                 |
|-------------|-------------------------------------------------------------------------|
| `doc/`      | All project documentation (architecture, requirements, decisions, guides). |
| `scripts/`  | All scripts (build, test, setup, deployment, utilities).                |
| `skills/`   | AI skills: reusable instructions or workflows for the AI assistant.     |
| `aitasks/`  | Tasks for the AI coding assistant to work on.                           |
| `app/`      | The Swift app (`app/ASCforMac/`), its tests (`app/ASCforMacTests/`) and its UI test (`app/ASCforMacUITests/`). |
| `facade/`   | The C++ facade between the Swift app and the ASC core.                  |
| `core/`     | CMake build of the ASC core and `unittester` from `thirdparty/asc/` (see `doc/buildAndTest.md`). |
| `cmake/`    | CMake helper files, e.g. the vcpkg triplet in `cmake/triplets/`.        |
| `build/`    | Build output and vcpkg (created by the build, not committed).          |
| `thirdparty/` | 3rd party code and data; `thirdparty/asc/` is the original ASC as `git subtree` (see `doc/thirdparty.md`). Keep changes there minimal and marked. `thirdparty/upstream-patches/` holds fixes prepared as pull requests for ASC. `thirdparty/licenses/` holds licence texts that are neither in vcpkg's files nor in `thirdparty/asc/`. |

## Available tools

The tools installed on every developer's computer are defined in
[`doc/developerInfrastructure.md`](doc/developerInfrastructure.md). Currently these are:

- **Bash** (3.2 or newer, since macOS ships Bash 3.2), for scripts in `scripts/`
- **Python 3** (3.10 or newer), called as `python3`
- **Git** (2.20 or newer)
- **Xcode** (27.0 or newer), with Apple Clang, the macOS SDK and `make`
- **CMake** (3.25 or newer)
- **clang-tidy** from Homebrew's `llvm` package (not on the `PATH`; see
  `doc/developerInfrastructure.md`)

vcpkg and the libraries it provides, and the SwiftLint plugin, are loaded by the build (see
`doc/developerInfrastructure.md`).

Rely only on these tools. Do not write scripts or instructions that need other tools
(e.g. Node.js, `jq`, Docker) unless they have been added to `doc/developerInfrastructure.md` first.

Use stable releases of all tools, libraries and frameworks. Using a pre-release version (e.g. an
alpha, beta or release candidate) needs the user's explicit decision, recorded in
`doc/architecture.md`.

## Conventions

- **Architecture:** every implementation must follow the software architecture in
  [`doc/architecture.md`](doc/architecture.md). Read it before working on a task. Deviating
  from it needs the user's decision, recorded in `doc/architecture.md`.
- **Documentation** goes into `doc/`. Do not scatter documentation files across the repository
  (this `AGENTS.md` and a top-level `README.md` are the exceptions).
- **Scripts** go into `scripts/`. Make shell scripts executable and give each a short header comment
  explaining what it does and how to call it. The scripts are tested by `scripts/test.sh`: add
  tests for every new script or command, and run `scripts/test.sh` after every change to a script.
- **Skills** go into `skills/`, one subdirectory per skill with a `SKILL.md`. Check this directory
  for a matching skill before starting a task and follow it if one applies. `.claude/skills` is a
  symbolic link to `skills/`, so Claude Code registers these skills natively; do not put skills
  into `.claude/skills` directly (see `doc/developerInfrastructure.md` for symbolic links on Windows).
- **Tasks** go into `aitasks/`, one file per task, created with `scripts/tasks.sh new` (the task
  template is defined in `scripts/tasks.sh`). When asked to work on a task, read its file in
  `aitasks/` first and treat it as the specification. Check that the task fulfills all criteria in
  [`doc/aiTaskDefinitionOfReady.md`](doc/aiTaskDefinitionOfReady.md) before starting; if it does
  not, complete the task description first or ask the user. Make sure all tasks listed under its
  dependencies are done before starting, and check every acceptance criterion and every criterion
  in [`doc/aiTaskDefinitionOfDone.md`](doc/aiTaskDefinitionOfDone.md) before reporting the task as
  complete. Use the skill `add-task` to create a task, `improve-task` to review it before
  implementing it, and `implement-task` to implement it.
- **Task status** is kept in the task file and is one of:
  - `open`: not started yet
  - `in-work`: currently being worked on
  - `waiting`: blocked, e.g. on a dependency or on input from a human (note the reason in the task)
  - `done`: completed, all acceptance criteria and the Definition of Done are met
  - `aborted`: will not be done (note the reason in the task)

  Set the status to `in-work` when starting a task and update it when the state changes.
  Always change the status with `scripts/tasks.sh status ID STATE [COMMENT]` (e.g.
  `scripts/tasks.sh status TASK-0003 waiting "Waiting for the user's ratings"`), never by editing
  the task file: the script also records the change with a timestamp in the task's **History**
  and requires a reason for `waiting` and `aborted`.
- **Task numbers never change:** a task keeps its ID for its whole life; never renumber tasks.
  Only the initial setup tasks of the template (TASK-0001 to TASK-0007) are numbered in the order
  they should be done. For all other tasks, the order is defined only by their **Dependencies**:
  if a task has to be done before another one, add it to the other task's dependencies.
- **Project initialization:** `scripts/init-project.sh NAME` turns a new copy of this template
  into a new project (renames it, resets or keeps the git history). It deletes the git history by
  default, so only run it as part of the corresponding task and after the user has confirmed.
- **Task script:** use `scripts/tasks.sh` for task handling, e.g. `scripts/tasks.sh list open`
  lists all open tasks and `scripts/tasks.sh new "Short description"` creates a new task with the
  next free ID from the template (`scripts/tasks.sh help` shows all commands). Always create new
  tasks with this script, then fill in the remaining sections of the created file. The script reads the
  `ID`, `Status`, `Dependencies` and `Short description` rows of the header table, so keep their
  format intact (dependencies as a comma-separated list of task IDs, or `none`).
- Keep this file up to date when the structure or conventions of the project change.

## Working approach

The development process of this project is described in
[`doc/swDevelopmentProcess.md`](doc/swDevelopmentProcess.md). In short:

1. Read the relevant task in `aitasks/` and any related documentation in `doc/`.
2. Check `skills/` for applicable skills.
3. Implement the change, reusing existing scripts in `scripts/` where possible.
4. Update documentation in `doc/` when behavior or structure changes.
