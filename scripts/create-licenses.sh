#!/usr/bin/env bash
#
# create-licenses.sh - Creates the licence information of asc-for-mac (Licenses.json), which
# the app shows in its window "Licenses…".
#
# Usage:
#   scripts/create-licenses.sh [--sbom FILE] [--installed DIR] [--output FILE]
#
# --sbom FILE       The SBOM (default: doc/sbom.spdx.json, see scripts/create-sbom.sh).
# --installed DIR   vcpkg's installed tree (default: build/core/vcpkg_installed, created by
#                   scripts/build-core.sh).
# --output FILE     The licence information (default: build/core/licenses/Licenses.json).
#
# For every package of the SBOM, the licence information contains its name, version, licence,
# copyright notice, source code location and full licence texts. Copyright notices and the
# sources of the licence texts are listed in scripts/licenses.json; the texts come from vcpkg's
# copyright files, from thirdparty/ and from the SBOM. The script fails if a package of the
# SBOM is missing in scripts/licenses.json (or the other way round), if a licence text is
# missing, or if a GPL or LGPL package has no source code location. The app and the
# components that are not from vcpkg are listed first, then the vcpkg libraries.
# scripts/build-core.sh calls it, and the Xcode build copies the result into the app bundle.
# See doc/buildAndTest.md.

# Note for developers: the comment block above is printed by --help.
# Keep this script compatible with Bash 3.2 (see doc/developerInfrastructure.md).

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="$REPO_DIR/scripts/licenses.json"

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

SBOM="$REPO_DIR/doc/sbom.spdx.json"
INSTALLED="$REPO_DIR/build/core/vcpkg_installed"
OUTPUT="$REPO_DIR/build/core/licenses/Licenses.json"
while [ $# -gt 0 ]; do
    case "$1" in
        --sbom)      [ $# -ge 2 ] || die "--sbom needs a file"; SBOM="$2"; shift ;;
        --installed) [ $# -ge 2 ] || die "--installed needs a directory"; INSTALLED="$2"; shift ;;
        --output)    [ $# -ge 2 ] || die "--output needs a file"; OUTPUT="$2"; shift ;;
        -h|--help)   usage; exit 0 ;;
        *)           usage >&2; die "unknown argument '$1'" ;;
    esac
    shift
done

command -v python3 >/dev/null 2>&1 || die "python3 not found (see doc/developerInfrastructure.md)"
[ -f "$CONFIG" ] || die "$CONFIG not found"
[ -f "$SBOM" ] || die "$SBOM not found; run scripts/create-sbom.sh first"
[ -d "$INSTALLED" ] || die "$INSTALLED not found; run scripts/build-core.sh first"

python3 - "$REPO_DIR" "$CONFIG" "$SBOM" "$INSTALLED" "$OUTPUT" <<'PY'
import fnmatch, hashlib, json, os, sys

repo, config_file, sbom_file, installed, output = sys.argv[1:6]
config = json.load(open(config_file, encoding="utf-8"))
sbom = json.load(open(sbom_file, encoding="utf-8"))
triplet = json.load(open(os.path.join(repo, "scripts", "sbom-components.json")))["vcpkgTriplet"]
extracted = {e["licenseId"]: e["extractedText"] for e in sbom.get("hasExtractedLicensingInfos", [])}
entries = config["packages"]
errors = []

def entry_for(key):
    if key in entries:
        return key
    matches = [k for k in entries if "*" in k and fnmatch.fnmatchcase(key, k)]
    return matches[0] if len(matches) == 1 else None

def read_text(source, package):
    if source == "vcpkg":
        port = package["name"]
        path = os.path.join(installed, triplet, "share", port, "copyright")
    elif source.startswith("file:"):
        path = os.path.join(repo, source[len("file:"):])
    elif source.startswith("spdx:"):
        text = extracted.get(source[len("spdx:"):])
        if text is None:
            errors.append("%s: licence %s is not in the SBOM" % (package["name"], source))
        return text
    else:
        errors.append("%s: unknown licence text source '%s'" % (package["name"], source))
        return None
    if not os.path.isfile(path):
        errors.append("%s: licence text %s not found" % (package["name"], path))
        return None
    with open(path, encoding="utf-8", errors="replace") as f:
        return f.read().replace("\r\n", "\n")

def source_location(location):
    """Makes an SPDX download location readable, e.g. git+https://x@v1#dir."""
    if location.startswith("git+"):
        url, _, directory = location[len("git+"):].partition("#")
        url, _, revision = url.rpartition("@") if "@" in url else (url, "", "")
        text = "%s (Git, revision %s" % (url, revision) if revision else "%s (Git" % url
        if directory:
            text += ", directory %s" % directory
        return text + ")"
    return location

texts = {}
packages = []
used = set()
for package in sbom["packages"]:
    key = package["SPDXID"][len("SPDXRef-"):]
    name = entry_for(key)
    if name is None:
        errors.append("%s (%s) is missing in scripts/licenses.json" % (package["name"], key))
        continue
    used.add(name)
    entry = entries[name]
    sources = entry.get("texts", ["vcpkg"] if key.startswith("vcpkg-") else [])
    if not sources:
        errors.append("%s has no licence text" % package["name"])
    text_ids = []
    for source in sources:
        text = read_text(source, package)
        if text is None:
            continue
        text_id = hashlib.sha256(text.encode("utf-8")).hexdigest()[:16]
        texts[text_id] = text
        text_ids.append(text_id)
    license = package["licenseDeclared"]
    if license == "NOASSERTION":
        errors.append("%s has an unclear licence (NOASSERTION in the SBOM)" % package["name"])
    location = entry.get("source") or package.get("downloadLocation", "NOASSERTION")
    if location == "NOASSERTION":
        if "GPL" in license:
            errors.append("%s (%s) has no source code location" % (package["name"], license))
        location = None
    item = {
        "id": package["SPDXID"],
        "name": package["name"],
        "version": package["versionInfo"],
        "license": license,
        "copyright": entry["copyright"],
        "textIds": text_ids,
    }
    if location:
        item["source"] = source_location(location)
    if "note" in entry:
        item["note"] = entry["note"]
    packages.append(item)

# The app and the components that are not from vcpkg (own code, ASC) first, then the libraries.
packages.sort(key=lambda p: p["id"].startswith("SPDXRef-vcpkg-"))

for name in sorted(set(entries) - used):
    errors.append("scripts/licenses.json lists %s, which is not in the SBOM" % name)
if errors:
    sys.exit("Error: " + "\nError: ".join(errors))

app = sbom["packages"][0]
info = {
    "app": {"name": app["name"], "version": app["versionInfo"], "license": app["licenseDeclared"]},
    "notes": config["notes"],
    "packages": packages,
    "texts": texts,
}
directory = os.path.dirname(output)
if directory:
    os.makedirs(directory, exist_ok=True)
with open(output, "w", encoding="utf-8") as out:
    json.dump(info, out, indent=1, ensure_ascii=False, sort_keys=True)
    out.write("\n")
print("Licence information written to %s (%d packages, %d licence texts)."
      % (output, len(packages), len(texts)))
PY
