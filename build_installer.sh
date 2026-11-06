#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "==> Building Notifier Builder in Xcode..."
xcodebuild -project "$SCRIPT_DIR/Untitled Project.xcodeproj" -scheme "MyApp" -configuration Debug build

DERIVED_PRODUCTS=$(xcodebuild -project "$SCRIPT_DIR/Untitled Project.xcodeproj" -scheme "MyApp" -configuration Debug -showBuildSettings | awk -F ' = ' '/BUILT_PRODUCTS_DIR/ {print $2}')
APP_PATH="$DERIVED_PRODUCTS/Notifier Builder.app"
PKG_OUTPUT="$SCRIPT_DIR/NotifierBuilder-1.0.pkg"

if [ ! -d "$APP_PATH" ]; then
    echo "Error: App bundle not found at $APP_PATH"
    exit 1
fi

echo "==> Packaging $APP_PATH into $PKG_OUTPUT..."
pkgbuild --component "$APP_PATH" \
         --install-location "/Applications" \
         --identifier "com.jamfconcepts.notifierbuilder" \
         --version "1.0.0" \
         "$PKG_OUTPUT"

echo "✓ Installer package built successfully at:"
echo "  $PKG_OUTPUT"
