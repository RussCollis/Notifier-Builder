#!/bin/bash
# Wraps a signed, notarized Notifier Builder.app in a signed, notarized, stapled DMG.
# Usage: ./make_dmg.sh "/path/to/Notifier Builder.app"
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_PATH="${1:-$SCRIPT_DIR/Notifier Builder.app}"
IDENTITY="Developer ID Application: Russell Collis (UM5LY5579J)"
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_PATH/Contents/Info.plist")
DMG="$SCRIPT_DIR/NotifierBuilder-$VERSION.dmg"

STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT
ditto "$APP_PATH" "$STAGE/Notifier Builder.app"
ln -s /Applications "$STAGE/Applications"

echo "==> Creating $DMG..."
rm -f "$DMG"
hdiutil create -volname "Notifier Builder" -srcfolder "$STAGE" -ov -format UDZO "$DMG"

echo "==> Signing, notarizing and stapling..."
codesign --force --timestamp --sign "$IDENTITY" "$DMG"
xcrun notarytool submit "$DMG" --keychain-profile notary --wait
xcrun stapler staple "$DMG"
spctl -a -vvv -t open --context context:primary-signature "$DMG"
