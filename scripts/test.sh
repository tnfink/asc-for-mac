#!/usr/bin/env bash
#
# test.sh - Automated tests for the scripts in scripts/.
#
# Usage:
#   scripts/test.sh
#
# Runs all tests in temporary directories (the repository itself is not changed),
# prints one line per failed check and a summary. Exits with 1 if a check failed.
#
# Run it after every change to a script in scripts/.

# Note for developers: keep this script compatible with Bash 3.2
# (see doc/developerInfrastructure.md). Add tests for every new script or command.

set -u

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TASKS="$REPO_DIR/scripts/tasks.sh"
INIT="$REPO_DIR/scripts/init-project.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Git identity for the commits made in the test repositories, independent of the
# developer's configuration.
export GIT_AUTHOR_NAME="Test" GIT_AUTHOR_EMAIL="test@example.com"
export GIT_COMMITTER_NAME="Test" GIT_COMMITTER_EMAIL="test@example.com"

CHECKS=0
FAILURES=0

fail() {
    FAILURES=$((FAILURES + 1))
    echo "FAIL: $*"
}

# check DESCRIPTION COMMAND...: the command must succeed.
check() {
    local description="$1"
    shift
    CHECKS=$((CHECKS + 1))
    "$@" >/dev/null 2>&1 || fail "$description"
}

# check_fails DESCRIPTION COMMAND...: the command must fail.
check_fails() {
    local description="$1"
    shift
    CHECKS=$((CHECKS + 1))
    if "$@" >/dev/null 2>&1; then fail "$description (expected an error)"; fi
}

# check_equal DESCRIPTION EXPECTED ACTUAL
check_equal() {
    CHECKS=$((CHECKS + 1))
    [ "$2" = "$3" ] || fail "$1: expected '$2', got '$3'"
}

# check_contains DESCRIPTION TEXT PATTERN (fixed string)
check_contains() {
    CHECKS=$((CHECKS + 1))
    printf '%s\n' "$2" | grep -qF -- "$3" || fail "$1: '$3' not found"
}

# check_not_contains DESCRIPTION TEXT PATTERN (fixed string)
check_not_contains() {
    CHECKS=$((CHECKS + 1))
    if printf '%s\n' "$2" | grep -qF -- "$3"; then fail "$1: '$3' found"; fi
}

# field FILE LABEL: value of a header table row, like tasks.sh reads it.
field() {
    awk -F'|' -v label="**$2**" '{
        k = $2; gsub(/^[ \t]+|[ \t]+$/, "", k)
        if (k == label) { v = $3; gsub(/<!--.*-->/, "", v); gsub(/^[ \t]+|[ \t]+$/, "", v); print v; exit }
    }' "$1"
}

# ---------------------------------------------------------------------------
# tasks.sh
# ---------------------------------------------------------------------------

