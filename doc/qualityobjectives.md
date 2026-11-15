# Quality Objectives

This document defines the quality objectives of **asc-for-mac**, the macOS port of Advanced
Strategic Command (see `README.md`). It is the basis for architecture decisions
(`doc/architecture.md`) and QA measures (`doc/qameasures.md`).

## Standard and rating scale

The objectives are based on the 9 quality characteristics of the product quality model of
**ISO/IEC 25010:2023**.

Each characteristic is rated with a whole number from **1 to 5**:

- **1** = least important
- **5** = most important

The ratings and explanations were given by the project owner.

## Quality objectives

| Characteristic          | Rating | Explanation |
|-------------------------|:------:|-------------|
| Functional suitability  | 3      | No real harm arises if something behaves a little differently from the original version. |
| Performance efficiency  | 3      | The efficiency should be good enough that the user does not have to wait. |
| Compatibility           | 4      | All existing, and probably new, maps should be supported. Saved games from other systems must be supported. Playing over the network with other systems, such as Linux, should work too. |
| Interaction capability  | 3      | The app should behave like a native Mac app. |
| Reliability             | 4      | A crash after a long game would not give a good user experience. |
| Security                | 2      | Security is not a really important issue. However, it must not be possible to break into the system through the ports opened for network play. |
| Maintainability         | 2      | No huge changes are expected after the port is done. |
| Flexibility             | 2      | The app only needs to run on current and future macOS versions. This is to be achieved by using the official macOS APIs and avoiding old and especially deprecated APIs. |
| Safety                  | 1      | No harm can be done to people, property or the environment. |

## Most important objectives

The highest-rated characteristics are **Compatibility** (4) and **Reliability** (4): maps,
save games and network play must work with ASC on other systems, and long games must not end
in a crash.
