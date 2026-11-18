# TASK-0009: Decide how network games are handled

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0009 |
| **Short description** | Decide how network games are handled |
| **Status**        | open <!-- One of: open, in-work, waiting, done, aborted -->   |
| **External link** | none |
| **Dependencies**  | TASK-0008 |

## Motivation

Network play with other systems, such as Linux, should work (quality objective
*Compatibility* in `doc/qualityobjectives.md`), and it must not be possible to hack the system
using the open ports for network play (quality objective *Security*). While defining the
context and constraints in TASK-0004, the user postponed the decision whether network games
need a 3rd party system at runtime (e.g. a server or service for network play) or run
directly between the players' computers. Without this decision, the port of the network play
cannot be planned.

## Task description

1. Find out how the original ASC handles network games, based on the ASC source code copied
   into the repository in TASK-0008.
2. Explain the findings to the user and present the options for handling network games in
   asc-for-mac (e.g. with or without a server or service for network play), with their
   advantages and disadvantages with respect to the quality objectives in
   `doc/qualityobjectives.md` and the constraints in `doc/context.md`.
3. The user decides; the AI proposes, but does not decide. Ask the user for the reason of the
   decision.
4. Record the decision, the discussed options and the rationale in `doc/architecture.md`, and
   update the section on 3rd party systems in `doc/context.md` if a 3rd party system is needed
   at runtime.
5. If the decision requires implementation work, propose follow-up tasks with the skill
   `add-task`.

Out of scope: implementing the network play.

## Acceptance criteria

- [ ] The AI has described to the user how the original ASC handles network games, with
      references to the relevant parts of the ASC source code.
- [ ] The AI has presented at least two options with their advantages and disadvantages, and
      the user has decided.
- [ ] `doc/architecture.md` contains a section on network games with the decision, the
      discussed options and the rationale.
- [ ] `doc/context.md` states whether network games need a 3rd party system at runtime.

## History

<!--
  Log of all status changes, oldest first. Add a row for every change of the Status field.
  Timestamp format: ISO 8601 with time zone offset, e.g. 2026-11-11T14:30+0100
  (get it with: date +%Y-%m-%dT%H:%M%z).
  Comment: optional, but required for "waiting" and "aborted" (state the reason).
-->

| Timestamp                | Status | Comment       |
|--------------------------|--------|---------------|
| 2026-11-18T15:32+0100 | open   | Task created  |
