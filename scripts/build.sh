#!/usr/bin/env bash
#
# build.sh - Builds asc-for-mac with Xcode (the main build, see doc/architecture.md).
#
# Usage:
#   scripts/build.sh [--release]
#
# --release   Build the Release configuration (default: Debug).
#
# Runs xcodebuild on ASCforMac.xcodeproj (scheme ASCforMac). The Xcode project builds the
# ASC core, the facade and the libraries from vcpkg through its external build target
# (scripts/build-core.sh), then the Swift app. SwiftLint runs as package plugin during the
# build. Output: build/xcode/Build/Products/<Configuration>/ASCforMac.app.
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

CONFIGURATION=Debug
while [ $# -gt 0 ]; do
    case "$1" in
        --release) CONFIGURATION=Release ;;
        -h|--help) usage; exit 0 ;;
        *)         usage >&2; die "unknown argument '$1'" ;;
    esac
    shift
done

command -v xcodebuild >/dev/null 2>&1 || die "xcodebuild not found (see doc/developerInfrastructure.md)"

cd "$REPO_DIR"
# -skipPackagePluginValidation: the SwiftLint plugin is pinned in the project; without this
# option, xcodebuild asks to trust the plugin interactively.
xcodebuild -project ASCforMac.xcodeproj -scheme ASCforMac -configuration "$CONFIGURATION" \
    -derivedDataPath build/xcode -skipPackagePluginValidation build
