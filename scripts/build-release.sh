#!/usr/bin/env bash
# Build Prompteria for direct distribution (Developer ID) and create a signed, notarized DMG.
#
# Prerequisites:
#   - Apple Developer account with Developer ID Application certificate
#   - project.yml: Replace YOUR_TEAM_ID with your Team ID
#   - For notarization: NOTARY_APPLE_ID, NOTARY_APP_PASSWORD, NOTARY_TEAM_ID (optional)
#
# Usage: ./scripts/build-release.sh [version]
#   version: Optional (e.g. 1.0.0). Defaults to git describe or "dev"

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_DIR"

VERSION="${1:-$(git describe --tags --always 2>/dev/null || echo 'dev')}"
APP_NAME="Prompteria"
SCHEME="Prompteria"
ARCHIVE_NAME="${APP_NAME}.xcarchive"
BUILD_DIR="$PROJECT_DIR/build"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
EXPORT_DIR="$BUILD_DIR/export"

# Use unsigned build when BUILD_UNSIGNED=1 or when Developer ID cert is not available (e.g. CI)
USE_SIGNING=true
if [ "$BUILD_UNSIGNED" = "1" ]; then
    USE_SIGNING=false
    echo "Building ${APP_NAME} v${VERSION} (unsigned)..."
elif ! security find-identity -v -p codesigning 2>/dev/null | grep -q "Developer ID Application"; then
    USE_SIGNING=false
    echo "Building ${APP_NAME} v${VERSION} (unsigned - no Developer ID certificate found)..."
else
    echo "Building ${APP_NAME} v${VERSION} (Developer ID + notarization)..."
fi

# Ensure Xcode project exists
if [ ! -f "Prompteria.xcodeproj/project.pbxproj" ]; then
    echo "Generating Xcode project..."
    if command -v xcodegen &> /dev/null; then
        xcodegen generate
    else
        echo "Error: xcodegen not found. Install with: brew install xcodegen"
        exit 1
    fi
fi

# Clean and create build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

if [ "$USE_SIGNING" = true ]; then
    # Archive with Developer ID signing
    echo "Archiving..."
    xcodebuild archive \
        -scheme "$SCHEME" \
        -configuration Release \
        -archivePath "$BUILD_DIR/$ARCHIVE_NAME" \
        -destination "generic/platform=macOS" \
        CODE_SIGN_STYLE="Manual" \
        CODE_SIGN_IDENTITY="Developer ID Application"

    # Export for Developer ID distribution
    echo "Exporting..."
    xcodebuild -exportArchive \
        -archivePath "$BUILD_DIR/$ARCHIVE_NAME" \
        -exportPath "$EXPORT_DIR" \
        -exportOptionsPlist "$SCRIPT_DIR/ExportOptions-developerid.plist"

    APP_PATH="$EXPORT_DIR/${APP_NAME}.app"
else
    # Archive unsigned (for CI or when certs not available)
    echo "Archiving..."
    xcodebuild archive \
        -scheme "$SCHEME" \
        -configuration Release \
        -archivePath "$BUILD_DIR/$ARCHIVE_NAME" \
        -destination "generic/platform=macOS" \
        CODE_SIGN_IDENTITY="-" \
        CODE_SIGN_STYLE="Manual" \
        DEVELOPMENT_TEAM=""

    APP_PATH="$BUILD_DIR/$ARCHIVE_NAME/Products/Applications/${APP_NAME}.app"
fi
if [ ! -d "$APP_PATH" ]; then
    echo "Error: App not found at $APP_PATH"
    exit 1
fi

# Create DMG
DMG_STAGING="$BUILD_DIR/dmg-staging"
rm -rf "$DMG_STAGING"
mkdir -p "$DMG_STAGING"
cp -R "$APP_PATH" "$DMG_STAGING/"

if command -v create-dmg &> /dev/null; then
    echo "Creating DMG with create-dmg..."
    rm -f "$BUILD_DIR/$DMG_NAME"
    create-dmg \
        --volname "$APP_NAME" \
        --window-pos 200 120 \
        --window-size 600 400 \
        --icon-size 100 \
        --icon "${APP_NAME}.app" 150 190 \
        --hide-extension "${APP_NAME}.app" \
        --app-drop-link 450 185 \
        --skip-jenkins \
        "$BUILD_DIR/$DMG_NAME" \
        "$DMG_STAGING/"
else
    echo "Creating DMG with hdiutil..."
    hdiutil create -volname "$APP_NAME" -srcfolder "$DMG_STAGING" -ov -format UDZO \
        "$BUILD_DIR/$DMG_NAME"
fi

# Sign DMG (only when building signed)
if [ "$USE_SIGNING" = true ] && security find-identity -v -p codesigning | grep -q "Developer ID Installer"; then
    echo "Signing DMG..."
    codesign --force --sign "Developer ID Installer" "$BUILD_DIR/$DMG_NAME"
fi

# Notarize (only when building signed; requires NOTARY_APPLE_ID and NOTARY_APP_PASSWORD)
if [ "$USE_SIGNING" = true ] && [ -n "$NOTARY_APPLE_ID" ] && [ -n "$NOTARY_APP_PASSWORD" ]; then
    echo "Submitting for notarization..."
    if [ -n "$NOTARY_TEAM_ID" ]; then
        xcrun notarytool submit "$BUILD_DIR/$DMG_NAME" \
            --apple-id "$NOTARY_APPLE_ID" \
            --password "$NOTARY_APP_PASSWORD" \
            --team-id "$NOTARY_TEAM_ID" \
            --wait
    else
        xcrun notarytool submit "$BUILD_DIR/$DMG_NAME" \
            --apple-id "$NOTARY_APPLE_ID" \
            --password "$NOTARY_APP_PASSWORD" \
            --wait
    fi
    echo "Stapling notarization ticket..."
    xcrun stapler staple "$BUILD_DIR/$DMG_NAME"
    echo "✓ Notarization complete!"
else
    echo ""
    echo "Skipping notarization (set NOTARY_APPLE_ID and NOTARY_APP_PASSWORD to enable)."
fi

echo ""
echo "✓ Build complete!"
echo "  DMG: $BUILD_DIR/$DMG_NAME"
echo ""
echo "To install: Open the DMG and drag Prompteria to Applications."
