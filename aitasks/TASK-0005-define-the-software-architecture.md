# TASK-0005: Define the software architecture

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0005 |
| **Short description** | Define the software architecture |
| **Status**        | done <!-- One of: open, in-work, waiting, done, aborted -->   |
| **External link** | none |
| **Dependencies**  | TASK-0002, TASK-0003, TASK-0004 |

## Motivation

The software architecture is the foundation for all further implementation work. Once the
features of the application (TASK-0002), its quality objectives (TASK-0003) and its context and
constraints (TASK-0004) are known, a fitting architecture can be defined. A documented,
user-approved architecture gives humans and AI agents a common structure to follow and keeps
implementation decisions consistent.

## Task description

After TASK-0002, TASK-0003 and TASK-0004 are done, define a software architecture.

Before proposing anything, analyze the original ASC: use its website
(<https://www.asc-hq.org>) and its public source code to find out its programming language,
the libraries it uses and its structure. Base the proposals on this analysis and summarize it
in `doc/architecture.md`.

The architecture covers both the structure and the technology stack, and is decided topic by
topic. It covers at least these topics:

- the reuse of the original ASC code: how the existing code is used in the port (e.g. keep it
  and call it from Swift, port parts of it to Swift, replace its libraries with Apple
  frameworks),
- the structure of the application (e.g. its main modules and how they depend on each other),
- the programming language and its runtime, including their versions (e.g. the Swift version
  and the minimum macOS version),
- the server-side framework,
- the UI technology (e.g. AppKit, SwiftUI, Metal or SpriteKit),
- the data storage (e.g. save games, maps and settings),
- the integration of the 3rd party systems listed in `doc/context.md`,
- the location of the 3rd party artifacts in the repository (the ASC source code, the
  libraries, and the maps, graphics and campaigns; used by TASK-0008),
- the deployment and operation (e.g. packaging, code signing and notarization, distribution
  via GitHub, updates),
- the build tool, the test framework and the tool for the static quality check (needed by
  TASK-0006).

A topic that does not apply to the application (e.g. no server) is skipped with a short note
in `doc/architecture.md`. Decide on stable releases; a pre-release version needs the user's
explicit decision.

How network games are handled is not decided here; it was postponed to TASK-0009. Note this in
`doc/architecture.md`.

For each topic:

1. Introduce a fitting architecture to the user, based on the results of the previous tasks:
   - the domain, problems and features in `README.md`,
   - the quality objectives in `doc/qualityobjectives.md`,
   - the context and constraints in `doc/context.md`.
   Present the proposed architecture together with at least one alternative, and state the
   advantages and disadvantages of each with respect to the quality objectives and the
   constraints.
2. Discuss the architecture with the user.
3. The user decides in the end on the software architecture. The AI proposes and discusses,
   but does not decide. Ask the user for the reason of each decision. If the user gives no
   reason of their own, tell the user that the arguments of the proposal will be recorded as
   the rationale, and mark it in `doc/architecture.md` as "proposed by the AI, accepted by
   the user".
4. Save the results in `doc/architecture.md`, with one section per topic, including:
   - the architecture the user decided on,
   - the alternatives that were discussed,
   - the rationale for the decision, i.e. why the user chose this architecture over the
     alternatives (e.g. with respect to the quality objectives and constraints).

Finally, add a rule to `AGENTS.md` that every implementation must follow
`doc/architecture.md`, so AI agents read it before working on a task.

## Acceptance criteria

- [x] The AI has analyzed the original ASC (programming language, libraries, structure), and
      `doc/architecture.md` summarizes the analysis.
- [x] For each topic listed in the task description, the AI has introduced a fitting
      architecture and at least one alternative to the user, with their advantages and
      disadvantages with respect to the quality objectives and the constraints, and has
      discussed them with the user.
- [x] The user has decided on each topic of the software architecture.
- [x] `doc/architecture.md` exists and describes the software architecture the user decided on,
      with one section per topic listed in the task description, including the programming
      language and runtime with their versions, the build tool, the test framework and the
      tool for the static quality check. Topics that do not apply are marked as such.
- [x] `doc/architecture.md` contains the decision on the reuse of the original ASC code and
      the location of the 3rd party artifacts in the repository.
- [x] `doc/architecture.md` notes that the handling of network games is decided in TASK-0009.
- [x] `doc/architecture.md` reflects the results of the discussion with the user.
- [x] `doc/architecture.md` lists the alternatives that were discussed for each topic.
- [x] `doc/architecture.md` states the rationale for each decision, as given by the user, or
      marks it as "proposed by the AI, accepted by the user".
- [x] `AGENTS.md` contains a rule that every implementation must follow `doc/architecture.md`.

## History

<!--
  Log of all status changes, oldest first. Add a row for every change of the Status field.
  Timestamp format: ISO 8601 with time zone offset, e.g. 2026-11-11T14:30+0100
  (get it with: date +%Y-%m-%dT%H:%M%z).
  Comment: optional, but required for "waiting" and "aborted" (state the reason).
-->

| Timestamp                | Status | Comment       |
|--------------------------|--------|---------------|
| 2026-11-11T16:25+0100 | open   | Task created  |
| 2026-11-18T16:13+0100 | in-work | Implementation started |
| 2026-11-19T12:53+0100 | done | All acceptance criteria and the Definition of Done are fulfilled |
