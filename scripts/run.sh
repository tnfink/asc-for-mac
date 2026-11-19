#!/usr/bin/env bash
#
# run.sh - Starts the locally built asc-for-mac app.
#
# Usage:
#   scripts/run.sh [--build]
#
# --build   Build the app first with scripts/build.sh.
#
# Opens build/xcode/Build/Products/Debug/ASCforMac.app. See doc/buildAndTest.md.

# Note for developers: the comment block above is printed by --help.
# Keep this script compatible with Bash 3.2 (see doc/developerInfrastructure.md).

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$REPO_DIR/build/xcode/Build/Products/Debug/ASCforMac.app"

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

BUILD=false
while [ $# -gt 0 ]; do
    case "$1" in
        --build)   BUILD=true ;;
        -h|--help) usage; exit 0 ;;
        *)         usage >&2; die "unknown argument '$1'" ;;
    esac
    shift
done

if $BUILD; then
    "$REPO_DIR/scripts/build.sh"
fi
[ -d "$APP" ] || die "$APP not found; run scripts/build.sh first (or use --build)"
open "$APP"
