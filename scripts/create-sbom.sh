#!/usr/bin/env bash
#
# create-sbom.sh - Creates the SBOM of asc-for-mac (doc/sbom.spdx.json, SPDX 2.3 JSON).
#
# Usage:
#   scripts/create-sbom.sh [--check] [--installed DIR] [--output FILE]
#
# --check           Do not write the SBOM; fail if FILE differs from what would be written
#                   (run by scripts/check.sh).
# --installed DIR   vcpkg's installed tree (default: build/core/vcpkg_installed, created by
#                   scripts/build-core.sh).
# --output FILE     The SBOM file (default: doc/sbom.spdx.json).
#
# The SBOM lists everything contained in the app: every library vcpkg installed for the app
# (from the SPDX files vcpkg writes for each port, without vcpkg's build helpers), and the
# components listed in scripts/sbom-components.json (ASC, the libraries bundled in ASC's
# source code, the game data, the project's own code). Packages with an unclear licence
# (NOASSERTION) are printed. The output only changes when the components change.
# See doc/buildAndTest.md.

# Note for developers: the comment block above is printed by --help.
# Keep this script compatible with Bash 3.2 (see doc/developerInfrastructure.md).

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPONENTS="$REPO_DIR/scripts/sbom-components.json"

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

CHECK=false
INSTALLED="$REPO_DIR/build/core/vcpkg_installed"
OUTPUT="$REPO_DIR/doc/sbom.spdx.json"
while [ $# -gt 0 ]; do
    case "$1" in
        --check)     CHECK=true ;;
        --installed) [ $# -ge 2 ] || die "--installed needs a directory"; INSTALLED="$2"; shift ;;
        --output)    [ $# -ge 2 ] || die "--output needs a file"; OUTPUT="$2"; shift ;;
        -h|--help)   usage; exit 0 ;;
        *)           usage >&2; die "unknown argument '$1'" ;;
    esac
    shift
done

command -v python3 >/dev/null 2>&1 || die "python3 not found (see doc/developerInfrastructure.md)"
[ -f "$COMPONENTS" ] || die "$COMPONENTS not found"
[ -d "$INSTALLED/vcpkg/info" ] || die "$INSTALLED/vcpkg/info not found; run scripts/build-core.sh first"

python3 - "$COMPONENTS" "$INSTALLED" "$OUTPUT" "$CHECK" <<'PY'
import datetime, glob, hashlib, json, os, sys

components_file, installed, output, check = sys.argv[1:5]
check = check == "true"
config = json.load(open(components_file))
triplet = config["vcpkgTriplet"]
asc_commit = config["ascCommit"]
helpers = set(config["vcpkgBuildHelpers"]["ports"])
overrides = config.get("vcpkgOverrides", {})

def spdx_id(text):
    return "SPDXRef-" + "".join(c if c.isalnum() or c in ".-" else "-" for c in text)

def package(ident, name, version, download, license, comment, homepage=None):
    result = {
        "SPDXID": spdx_id(ident),
        "name": name,
        "versionInfo": version,
        "downloadLocation": download,
        "filesAnalyzed": False,
        "licenseConcluded": "NOASSERTION",
        "licenseDeclared": license,
        "copyrightText": "NOASSERTION",
        "comment": comment,
    }
    if homepage:
        result["homepage"] = homepage
    return result

packages = []

# Libraries installed by vcpkg, one package per port.
ports = sorted({os.path.basename(f).split("_")[0]
                for f in glob.glob(os.path.join(installed, "vcpkg", "info", "*.list"))})
if not ports:
    sys.exit("Error: no vcpkg ports found in %s/vcpkg/info" % installed)
for port in ports:
    if port in helpers:
        continue
    spdx_file = os.path.join(installed, triplet, "share", port, "vcpkg.spdx.json")
    if not os.path.isfile(spdx_file):
        sys.exit("Error: %s not found" % spdx_file)
    doc = json.load(open(spdx_file))
    by_id = {p["SPDXID"]: p for p in doc["packages"]}
    port_pkg = by_id["SPDXRef-port"]
    port_version = port_pkg.get("versionInfo", "NOASSERTION")
    # Origin: the upstream sources vcpkg downloaded, without patches.
    resources = [p for i, p in sorted(by_id.items()) if i.startswith("SPDXRef-resource-")]
    sources = [p["downloadLocation"] for p in resources
               if ".patch" not in p.get("downloadLocation", "")]
    download = sources[0] if sources else port_pkg.get("homepage", "NOASSERTION")
    override = overrides.get(port, {})
    comment = "vcpkg port %s %s, triplet %s." % (port, port_version, triplet)
    if "comment" in override:
        comment += " " + override["comment"]
    packages.append(package(
        "vcpkg-" + port, port,
        override.get("version", port_version.split("#")[0]),
        download,
        override.get("license", port_pkg.get("licenseConcluded", "NOASSERTION")),
        comment,
        port_pkg.get("homepage")))

# Components that are not provided by vcpkg.
for item in config["packages"]:
    packages.append(package(
        item["id"], item["name"], item["version"],
        item["downloadLocation"].replace("{ascCommit}", asc_commit),
        item["license"], item["comment"], item.get("homepage")))

app = config["app"]
app_package = package("app", app["name"], app["version"], app["downloadLocation"],
                      app["license"], app["comment"])
relationships = [{"spdxElementId": "SPDXRef-DOCUMENT", "relationshipType": "DESCRIBES",
                  "relatedSpdxElement": app_package["SPDXID"]}]
relationships += [{"spdxElementId": app_package["SPDXID"], "relationshipType": "CONTAINS",
                   "relatedSpdxElement": p["SPDXID"]} for p in packages]
content = {
    "packages": [app_package] + packages,
    "relationships": relationships,
    "hasExtractedLicensingInfos": config["extractedLicenses"],
}

# The namespace is derived from the content; the creation time is kept as long as the
# content does not change, so the file only changes when the components change.
digest = hashlib.sha256(json.dumps(content, sort_keys=True).encode()).hexdigest()
namespace = "https://spdx.org/spdxdocs/asc-for-mac-" + digest
created = None
if os.path.isfile(output):
    try:
        old = json.load(open(output))
        if old.get("documentNamespace") == namespace:
            created = old["creationInfo"]["created"]
    except (ValueError, KeyError):
        pass
if created is None:
    created = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

document = {
    "spdxVersion": "SPDX-2.3",
    "dataLicense": "CC0-1.0",
    "SPDXID": "SPDXRef-DOCUMENT",
    "name": "asc-for-mac SBOM",
    "documentNamespace": namespace,
    "creationInfo": {
        "creators": ["Tool: asc-for-mac scripts/create-sbom.sh"],
        "created": created,
        "comment": "Created from vcpkg's SPDX files and scripts/sbom-components.json.",
    },
}
document.update(content)
text = json.dumps(document, indent=2, ensure_ascii=False) + "\n"

unclear = [p["name"] for p in packages if p["licenseDeclared"] == "NOASSERTION"]
if check:
    current = open(output).read() if os.path.isfile(output) else ""
    if current != text:
        sys.exit("Error: %s is out of date; run scripts/create-sbom.sh" % output)
    print("SBOM %s is up to date (%d packages)." % (output, len(packages) + 1))
else:
    with open(output, "w") as out:
        out.write(text)
    print("SBOM written to %s (%d packages)." % (output, len(packages) + 1))
if unclear:
    print("Packages with unclear licence (NOASSERTION): " + ", ".join(unclear))
PY
