#!/usr/bin/env bash
# Export Promptastic for Mac App Store submission.
#
# Prerequisites:
#   - Apple Developer account with "Apple Distribution" certificate
#   - Mac App Store provisioning profile for com.promptastic.app
#   - project.yml: Replace YOUR_TEAM_ID with your Team ID
#   - scripts/ExportOptions-appstore.plist: Update provisioning profile name
#
# Usage: ./scripts/export-mas.sh
# Output: build/Promptastic-mas/ (folder to upload via Transporter or Xcode)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_DIR"

APP_NAME="Promptastic"
SCHEME="Promptastic"
ARCHIVE_NAME="${APP_NAME}.xcarchive"
BUILD_DIR="$PROJECT_DIR/build"
EXPORT_DIR="$BUILD_DIR/${APP_NAME}-mas"

echo "Building ${APP_NAME} for Mac App Store..."

# Ensure Xcode project exists
if [ ! -f "Promptastic.xcodeproj/project.pbxproj" ]; then
    echo "Generating Xcode project..."
    xcodegen generate
fi

# Check for Apple Distribution certificate
if ! security find-identity -v -p codesigning | grep -q "Apple Distribution"; then
    echo "Error: Apple Distribution certificate not found."
    echo "Create one in Xcode → Settings → Accounts → Manage Certificates → + → Apple Distribution"
    exit 1
fi

# Clean and create build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Archive for Mac App Store
echo "Archiving..."
xcodebuild archive \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$BUILD_DIR/$ARCHIVE_NAME" \
    -destination "generic/platform=macOS" \
    CODE_SIGN_STYLE="Manual" \
    CODE_SIGN_IDENTITY="Apple Distribution"

# Export for App Store
echo "Exporting for App Store..."
xcodebuild -exportArchive \
    -archivePath "$BUILD_DIR/$ARCHIVE_NAME" \
    -exportPath "$EXPORT_DIR" \
    -exportOptionsPlist "$SCRIPT_DIR/ExportOptions-appstore.plist"

echo ""
echo "✓ Export complete!"
echo "  Output: $EXPORT_DIR"
echo ""
echo "Next steps:"
echo "  1. Open Transporter app (from Mac App Store) or use: xcrun altool --upload-app"
echo "  2. Upload the .pkg or .app from $EXPORT_DIR"
echo "  3. Or: Xcode → Window → Organizer → Distribute App → App Store Connect"
