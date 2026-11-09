#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="$SCRIPT_DIR/Notifier Builder.xcodeproj"
SCHEME="Notifier Builder"
CONFIGURATION="Release"

echo "==> Building Notifier Builder ($CONFIGURATION)..."
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration "$CONFIGURATION" build

# Read paths and version from the project's build settings so they never drift
BUILD_SETTINGS=$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration "$CONFIGURATION" -showBuildSettings)
setting() { echo "$BUILD_SETTINGS" | awk -F ' = ' -v key="$1" '$1 ~ "^ *"key"$" {print $2; exit}'; }

DERIVED_PRODUCTS=$(setting BUILT_PRODUCTS_DIR)
VERSION=$(setting MARKETING_VERSION)
BUILD_NUMBER=$(setting CURRENT_PROJECT_VERSION)

APP_PATH="$DERIVED_PRODUCTS/Notifier Builder.app"
PKG_OUTPUT="$SCRIPT_DIR/NotifierBuilder-$VERSION.pkg"

if [ ! -d "$APP_PATH" ]; then
    echo "Error: App bundle not found at $APP_PATH"
    exit 1
fi

echo "==> Packaging $APP_PATH (v$VERSION build $BUILD_NUMBER) into $PKG_OUTPUT..."
pkgbuild --component "$APP_PATH" \
         --install-location "/Applications" \
         --identifier "com.jamfconcepts.notifierbuilder" \
         --version "$VERSION.$BUILD_NUMBER" \
         "$PKG_OUTPUT"

echo "✓ Installer package built successfully at:"
echo "  $PKG_OUTPUT"