test_tasks() {
    export AITASKS_DIR="$TMP/tasks"
    local out file

    # help
    out="$("$TASKS" help)"
    check_contains "help lists 'list'" "$out" "tasks.sh list"
    check_contains "help lists 'new'" "$out" "tasks.sh new"
    check_contains "help lists 'status'" "$out" "tasks.sh status"
    check_fails "unknown command is rejected" "$TASKS" frobnicate

    # list without task directory
    out="$("$TASKS" list)"
    check_equal "list without tasks prints only the header" "ID   STATUS   SHORT DESCRIPTION" "$out"

    # new
    out="$("$TASKS" new "Define quality objectives based on ISO 25010")"
    file="$AITASKS_DIR/TASK-0001-define-quality-objectives-based-on-iso.md"
    check "new creates the file with a slug cut at a word boundary" test -f "$file"
    check_contains "new reports the created task" "$out" "Created TASK-0001"
    check_equal "new sets the ID" "TASK-0001" "$(field "$file" ID)"
    check_equal "new sets the short description" \
        "Define quality objectives based on ISO 25010" "$(field "$file" "Short description")"
    check_equal "new sets the status open" "open" "$(field "$file" Status)"
    check_contains "new sets the title" "$(cat "$file")" "# TASK-0001: Define quality objectives"
    check_contains "new adds the creation to the history" "$(tail -1 "$file")" "| open   | Task created"
    check_not_contains "new leaves no placeholders" "$(cat "$file")" "{{"

    "$TASKS" new 'Special & chars \1 "quoted"' >/dev/null
    check_equal "new keeps special characters" 'Special & chars \1 "quoted"' \
        "$(field "$AITASKS_DIR"/TASK-0002-*.md "Short description")"
    check_fails "new rejects an empty description" "$TASKS" new "   "
    check_fails "new rejects '|'" "$TASKS" new "a | b"
    check_fails "new rejects several arguments" "$TASKS" new a b

    # next ID after a gap
    mv "$AITASKS_DIR"/TASK-0002-*.md "$AITASKS_DIR/TASK-0009-gap.md"
    sed -i.bak 's/| TASK-0002 |/| TASK-0009 |/' "$AITASKS_DIR/TASK-0009-gap.md" && rm "$AITASKS_DIR"/*.bak
    "$TASKS" new "After the gap" >/dev/null
    check "new continues after the highest ID" test -f "$AITASKS_DIR/TASK-0010-after-the-gap.md"

    # list with filter and dependencies
    sed -i.bak 's/^| \*\*Dependencies\*\*  |.*/| **Dependencies**  | TASK-0001, TASK-0009 |/' \
        "$AITASKS_DIR/TASK-0010-after-the-gap.md" && rm "$AITASKS_DIR"/*.bak
    out="$("$TASKS" list)"
    check_not_contains "list hides dependencies by default" "$out" "DEPENDS ON"
    check_contains "list shows all tasks" "$out" "TASK-0010"
    out="$("$TASKS" list -deps)"
    check_contains "list -deps shows the dependency column" "$out" "DEPENDS ON"
    check_contains "list -deps shows dependencies" "$out" "TASK-0001, TASK-0009"
    check_fails "list rejects an invalid state" "$TASKS" list finished
    check_fails "list rejects an unknown option" "$TASKS" list -x
    check_fails "list rejects two states" "$TASKS" list open "done"

    # status
    file="$AITASKS_DIR/TASK-0001-define-quality-objectives-based-on-iso.md"
    out="$("$TASKS" status TASK-0001 in-work "Implementation started")"
    check_contains "status reports the change" "$out" "TASK-0001: open -> in-work"
    check_equal "status changes the status" "in-work" "$(field "$file" Status)"
    check_contains "status keeps the comment in the status cell" "$(cat "$file")" \
        "in-work <!-- One of: open, in-work, waiting, done, aborted -->"
    check_contains "status adds a history row" "$(tail -1 "$file")" "| in-work | Implementation started |"
    check_fails "status requires a reason for waiting" "$TASKS" status TASK-0001 waiting
    check_fails "status requires a reason for aborted" "$TASKS" status 1 aborted
    check_fails "status rejects '|' in the comment" "$TASKS" status 1 waiting "a | b"
    check_fails "status rejects the current status" "$TASKS" status 1 in-work
    check_fails "status rejects an invalid state" "$TASKS" status 1 finished
    check_fails "status rejects an unknown task" "$TASKS" status TASK-0099 "done"
    "$TASKS" status 1 "done" >/dev/null
    check_equal "status accepts a short ID" "done" "$(field "$file" Status)"
    check_equal "the history has one row per status change" "3" \
        "$(grep -c '^| 20[0-9][0-9]-' "$file")"
    out="$("$TASKS" list "done")"
    check_contains "list filters by status" "$out" "TASK-0001"
    check_not_contains "list filter excludes other tasks" "$out" "TASK-0010"

    unset AITASKS_DIR
}

# ---------------------------------------------------------------------------
# init-project.sh
# ---------------------------------------------------------------------------

# make_repo DIR: creates a minimal copy of the template as a git repository with
# one commit and a remote "origin".
make_repo() {
    local dir="$1"
    mkdir -p "$dir/scripts" "$dir/aitasks"
    cp "$INIT" "$dir/scripts/"
    cat > "$dir/AGENTS.md" <<'EOF'
# AGENTS.md

## About this project

This repository is a **template**.

## Repository layout

Layout text.
EOF
    echo "task" > "$dir/aitasks/TASK-0001-init.md"
    echo "Template license" > "$dir/LICENSE"
    (
        cd "$dir" &&
        git init -q &&
        git add -A &&
        git commit -q -m "Template" &&
        git remote add origin https://example.com/template.git
    )
}

