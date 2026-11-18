# TASK-0004: Define context and constraints of the application

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0004 |
| **Short description** | Define context and constraints of the application |
| **Status**        | done <!-- One of: open, in-work, waiting, done, aborted -->   |
| **External link** | none |
| **Dependencies**  | TASK-0002, TASK-0003 |

## Motivation

The context and constraints of the application limit the options for the architecture and the
implementation. Knowing early which 3rd party systems must be included, which programming
languages or frameworks are prescribed, which legal or regulatory requirements apply and how
the application will be operated, distributed and hosted prevents design decisions that would
later have to be reverted, and gives humans and AI agents a documented basis for all further
work.

## Task description

Define the context and constraints of the application by asking the user the following
questions:

- Are there 3rd party systems that must be included?
- Are there constraints on programming languages or frameworks?
- Are there legal or regulatory requirements?
- Are there constraints on operations, distribution and hosting (e.g. the website the app is
  downloaded from, code signing and notarization by Apple, how updates reach the users)?

Before each question, give the user a few examples of what it could mean for this
application, derived from `README.md` and `doc/qualityobjectives.md` (e.g. the original ASC
source code and the libraries it uses, the open-source license of ASC and of its graphics and
maps, or the website the app is downloaded from). The examples only help the user; they do
not suggest an answer.

Record the results in `doc/context.md`, with one section per question.

This should be done after TASK-0002 and TASK-0003, so the domain, problems and features of the
application described in `README.md` and its quality objectives in `doc/qualityobjectives.md`
are known. The answers come from the user; the AI asks for them and does not invent them.

## Acceptance criteria

- [x] The AI has asked the user about 3rd party systems, constraints on programming languages
      or frameworks, legal or regulatory requirements, and constraints on operations,
      distribution and hosting, and has given examples related to this application for each
      question.
- [x] `doc/context.md` exists and has one section per question.
- [x] `doc/context.md` describes the 3rd party systems that must be included, or states that
      there are none.
- [x] `doc/context.md` describes the constraints on programming languages and frameworks, or
      states that there are none.
- [x] `doc/context.md` describes the legal and regulatory requirements, or states that there
      are none.
- [x] `doc/context.md` describes the constraints on operations, distribution and hosting, or
      states that there are none.
- [x] The content of `doc/context.md` is based on the user's answers.

## History

<!--
  Log of all status changes, oldest first. Add a row for every change of the Status field.
  Timestamp format: ISO 8601 with time zone offset, e.g. 2026-11-11T14:30+0100
  (get it with: date +%Y-%m-%dT%H:%M%z).
  Comment: optional, but required for "waiting" and "aborted" (state the reason).
-->

| Timestamp                | Status | Comment       |
|--------------------------|--------|---------------|
| 2026-11-11T16:22+0100 | open   | Task created  |
| 2026-11-16T16:54+0100 | in-work | Implementation started |
| 2026-11-18T15:37+0100 | done | All acceptance criteria and the Definition of Done are fulfilled |
