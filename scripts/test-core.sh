#!/usr/bin/env bash
#
# test-core.sh - Runs ASC's unittester built by scripts/build-core.sh.
#
# Usage:
#   scripts/test-core.sh [--sanitizers]
#
# --sanitizers   Run the unittester of the sanitizer build (build/core-sanitizers, built
#                with scripts/build-core.sh --sanitizers) instead of build/core.
#
# Runs build/core/unittester in build/core/unittest-run, where the build has placed
# the data archives (unittest-data/main.ascdat, unittest-data/asc2_dlg.zip) and the
# configuration file asc2rc. Exits with the exit code of unittester (0 = all tests
# passed). Build first with scripts/build-core.sh. See doc/buildAndTest.md.

# Note for developers: the comment block above is printed by --help.
# Keep this script compatible with Bash 3.2 (see doc/developerInfrastructure.md).

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$REPO_DIR/build/core"

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

while [ $# -gt 0 ]; do
    case "$1" in
        --sanitizers) BUILD_DIR="$REPO_DIR/build/core-sanitizers" ;;
        -h|--help) usage; exit 0 ;;
        *)         usage >&2; die "unknown argument '$1'" ;;
    esac
    shift
done

[ -x "$BUILD_DIR/unittester" ] || die "$BUILD_DIR/unittester not found; run scripts/build-core.sh first"
[ -d "$BUILD_DIR/unittest-run" ] || die "$BUILD_DIR/unittest-run not found; run scripts/build-core.sh first"

cd "$BUILD_DIR/unittest-run"
exec "$BUILD_DIR/unittester" -c asc2rc
