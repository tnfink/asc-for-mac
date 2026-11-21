#!/usr/bin/env bash
#
# build-core.sh - Builds the ASC core and ASC's unittester for macOS with CMake and vcpkg.
#
# Usage:
#   scripts/build-core.sh [--clean] [--sanitizers | --coverage]
#
# --clean        Delete the CMake build directory first; vcpkg and its downloaded and
#                built libraries are kept.
# --sanitizers   Build with AddressSanitizer and UndefinedBehaviorSanitizer (preset
#                "macos-sanitizers") into build/core-sanitizers instead of build/core
#                (QA measure S2, see doc/qameasures.md).
# --coverage     Compile the facade with code coverage instrumentation (preset
#                "macos-coverage") into build/core-coverage instead of build/core
#                (QA measure S7, see doc/qameasures.md).
#
# Steps:
#   1. Fetches vcpkg into build/vcpkg (git clone), at the commit given as
#      "builtin-baseline" in vcpkg.json, and bootstraps it. Nothing of vcpkg is
#      committed to the repository.
#   2. Configures the CMake build with the preset "macos" (CMakePresets.json); vcpkg
#      downloads and builds the libraries listed in vcpkg.json as static libraries for
#      arm64 and macOS 27 (triplet arm64-osx-asc in cmake/triplets/).
#   3. Builds the ASC core library, ASC's tool asc_mount, the data archives and
#      unittester into build/core.
#   4. Creates the licence information for the app (scripts/create-licenses.sh) in
#      build/core/licenses/.
#
# The ASC code and data are taken from thirdparty/asc/; only vcpkg and its libraries
# are downloaded. See doc/buildAndTest.md.

# Note for developers: the comment block above is printed by --help.
# Keep this script compatible with Bash 3.2 (see doc/developerInfrastructure.md).

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VCPKG_DIR="$REPO_DIR/build/vcpkg"
BUILD_DIR="$REPO_DIR/build/core"
PRESET=macos
VCPKG_URL="https://github.com/microsoft/vcpkg.git"

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

CLEAN=false
while [ $# -gt 0 ]; do
    case "$1" in
        --clean)   CLEAN=true ;;
        --sanitizers) PRESET=macos-sanitizers; BUILD_DIR="$REPO_DIR/build/core-sanitizers" ;;
        --coverage)   PRESET=macos-coverage; BUILD_DIR="$REPO_DIR/build/core-coverage" ;;
        -h|--help) usage; exit 0 ;;
        *)         usage >&2; die "unknown argument '$1'" ;;
    esac
    shift
done

command -v cmake >/dev/null 2>&1 || die "cmake not found (see doc/developerInfrastructure.md)"
command -v git >/dev/null 2>&1 || die "git not found (see doc/developerInfrastructure.md)"

# --- vcpkg -------------------------------------------------------------------

BASELINE="$(sed -n 's/.*"builtin-baseline"[^"]*"\([0-9a-f]*\)".*/\1/p' "$REPO_DIR/vcpkg.json")"
[ -n "$BASELINE" ] || die "no builtin-baseline found in vcpkg.json"

if [ ! -d "$VCPKG_DIR/.git" ]; then
    echo "Fetching vcpkg into $VCPKG_DIR ..."
    git clone --quiet "$VCPKG_URL" "$VCPKG_DIR"
fi
if [ "$(git -C "$VCPKG_DIR" rev-parse HEAD)" != "$BASELINE" ]; then
    echo "Checking out vcpkg $BASELINE ..."
    git -C "$VCPKG_DIR" fetch --quiet origin
    git -C "$VCPKG_DIR" checkout --quiet "$BASELINE"
    rm -f "$VCPKG_DIR/vcpkg"
fi
if [ ! -x "$VCPKG_DIR/vcpkg" ]; then
    echo "Bootstrapping vcpkg ..."
    "$VCPKG_DIR/bootstrap-vcpkg.sh" -disableMetrics
fi

# --- CMake -------------------------------------------------------------------

if $CLEAN; then
    rm -rf "$BUILD_DIR"
fi

cd "$REPO_DIR"
export VCPKG_ROOT="$VCPKG_DIR"
export VCPKG_DISABLE_METRICS=1
cmake --preset "$PRESET"
cmake --build --preset "$PRESET" --parallel
# The licence information shown in the app (copied into the app bundle by the Xcode build).
"$REPO_DIR/scripts/create-licenses.sh" --installed "$BUILD_DIR/vcpkg_installed" \
    --output "$BUILD_DIR/licenses/Licenses.json"
echo "ASC core built in $BUILD_DIR"