test_init_project() {
    local repo out

    repo="$TMP/init-checks"
    make_repo "$repo"
    check_fails "init-project requires a NAME" "$repo/scripts/init-project.sh" --yes
    check_fails "init-project rejects an invalid NAME" "$repo/scripts/init-project.sh" --yes "my shop"
    check_fails "init-project rejects an unknown option" "$repo/scripts/init-project.sh" --foo Demo
    check_fails "init-project asks for confirmation without --yes" \
        sh -c "'$repo/scripts/init-project.sh' Demo </dev/null"
    echo "change" >> "$repo/AGENTS.md"
    check_fails "init-project rejects changes outside aitasks/" "$repo/scripts/init-project.sh" --yes Demo
    check_equal "a rejected run changes nothing" "1" "$(git -C "$repo" rev-list --count HEAD)"
    check_contains "help shows the usage" "$("$repo/scripts/init-project.sh" --help)" "Usage:"

    # Reset (default)
    repo="$TMP/init-reset"
    make_repo "$repo"
    echo "status in-work" >> "$repo/aitasks/TASK-0001-init.md"
    check "init-project accepts changes in aitasks/" "$repo/scripts/init-project.sh" --yes MyShop
    check_equal "reset leaves a single commit" "1" "$(git -C "$repo" rev-list --count HEAD)"
    check_equal "reset removes all remotes" "" "$(git -C "$repo" remote)"
    check_equal "reset commits everything" "" "$(git -C "$repo" status --porcelain)"
    check_contains "the task change is committed" "$(git -C "$repo" show HEAD:aitasks/TASK-0001-init.md)" \
        "status in-work"
    out="$(cat "$repo/AGENTS.md")"
    check_contains "AGENTS.md names the project" "$out" "This is the project **MyShop**."
    check_not_contains "AGENTS.md no longer describes the template" "$out" "This repository is a **template**."
    check_contains "AGENTS.md keeps the other sections" "$out" "## Repository layout"
    check_fails "reset removes the template's LICENSE" test -e "$repo/LICENSE"

    # Keep history
    repo="$TMP/init-keep"
    make_repo "$repo"
    check "init-project --keep-history succeeds" "$repo/scripts/init-project.sh" --keep-history --yes MyShop
    check_equal "keep-history adds one commit" "2" "$(git -C "$repo" rev-list --count HEAD)"
    check_equal "keep-history renames origin to upstream" "upstream" "$(git -C "$repo" remote)"
    check_contains "keep-history updates AGENTS.md" "$(cat "$repo/AGENTS.md")" "**MyShop**"
    check_fails "keep-history removes the template's LICENSE" test -e "$repo/LICENSE"
    check_equal "keep-history commits everything" "" "$(git -C "$repo" status --porcelain)"

    # Keep git (repository created with "Use this template")
    repo="$TMP/init-keep-git"
    make_repo "$repo"
    check_fails "init-project rejects --keep-git together with --keep-history" \
        "$repo/scripts/init-project.sh" --keep-git --keep-history --yes MyShop
    check "init-project --keep-git succeeds" "$repo/scripts/init-project.sh" --keep-git --yes MyShop
    check_equal "keep-git adds one commit" "2" "$(git -C "$repo" rev-list --count HEAD)"
    check_equal "keep-git keeps origin" "https://example.com/template.git" \
        "$(git -C "$repo" remote get-url origin 2>/dev/null)"
    check_equal "keep-git commits everything" "" "$(git -C "$repo" status --porcelain)"
    check_contains "keep-git updates AGENTS.md" "$(cat "$repo/AGENTS.md")" "**MyShop**"
    check_fails "keep-git removes the template's LICENSE" test -e "$repo/LICENSE"
}

# ---------------------------------------------------------------------------

test_tasks
test_init_project

echo "$CHECKS checks, $FAILURES failed."
[ "$FAILURES" -eq 0 ]
