# TASK-0007: Define automated QA measures based on quality objectives

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0007 |
| **Short description** | Define automated QA measures based on quality objectives |
| **Status**        | open <!-- One of: open, in-work, waiting, done, aborted -->   |
| **External link** | none |
| **Dependencies**  | TASK-0003, TASK-0006 |

## Motivation

The quality objectives defined in TASK-0003 state which quality characteristics matter most for
the application. To make sure the application actually meets them, they must be translated into
concrete QA measures, such as automated tests and code analysis. Once the core application
exists (TASK-0006), these measures can be planned for its actual build system and code base.
Deciding them together with the user and turning them into tasks makes quality assurance an
explicit, traceable part of the development.

## Task description

After the core application has been created in TASK-0006, use the quality objectives defined in
TASK-0003 (`doc/qualityobjectives.md`) to define QA measures, such as automated tests and code
analysis:

1. The AI creates a suggestion for automated QA measures, based on the quality objectives and
   the core application with its build system, testing and static quality check from TASK-0006.
2. The suggestion is discussed with the user.
3. A decision must be made. The user decides which QA measures are implemented.
4. Document the result in `doc/qameasures.md`, including:
   - the decided QA measures and which quality objectives each of them addresses,
   - the suggested measures that were not chosen,
   - the rationale for the decision, as given by the user.
5. As result of this task, additional tasks are created, using the skill `add-task`, that
   implement the decided QA measures.

Implementing the QA measures is out of scope; it is done in the newly created tasks.

## Acceptance criteria

- [ ] The AI has created a suggestion for automated QA measures based on the quality objectives
      in `doc/qualityobjectives.md`.
- [ ] The suggestion has been discussed with the user, and the user has decided which QA
      measures are implemented.
- [ ] `doc/qameasures.md` exists and lists the decided QA measures, each with the quality
      objectives it addresses.
- [ ] `doc/qameasures.md` lists the suggested measures that were not chosen.
- [ ] `doc/qameasures.md` states the rationale for the decision, as given by the user.
- [ ] For the decided QA measures, additional tasks have been created with the skill `add-task`;
      `scripts/tasks.sh list open` shows them.
- [ ] Each new task states which decided QA measure it implements, refers to
      `doc/qameasures.md`, and depends on this task.

## History

<!--
  Log of all status changes, oldest first. Add a row for every change of the Status field.
  Timestamp format: ISO 8601 with time zone offset, e.g. 2026-11-11T14:30+0100
  (get it with: date +%Y-%m-%dT%H:%M%z).
  Comment: optional, but required for "waiting" and "aborted" (state the reason).
-->

| Timestamp                | Status | Comment       |
|--------------------------|--------|---------------|
| 2026-11-12T10:16+0100 | open   | Task created  |
