#!/usr/bin/env bash
#
# test-sanitizers.sh - Runs all automated tests with AddressSanitizer and
# UndefinedBehaviorSanitizer (QA measure S2, see doc/qameasures.md).
#
# Usage:
#   scripts/test-sanitizers.sh
#
# Steps:
#   1. Builds the ASC core, the facade and unittester with the sanitizers into
#      build/core-sanitizers (scripts/build-core.sh --sanitizers).
#   2. Runs ASC's unittester from this build (scripts/test-core.sh --sanitizers).
#   3. Runs the Swift tests with xcodebuild, with AddressSanitizer and
#      UndefinedBehaviorSanitizer enabled, linking the instrumented libasc_all.a from
#      build/core-sanitizers (Xcode output in build/xcode-sanitizers).
# Every sanitizer finding aborts the program and makes this script fail. The normal build
# (build/core, build/xcode) is not touched. See doc/buildAndTest.md.

# Note for developers: the comment block above is printed by --help.
# Keep this script compatible with Bash 3.2 (see doc/developerInfrastructure.md).

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SANITIZER_DIR="$REPO_DIR/build/core-sanitizers"

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
    shift
done

command -v xcodebuild >/dev/null 2>&1 || die "xcodebuild not found (see doc/developerInfrastructure.md)"

cd "$REPO_DIR"

echo "== 1/3 Build the ASC core with sanitizers"
scripts/build-core.sh --sanitizers

echo "== 2/3 unittester with sanitizers"
scripts/test-core.sh --sanitizers

echo "== 3/3 Swift tests with sanitizers"
# TEST_RUNNER_ASC_CORE_BUILD_DIR is passed to the tests as ASC_CORE_BUILD_DIR, so the
# unittester test runs the instrumented unittester.
TEST_RUNNER_ASC_CORE_BUILD_DIR="$SANITIZER_DIR" \
xcodebuild -project ASCforMac.xcodeproj -scheme ASCforMac -configuration Debug \
    -derivedDataPath build/xcode-sanitizers -skipPackagePluginValidation \
    -enableAddressSanitizer YES -enableUndefinedBehaviorSanitizer YES \
    ASC_CORE_BUILD_DIR="$SANITIZER_DIR" ASC_CORE_BUILD_ARGS=--sanitizers \
    test
echo "All tests passed with sanitizers."
