#!/usr/bin/env bash
#
# create-icns.sh - Renders an Icon Composer icon (.icon) into an .icns file with all sizes.
#
# Usage:
#   scripts/create-icns.sh ICON OUTPUT
#
# ICON    An Icon Composer document, e.g. app/ASCforMac/AppIcon.icon (the app icon).
# OUTPUT  The .icns file to create, e.g. build/release/VolumeIcon.icns.
#
# Renders the default (light) appearance of the icon for macOS with ictool, which comes with
# Xcode (Icon Composer), in all sizes of an .icns file (16x16 to 512x512, each also @2x, i.e.
# up to 1024x1024 pixels), and combines them into OUTPUT. scripts/create-dmg.sh uses it for the
# volume icon of the .dmg; the app itself gets its icon from Xcode (see doc/buildAndTest.md).

# Note for developers: the comment block above is printed by --help.
# Keep this script compatible with Bash 3.2 (see doc/developerInfrastructure.md).

set -euo pipefail

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

case "${1:-}" in
    -h|--help) usage; exit 0 ;;
esac
[ $# -eq 2 ] || { usage >&2; die "expected ICON and OUTPUT"; }
ICON="$1"
OUTPUT="$2"
[ -f "$ICON/icon.json" ] || die "$ICON is not an Icon Composer document (no icon.json)"

# ictool is part of Icon Composer, which is part of Xcode. ICTOOL overrides it (for tests).
if [ -z "${ICTOOL:-}" ]; then
    command -v xcode-select >/dev/null 2>&1 || die "xcode-select not found (see doc/developerInfrastructure.md)"
    ICTOOL="$(xcode-select -p)/../Applications/Icon Composer.app/Contents/Executables/ictool"
fi
[ -x "$ICTOOL" ] || die "ictool not found at $ICTOOL (it comes with Xcode, see doc/developerInfrastructure.md)"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# The PNG types of an .icns file and their sizes in pixels.
TYPES="icp4:16 icp5:32 ic11:32 ic12:64 ic07:128 ic13:256 ic08:256 ic14:512 ic09:512 ic10:1024"
for entry in $TYPES; do
    type="${entry%%:*}"
    size="${entry##*:}"
    "$ICTOOL" "$ICON" --export-image --output-file "$WORK/$type.png" --platform macOS \
        --rendition Default --width "$size" --height "$size" --scale 1 >/dev/null
    [ -s "$WORK/$type.png" ] || die "ictool did not render $ICON at ${size}x$size"
done

mkdir -p "$(dirname "$OUTPUT")"
python3 - "$WORK" "$OUTPUT" $TYPES <<'EOF'
import struct
import sys

work, output, entries = sys.argv[1], sys.argv[2], sys.argv[3:]
chunks = b""
for entry in entries:
    icns_type, size = entry.split(":")
    with open(f"{work}/{icns_type}.png", "rb") as f:
        png = f.read()
    width, height = struct.unpack(">II", png[16:24])
    if png[:8] != b"\x89PNG\r\n\x1a\n" or (width, height) != (int(size), int(size)):
        sys.exit(f"Error: {icns_type}.png is not a {size}x{size} PNG")
    chunks += icns_type.encode("ascii") + struct.pack(">I", 8 + len(png)) + png
with open(output, "wb") as f:
    f.write(b"icns" + struct.pack(">I", 8 + len(chunks)) + chunks)
EOF
echo "Created $OUTPUT"
