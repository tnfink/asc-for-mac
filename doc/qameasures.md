# QA Measures

This document describes the automated quality assurance (QA) measures of **asc-for-mac**,
derived from the quality objectives in `doc/qualityobjectives.md` (ISO/IEC 25010:2023, rating
1 = least important to 5 = most important). The measures were decided by the project owner in
TASK-0007. A rationale marked *"proposed by the AI, accepted by the user"* consists of the
arguments of the AI's suggestion, which the user accepted as the reason.

How to run the existing measures is described in `doc/buildAndTest.md`.

## Existing QA measures (from TASK-0006)

| Measure | What it checks | Quality objectives |
|---------|----------------|--------------------|
| Facade tests (Swift Testing, `scripts/test-app.sh`) | The facade returns correct results from the ASC core | Functional suitability (3) |
| ASC's `unittester` (run by the Swift tests and `scripts/test-core.sh`) | About 19 test modules of the game core: attack, movement, research, AI, events, stream encoding (save game format), map loading | Functional suitability (3), Compatibility (4), Reliability (4) |
| `swift format lint` (`scripts/check.sh`) | Uniform formatting of the Swift code | Maintainability (2) |
| SwiftLint, strict (Xcode build) | Risky Swift patterns, e.g. force casts | Reliability (4), Maintainability (2) |
| clang-tidy (facade, `scripts/check.sh`) | Bug-prone patterns, CERT rules, modernization | Reliability (4), Security (2), Maintainability (2) |
| Clang Static Analyzer (facade, `scripts/check.sh`) | Null pointers, memory and logic errors | Reliability (4), Security (2) |
| Compiler warnings as errors (Swift app, facade) | All warnings, including the use of deprecated APIs in the project's own code | Reliability (4), Flexibility (2) |

**Gaps** identified in TASK-0007:

- **Compatibility (4):** no test uses real maps and save games from ASC on other systems.
- **Reliability (4):** the old C++ core runs with a new compiler on arm64 for the first time,
  without a check for memory errors at runtime; a crash after a long game is not tested.
- The static checks cover only the project's own code, not the ASC core.
- The measures do not run automatically.

## Decided QA measures

| # | Measure | Quality objectives | When it runs | Task |
|---|---------|--------------------|--------------|------|
| S1 | **Compatibility test with real files:** a set of maps and save games created with ASC on Linux (and Windows, if available) is loaded automatically; save games are also saved again and compared. | Compatibility (4) | With the automated tests | TASK-0015 |
| S2 | **Sanitizer run:** `unittester` and the Swift tests also run with AddressSanitizer and UndefinedBehaviorSanitizer. | Reliability (4) | Active immediately, with the automated tests | TASK-0016 |
| S3 | **Long-game test:** an automated game AI against AI over many turns on standard maps, without a window; it must not crash, and saving and loading in between must work. | Reliability (4), Compatibility (4) | At least for every release; at the end of each task if the test is fast | TASK-0017 |
| S5 | **Performance smoke test:** time limits for loading a map and for an AI turn. | Performance efficiency (3) | With the automated tests, for regression testing | TASK-0018 |
| S6 | **UI test** (XCTest UI testing): starts the app and checks the menu bar, About and Quit. | Interaction capability (3) | With the automated tests | TASK-0019 |
| S7 | **Code coverage** of the Swift app and the facade, measured with Xcode's coverage report, so that regressions in coverage are detected. | Maintainability (2), Functional suitability (3) | Active immediately, with the automated tests | TASK-0020 |
| CI | **Continuous integration:** build, automated tests and static checks run automatically for every push (instead of S4). | All objectives (ensures that the measures actually run) | For every push | TASK-0021 |

**Security of network play (S8)** is decided together with the handling of network games in
TASK-0009, which records the resulting QA measures in this document.

### Rationale

- **S1** — *proposed by the AI, accepted by the user:* Compatibility is the highest-rated
  objective (together with Reliability); maps and save games from other systems must work, and
  only real files from those systems show whether they do. The test needs the facade functions
  for loading and saving from TASK-0013.
- **S2** — *proposed by the AI, accepted by the user:* the C++ core runs with a new compiler
  on arm64 for the first time; sanitizers find memory errors and undefined behavior at runtime,
  like the alignment problem found in TASK-0012, before they cause crashes (Reliability). The
  user decided that it must be active immediately.
- **S3** — *proposed by the AI, accepted by the user:* the user named a crash after a long game
  as a bad user experience (Reliability); only a long automated game tests this, including
  saving and loading in between. The user decided that it runs at least for every release and,
  if it is fast, at the end of each task.
- **S5** (user): important for regression testing; the user wants that the user does not have
  to wait (Performance efficiency).
- **S6** — *proposed by the AI, accepted by the user:* the app should behave like a native Mac
  app (Interaction capability); a UI test checks the menu bar, About and Quit automatically. The
  user decided that it is done in its own task.
- **S7** (user): it makes sense to measure the coverage early to detect regressions; there is no
  benefit in adding it later. (The AI had suggested not to add it now because of its low value
  at this stage.)
- **CI** (user): an automatic run for every push is done by a CI later, instead of a local git
  hook (S4).

## Suggested measures that were not chosen

| # | Measure | Reason |
|---|---------|--------|
| S4 | A git `pre-push` hook running `scripts/check.sh` and `scripts/test-app.sh` before each push. | (user) This will be done by the CI later (TASK-0021). |
| S8 | Security test of network play (open ports, malformed packets) as a separate measure. | (user) Belongs to TASK-0009, which decides the handling of network games and how network play is secured and tested. |
