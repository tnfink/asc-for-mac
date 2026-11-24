#!/usr/bin/env bash
#
# create-dmg.sh - Builds, signs, notarizes and packages asc-for-mac as a .dmg for a release.
#
# Usage:
#   scripts/create-dmg.sh [--profile NAME] [--no-notarization]
#   scripts/create-dmg.sh --package-only APP DMG
#
# 1. Builds the Release configuration ("scripts/build.sh --release"); Xcode signs the app with
#    the Developer ID of the Team ID in the project, with the hardened runtime.
# 2. Checks the signature, notarizes the app with Apple's notarytool and staples the ticket.
# 3. Creates build/release/ASC-for-Mac-<version>.dmg with the app and a link to the
#    Applications folder, signs it with the same Developer ID, notarizes and staples it. The
#    volume shows the app icon (app/ASCforMac/AppIcon.icon, rendered by scripts/create-icns.sh).
# 4. Checks the app and the .dmg with Gatekeeper (spctl).
#
# The release version is the app's version plus "-mac" and its build number, e.g.
# 2.6.99.0-mac1 (see doc/buildAndTest.md, "Release package").
#
# --profile NAME     The keychain profile with the notarization credentials, created once with
#                    "xcrun notarytool store-credentials NAME" (default: asc-for-mac-notary).
# --no-notarization  Only build, sign and package; skips notarization and the Gatekeeper
#                    checks (for testing the package; such a .dmg must not be published).
# --package-only APP DMG
#                    Only packages the existing app APP as DMG, with the volume icon; no
#                    build, no signing, no notarization (for testing the packaging).

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

step() {
    echo "== $*"
}

PROFILE=asc-for-mac-notary
NOTARIZE=1
PACKAGE_APP=""
PACKAGE_DMG=""
while [ $# -gt 0 ]; do
    case "$1" in
        --profile)
            [ $# -ge 2 ] || die "--profile needs a name"
            PROFILE="$2"
            shift
            ;;
        --no-notarization) NOTARIZE=0 ;;
        --package-only)
            [ $# -ge 3 ] || die "--package-only needs APP and DMG"
            PACKAGE_APP="$2"
            PACKAGE_DMG="$3"
            shift 2
            ;;
        -h|--help) usage; exit 0 ;;
        *)         usage >&2; die "unknown argument '$1'" ;;
    esac
    shift
done

# package APP DMG VOLUME_NAME: creates the compressed DMG with the app, a link to the
# Applications folder and the app icon as volume icon.
package() {
    local app="$1" dmg="$2" volume="$3" staging
    staging="$(dirname "$dmg")/dmg-content"
    rm -rf "$staging" "$dmg"
    mkdir -p "$staging"
    ditto "$app" "$staging/ASCforMac.app"
    ln -s /Applications "$staging/Applications"
    # The volume icon: .VolumeIcon.icns at the root of the volume, and the root folder has the
    # Finder flag "custom icon" (kHasCustomIcon, 0x0400 in the Finder flags at byte 8 of
    # com.apple.FinderInfo), which the image takes over from the folder it is created from.
    "$REPO_DIR/scripts/create-icns.sh" "$REPO_DIR/app/ASCforMac/AppIcon.icon" "$staging/.VolumeIcon.icns"
    xattr -wx com.apple.FinderInfo \
        "00 00 00 00 00 00 00 00 04 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00" \
        "$staging"
    # diskutil replaces "hdiutil create", which is deprecated; the volume is APFS (macOS 10.13
    # and newer), UDZO is the compressed read-only format.
    diskutil image create from --format UDZO --volumeName "$volume" "$staging" "$dmg"
    rm -rf "$staging"
}

if [ -n "$PACKAGE_APP" ]; then
    [ -d "$PACKAGE_APP" ] || die "$PACKAGE_APP is not an app"
    mkdir -p "$(dirname "$PACKAGE_DMG")"
    package "$PACKAGE_APP" "$PACKAGE_DMG" "ASC for Mac"
    echo "Created $PACKAGE_DMG (NOT signed; do not publish it)."
    exit 0
fi

