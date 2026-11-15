# TASK-0006: Create core application with build system

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0006 |
| **Short description** | Create core application with build system |
| **Status**        | open <!-- One of: open, in-work, waiting, done, aborted -->   |
| **External link** | none |
| **Dependencies**  | TASK-0005 |

## Motivation

All further features need a working foundation: an application skeleton that follows the
defined architecture and can be built, tested and checked automatically. Creating this core
application now, using all the information gathered to define the architecture, ensures that
every following feature is developed on the same structure, with automatic tests and static
quality checks from the start.

## Task description

Using all the information gathered to define the architecture, create a core application with
a build system that can be used as the foundation for further features:

- `README.md`: domain, problems and features of the application
- `doc/qualityobjectives.md`: quality objectives
- `doc/context.md`: context and constraints (e.g. prescribed languages and frameworks)
- `doc/architecture.md`: the software architecture decided on by the user

The core application must use the structure and the technologies decided in
`doc/architecture.md`, in particular:

1. the programming language and runtime in the decided versions,
2. the decided build tool,
3. automatic testing with the decided test framework,
4. a static quality check with the decided tool.

Use stable releases of all tools and libraries. If a decided tool only works in a pre-release
version (e.g. with the decided runtime version), stop and let the user decide, and record the
decision in `doc/architecture.md`.

Before implementing, check which acceptance criteria can only be verified with tools that are
optional or not available (e.g. a container runtime to start a container image). Tell the user
before starting, so the user can provide the tool, or agree with the user that the criterion
is verified later, and note this in the task.

Following the project conventions in `AGENTS.md`:

- Tools that are not listed in `doc/developerInfrastructure.md` (e.g. the runtime) must be
  added there before they are used. The document distinguishes:
  - **required tools** that every developer installs,
  - **tools loaded by the build** (e.g. a build tool wrapper and the libraries), which do not
    have to be installed,
  - **optional tools** (e.g. a container runtime to start the application locally).
- The commands to build, test, run the static quality check and start the application locally
  are documented in `doc/buildAndTest.md`.
- The section "About this project" in `AGENTS.md` names the tech stack and refers to
  `doc/buildAndTest.md` for the commands; the section "Development" in `README.md` refers to
  it as well.
- The build output (e.g. `build/` or `target/` directories and caches of the build tool) is
  excluded in `.gitignore`.

Implementing actual features of the application is out of scope; they are added in later tasks.

## Acceptance criteria

- [ ] The structure of the core application and the technologies it uses follow
      `doc/architecture.md`, including the versions of the programming language and runtime.
- [ ] All tools and libraries are stable releases, or the user has decided on a pre-release
      and the decision is recorded in `doc/architecture.md`.
- [ ] The application is built with the decided build tool, and the build succeeds from a
      clean checkout with a single documented command.
- [ ] Automatic tests can be run with a single documented command; at least one test exists
      and passes.
- [ ] A static quality check can be run with a single documented command and passes without
      findings.
- [ ] The application can be started locally with a single documented command.
- [ ] All tools required for building, testing and the static quality check are listed in
      `doc/developerInfrastructure.md`; tools loaded by the build and optional tools are
      marked as such.
- [ ] The commands for building, testing, the static quality check and starting the
      application are documented in `doc/buildAndTest.md`.
- [ ] The section "About this project" in `AGENTS.md` names the tech stack and refers to
      `doc/buildAndTest.md`; the section "Development" in `README.md` refers to it as well.
- [ ] `.gitignore` excludes the build output, and `git status` shows no build output after a
      build.

## History

<!--
  Log of all status changes, oldest first. Add a row for every change of the Status field.
  Timestamp format: ISO 8601 with time zone offset, e.g. 2026-11-11T14:30+0100
  (get it with: date +%Y-%m-%dT%H:%M%z).
  Comment: optional, but required for "waiting" and "aborted" (state the reason).
-->

| Timestamp                | Status | Comment       |
|--------------------------|--------|---------------|
| 2026-11-11T17:24+0100 | open   | Task created  |
