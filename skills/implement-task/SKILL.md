---
name: implement-task
description: Implement an AI task from aitasks/. Use when the user asks to implement, work on, do, execute or start a task (e.g. "implement TASK-0003"). Checks the task against the Definition of Ready before starting and against its acceptance criteria and the Definition of Done before marking it as done.
---

# implement-task

Implements one AI task from `aitasks/`. The task file is the specification. Work only starts
when the task fulfills the Definition of Ready, and the task is only marked as `done` when its
acceptance criteria and the Definition of Done are fulfilled.

## 1. Identify the task

- The user names the task by ID (e.g. `TASK-0003`) or file. Find its file in `aitasks/`.
- If no task is given, run `scripts/tasks.sh list open`, propose the open task with the lowest
  number whose dependencies are all `done`, and ask the user to confirm.
- Read the whole task file.

## 2. Check whether work can start

Do not change anything in the project before all of these checks pass.

1. **Status:** the status must be `open`, `in-work` (resuming) or `waiting` (resuming after the
   reason for waiting is resolved). If it is `done` or `aborted`, stop and tell the user.
2. **Dependencies:** every task listed under **Dependencies** must have the status `done`
   (check with `scripts/tasks.sh list done`). If not, stop and tell the user which dependencies
   are missing.
3. **Definition of Ready:** read `doc/aiTaskDefinitionOfReady.md` and check the task against
   every criterion in it.
4. **Tools:** check that the tools the task needs (e.g. a runtime in the version given in
   `doc/developerInfrastructure.md` or `doc/architecture.md`) are installed, e.g. with the
   check commands in `doc/developerInfrastructure.md`. If a tool is missing, tell the user
   which tool to install and wait; do not work around it with another version or tool.

If a check fails, do not start the implementation. Report which criteria are not fulfilled and
why. Offer to complete the task description together with the user; change the task file only
with the user's consent, then check again.

## 3. Start the task

Set the status to `in-work`; the script also records the change in the task's **History**:

```bash
scripts/tasks.sh status <ID> in-work "Implementation started"
```

Always change the status with `scripts/tasks.sh status`, never by editing the task file.

## 4. Implement the task

- Follow `AGENTS.md`, the project documentation in `doc/` and any applicable skills in `skills/`.
  Use only the tools listed in `doc/developerInfrastructure.md`.
- Do what the **Task description** asks for, no more. Do not expand the scope.
- If the task requires decisions or information from the user (e.g. asking for ratings or
  choosing an architecture), ask the user; never invent the user's answers.
- Ask for free-text information (e.g. names, descriptions, ratings with explanations) as plain
  text in the conversation. Use a multiple-choice question dialog only when the user chooses
  between fixed alternatives.
- If you discover additional work that is needed but outside this task, do not do it. Propose
  creating a new task with the skill `add-task` instead.
- If you are blocked (e.g. waiting for the user or an external party), set the status with
  `scripts/tasks.sh status <ID> waiting "<reason>"` and tell the user.

## 5. Check before completion

1. **Acceptance criteria:** check every acceptance criterion of the task. Verify it by a
   command, test or inspection, not by assumption. Tick each verified criterion (`- [x]`).
2. **Definition of Done:** read `doc/aiTaskDefinitionOfDone.md` and check every criterion
   listed there in the same way. If it lists no criteria yet, this check passes.
3. If a criterion is not fulfilled, continue implementing (step 4) and check again. If it
   cannot be fulfilled, leave the status `in-work` or set it to `waiting` with the reason, and
   tell the user.

## 6. Complete the task

Only when all acceptance criteria and all Definition of Done criteria are fulfilled:

1. Set the status to `done`:
   `scripts/tasks.sh status <ID> done "All acceptance criteria and the Definition of Done are fulfilled"`
2. Run `scripts/tasks.sh list done` and check that the task appears.
3. Report to the user: what was done, which files were changed, how each acceptance criterion
   was verified, and any open points or proposed follow-up tasks.

Do not commit changes unless the user asks for it.
