#!/usr/bin/env bash
#
# test.sh - Automated tests for the scripts in scripts/.
#
# Usage:
#   scripts/test.sh
#
# Runs all tests in temporary directories (the repository itself is not changed),
# prints one line per failed check and a summary. Exits with 1 if a check failed.
#
# Run it after every change to a script in scripts/.

# Note for developers: keep this script compatible with Bash 3.2
# (see doc/developerInfrastructure.md). Add tests for every new script or command.

set -u

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TASKS="$REPO_DIR/scripts/tasks.sh"
INIT="$REPO_DIR/scripts/init-project.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Git identity for the commits made in the test repositories, independent of the
# developer's configuration.
export GIT_AUTHOR_NAME="Test" GIT_AUTHOR_EMAIL="test@example.com"
export GIT_COMMITTER_NAME="Test" GIT_COMMITTER_EMAIL="test@example.com"

CHECKS=0
FAILURES=0

fail() {
    FAILURES=$((FAILURES + 1))
    echo "FAIL: $*"
}

# check DESCRIPTION COMMAND...: the command must succeed.
check() {
    local description="$1"
    shift
    CHECKS=$((CHECKS + 1))
    "$@" >/dev/null 2>&1 || fail "$description"
}

# check_fails DESCRIPTION COMMAND...: the command must fail.
check_fails() {
    local description="$1"
    shift
    CHECKS=$((CHECKS + 1))
    if "$@" >/dev/null 2>&1; then fail "$description (expected an error)"; fi
}

# check_equal DESCRIPTION EXPECTED ACTUAL
check_equal() {
    CHECKS=$((CHECKS + 1))
    [ "$2" = "$3" ] || fail "$1: expected '$2', got '$3'"
}

# check_contains DESCRIPTION TEXT PATTERN (fixed string)
check_contains() {
    CHECKS=$((CHECKS + 1))
    printf '%s\n' "$2" | grep -qF -- "$3" || fail "$1: '$3' not found"
}

# check_not_contains DESCRIPTION TEXT PATTERN (fixed string)
check_not_contains() {
    CHECKS=$((CHECKS + 1))
    if printf '%s\n' "$2" | grep -qF -- "$3"; then fail "$1: '$3' found"; fi
}

# field FILE LABEL: value of a header table row, like tasks.sh reads it.
field() {
    awk -F'|' -v label="**$2**" '{
        k = $2; gsub(/^[ \t]+|[ \t]+$/, "", k)
        if (k == label) { v = $3; gsub(/<!--.*-->/, "", v); gsub(/^[ \t]+|[ \t]+$/, "", v); print v; exit }
    }' "$1"
}

# ---------------------------------------------------------------------------
# tasks.sh
# ---------------------------------------------------------------------------
# create-licenses.sh
# ---------------------------------------------------------------------------

