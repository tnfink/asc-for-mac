#!/usr/bin/env bash
#
# create-source-archive.sh - Creates the archive with the sources of the libraries from vcpkg
# for a release.
#
# Usage:
#   scripts/create-source-archive.sh [--installed DIR] [--output FILE]
#
# --installed DIR   vcpkg's installed tree of the app's build (default:
#                   build/core/vcpkg_installed, created by scripts/build-core.sh); its ports
#                   are put into the archive.
# --output FILE     The archive (default:
#                   build/release/ASC-for-Mac-<release version>-vcpkg-sources.tar.gz).
#
# The GPL and LGPL require the complete source code of the app from the same place as the app
# (doc/thirdparty.md, "Licence analysis"). The repository contains the own code and ASC, but not
# the libraries vcpkg downloads; this archive is attached to each GitHub Release for them.
# The script downloads the sources of all libraries of vcpkg.json at the vcpkg baseline
# (vcpkg install --only-downloads, without the binary cache) and packs them together with
# vcpkg's port files (build scripts and patches) of every installed port and a README.txt.
# Needs vcpkg in build/vcpkg at the baseline (scripts/build-core.sh) and a network connection;
# takes a few minutes. See doc/buildAndTest.md ("Release on GitHub").

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

INSTALLED="$REPO_DIR/build/core/vcpkg_installed"
OUTPUT=""
while [ $# -gt 0 ]; do
    case "$1" in
        --installed)
            [ $# -ge 2 ] || die "--installed needs a directory"
            INSTALLED="$2"
            shift
            ;;
        --output)
            [ $# -ge 2 ] || die "--output needs a file"
            OUTPUT="$2"
            shift
            ;;
        -h|--help) usage; exit 0 ;;
        *)         usage >&2; die "unknown argument '$1'" ;;
    esac
    shift
done

VCPKG_DIR="$REPO_DIR/build/vcpkg"
[ -x "$VCPKG_DIR/vcpkg" ] || die "vcpkg not found in $VCPKG_DIR; run scripts/build-core.sh first"
[ -d "$INSTALLED/vcpkg/info" ] || die "no vcpkg installed tree in $INSTALLED; run scripts/build-core.sh first"
BASELINE="$(sed -n 's/.*"builtin-baseline": *"\([0-9a-f]*\)".*/\1/p' "$REPO_DIR/vcpkg.json")"
[ "$(git -C "$VCPKG_DIR" rev-parse HEAD)" = "$BASELINE" ] ||
    die "vcpkg in $VCPKG_DIR is not at the baseline $BASELINE; run scripts/build-core.sh first"

# The release version, as scripts/create-dmg.sh builds it: version plus "-mac" and build number.
PROJECT="$REPO_DIR/ASCforMac.xcodeproj/project.pbxproj"
VERSION="$(sed -n 's/.*MARKETING_VERSION = \([^;]*\);.*/\1/p' "$PROJECT" | head -n 1)"
BUILD="$(sed -n 's/.*CURRENT_PROJECT_VERSION = \([^;]*\);.*/\1/p' "$PROJECT" | head -n 1)"
RELEASE="$VERSION-mac$BUILD"
NAME="ASC-for-Mac-$RELEASE-vcpkg-sources"
[ -n "$OUTPUT" ] || OUTPUT="$REPO_DIR/build/release/$NAME.tar.gz"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
STAGING="$WORK/$NAME"
mkdir -p "$STAGING/downloads" "$STAGING/ports"

echo "== Downloading the library sources with vcpkg (takes a few minutes)"
cd "$REPO_DIR"
VCPKG_DISABLE_METRICS=1 "$VCPKG_DIR/vcpkg" install --only-downloads \
    --x-manifest-root="$REPO_DIR" --x-install-root="$WORK/installed" \
    --downloads-root="$WORK/downloads" --x-buildtrees-root="$WORK/buildtrees" \
    --binarysource=clear --triplet arm64-osx-asc --host-triplet arm64-osx-asc \
    --overlay-triplets="$REPO_DIR/cmake/triplets" >"$WORK/vcpkg.log" 2>&1 ||
    { tail -n 20 "$WORK/vcpkg.log" >&2; die "vcpkg could not download the sources"; }

# The sources; tools/ and ninja are build tools vcpkg downloads for itself, not part of the app.
for file in "$WORK/downloads"/*; do
    case "$(basename "$file")" in
        tools|ninja-*|*.part) ;;
        *) cp -R "$file" "$STAGING/downloads/" ;;
    esac
done
[ -n "$(ls "$STAGING/downloads")" ] || die "vcpkg downloaded no sources"

# vcpkg's port files (portfile.cmake, patches, ...) of every installed port.
PORTS="$(ls "$INSTALLED/vcpkg/info" | sed -n 's/^\([^_]*\)_.*\.list$/\1/p' | sort -u)"
for port in $PORTS; do
    [ -d "$VCPKG_DIR/ports/$port" ] || die "port $port not found in $VCPKG_DIR/ports"
    cp -R "$VCPKG_DIR/ports/$port" "$STAGING/ports/"
done

cat >"$STAGING/README.txt" <<EOF
Sources of the libraries in ASC for Mac $RELEASE

ASC for Mac links these libraries statically. They are built by vcpkg
(https://github.com/microsoft/vcpkg) at commit $BASELINE
with the triplet cmake/triplets/arm64-osx-asc.cmake of the asc-for-mac repository.

downloads/  the source archives and patches vcpkg downloads for the libraries
ports/      vcpkg's port files (build scripts and patches) of every library

The source code of ASC for Mac itself (own code, ASC, build files) is the repository
https://github.com/tnfink/asc-for-mac at the tag $RELEASE. To rebuild the app with
these sources, put the files of downloads/ into vcpkg's downloads directory and follow
doc/buildAndTest.md of the repository. The licences of all components are listed in
the app (ASC for Mac > Licenses...) and in doc/sbom.spdx.json.
EOF

mkdir -p "$(dirname "$OUTPUT")"
tar -czf "$OUTPUT" -C "$WORK" "$NAME"
echo "Created $OUTPUT ($(ls "$STAGING/downloads" | wc -l | tr -d ' ') downloads, $(echo "$PORTS" | wc -l | tr -d ' ') ports)"
