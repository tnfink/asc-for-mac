#!/usr/bin/env bash
#
# check.sh - Runs the static quality check of asc-for-mac's own code.
#
# Usage:
#   scripts/check.sh
#
# Checks only the project's own code (app/ and facade/), not thirdparty/asc/
# (see doc/architecture.md, "Static quality check"):
#   1. swift format lint (included in Xcode) for the Swift code in app/,
#   2. clang-tidy (Homebrew's llvm package) for the facade, configured in facade/.clang-tidy,
#   3. the Clang Static Analyzer (included in Xcode) for the facade,
#   4. the Xcode build (scripts/build.sh), in which SwiftLint runs as package plugin and
#      compiler warnings are treated as errors,
#   5. that the SBOM doc/sbom.spdx.json is up to date (scripts/create-sbom.sh --check).
# Exits with 1 if a check reports a finding. See doc/buildAndTest.md.

# Note for developers: the comment block above is printed by --help.
# Keep this script compatible with Bash 3.2 (see doc/developerInfrastructure.md).

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPILE_DB="$REPO_DIR/build/core/compile_commands.json"

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

# clang-tidy is not on the PATH: Homebrew does not link its llvm package, so that it does not
# replace Apple's Clang (see doc/developerInfrastructure.md).
CLANG_TIDY="${CLANG_TIDY:-}"
if [ -z "$CLANG_TIDY" ] && command -v brew >/dev/null 2>&1; then
    CLANG_TIDY="$(brew --prefix llvm)/bin/clang-tidy"
fi
[ -x "$CLANG_TIDY" ] || die "clang-tidy not found; install it with 'brew install llvm' (see doc/developerInfrastructure.md)"

cd "$REPO_DIR"
FACADE_SOURCES="facade/src/AscFacade.cpp facade/src/AscCoreAdapter.cpp"

echo "== 1/5 swift format lint"
xcrun swift-format lint --strict --recursive --configuration .swift-format app

echo "== 2/5 clang-tidy (facade)"
# The compile commands come from the CMake build of the ASC core and the facade.
[ -f "$COMPILE_DB" ] || scripts/build-core.sh
# shellcheck disable=SC2086
"$CLANG_TIDY" -p "$REPO_DIR/build/core" --quiet \
    --extra-arg="-isysroot$(xcrun --show-sdk-path)" $FACADE_SOURCES

echo "== 3/5 Clang Static Analyzer (facade)"
for source in $FACADE_SOURCES; do
    # Compile flags of the source from the compile commands, run with --analyze.
    flags="$(python3 - "$COMPILE_DB" "$REPO_DIR/$source" <<'PY'
import json, shlex, sys
db, source = sys.argv[1], sys.argv[2]
for entry in json.load(open(db)):
    if entry["file"] == source:
        args = shlex.split(entry["command"])[1:]
        out, skip = [], False
        for a in args:
            if skip:
                skip = False
                continue
            if a in ("-o", "-c"):
                skip = a == "-o"
                continue
            if a == source or a.startswith("-W") or a.startswith("-M"):
                continue
            out.append(a)
        print(shlex.join(out))
        break
PY
)"
    [ -n "$flags" ] || die "no compile command found for $source"
    # shellcheck disable=SC2086
    eval xcrun clang++ --analyze -Xclang -analyzer-werror -o /dev/null $flags "$source"
done

echo "== 4/5 Xcode build (SwiftLint, warnings as errors)"
scripts/build.sh > build/check-build.log 2>&1 || { tail -40 build/check-build.log; die "Xcode build failed (see build/check-build.log)"; }

echo "== 5/5 SBOM up to date"
scripts/create-sbom.sh --check
echo "Static quality check passed."