test_licenses_script() {
    local repo="$TMP/licenses" out info
    mkdir -p "$repo/scripts" "$repo/doc" "$repo/texts" "$repo/installed/arm64-osx-asc/share/zlib"
    cp "$REPO_DIR/scripts/create-licenses.sh" "$REPO_DIR/scripts/sbom-components.json" "$repo/scripts/"
    info="$repo/out/Licenses.json"
    echo "zlib licence text" > "$repo/installed/arm64-osx-asc/share/zlib/copyright"
    echo "GPL text" > "$repo/texts/GPL.txt"
    cat > "$repo/doc/sbom.spdx.json" <<'JSON'
{"packages": [
  {"SPDXID": "SPDXRef-app", "name": "App", "versionInfo": "1.0", "licenseDeclared": "GPL-2.0-or-later",
   "downloadLocation": "NOASSERTION"},
  {"SPDXID": "SPDXRef-vcpkg-zlib", "name": "zlib", "versionInfo": "1.3", "licenseDeclared": "Zlib",
   "downloadLocation": "git+https://example.com/zlib@v1.3"},
  {"SPDXID": "SPDXRef-own", "name": "Own", "versionInfo": "1.0", "licenseDeclared": "LicenseRef-Own",
   "downloadLocation": "git+https://example.com/own@abc#src/own"}
 ],
 "hasExtractedLicensingInfos": [{"licenseId": "LicenseRef-Own", "extractedText": "Own licence"}]}
JSON
    cat > "$repo/scripts/licenses.json" <<'JSON'
{"notes": ["A note"],
 "packages": {
  "app": {"copyright": "(C) App", "texts": ["file:texts/GPL.txt"], "source": "The repository"},
  "vcpkg-*": {"copyright": "(C) zlib"},
  "own": {"copyright": "(C) Own", "texts": ["spdx:LicenseRef-Own", "file:texts/GPL.txt"], "note": "Chosen"}
 }}
JSON

    out="$("$repo/scripts/create-licenses.sh" --help)"
    check_contains "create-licenses --help shows the usage" "$out" "scripts/create-licenses.sh"
    check_fails "create-licenses rejects an unknown argument" "$repo/scripts/create-licenses.sh" --frobnicate
    out="$("$repo/scripts/create-licenses.sh" --installed "$repo/none" 2>&1 || true)"
    check_contains "create-licenses needs a core build" "$out" "run scripts/build-core.sh first"

    out="$("$repo/scripts/create-licenses.sh" --installed "$repo/installed" --output "$info")"
    check_contains "create-licenses writes the licence information" "$out" "3 packages, 3 licence texts"
    check "the licence information is valid JSON" python3 -c 'import json, sys; json.load(open(sys.argv[1]))' "$info"
    out="$(python3 -c '
import json, sys
info = json.load(open(sys.argv[1]))
for p in info["packages"]:
    print(p["name"], p["version"], p["license"], p["copyright"], p.get("source"), p.get("note"),
          [info["texts"][i].strip() for i in p["textIds"]])
print("notes:", info["notes"], "app:", info["app"])
' "$info")"
    check_contains "the app's source location is taken from licenses.json" "$out" \
        "App 1.0 GPL-2.0-or-later (C) App The repository None ['GPL text']"
    check_contains "vcpkg ports get their copyright file and a readable source" "$out" \
        "zlib 1.3 Zlib (C) zlib https://example.com/zlib (Git, revision v1.3) None ['zlib licence text']"
    check_contains "extracted licences, files, directories and notes are used" "$out" \
        "Own 1.0 LicenseRef-Own (C) Own https://example.com/own (Git, revision abc, directory src/own) Chosen ['Own licence', 'GPL text']"
    check_contains "the notes and the app are included" "$out" "notes: ['A note']"
    check_equal "the components not from vcpkg come first" "App Own zlib" \
        "$(printf '%s\n' "$out" | sed -n '1,3p' | cut -d' ' -f1 | tr '\n' ' ' | sed 's/ $//')"

    rm "$repo/installed/arm64-osx-asc/share/zlib/copyright"
    out="$("$repo/scripts/create-licenses.sh" --installed "$repo/installed" --output "$info" 2>&1 || true)"
    check_contains "create-licenses detects a missing licence text" "$out" "licence text"
    echo "zlib licence text" > "$repo/installed/arm64-osx-asc/share/zlib/copyright"
    sed -i '' 's/, "source": "The repository"//' "$repo/scripts/licenses.json"
    out="$("$repo/scripts/create-licenses.sh" --installed "$repo/installed" --output "$info" 2>&1 || true)"
    check_contains "create-licenses needs a source location for GPL packages" "$out" \
        "App (GPL-2.0-or-later) has no source code location"
    sed -i '' 's/"own": /"other": /' "$repo/scripts/licenses.json"
    out="$("$repo/scripts/create-licenses.sh" --installed "$repo/installed" --output "$info" 2>&1 || true)"
    check_contains "create-licenses detects a package missing in licenses.json" "$out" \
        "Own (own) is missing in scripts/licenses.json"
    check_contains "create-licenses detects an entry missing in the SBOM" "$out" \
        "lists other, which is not in the SBOM"
}

# ---------------------------------------------------------------------------

