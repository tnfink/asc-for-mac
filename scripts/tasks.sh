#!/usr/bin/env bash
#
# tasks.sh - Helper for handling AI tasks stored in aitasks/.
#
# Usage:
#   scripts/tasks.sh list [-deps] [STATE]     List tasks (ID, status, short description),
#                                             optionally only those with the given STATE;
#                                             -deps also shows the dependencies of each task
#   scripts/tasks.sh new SHORT_DESCRIPTION    Create a new task with the next free ID
#                                             (TASK-0001, TASK-0002, ...) and status open
#   scripts/tasks.sh status ID STATE [COMMENT]
#                                             Set the status of task ID (e.g. TASK-0003) and
#                                             add a row to its History; COMMENT is required
#                                             for waiting and aborted (state the reason)
#   scripts/tasks.sh help                     Show this help
#
# STATE is one of: open, in-work, waiting, done, aborted
#
# Task files are all *.md files in aitasks/.
# The directory can be overridden with the environment variable AITASKS_DIR.

# Note for developers: the comment block above is printed by "help" (it ends at the
# first non-comment line). Document every new command there.
# The template for new tasks is defined in the function print_template below.
# Keep this script compatible with Bash 3.2 (see doc/developerInfrastructure.md).

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TASKS_DIR="${AITASKS_DIR:-$REPO_DIR/aitasks}"
VALID_STATES="open in-work waiting done aborted"

# usage: prints the header comment of this script (all comment lines after the
# shebang up to the first non-comment line), without the leading "# ".
# Skips the leading empty "#" line, so the help starts with the script name.
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

is_valid_state() {
    local state
    for state in $VALID_STATES; do
        [ "$state" = "$1" ] && return 0
    done
    return 1
}

# get_field FILE LABEL
# Prints the value of a row "| **LABEL** | value |" in the task's header table,
# with HTML comments and surrounding whitespace removed.
get_field() {
    awk -F'|' -v label="**$2**" '
        {
            key = $2
            gsub(/^[ \t]+|[ \t]+$/, "", key)
            if (key == label) {
                value = $3
                gsub(/<!--.*-->/, "", value)
                gsub(/^[ \t]+|[ \t]+$/, "", value)
                print value
                exit
            }
        }' "$1"
}

