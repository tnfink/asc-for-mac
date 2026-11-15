# TASK-0001: Name the application and set up its git repository

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0001 |
| **Short description** | Name the application and set up its git repository |
| **Status**        | done <!-- One of: open, in-work, waiting, done, aborted -->   |
| **External link** | none |
| **Dependencies**  | none |

## Motivation

This repository is a template. A project created from it must first get its own name and its
own git repository, otherwise it is still described as the template (e.g. in `AGENTS.md`)
and carries the template's git history and remote. Doing this as the very first
step ensures that all following tasks work on the new project.

## Task description

1. Ask the user for the name of the new application (letters, digits, `.`, `_` and `-`).
2. Ask the user how the project was created, and choose the git mode accordingly:
   - **"Use this template" on GitHub:** the repository is already the project's own repository.
     Keep the git history and remotes as they are (`--keep-git`).
   - **Direct clone of the template:** ask the user whether the template's git history should be
     - **reset** (default, no option): the history and all remotes are deleted and a new
       repository is created, or
     - **kept** (`--keep-history`): the history is kept and the remote `origin` is renamed to
       `upstream`, so template updates can be merged later.
3. Make sure the working tree has no uncommitted changes outside `aitasks/`.
4. Run `scripts/init-project.sh` with the name and the chosen option. Show the user the planned
   changes the script prints and get the user's explicit confirmation before running it with
   `--yes`, because deleting the git history cannot be undone.
5. The script removes the template's `LICENSE` file (0BSD), because the new project chooses its
   own license. Tell the user to add the project's own license if needed; choosing it is up to
   the user and out of scope for this task.
6. If the remote `origin` was deleted or renamed, tell the user to add the remote of the new
   project with `git remote add origin <URL>`.

Renaming the project directory itself is out of scope; the user chooses it when cloning.

## Acceptance criteria

- [x] The user has given the application name and the git mode has been chosen: keep git
      ("Use this template"), reset or keep history (direct clone).
- [x] The section "About this project" in `AGENTS.md` names the new project and no longer
      describes the repository as a template.
- [x] The template's `LICENSE` file has been removed.
- [x] Reset: `git log` shows a single initial commit and `git remote` lists no remotes.
- [x] *(Not applicable: reset was chosen.)* Kept history: the remote `origin` has been renamed to `upstream` and the changes are
      committed.
- [x] *(Not applicable: reset was chosen.)* Kept git: the git history and remotes are unchanged and the changes are committed.
- [x] `git status` shows no uncommitted changes outside `aitasks/` (changes to this task's file,
      e.g. ticked criteria and its status, are expected).

## History

<!--
  Log of all status changes, oldest first. Add a row for every change of the Status field.
  Timestamp format: ISO 8601 with time zone offset, e.g. 2026-11-11T14:30+0100
  (get it with: date +%Y-%m-%dT%H:%M%z).
  Comment: optional, but required for "waiting" and "aborted" (state the reason).
-->

| Timestamp                | Status | Comment       |
|--------------------------|--------|---------------|
| 2026-11-11T16:55+0100 | open   | Task created  |
| 2026-11-15T19:17+0100 | in-work | Implementation started |
| 2026-11-15T19:24+0100 | done | All acceptance criteria and the Definition of Done are fulfilled |
