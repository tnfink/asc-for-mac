# asc-for-mac

A macOS port of **Advanced Strategic Command (ASC)**, the existing open-source game
(website: <https://www.asc-hq.org>).

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

## Development

### Prerequisites

The required tools and their setup are described in
[`doc/developerInfrastructure.md`](doc/developerInfrastructure.md). In addition, you need an
**AI coding assistant** (e.g. Claude Code, Codex, Copilot or Cursor). Its instructions are in
[`AGENTS.md`](AGENTS.md).

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
status changes. Task numbers show the order in which tasks should be done.