test_tasks() {
    export AITASKS_DIR="$TMP/tasks"
    local out file

    # help
    out="$("$TASKS" help)"
    check_contains "help lists 'list'" "$out" "tasks.sh list"
    check_contains "help lists 'new'" "$out" "tasks.sh new"
    check_contains "help lists 'status'" "$out" "tasks.sh status"
    check_fails "unknown command is rejected" "$TASKS" frobnicate

    # list without task directory
    out="$("$TASKS" list)"
    check_equal "list without tasks prints only the header" "ID   STATUS   SHORT DESCRIPTION" "$out"

    # new
    out="$("$TASKS" new "Define quality objectives based on ISO 25010")"
    file="$AITASKS_DIR/TASK-0001-define-quality-objectives-based-on-iso.md"
    check "new creates the file with a slug cut at a word boundary" test -f "$file"
    check_contains "new reports the created task" "$out" "Created TASK-0001"
    check_equal "new sets the ID" "TASK-0001" "$(field "$file" ID)"
    check_equal "new sets the short description" \
        "Define quality objectives based on ISO 25010" "$(field "$file" "Short description")"
    check_equal "new sets the status open" "open" "$(field "$file" Status)"
    check_contains "new sets the title" "$(cat "$file")" "# TASK-0001: Define quality objectives"
    check_contains "new adds the creation to the history" "$(tail -1 "$file")" "| open   | Task created"
    check_not_contains "new leaves no placeholders" "$(cat "$file")" "{{"

    "$TASKS" new 'Special & chars \1 "quoted"' >/dev/null
    check_equal "new keeps special characters" 'Special & chars \1 "quoted"' \
        "$(field "$AITASKS_DIR"/TASK-0002-*.md "Short description")"
    check_fails "new rejects an empty description" "$TASKS" new "   "
    check_fails "new rejects '|'" "$TASKS" new "a | b"
    check_fails "new rejects several arguments" "$TASKS" new a b

    # next ID after a gap
    mv "$AITASKS_DIR"/TASK-0002-*.md "$AITASKS_DIR/TASK-0009-gap.md"
    sed -i.bak 's/| TASK-0002 |/| TASK-0009 |/' "$AITASKS_DIR/TASK-0009-gap.md" && rm "$AITASKS_DIR"/*.bak
    "$TASKS" new "After the gap" >/dev/null
    check "new continues after the highest ID" test -f "$AITASKS_DIR/TASK-0010-after-the-gap.md"

    # list with filter and dependencies
    sed -i.bak 's/^| \*\*Dependencies\*\*  |.*/| **Dependencies**  | TASK-0001, TASK-0009 |/' \
        "$AITASKS_DIR/TASK-0010-after-the-gap.md" && rm "$AITASKS_DIR"/*.bak
    out="$("$TASKS" list)"
    check_not_contains "list hides dependencies by default" "$out" "DEPENDS ON"
    check_contains "list shows all tasks" "$out" "TASK-0010"
    out="$("$TASKS" list -deps)"
    check_contains "list -deps shows the dependency column" "$out" "DEPENDS ON"
    check_contains "list -deps shows dependencies" "$out" "TASK-0001, TASK-0009"
    check_fails "list rejects an invalid state" "$TASKS" list finished
    check_fails "list rejects an unknown option" "$TASKS" list -x
    check_fails "list rejects two states" "$TASKS" list open "done"

    # status
    file="$AITASKS_DIR/TASK-0001-define-quality-objectives-based-on-iso.md"
    out="$("$TASKS" status TASK-0001 in-work "Implementation started")"
    check_contains "status reports the change" "$out" "TASK-0001: open -> in-work"
    check_equal "status changes the status" "in-work" "$(field "$file" Status)"
    check_contains "status keeps the comment in the status cell" "$(cat "$file")" \
        "in-work <!-- One of: open, in-work, waiting, done, aborted -->"
    check_contains "status adds a history row" "$(tail -1 "$file")" "| in-work | Implementation started |"
    check_fails "status requires a reason for waiting" "$TASKS" status TASK-0001 waiting
    check_fails "status requires a reason for aborted" "$TASKS" status 1 aborted
    check_fails "status rejects '|' in the comment" "$TASKS" status 1 waiting "a | b"
    check_fails "status rejects the current status" "$TASKS" status 1 in-work
    check_fails "status rejects an invalid state" "$TASKS" status 1 finished
    check_fails "status rejects an unknown task" "$TASKS" status TASK-0099 "done"
    "$TASKS" status 1 "done" >/dev/null
    check_equal "status accepts a short ID" "done" "$(field "$file" Status)"
    check_equal "the history has one row per status change" "3" \
        "$(grep -c '^| 20[0-9][0-9]-' "$file")"
    out="$("$TASKS" list "done")"
    check_contains "list filters by status" "$out" "TASK-0001"
    check_not_contains "list filter excludes other tasks" "$out" "TASK-0010"

    unset AITASKS_DIR
}

# ---------------------------------------------------------------------------
# init-project.sh
# ---------------------------------------------------------------------------

