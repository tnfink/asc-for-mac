#!/usr/bin/env bash
#
# test-ui.sh - Runs the UI test of asc-for-mac (QA measure S6, see doc/qameasures.md).
#
# Usage:
#   scripts/test-ui.sh
#
# Runs "xcodebuild test" on ASCforMac.xcodeproj with the scheme ASCforMacUITests: starts the
# app without the game (launch argument --no-game) and checks the menu bar, the About window
# and Quit with Cmd+Q. Builds everything first if needed (Xcode output in build/xcode).
# The UI test takes over mouse and keyboard while it runs; do not use the computer meanwhile.
# macOS asks once for the permission for UI automation, see doc/developerInfrastructure.md.
# scripts/test-app.sh does not run the UI test. See doc/buildAndTest.md.

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
echo "The UI test takes over mouse and keyboard; do not use the computer until it has finished."
xcodebuild -project ASCforMac.xcodeproj -scheme ASCforMacUITests -configuration Debug \
    -derivedDataPath build/xcode -skipPackagePluginValidation test
