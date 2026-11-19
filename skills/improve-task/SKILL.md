---
name: improve-task
description: Review and improve an AI task from aitasks/ before it is implemented. Use when the user asks to check, review, improve, refine, update or validate a task (e.g. "improve TASK-0003"). Checks whether the task is still valid for the current state of the project, updates it if not, and looks for other errors and possible improvements.
---

# improve-task

Reviews one AI task from `aitasks/` against the current state of the project and improves it,
so that it is still valid, free of errors and unambiguous to implement. This skill only changes
the task file; it does not implement the task.

## 1. Identify the task

- The user names the task by ID (e.g. `TASK-0003`) or file. Find its file in `aitasks/`.
- If no task is given, run `scripts/tasks.sh list open` and ask the user which task to review.
- Read the whole task file.
- If the status is `done` or `aborted`, stop and tell the user: completed tasks document past
  decisions and are not changed. If the status is `in-work`, warn the user that the task is
  being implemented and continue only if the user confirms.

## 2. Gather the current state of the project

Collect what is needed to judge the task, focused on what the task touches:

- `AGENTS.md`, `README.md` and the documents in `doc/` relevant to the task (e.g.
  `doc/architecture.md`, `doc/context.md`, `doc/qualityobjectives.md`, if they exist).
- The files, scripts and code the task refers to or will have to change.
- All other tasks: `scripts/tasks.sh list` and, where relevant, their files, in particular the
  dependencies and tasks that were completed after this task was created (see its **History**).
- Changes since the task was created: `git log --since=<creation timestamp>` and the changed
  files, if the repository has history.

## 3. Check whether the task is still valid

Compare the task with the current state of the project:

- **Already done?** Has the work, or part of it, already been done by other tasks or changes?
- **Still needed?** Is the task still necessary, or has it become obsolete (e.g. by a changed
  architecture or a different solution)?
- **References:** do the files, directories, scripts, documents, components and task IDs the
  task mentions still exist under these names?
- **Assumptions:** does the task still match the current architecture, context and
  constraints, quality objectives and conventions in `AGENTS.md`?
- **Dependencies:** do all listed tasks exist, are none of them `aborted`, are there no cycles,
  and are dependencies missing (tasks this one needs but does not list)?

## 4. Check for other errors and possible improvements

- **Definition of Ready:** check the task against every criterion in
  `doc/aiTaskDefinitionOfReady.md`.
- **Consistency:** do the short description, motivation, task description and acceptance
  criteria fit together without contradictions? Is every part of the task description covered
  by an acceptance criterion?
- **Clarity:** is the task unambiguous? Could an AI agent implement it without guessing?
  Are terms, file names and expected results precise?
- **Acceptance criteria:** is each criterion concrete and verifiable by a command, a test or an
  inspection? Remove duplicates, sharpen vague wording.
- **Scope:** is the task small enough to implement and review in one go? If not, propose
  splitting it into several tasks.
- **Project guidelines:** does the task follow the project conventions in `AGENTS.md` (e.g.
  documentation in `doc/`, scripts in `scripts/`, only the tools from
  `doc/developerInfrastructure.md`)? Will it fulfill `doc/aiTaskDefinitionOfDone.md`?
- **Form:** spelling, grammar, formatting, leftover placeholder comments.

## 5. Decide what to change

Sort every finding into one of two groups:

- **Corrections** that keep the intent of the task: fixing outdated references, spelling and
  formatting, sharpening wording, making acceptance criteria verifiable, adding a missing
  dependency that clearly follows from the project. Apply these directly.
- **Changes of intent or scope**: changing or dropping requirements, adding new requirements,
  splitting the task, changing the short description, or aborting an obsolete task.
  **Ask the user first** and apply only what the user agrees to.

Never invent requirements, and keep the user's original wording for requirements and
constraints wherever it is still correct.

## 6. Update the task file

- Edit the sections **External link**, **Dependencies**, **Motivation**, **Task description**
  and **Acceptance criteria** as decided in step 5.
- Do not change the **ID** row, the **Status** row or the **History** section, except:
  - **Short description:** only with the user's consent; keep the row format and update the
    title line to match. The file name stays unchanged.
  - **Abort:** if the user agrees that the task is obsolete, set the status with
    `scripts/tasks.sh status <ID> aborted "<reason>"`; the script records it in the history.
- **Split:** create the new tasks with the skill `add-task`, reduce this task accordingly and
  link the tasks via dependencies. If the new tasks must be done before this one, add them to
  this task's **Dependencies**; never renumber tasks (see `AGENTS.md`).
- Run `scripts/tasks.sh list` and check that the task is still listed correctly.

## 7. Report

Report to the user:

- whether the task is still valid for the current state of the project,
- the corrections you applied,
- the changes you proposed and what the user decided,
- whether the task now fulfills the Definition of Ready, i.e. whether it can be implemented
  with the skill `implement-task`.

Do not implement the task and do not commit changes unless the user asks for it.
