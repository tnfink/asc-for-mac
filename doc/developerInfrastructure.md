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

Configure your name and email address once, otherwise commits (e.g. by
`scripts/init-project.sh`) fail:

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

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
