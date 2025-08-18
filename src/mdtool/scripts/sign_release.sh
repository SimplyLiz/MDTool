#!/bin/bash

# MD Tool - Code Signing Script
# This script builds and signs the macOS release version

set -e  # Exit on any error

echo "🔨 Building MD Tool for macOS release..."
flutter clean
flutter build macos --release

echo "🔒 Signing the application..."
APP_PATH="build/macos/Build/Products/Release/md_tool.app"
IDENTITY="Apple Development: Lisa Welsch (ZFWXPDVR85)"

# First, sign all embedded frameworks that may have adhoc signatures
echo "  📝 Re-signing embedded frameworks..."
FRAMEWORKS_PATH="$APP_PATH/Contents/Frameworks"
if [ -d "$FRAMEWORKS_PATH" ]; then
    for framework in "$FRAMEWORKS_PATH"/*.framework; do
        if [ -d "$framework" ]; then
            echo "    🔐 Signing $(basename "$framework")"
            codesign --force --sign "$IDENTITY" --timestamp "$framework"
        fi
    done
fi

# Sign the app with hardened runtime and timestamp (deep sign to catch any remaining items)
echo "  🔏 Deep signing the main application..."
codesign --force --deep --sign "$IDENTITY" --timestamp --options runtime "$APP_PATH"

echo "✅ Verifying signature..."
codesign -dv --verbose=4 "$APP_PATH"

echo "🎉 MD Tool successfully built and signed!"
echo "📍 Location: $APP_PATH"

# Test if the app can be launched
echo "🧪 Testing app launch..."
if open "$APP_PATH"; then
    echo "✅ App launched successfully!"
else
    echo "❌ App failed to launch"
    exit 1
fi