for tool in xcodebuild codesign diskutil spctl; do
    command -v "$tool" >/dev/null 2>&1 || die "$tool not found (see doc/developerInfrastructure.md)"
done

cd "$REPO_DIR"
APP=build/xcode/Build/Products/Release/ASCforMac.app
OUT_DIR=build/release

# Submits a file to Apple's notary service, waits for the result and staples the ticket.
notarize() {
    local file="$1" upload="$1"
    if [ -d "$file" ]; then
        # notarytool accepts .zip, .pkg and .dmg; an app is uploaded as a zip archive.
        upload="$OUT_DIR/$(basename "$file").zip"
        rm -f "$upload"
        ditto -c -k --keepParent "$file" "$upload"
    fi
    local result id
    # notarytool also exits with 0 if Apple rejects the file, so the status is checked.
    result="$(xcrun notarytool submit "$upload" --keychain-profile "$PROFILE" --wait 2>&1)" || true
    echo "$result"
    if ! echo "$result" | grep -q "^ *status: Accepted"; then
        id="$(echo "$result" | sed -n 's/^ *id: //p' | head -n 1)"
        die "notarization of $file failed; see Apple's log with: xcrun notarytool log ${id:-<id>} --keychain-profile $PROFILE"
    fi
    [ "$upload" = "$file" ] || rm -f "$upload"
    xcrun stapler staple "$file"
    xcrun stapler validate "$file"
}

if [ "$NOTARIZE" -eq 1 ]; then
    xcrun notarytool history --keychain-profile "$PROFILE" >/dev/null 2>&1 ||
        die "no notarization credentials in the keychain profile '$PROFILE'; create them with: xcrun notarytool store-credentials $PROFILE (see doc/buildAndTest.md)"
fi

step "Building the Release configuration"
scripts/build.sh --release

step "Checking the signature of the app"
codesign --verify --deep --strict --verbose=2 "$APP"
SIGNATURE="$(codesign -d --verbose=2 "$APP" 2>&1)"
echo "$SIGNATURE" | grep -q "^Authority=Developer ID Application: " ||
    die "the app is not signed with a Developer ID Application certificate"
echo "$SIGNATURE" | grep -q "flags=.*(runtime)" || die "the app is not signed with the hardened runtime"
# Apple rejects apps with this debugging entitlement, which Xcode adds unless the build setting
# CODE_SIGN_INJECT_BASE_ENTITLEMENTS is NO (set in the Release configuration).
if codesign -d --entitlements - "$APP" 2>/dev/null | grep -q "get-task-allow"; then
    die "the app has the entitlement com.apple.security.get-task-allow, which notarization rejects"
fi
TEAM_ID="$(echo "$SIGNATURE" | sed -n 's/^TeamIdentifier=//p')"
IDENTITY="$(echo "$SIGNATURE" | sed -n 's/^Authority=\(Developer ID Application: .*\)$/\1/p')"
echo "Signed by: $IDENTITY"

PLIST="$APP/Contents/Info.plist"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PLIST")"
BUILD="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$PLIST")"
RELEASE="$VERSION-mac$BUILD"
DMG="$OUT_DIR/ASC-for-Mac-$RELEASE.dmg"
echo "Release version: $RELEASE"
mkdir -p "$OUT_DIR"

if [ "$NOTARIZE" -eq 1 ]; then
    step "Notarizing the app (takes a few minutes)"
    notarize "$APP"
fi

step "Creating $DMG"
package "$APP" "$DMG" "ASC for Mac $RELEASE"
codesign --sign "$IDENTITY" --timestamp "$DMG"
codesign --verify --verbose=2 "$DMG"
echo "Team ID: $TEAM_ID"

if [ "$NOTARIZE" -eq 1 ]; then
    step "Notarizing the .dmg (takes a few minutes)"
    notarize "$DMG"

    step "Checking the app and the .dmg with Gatekeeper"
    spctl --assess --type execute --verbose "$APP"
    spctl --assess --type open --context context:primary-signature --verbose "$DMG"
    echo "Created $DMG (signed, notarized and stapled)."
else
    echo "Created $DMG (signed, NOT notarized; do not publish it)."
fi