# make_repo DIR: creates a minimal copy of the template as a git repository with
# one commit and a remote "origin".
make_repo() {
    local dir="$1"
    mkdir -p "$dir/scripts" "$dir/aitasks"
    cp "$INIT" "$dir/scripts/"
    cat > "$dir/AGENTS.md" <<'EOF'
# AGENTS.md

## About this project

This repository is a **template**.

## Repository layout

Layout text.
EOF
    echo "task" > "$dir/aitasks/TASK-0001-init.md"
    echo "Template license" > "$dir/LICENSE"
    (
        cd "$dir" &&
        git init -q &&
        git add -A &&
        git commit -q -m "Template" &&
        git remote add origin https://example.com/template.git
    )
}

test_init_project() {
    local repo out

    repo="$TMP/init-checks"
    make_repo "$repo"
    check_fails "init-project requires a NAME" "$repo/scripts/init-project.sh" --yes
    check_fails "init-project rejects an invalid NAME" "$repo/scripts/init-project.sh" --yes "my shop"
    check_fails "init-project rejects an unknown option" "$repo/scripts/init-project.sh" --foo Demo
    check_fails "init-project asks for confirmation without --yes" \
        sh -c "'$repo/scripts/init-project.sh' Demo </dev/null"
    echo "change" >> "$repo/AGENTS.md"
    check_fails "init-project rejects changes outside aitasks/" "$repo/scripts/init-project.sh" --yes Demo
    check_equal "a rejected run changes nothing" "1" "$(git -C "$repo" rev-list --count HEAD)"
    check_contains "help shows the usage" "$("$repo/scripts/init-project.sh" --help)" "Usage:"

    # Reset (default)
    repo="$TMP/init-reset"
    make_repo "$repo"
    echo "status in-work" >> "$repo/aitasks/TASK-0001-init.md"
    check "init-project accepts changes in aitasks/" "$repo/scripts/init-project.sh" --yes MyShop
    check_equal "reset leaves a single commit" "1" "$(git -C "$repo" rev-list --count HEAD)"
    check_equal "reset removes all remotes" "" "$(git -C "$repo" remote)"
    check_equal "reset commits everything" "" "$(git -C "$repo" status --porcelain)"
    check_contains "the task change is committed" "$(git -C "$repo" show HEAD:aitasks/TASK-0001-init.md)" \
        "status in-work"
    out="$(cat "$repo/AGENTS.md")"
    check_contains "AGENTS.md names the project" "$out" "This is the project **MyShop**."
    check_not_contains "AGENTS.md no longer describes the template" "$out" "This repository is a **template**."
    check_contains "AGENTS.md keeps the other sections" "$out" "## Repository layout"
    check_fails "reset removes the template's LICENSE" test -e "$repo/LICENSE"

    # Keep history
    repo="$TMP/init-keep"
    make_repo "$repo"
    check "init-project --keep-history succeeds" "$repo/scripts/init-project.sh" --keep-history --yes MyShop
    check_equal "keep-history adds one commit" "2" "$(git -C "$repo" rev-list --count HEAD)"
    check_equal "keep-history renames origin to upstream" "upstream" "$(git -C "$repo" remote)"
    check_contains "keep-history updates AGENTS.md" "$(cat "$repo/AGENTS.md")" "**MyShop**"
    check_fails "keep-history removes the template's LICENSE" test -e "$repo/LICENSE"
    check_equal "keep-history commits everything" "" "$(git -C "$repo" status --porcelain)"

    # Keep git (repository created with "Use this template")
    repo="$TMP/init-keep-git"
    make_repo "$repo"
    check_fails "init-project rejects --keep-git together with --keep-history" \
        "$repo/scripts/init-project.sh" --keep-git --keep-history --yes MyShop
    check "init-project --keep-git succeeds" "$repo/scripts/init-project.sh" --keep-git --yes MyShop
    check_equal "keep-git adds one commit" "2" "$(git -C "$repo" rev-list --count HEAD)"
    check_equal "keep-git keeps origin" "https://example.com/template.git" \
        "$(git -C "$repo" remote get-url origin 2>/dev/null)"
    check_equal "keep-git commits everything" "" "$(git -C "$repo" status --porcelain)"
    check_contains "keep-git updates AGENTS.md" "$(cat "$repo/AGENTS.md")" "**MyShop**"
    check_fails "keep-git removes the template's LICENSE" test -e "$repo/LICENSE"
}

# ---------------------------------------------------------------------------
# build-core.sh and test-core.sh
# ---------------------------------------------------------------------------

