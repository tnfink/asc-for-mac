#!/usr/bin/env bash
#
# test-long-game.sh - Runs the long-game test of asc-for-mac (QA measure S3).
#
# Usage:
#   scripts/test-long-game.sh
#
# Runs only the Swift test LongGameTests with "xcodebuild test": an AI-only game over many
# rounds on ASC's standard maps without a window, saved and loaded at intervals. It takes
# minutes, so "scripts/test-app.sh" skips it. Builds everything first if needed.
# See doc/buildAndTest.md.

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

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        *)         usage >&2; die "unknown argument '$1'" ;;
    esac
done

command -v xcodebuild >/dev/null 2>&1 || die "xcodebuild not found (see doc/developerInfrastructure.md)"

cd "$REPO_DIR"
# xcodebuild passes variables starting with TEST_RUNNER_ to the tests without the prefix;
# ASC_LONG_GAME=1 enables LongGameTests (app/ASCforMacTests/LongGameTests.swift).
TEST_RUNNER_ASC_LONG_GAME=1 xcodebuild -project ASCforMac.xcodeproj -scheme ASCforMac \
    -configuration Debug -derivedDataPath build/xcode -skipPackagePluginValidation test \
    -only-testing:ASCforMacTests/LongGameTests
