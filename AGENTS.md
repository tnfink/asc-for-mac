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
`README.md`. Keep this section up to date with project-specific information (purpose,
tech stack, build and test commands).

## Repository layout

| Directory   | Purpose                                                                 |
|-------------|-------------------------------------------------------------------------|
| `doc/`      | All project documentation (architecture, requirements, decisions, guides). |
| `scripts/`  | All scripts (build, test, setup, deployment, utilities).                |
| `skills/`   | AI skills: reusable instructions or workflows for the AI assistant.     |
| `aitasks/`  | Tasks for the AI coding assistant to work on.                           |

## Available tools

The tools installed on every developer's computer are defined in
[`doc/developerInfrastructure.md`](doc/developerInfrastructure.md). Currently these are:

- **Bash** (3.2 or newer, since macOS ships Bash 3.2), for scripts in `scripts/`
- **Python 3** (3.10 or newer), called as `python3`
- **Git** (2.20 or newer)

Rely only on these tools. Do not write scripts or instructions that need other tools
(e.g. Node.js, `jq`, Docker) unless they have been added to `doc/developerInfrastructure.md` first.

Use stable releases of all tools, libraries and frameworks. Using a pre-release version (e.g. an
alpha, beta or release candidate) needs the user's explicit decision, recorded in
`doc/architecture.md`.

## Conventions

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
- **Task numbers show the order:** tasks are numbered in the order they should be done. If a new
  task has to be done before existing ones, renumber the tasks so the numbers still show the
  order, and update all references to the changed IDs (dependencies and text).
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
