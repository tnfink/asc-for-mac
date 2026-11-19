#!/usr/bin/env bash
#
# test-app.sh - Runs all automated tests of asc-for-mac with Xcode.
#
# Usage:
#   scripts/test-app.sh
#
# Runs "xcodebuild test" on ASCforMac.xcodeproj (scheme ASCforMac): the Swift Testing tests
# of the facade and the test that runs ASC's unittester. Builds everything first if needed.
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
xcodebuild -project ASCforMac.xcodeproj -scheme ASCforMac -configuration Debug \
    -derivedDataPath build/xcode -skipPackagePluginValidation test