# task_files: prints all task files, one per line, sorted by name.
task_files() {
    local file
    for file in "$TASKS_DIR"/*.md; do
        [ -e "$file" ] || continue
        echo "$file"
    done
}

# cmd_list [-deps] [STATE]: options and STATE may be given in any order.
cmd_list() {
    local filter="" show_deps=false arg
    for arg in "$@"; do
        case "$arg" in
            -deps|--deps) show_deps=true ;;
            -*) die "unknown option '$arg' for 'list'" ;;
            *)
                [ -z "$filter" ] || die "only one STATE allowed for 'list'"
                filter="$arg"
                ;;
        esac
    done
    if [ -n "$filter" ] && ! is_valid_state "$filter"; then
        die "invalid state '$filter' (valid: $VALID_STATES)"
    fi

    # Rows are collected tab-separated first, so the column widths can be
    # computed from the content (the dependency lists vary in length).
    local file id status dependencies description
    {
        if $show_deps; then
            printf 'ID\tSTATUS\tDEPENDS ON\tSHORT DESCRIPTION\n'
        else
            printf 'ID\tSTATUS\tSHORT DESCRIPTION\n'
        fi
        while IFS= read -r file; do
            [ -n "$file" ] || continue
            status="$(get_field "$file" "Status")"
            if [ -n "$filter" ] && [ "$status" != "$filter" ]; then
                continue
            fi
            id="$(get_field "$file" "ID")"
            description="$(get_field "$file" "Short description")"
            if $show_deps; then
                dependencies="$(get_field "$file" "Dependencies")"
                case "$dependencies" in
                    ""|none|None|NONE) dependencies="-" ;;
                esac
                printf '%s\t%s\t%s\t%s\n' "${id:-?}" "${status:-?}" "$dependencies" "$description"
            else
                printf '%s\t%s\t%s\n' "${id:-?}" "${status:-?}" "$description"
            fi
        done <<EOF
$(task_files)
EOF
    } | format_columns
}

# format_columns: reads tab-separated rows and prints them as aligned columns
# (the last column is not padded).
format_columns() {
    awk -F'\t' '
        {
            rows[NR] = $0
            for (i = 1; i < NF; i++) if (length($i) > width[i]) width[i] = length($i)
        }
        END {
            for (r = 1; r <= NR; r++) {
                n = split(rows[r], cols, "\t")
                line = ""
                for (i = 1; i < n; i++) line = line sprintf("%-" width[i] "s   ", cols[i])
                print line cols[n]
            }
        }'
}

# next_id: prints the next free task ID (highest existing number + 1), considering
# both the ID fields and the file names of existing tasks.
next_id() {
    local file id number max=0
    while IFS= read -r file; do
        [ -n "$file" ] || continue
        for id in "$(get_field "$file" "ID")" "$(basename "$file")"; do
            number="$(echo "$id" | sed -n 's/^TASK-\([0-9][0-9]*\).*/\1/p')"
            [ -n "$number" ] || continue
            number=$((10#$number))
            [ "$number" -gt "$max" ] && max="$number"
        done
    done <<EOF
$(task_files)
EOF
    printf 'TASK-%04d\n' $((max + 1))
}

# slugify TEXT: lowercase, non-alphanumerics replaced by "-", at most 40 characters.
# Longer slugs are cut at a word boundary (a single word longer than 40 characters is cut).
slugify() {
    local slug short
    slug="$(echo "$1" | tr '[:upper:]' '[:lower:]' \
        | sed -e 's/[^a-z0-9][^a-z0-9]*/-/g' -e 's/^-//' -e 's/-$//')"
    if [ "${#slug}" -le 40 ]; then
        echo "$slug"
        return
    fi
    # Keep 41 characters, so a word ending exactly at position 40 is kept,
    # then drop the last (incomplete) word.
    short="$(echo "$slug" | cut -c1-41 | sed 's/-[^-]*$//')"
    if [ "${#short}" -gt 40 ] || [ -z "$short" ]; then
        short="$(echo "$slug" | cut -c1-40)"
    fi
    echo "$short"
}

# find_task ID: prints the file of the task with the given ID (TASK-0003, or just 3 / 0003).
find_task() {
    local id="$1" file
    case "$id" in
        TASK-*) ;;
        *[!0-9]*|"") die "invalid task ID '$1' (expected e.g. TASK-0003)" ;;
        *) id="$(printf 'TASK-%04d' $((10#$id)))" ;;
    esac
    while IFS= read -r file; do
        [ -n "$file" ] || continue
        if [ "$(get_field "$file" "ID")" = "$id" ]; then
            echo "$file"
            return
        fi
    done <<EOF
$(task_files)
EOF
    die "task $id not found in $TASKS_DIR"
}

# cmd_status ID STATE [COMMENT]: sets the status of a task and records the change
# in its History section.
cmd_status() {
    local file new_state="$2" comment="${3:-}" old_state timestamp
    file="$(find_task "$1")"
    is_valid_state "$new_state" || die "invalid state '$new_state' (valid: $VALID_STATES)"
    case "$comment" in
        *'|'*) die "COMMENT must not contain '|'" ;;
    esac
    if [ -z "$comment" ]; then
        case "$new_state" in
            waiting|aborted) die "a COMMENT with the reason is required for '$new_state'" ;;
        esac
    fi
    old_state="$(get_field "$file" "Status")"
    [ "$old_state" != "$new_state" ] || die "$1 already has the status '$new_state'"
    timestamp="$(date +%Y-%m-%dT%H:%M%z)"

    # Pass 1 finds the last table row of the History section; pass 2 replaces the
    # status value (keeping the comment in the cell) and appends the new history row.
    STATE="$new_state" ROW="| $timestamp | $new_state | $comment |" awk -F'|' -v OFS='|' '
        NR == FNR {
            if (/^## /) in_history = ($0 ~ /^## History/)
            if (in_history && /^\|/) last_row = FNR
            next
        }
        {
            key = $2
            gsub(/^[ \t]+|[ \t]+$/, "", key)
            if (key == "**Status**") {
                if (!sub(/^[ \t]*[a-z-]+/, " " ENVIRON["STATE"], $3)) $3 = " " ENVIRON["STATE"] " " $3
            }
            print
            if (FNR == last_row) print ENVIRON["ROW"]
        }
        END { if (!last_row) exit 1 }
    ' "$file" "$file" > "$file.tmp" || { rm -f "$file.tmp"; die "no History table found in $file"; }
    mv "$file.tmp" "$file"

    echo "$(get_field "$file" "ID"): ${old_state:-?} -> $new_state"
}