# The real build takes long and downloads vcpkg; these tests only check the command line
# handling and the error cases, in a copy of the scripts outside the repository.
test_core_scripts() {
    local repo="$TMP/core" out
    mkdir -p "$repo/scripts"
    cp "$REPO_DIR/scripts/build-core.sh" "$REPO_DIR/scripts/test-core.sh" "$repo/scripts/"

    out="$("$repo/scripts/build-core.sh" --help)"
    check_contains "build-core --help shows the usage" "$out" "scripts/build-core.sh [--clean]"
    check_fails "build-core rejects an unknown argument" "$repo/scripts/build-core.sh" --frobnicate
    printf '{ "name": "x" }\n' > "$repo/vcpkg.json"
    out="$("$repo/scripts/build-core.sh" 2>&1 || true)"
    check_contains "build-core needs a builtin-baseline in vcpkg.json" "$out" "no builtin-baseline"
    out="$("$repo/scripts/build-core.sh" --sanitizers 2>&1 || true)"
    check_contains "build-core accepts --sanitizers" "$out" "no builtin-baseline"
    out="$("$repo/scripts/build-core.sh" --coverage 2>&1 || true)"
    check_contains "build-core accepts --coverage" "$out" "no builtin-baseline"

    out="$("$repo/scripts/test-core.sh" --help)"
    check_contains "test-core --help shows the usage" "$out" "scripts/test-core.sh"
    check_fails "test-core rejects an unknown argument" "$repo/scripts/test-core.sh" --frobnicate
    out="$("$repo/scripts/test-core.sh" 2>&1 || true)"
    check_contains "test-core needs a build first" "$out" "run scripts/build-core.sh first"
    check_contains "test-core uses build/core by default" "$out" "build/core/unittester"
    out="$("$repo/scripts/test-core.sh" --sanitizers 2>&1 || true)"
    check_contains "test-core --sanitizers uses build/core-sanitizers" "$out" \
        "build/core-sanitizers/unittester"
}

# ---------------------------------------------------------------------------
# build.sh, test-app.sh, test-ui.sh, test-sanitizers.sh, test-coverage.sh, run.sh and check.sh
# ---------------------------------------------------------------------------

# The Xcode build takes long; these tests only check the command line handling and the
# error cases, in a copy of the scripts outside the repository.
test_app_scripts() {
    local repo="$TMP/app" out script
    mkdir -p "$repo/scripts"
    for script in build.sh test-app.sh test-ui.sh test-sanitizers.sh test-coverage.sh run.sh check.sh; do
        cp "$REPO_DIR/scripts/$script" "$repo/scripts/"
        out="$("$repo/scripts/$script" --help)"
        check_contains "$script --help shows the usage" "$out" "scripts/$script"
        check_fails "$script rejects an unknown argument" "$repo/scripts/$script" --frobnicate
    done
    out="$("$repo/scripts/run.sh" 2>&1 || true)"
    check_contains "run.sh needs a build first" "$out" "run scripts/build.sh first"
    out="$("$repo/scripts/test-coverage.sh" 2>&1 || true)"
    check_contains "test-coverage.sh needs a baseline" "$out" "create it with --update-baseline"
    out="$(CLANG_TIDY=/nonexistent/clang-tidy PATH=/usr/bin:/bin "$repo/scripts/check.sh" 2>&1 || true)"
    check_contains "check.sh needs clang-tidy" "$out" "clang-tidy not found"
}

# ---------------------------------------------------------------------------
# create-sbom.sh
# ---------------------------------------------------------------------------

# A fake vcpkg installed tree with one library, one build helper and one port with an
# override from scripts/sbom-components.json.
make_vcpkg_tree() {
    local dir="$1" port license
    mkdir -p "$dir/vcpkg/info"
    for port in zlib vcpkg-cmake libsigcpp; do
        touch "$dir/vcpkg/info/${port}_1.0_arm64-osx-asc.list"
        mkdir -p "$dir/arm64-osx-asc/share/$port"
        license="Zlib"
        [ "$port" = libsigcpp ] && license="NOASSERTION"
        cat > "$dir/arm64-osx-asc/share/$port/vcpkg.spdx.json" <<JSON
{"packages": [
  {"SPDXID": "SPDXRef-port", "name": "$port", "versionInfo": "1.0#2",
   "licenseConcluded": "$license", "homepage": "https://example.com/$port"},
  {"SPDXID": "SPDXRef-binary", "name": "$port:arm64-osx-asc"},
  {"SPDXID": "SPDXRef-resource-0", "downloadLocation": "https://example.com/fix.patch"},
  {"SPDXID": "SPDXRef-resource-1", "downloadLocation": "git+https://example.com/$port@v1.0"}
]}
JSON
    done
}

