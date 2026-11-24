# Developer Infrastructure

This document defines the tools that must be installed on every developer's computer.

AI coding agents working in this repository **can rely on these tools being available** and may use them
in scripts and while executing tasks. Agents must not assume any tool that is not listed here. If a new tool
is needed, add it to this document first, so the whole team installs it.

## Required tools

| Tool   | Minimum version | Purpose                                                    | Check installation  |
|--------|-----------------|------------------------------------------------------------|---------------------|
| Bash   | 3.2             | Shell for running the scripts in `scripts/`                | `bash --version`    |
| Python | 3.10            | Scripting language for automation and tooling              | `python3 --version` |
| Git    | 2.20            | Version control; used by `scripts/init-project.sh`         | `git --version`     |
| Xcode  | 27.0            | Apple Clang, macOS SDK and `make` for building the app (macOS 27, Apple Silicon) | `xcodebuild -version` |
| CMake  | 3.25            | Build of the ASC core (`scripts/build-core.sh`)            | `cmake --version`   |
| clang-tidy | 23 (Homebrew `llvm`) | Static check of the facade (`scripts/check.sh`) | `"$(brew --prefix llvm)/bin/clang-tidy" --version` |

### Bash

- **macOS / Linux:** preinstalled.
- **Windows:** use [Git Bash](https://gitforwindows.org/) or WSL (Windows Subsystem for Linux).

macOS ships with Bash 3.2, so scripts must not use features of newer Bash versions
(e.g. associative arrays or `mapfile`) unless the minimum version above is raised.

### Python

- Install from [python.org](https://www.python.org/downloads/) or with a package manager
  (e.g. `brew install python` on macOS, `apt install python3` on Debian/Ubuntu).
- Call Python as `python3`; on some systems `python` is missing or points to Python 2.
- Scripts that need third-party packages must document them (e.g. in a `requirements.txt`)
  instead of assuming they are installed globally.

### Git

- **macOS:** run `git --version`; if Git is missing, macOS offers to install the Xcode Command
  Line Tools, which include it. Alternatively: `brew install git`.
- **Linux:** install with the package manager, e.g. `apt install git` on Debian/Ubuntu.
- **Windows:** install [Git for Windows](https://gitforwindows.org/), which also provides Git Bash.
  Enable symbolic links (see below).

The project uses `git subtree` for the original ASC in `thirdparty/asc/` (see
`doc/thirdparty.md`). It is part of Git (Apple Git, Git for Windows and most Linux packages);
check with `git subtree` (prints its usage). On some Linux distributions it is in a separate
package, e.g. `git-subtree`.

Configure your name and email address once, otherwise commits (e.g. by
`scripts/init-project.sh`) fail:

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

### Xcode

- **macOS only** (asc-for-mac is built on and for macOS 27 on Apple Silicon, see
  `doc/architecture.md`): install Xcode from the App Store or from
  <https://developer.apple.com/xcode/>, start it once to accept the license, and check that
  `xcode-select -p` points to it. Xcode includes Apple Clang, the macOS SDK, `make`, `lipo`
  and `vtool`, and the tools for signing and notarizing a release (`scripts/create-dmg.sh`):
  `xcrun notarytool` and `xcrun stapler`, and Icon Composer with its command line tool `ictool`
  (`"$(xcode-select -p)/../Applications/Icon Composer.app/Contents/Executables/ictool"`) for
  the app icon (`scripts/create-icns.sh`). `codesign`, `diskutil`, `spctl`, `xattr` and `PlistBuddy`
  (`/usr/libexec/PlistBuddy`) are part of macOS.
- **Permission for UI automation:** the UI test (`scripts/test-ui.sh`, see
  `doc/buildAndTest.md`) controls the app with mouse and keyboard. When it runs for the first
  time, macOS asks to allow the UI automation; approve it manually in the dialog. Afterwards
  the UI test runs without asking. Without this approval the UI test cannot run.

### CMake

- **macOS:** `brew install cmake`, or the installer from <https://cmake.org/download/>.

### clang-tidy

- **macOS:** `brew install llvm` (only clang-tidy is used; LLD and LLDB are not needed).
- Homebrew does not put the programs of `llvm` on the `PATH`, so that they do not replace
  Apple's Clang from Xcode. Leave it that way: `scripts/check.sh` finds clang-tidy via
  `brew --prefix llvm`. To use another clang-tidy, set the environment variable `CLANG_TIDY`
  to its path.

swift-format, the Clang Static Analyzer and `libtool` are part of Xcode.

## Tools loaded by the build

- **vcpkg** and the libraries it provides: `scripts/build-core.sh` fetches vcpkg with Git into
  `build/vcpkg` and checks out the commit given as `builtin-baseline` in `vcpkg.json`, which
  also pins the versions of all libraries. vcpkg downloads its own helper tools (e.g. Ninja)
  as needed. Built libraries are cached by vcpkg in `~/.cache/vcpkg/archives`, so later
  builds are fast. Nothing of vcpkg is committed to the repository.
- **SwiftLint**: integrated in the Xcode project as its official Swift package plugin
  (<https://github.com/SimplyDanny/SwiftLintPlugins>, exact version pinned in the project,
  currently 0.65.1). Xcode downloads it into `build/xcode/SourcePackages` (or Xcode's
  DerivedData) and runs it during every build.

## Git: symbolic links

The repository contains symbolic links, e.g. `.claude/skills` → `../skills`, which makes the skills
in `skills/` available to Claude Code. Git must check them out as real symbolic links.

- **macOS / Linux:** works out of the box.
- **Windows:** Git for Windows checks out symbolic links as plain text files by default, which
  silently breaks them. To enable symbolic links:
  1. Enable *Developer Mode* in the Windows settings (*System → For developers*), or run Git
     with administrator rights.
  2. Enable symbolic links in Git, either by selecting *Enable symbolic links* in the Git for
     Windows installer or with:

     ```bash
     git config --global core.symlinks true
     ```

  3. Clone the repository afterwards. For an existing clone, run `git config core.symlinks true`
     inside it and restore the links with `git checkout -- .claude/skills`.

  Check: `ls -l .claude/skills` must show `skills -> ../skills`, and `ls .claude/skills/` must
  list the skill directories.

## Adding a tool

1. Add a row to the table above with minimum version, purpose and a check command.
2. Add installation notes for the supported operating systems.
3. Tell the team, so everyone installs it.

Tools that do not have to be installed by everyone go into their own sections below the
required tools, created when the first such tool is added:

- **Tools loaded by the build:** tools the build downloads itself (e.g. a build tool wrapper
  and libraries), with a note where their versions are defined.
- **Optional tools:** tools only needed for some activities (e.g. a container runtime to start
  the application locally), in a table with purpose and check command. Scripts and the build
  must not require them.