# print_template: prints the template for a new task. The placeholders {{ID}},
# {{DESCRIPTION}} and {{TIMESTAMP}} are replaced by cmd_new. The rows "ID", "Status",
# "Dependencies" and "Short description" are read by get_field, so keep their format intact.
print_template() {
    cat <<'TEMPLATE'
# {{ID}}: {{DESCRIPTION}}

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | {{ID}} |
| **Short description** | {{DESCRIPTION}} |
| **Status**        | open <!-- One of: open, in-work, waiting, done, aborted -->   |
| **External link** | <!-- Optional, e.g. https://jira.example.com/browse/PROJ-123; otherwise "none" -->  |
| **Dependencies**  | <!-- IDs of tasks that must be done first, e.g. TASK-0002, TASK-0005; otherwise "none" --> |

## Motivation

<!--
  Why is this task important? What problem does it solve, who benefits,
  and what happens if it is not done? Give the AI enough context to make
  sensible decisions in situations the task description does not cover.
-->

## Task description

<!--
  What needs to be done? Describe the expected changes, relevant files,
  components or documents in doc/, constraints, and anything that is
  explicitly out of scope.
-->

## Acceptance criteria

<!--
  Concrete, verifiable conditions that must all be met for the task to be
  considered done. Prefer criteria that can be checked by a command, test,
  or inspection.
-->

- [ ] <!-- e.g. Feature X behaves as described when ... -->
- [ ] <!-- e.g. Automated tests for X exist and pass (scripts/test.sh) -->
- [ ] <!-- e.g. Command Y prints Z for input W -->

## History

<!--
  Log of all status changes, oldest first. Add a row for every change of the Status field.
  Timestamp format: ISO 8601 with time zone offset, e.g. 2026-11-11T14:30+0100
  (get it with: date +%Y-%m-%dT%H:%M%z).
  Comment: optional, but required for "waiting" and "aborted" (state the reason).
-->

| Timestamp                | Status | Comment       |
|--------------------------|--------|---------------|
| {{TIMESTAMP}} | open   | Task created  |
TEMPLATE
}

cmd_new() {
    local description="$1"
    description="$(echo "$description" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    [ -n "$description" ] || die "SHORT_DESCRIPTION must not be empty"
    case "$description" in
        *'|'*) die "SHORT_DESCRIPTION must not contain '|'" ;;
    esac

    mkdir -p "$TASKS_DIR"
    local id slug file timestamp
    id="$(next_id)"
    slug="$(slugify "$description")"
    file="$TASKS_DIR/$id${slug:+-$slug}.md"
    [ -e "$file" ] && die "file already exists: $file"
    timestamp="$(date +%Y-%m-%dT%H:%M%z)"

    # Values are passed via the environment and replaced literally (no regex, so
    # characters like "&" or "\" in the description are kept as they are).
    print_template | ID="$id" DESCRIPTION="$description" TIMESTAMP="$timestamp" awk '
        function replace(line, placeholder, value,    out, pos) {
            out = ""
            while ((pos = index(line, placeholder)) > 0) {
                out = out substr(line, 1, pos - 1) value
                line = substr(line, pos + length(placeholder))
            }
            return out line
        }
        {
            line = replace($0, "{{ID}}", ENVIRON["ID"])
            line = replace(line, "{{DESCRIPTION}}", ENVIRON["DESCRIPTION"])
            line = replace(line, "{{TIMESTAMP}}", ENVIRON["TIMESTAMP"])
            print line
        }
    ' > "$file"

    echo "Created $id: $file"
}

main() {
    local command="${1:-help}"
    [ $# -gt 0 ] && shift
    case "$command" in
        list)
            cmd_list "$@"
            ;;
        new)
            [ $# -eq 1 ] || die "usage: tasks.sh new SHORT_DESCRIPTION (quote it if it contains spaces)"
            cmd_new "$1"
            ;;
        status)
            [ $# -ge 2 ] && [ $# -le 3 ] \
                || die "usage: tasks.sh status ID STATE [COMMENT] (quote COMMENT if it contains spaces)"
            cmd_status "$@"
            ;;
        help|-h|--help)
            usage
            ;;
        *)
            usage >&2
            die "unknown command '$command'"
            ;;
    esac
}

main "$@"