test_sbom_script() {
    local repo="$TMP/sbom" sbom out
    mkdir -p "$repo/scripts"
    cp "$REPO_DIR/scripts/create-sbom.sh" "$REPO_DIR/scripts/sbom-components.json" "$repo/scripts/"
    sbom="$repo/sbom.spdx.json"

    out="$("$repo/scripts/create-sbom.sh" --help)"
    check_contains "create-sbom --help shows the usage" "$out" "scripts/create-sbom.sh"
    check_fails "create-sbom rejects an unknown argument" "$repo/scripts/create-sbom.sh" --frobnicate
    out="$("$repo/scripts/create-sbom.sh" 2>&1 || true)"
    check_contains "create-sbom needs a core build" "$out" "run scripts/build-core.sh first"

    make_vcpkg_tree "$repo/installed"
    out="$("$repo/scripts/create-sbom.sh" --installed "$repo/installed" --output "$sbom")"
    check_contains "create-sbom writes the SBOM" "$out" "SBOM written to"
    check_not_contains "the components have no unclear licence" "$out" "unclear licence"
    check "the SBOM is valid JSON" python3 -c 'import json, sys; json.load(open(sys.argv[1]))' "$sbom"
    out="$(cat "$sbom")"
    check_contains "the SBOM is SPDX 2.3" "$out" '"spdxVersion": "SPDX-2.3"'
    check_contains "the SBOM lists vcpkg ports" "$out" '"SPDXID": "SPDXRef-vcpkg-zlib"'
    check_not_contains "the SBOM leaves out vcpkg's build helpers" "$out" 'vcpkg-cmake'
    check_contains "the SBOM uses the upstream version" "$out" '"versionInfo": "1.0"'
    check_contains "the SBOM takes the origin without patches" "$out" \
        '"downloadLocation": "git+https://example.com/zlib@v1.0"'
    check_contains "the SBOM applies overrides" "$out" '"licenseDeclared": "LGPL-2.1-or-later"'
    check_contains "the SBOM lists ASC" "$out" '"name": "Advanced Strategic Command (ASC)"'
    check_contains "the SBOM fills in the ASC commit" "$out" "asc-hq@074a6ef"

    cp "$sbom" "$repo/before.json"
    "$repo/scripts/create-sbom.sh" --installed "$repo/installed" --output "$sbom" >/dev/null
    check "create-sbom output is stable" cmp -s "$repo/before.json" "$sbom"
    check "create-sbom --check accepts an up-to-date SBOM" \
        "$repo/scripts/create-sbom.sh" --check --installed "$repo/installed" --output "$sbom"
    rm "$repo/installed/vcpkg/info/zlib_1.0_arm64-osx-asc.list"
    check_fails "create-sbom --check detects an out-of-date SBOM" \
        "$repo/scripts/create-sbom.sh" --check --installed "$repo/installed" --output "$sbom"
}

# ---------------------------------------------------------------------------
# create-licenses.sh
# ---------------------------------------------------------------------------

