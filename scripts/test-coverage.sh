#!/usr/bin/env bash
#
# test-coverage.sh - Runs the Swift tests with code coverage and checks the line coverage of
# the project's own code against a baseline (QA measure S7, see doc/qameasures.md).
#
# Usage:
#   scripts/test-coverage.sh [--update-baseline]
#
# --update-baseline   Write the measured coverage into scripts/coverage-baseline.txt instead
#                     of checking it; commit the file afterwards.
#
# Steps:
#   1. Builds the ASC core with the facade compiled with coverage instrumentation into
#      build/core-coverage (scripts/build-core.sh --coverage).
#   2. Runs the Swift tests with xcodebuild and code coverage enabled, linking
#      build/core-coverage/libasc_all.a (Xcode output in build/xcode-coverage).
#   3. Prints the line coverage of the Swift app (app/ASCforMac/) and the facade (facade/),
#      per file and in total, measured with llvm-cov; thirdparty/asc/ and the tests are not
#      counted.
#   4. Fails if the total coverage or the coverage of any file is lower than in
#      scripts/coverage-baseline.txt (no tolerance), or if files were added or removed since
#      the baseline was written.
# The normal build (build/core, build/xcode) is not touched. See doc/buildAndTest.md.

# Note for developers: the comment block above is printed by --help.
# Keep this script compatible with Bash 3.2 (see doc/developerInfrastructure.md).

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COVERAGE_DIR="$REPO_DIR/build/core-coverage"
XCODE_DIR="$REPO_DIR/build/xcode-coverage"
BASELINE="$REPO_DIR/scripts/coverage-baseline.txt"

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

UPDATE=false
while [ $# -gt 0 ]; do
    case "$1" in
        --update-baseline) UPDATE=true ;;
        -h|--help) usage; exit 0 ;;
        *)         usage >&2; die "unknown argument '$1'" ;;
    esac
    shift
done

command -v xcodebuild >/dev/null 2>&1 || die "xcodebuild not found (see doc/developerInfrastructure.md)"
command -v python3 >/dev/null 2>&1 || die "python3 not found (see doc/developerInfrastructure.md)"
$UPDATE || [ -f "$BASELINE" ] || die "$BASELINE not found; create it with --update-baseline"

cd "$REPO_DIR"

echo "== 1/3 Build the ASC core with coverage of the facade"
scripts/build-core.sh --coverage

echo "== 2/3 Swift tests with code coverage"
rm -rf "$XCODE_DIR/Build/ProfileData"
# TEST_RUNNER_ASC_CORE_BUILD_DIR is passed to the tests as ASC_CORE_BUILD_DIR, so the
# unittester test runs the unittester of build/core-coverage.
TEST_RUNNER_ASC_CORE_BUILD_DIR="$COVERAGE_DIR" \
xcodebuild -project ASCforMac.xcodeproj -scheme ASCforMac -configuration Debug \
    -derivedDataPath "$XCODE_DIR" -skipPackagePluginValidation -enableCodeCoverage YES \
    ASC_CORE_BUILD_DIR="$COVERAGE_DIR" ASC_CORE_BUILD_ARGS=--coverage \
    test

echo "== 3/3 Line coverage of the Swift app and the facade"
PROFDATA="$(find "$XCODE_DIR/Build/ProfileData" -name '*.profdata' | head -n 1)"
[ -n "$PROFDATA" ] || die "no coverage data found in $XCODE_DIR/Build/ProfileData"
APP_BIN="$XCODE_DIR/Build/Products/Debug/ASCforMac.app/Contents/MacOS"
# Debug builds put the app's code into ASCforMac.debug.dylib.
if [ -f "$APP_BIN/ASCforMac.debug.dylib" ]; then
    BINARY="$APP_BIN/ASCforMac.debug.dylib"
else
    BINARY="$APP_BIN/ASCforMac"
fi

SUMMARY="$XCODE_DIR/coverage-summary.json"
xcrun llvm-cov export -summary-only -instr-profile "$PROFDATA" "$BINARY" \
    -ignore-filename-regex='(thirdparty/|ASCforMacTests/)' > "$SUMMARY"

python3 - "$SUMMARY" "$REPO_DIR" "$BASELINE" "$UPDATE" <<'EOF'
import json, sys

summary_file, repo, baseline_file, update = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]

# Line coverage per file (covered, total), with paths relative to the repository.
current = {}
for data in json.load(open(summary_file))["data"]:
    for entry in data["files"]:
        name = entry["filename"]
        if name.startswith(repo + "/"):
            name = name[len(repo) + 1:]
        if not (name.startswith("app/ASCforMac/") or name.startswith("facade/")):
            continue
        lines = entry["summary"]["lines"]
        current[name] = (lines["covered"], lines["count"])
if not current:
    sys.exit("Error: no files of the Swift app or the facade in the coverage data")
total = (sum(c for c, _ in current.values()), sum(t for _, t in current.values()))

def percent(value):
    covered, count = value
    return 100.0 * covered / count if count else 100.0

for name in sorted(current):
    print("%7.2f%%  %4d/%-4d  %s" % ((percent(current[name]),) + current[name] + (name,)))
print("%7.2f%%  %4d/%-4d  TOTAL" % ((percent(total),) + total))

if update == "true":
    with open(baseline_file, "w") as out:
        out.write("# Line coverage baseline of scripts/test-coverage.sh (QA measure S7):\n")
        out.write("# covered lines, total lines, file. Written with --update-baseline.\n")
        for name in sorted(current):
            out.write("%d %d %s\n" % (current[name] + (name,)))
        out.write("%d %d TOTAL\n" % total)
    print("Baseline written to %s" % baseline_file)
    sys.exit(0)

baseline = {}
for line in open(baseline_file):
    if line.strip() and not line.startswith("#"):
        covered, count, name = line.split(None, 2)
        baseline[name.strip()] = (int(covered), int(count))
current["TOTAL"] = total

def lower(now, base):
    # now < base, compared exactly as fractions
    return now[0] * base[1] < base[0] * now[1]

errors = []
for name in sorted(set(baseline) | set(current)):
    if name not in baseline:
        errors.append("%s is not in the baseline (new file)" % name)
    elif name not in current:
        errors.append("%s is in the baseline but was not measured (file removed?)" % name)
    elif lower(current[name], baseline[name]):
        errors.append("%s: %.2f%% is below the baseline of %.2f%%"
                      % (name, percent(current[name]), percent(baseline[name])))
if errors:
    print("Coverage check failed:")
    for error in errors:
        print("  " + error)
    print("If this is intended, update the baseline with scripts/test-coverage.sh --update-baseline.")
    sys.exit(1)
print("Coverage is not below the baseline.")
EOF
