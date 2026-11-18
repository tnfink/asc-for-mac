# Context and Constraints

This document describes the context and constraints of **asc-for-mac**, the macOS port of
Advanced Strategic Command (see `README.md`). Together with `doc/qualityobjectives.md` it is
the basis for the software architecture (`doc/architecture.md`). The content is based on the
answers of the project owner.

## 3rd party systems

asc-for-mac includes these 3rd party artifacts:

- the original ASC source code (<https://www.asc-hq.org>),
- the libraries ASC uses, e.g. for graphics, sound or networking,
- ASC's existing maps, graphics and campaigns.

These artifacts are **only used at build time**. To minimize the dependencies, all needed
artifacts are copied into the repository (task TASK-0008), so the build does not depend on
external sources.

**Open point:** whether network games need a 3rd party system at runtime (e.g. a server or
service for network play) or run directly between the players' computers is not decided yet.
The decision is postponed to task TASK-0009.

## Programming languages and frameworks

There are **no constraints** on programming languages or frameworks.

Preference of the project owner: use **Swift** and the current frameworks Apple provides.

## Legal and regulatory requirements

Only the **open-source license of ASC** constrains the project. Because of it, the app is not
distributed through Apple's App Store (see `README.md`).

## Operations, distribution and hosting

- **Distribution:** the app is published on a platform that supports open-source products,
  such as GitHub, and is downloaded from there. It is not distributed through Apple's App
  Store.
- **Apple Developer ID:** a new Apple Developer ID is needed (task TASK-0010).
- **Supported systems:** the current Mac models and macOS versions are supported.
