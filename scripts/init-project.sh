#!/usr/bin/env bash
#
# init-project.sh - Turns a new copy of the project template into a new project.
#
# Usage:
#   scripts/init-project.sh [--keep-git | --keep-history] [--yes] NAME
#
# NAME             Name of the new project (letters, digits, ".", "_" and "-"; e.g. MyShop)
# --keep-git       Keep the git history and all remotes as they are. Use this for a
#                  repository created with GitHub's "Use this template" button.
# --keep-history   Keep the template's git history, but rename the remote "origin" to
#                  "upstream", so template updates can still be merged later. Use this
#                  for a clone of the template repository.
#                  Default (neither option): the git history and all remotes are deleted
#                  and a new repository is created.
# --yes            Do not ask for confirmation (for non-interactive use)
#
# Steps:
#   1. Replaces the "About this project" section in AGENTS.md with one for project NAME.
#   2. Removes the template's LICENSE file; the new project chooses its own license.
#   3. Resets the git repository or keeps it (see the options above) and commits the
#      result.
#
# The working tree must be clean before running this script; only changes in aitasks/
# are allowed (they are included in the commit).

# Note for developers: the comment block above is printed by --help.
# Keep this script compatible with Bash 3.2 (see doc/developerInfrastructure.md).

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
    awk '
        NR == 1 { next }
        !/^#/   { exit }
        { sub(/^# ?/, ""); if (started || $0 != "") { started = 1; print } }
    ' "${BASH_SOURCE[0]}"
}

die() {
    echo "Error: $*" >&2
    exit 1
}

# --- Parse arguments -------------------------------------------------------

NAME=""
GIT_MODE=reset
ASSUME_YES=false
while [ $# -gt 0 ]; do
    case "$1" in
        --keep-git|--keep-history)
            [ "$GIT_MODE" = reset ] || die "use only one of --keep-git and --keep-history"
            GIT_MODE="${1#--}"
            ;;
        --yes)          ASSUME_YES=true ;;
        -h|--help)      usage; exit 0 ;;
        -*)             usage >&2; die "unknown option '$1'" ;;
        *)
            [ -z "$NAME" ] || die "only one NAME allowed"
            NAME="$1"
            ;;
    esac
    shift
done

[ -n "$NAME" ] || { usage >&2; die "NAME is missing"; }
echo "$NAME" | grep -Eq '^[A-Za-z0-9][A-Za-z0-9._-]*$' \
    || die "invalid NAME '$NAME' (use letters, digits, '.', '_' and '-', starting with a letter or digit)"

cd "$REPO_DIR"

# --- Checks ----------------------------------------------------------------

[ -d .git ] || die "$REPO_DIR is not the root of a git repository"
command -v git >/dev/null || die "git is not installed"
# Changes in aitasks/ are allowed: the task running this script (TASK-0001) has
# already updated its status there. They are included in the commit below.
if [ -n "$(git status --porcelain -- . ':(exclude)aitasks')" ]; then
    die "the working tree has uncommitted changes outside aitasks/; commit or stash them first"
fi

HAS_ORIGIN=false
git remote get-url origin >/dev/null 2>&1 && HAS_ORIGIN=true

# --- Confirm ---------------------------------------------------------------

echo "This will initialize the project '$NAME' in $REPO_DIR:"
echo "  - replace the 'About this project' section in AGENTS.md"
if [ -f LICENSE ]; then
    echo "  - remove the template's LICENSE file (choose your project's own license)"
fi
if [ "$GIT_MODE" = keep-git ]; then
    echo "  - commit the changes (git history and remotes are kept)"
elif [ "$GIT_MODE" = keep-history ]; then
    if $HAS_ORIGIN; then
        echo "  - rename the git remote 'origin' to 'upstream' ($(git remote get-url origin))"
    fi
    echo "  - commit the changes (git history is kept)"
else
    echo "  - DELETE the git history ($(git rev-list --all --count 2>/dev/null || echo 0) commits) and all remotes,"
    echo "    create a new git repository and make an initial commit"
fi

if ! $ASSUME_YES; then
    [ -t 0 ] || die "no terminal to ask for confirmation; use --yes to proceed without asking"
    printf 'Proceed? [y/N] '
    read -r answer
    case "$answer" in
        y|Y|yes|YES) ;;
        *) echo "Aborted, nothing was changed."; exit 1 ;;
    esac
fi

# --- 1. Update AGENTS.md ---------------------------------------------------

if [ -f AGENTS.md ]; then
    NAME="$NAME" awk '
        /^## About this project/ {
            print
            print ""
            print "This is the project **" ENVIRON["NAME"] "**. It was created from a template for software"
            print "development projects that rely heavily on an AI coding assistant."
            print "The domain, the problems solved and the features of the application are described in"
            print "`README.md`. Keep this section up to date with project-specific information (purpose,"
            print "tech stack, build and test commands)."
            print ""
            skip = 1
            next
        }
        skip && /^## / { skip = 0 }
        !skip { print }
    ' AGENTS.md > AGENTS.md.tmp
    mv AGENTS.md.tmp AGENTS.md
    echo "Updated AGENTS.md."
fi

# --- 2. Remove the template's license --------------------------------------

if [ -f LICENSE ]; then
    rm LICENSE
    echo "Removed the template's LICENSE file. Add your project's own license if needed."
fi

# --- 3. Git ----------------------------------------------------------------

if [ "$GIT_MODE" = keep-git ]; then
    git add -A
    git commit -q -m "Initialize project $NAME from template"
elif [ "$GIT_MODE" = keep-history ]; then
    if $HAS_ORIGIN; then
        git remote rename origin upstream
        echo "Renamed remote 'origin' to 'upstream'. Add the new project's remote with:"
        echo "  git remote add origin <URL>"
    fi
    git add -A
    git commit -q -m "Initialize project $NAME from template"
else
    rm -rf .git
    git init -q
    git add -A
    git commit -q -m "Initial commit of project $NAME (created from template)"
    echo "Created a new git repository. Add the project's remote with:"
    echo "  git remote add origin <URL>"
fi

echo "Project '$NAME' initialized."
