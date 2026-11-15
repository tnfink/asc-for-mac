# ai-assisted-project-template

A template for software development projects that rely heavily on an **AI coding assistant**
(AICA) such as Claude Code, Codex, Copilot or Cursor.

The template provides a ready-to-use structure and process in which humans and AI agents work
together: work is planned as plain-text tasks, the AI implements them with defined skills, and
documentation tells the AI where everything is and which rules apply.

> **Note:** This README describes the template. In a project created from it, this file is
> replaced by the project's own README in task `TASK-0002`.

## What's inside

| Path                          | Content                                                                 |
|-------------------------------|-------------------------------------------------------------------------|
| `AGENTS.md`                   | Instructions for AI coding assistants: layout, conventions, rules       |
| `CLAUDE.md`                   | Imports `AGENTS.md`, so Claude Code loads the same instructions         |
| `aitasks/`                    | Tasks for the AI, one Markdown file per task                            |
| `doc/`                        | All project documentation                                               |
| `scripts/`                    | All scripts                                                             |
| `skills/`                     | Skills for the AI (`.claude/skills` links here for Claude Code)         |

Key documents and tools:

- [`doc/swDevelopmentProcess.md`](doc/swDevelopmentProcess.md): the AI-based development process,
  including a flowchart
- [`doc/developerInfrastructure.md`](doc/developerInfrastructure.md): the tools every developer
  needs, and which the AI may rely on
- [`doc/aiTaskDefinitionOfReady.md`](doc/aiTaskDefinitionOfReady.md) /
  [`doc/aiTaskDefinitionOfDone.md`](doc/aiTaskDefinitionOfDone.md): criteria a task must meet
  before work starts and before it is done
- `scripts/tasks.sh`: lists and creates tasks and changes their status
- `scripts/init-project.sh`: turns a new copy of the template into a new project
- `scripts/test.sh`: automated tests for the scripts
- Skills `add-task`, `improve-task` and `implement-task`: create, review and implement tasks

## Prerequisites

The required tools and their setup are described in
[`doc/developerInfrastructure.md`](doc/developerInfrastructure.md). In addition, you need an
**AI coding assistant**.

## Getting started

1. **Create your project from the template**, in one of two ways:

   - **Recommended: "Use this template" on GitHub.** On the template's GitHub page, click
     *Use this template* → *Create a new repository*. GitHub creates your own repository with a
     fresh history. Clone it into a directory named after your project:

     ```bash
     git clone <your-repository-url> my-project
     cd my-project
     ```

   - **Clone the template directly** (e.g. if your project is not hosted on GitHub):

     ```bash
     git clone https://github.com/tnfink/ai-assisted-project-template.git my-project
     cd my-project
     ```

2. **Start your AI coding assistant** in the project directory, e.g. `claude`.

3. **Work through the prepared tasks in order.** Ask the AI to implement them one by one, e.g.
   with `/implement-task TASK-0001` in Claude Code, or "implement TASK-0001" in any assistant:

   | Task      | What happens                                                                  |
   |-----------|-------------------------------------------------------------------------------|
   | TASK-0001 | Name the application and set up its git repository (`scripts/init-project.sh`) |
   | TASK-0002 | The AI asks you about domain, problems and features and writes `README.md`    |
   | TASK-0003 | The AI explains the ISO 25010 quality characteristics, you rate them → `doc/qualityobjectives.md` |
   | TASK-0004 | You describe 3rd party systems, technology, legal and hosting constraints → `doc/context.md` |
   | TASK-0005 | The AI proposes structure and tech stack topic by topic, you decide → `doc/architecture.md` |
   | TASK-0006 | The AI creates the core application with build, tests and static checks → `doc/buildAndTest.md` |
   | TASK-0007 | The AI proposes QA measures, you decide → `doc/qameasures.md` and new tasks    |

   These tasks are interactive: the AI asks you for the information and you make the decisions.

   TASK-0001 asks how you created the project. With *Use this template*, your repository is
   kept as it is. With a direct clone, it either deletes the template's git history and
   remotes, or keeps the history and renames the remote `origin` to `upstream`, so you can
   merge template updates later.

   > **Caution:** deleting the git history cannot be undone (TASK-0001 asks for confirmation
   > first). Run TASK-0001 only in your new project, never in the template itself.

4. **Direct clone only:** add your project's remote after TASK-0001:
   `git remote add origin <your-repository-url>`.

## Working with tasks

After the setup, new work follows the process in
[`doc/swDevelopmentProcess.md`](doc/swDevelopmentProcess.md):

1. **Create tasks** from a requirement: `/add-task <what needs to be done>`.
2. **Review a task** before implementing it: `/improve-task TASK-<NNNN>`.
3. **Implement it**: `/implement-task TASK-<NNNN>`. The AI checks the Definition of Ready, works
   on the task, verifies the acceptance criteria and the Definition of Done, and marks it `done`.
4. **Review the results** and repeat.

Show the current tasks and their dependencies:

```bash
scripts/tasks.sh list          # all tasks
scripts/tasks.sh list open     # only open tasks
scripts/tasks.sh list -deps    # all tasks with their dependencies
scripts/tasks.sh status TASK-0003 waiting "Waiting for the user's ratings"
                               # change the status (recorded in the task's history)
scripts/tasks.sh help          # all commands
```

Each task has a status (`open`, `in-work`, `waiting`, `done`, `aborted`) and a history of all
status changes. Task numbers show the order in which tasks should be done.

## Adapting the template

- **Definition of Ready / Done:** add your project's criteria to
  `doc/aiTaskDefinitionOfReady.md` and `doc/aiTaskDefinitionOfDone.md`.
- **Skills:** add new skills as `skills/<name>/SKILL.md`.
- **Tools:** add new tools to `doc/developerInfrastructure.md` before the AI uses them.
- **Scripts:** add tests for new scripts or commands to `scripts/test.sh` and run it after
  every change.
- **Rules for the AI:** keep `AGENTS.md` up to date when structure or conventions change.

## License

This template is licensed under the [BSD Zero Clause License (0BSD)](LICENSE): you may use, copy,
modify and distribute it for any purpose, without having to keep any copyright notice.

Projects created from the template do not inherit this license: TASK-0001 removes the `LICENSE`
file, so you can choose your project's own license.