test_licenses_script() {
    local repo="$TMP/licenses" out info
    mkdir -p "$repo/scripts" "$repo/doc" "$repo/texts" "$repo/installed/arm64-osx-asc/share/zlib"
    cp "$REPO_DIR/scripts/create-licenses.sh" "$REPO_DIR/scripts/sbom-components.json" "$repo/scripts/"
    info="$repo/out/Licenses.json"
    echo "zlib licence text" > "$repo/installed/arm64-osx-asc/share/zlib/copyright"
    echo "GPL text" > "$repo/texts/GPL.txt"
    cat > "$repo/doc/sbom.spdx.json" <<'JSON'
{"packages": [
  {"SPDXID": "SPDXRef-app", "name": "App", "versionInfo": "1.0", "licenseDeclared": "GPL-2.0-or-later",
   "downloadLocation": "NOASSERTION"},
  {"SPDXID": "SPDXRef-vcpkg-zlib", "name": "zlib", "versionInfo": "1.3", "licenseDeclared": "Zlib",
   "downloadLocation": "git+https://example.com/zlib@v1.3"},
  {"SPDXID": "SPDXRef-own", "name": "Own", "versionInfo": "1.0", "licenseDeclared": "LicenseRef-Own",
   "downloadLocation": "git+https://example.com/own@abc#src/own"}
 ],
 "hasExtractedLicensingInfos": [{"licenseId": "LicenseRef-Own", "extractedText": "Own licence"}]}
JSON
    cat > "$repo/scripts/licenses.json" <<'JSON'
{"notes": ["A note"],
 "packages": {
  "app": {"copyright": "(C) App", "texts": ["file:texts/GPL.txt"], "source": "The repository"},
  "vcpkg-*": {"copyright": "(C) zlib"},
  "own": {"copyright": "(C) Own", "texts": ["spdx:LicenseRef-Own", "file:texts/GPL.txt"], "note": "Chosen"}
 }}
JSON

    out="$("$repo/scripts/create-licenses.sh" --help)"
    check_contains "create-licenses --help shows the usage" "$out" "scripts/create-licenses.sh"
    check_fails "create-licenses rejects an unknown argument" "$repo/scripts/create-licenses.sh" --frobnicate
    out="$("$repo/scripts/create-licenses.sh" --installed "$repo/none" 2>&1 || true)"
    check_contains "create-licenses needs a core build" "$out" "run scripts/build-core.sh first"

    out="$("$repo/scripts/create-licenses.sh" --installed "$repo/installed" --output "$info")"
    check_contains "create-licenses writes the licence information" "$out" "3 packages, 3 licence texts"
    check "the licence information is valid JSON" python3 -c 'import json, sys; json.load(open(sys.argv[1]))' "$info"
    out="$(python3 -c '
import json, sys
info = json.load(open(sys.argv[1]))
for p in info["packages"]:
    print(p["name"], p["version"], p["license"], p["copyright"], p.get("source"), p.get("note"),
          [info["texts"][i].strip() for i in p["textIds"]])
print("notes:", info["notes"], "app:", info["app"])
' "$info")"
    check_contains "the app's source location is taken from licenses.json" "$out" \
        "App 1.0 GPL-2.0-or-later (C) App The repository None ['GPL text']"
    check_contains "vcpkg ports get their copyright file and a readable source" "$out" \
        "zlib 1.3 Zlib (C) zlib https://example.com/zlib (Git, revision v1.3) None ['zlib licence text']"
    check_contains "extracted licences, files, directories and notes are used" "$out" \
        "Own 1.0 LicenseRef-Own (C) Own https://example.com/own (Git, revision abc, directory src/own) Chosen ['Own licence', 'GPL text']"
    check_contains "the notes and the app are included" "$out" "notes: ['A note']"
    check_equal "the components not from vcpkg come first" "App Own zlib" \
        "$(printf '%s\n' "$out" | sed -n '1,3p' | cut -d' ' -f1 | tr '\n' ' ' | sed 's/ $//')"

    rm "$repo/installed/arm64-osx-asc/share/zlib/copyright"
    out="$("$repo/scripts/create-licenses.sh" --installed "$repo/installed" --output "$info" 2>&1 || true)"
    check_contains "create-licenses detects a missing licence text" "$out" "licence text"
    echo "zlib licence text" > "$repo/installed/arm64-osx-asc/share/zlib/copyright"
    sed -i '' 's/, "source": "The repository"//' "$repo/scripts/licenses.json"
    out="$("$repo/scripts/create-licenses.sh" --installed "$repo/installed" --output "$info" 2>&1 || true)"
    check_contains "create-licenses needs a source location for GPL packages" "$out" \
        "App (GPL-2.0-or-later) has no source code location"
    sed -i '' 's/"own": /"other": /' "$repo/scripts/licenses.json"
    out="$("$repo/scripts/create-licenses.sh" --installed "$repo/installed" --output "$info" 2>&1 || true)"
    check_contains "create-licenses detects a package missing in licenses.json" "$out" \
        "Own (own) is missing in scripts/licenses.json"
    check_contains "create-licenses detects an entry missing in the SBOM" "$out" \
        "lists other, which is not in the SBOM"
}

# ---------------------------------------------------------------------------

test_tasks
test_init_project
test_core_scripts
test_app_scripts
test_sbom_script
test_licenses_script

echo "$CHECKS checks, $FAILURES failed."
[ "$FAILURES" -eq 0 ]
