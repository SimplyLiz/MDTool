#!/bin/bash

# Create a standalone QuickLook extension
# This script builds the extension without Xcode dependencies

EXTENSION_NAME="MarkdownQLPreview"
BUILD_DIR="build_standalone"
EXTENSION_DIR="$BUILD_DIR/$EXTENSION_NAME.qlgenerator"

# Clean and create build directory
rm -rf "$BUILD_DIR"
mkdir -p "$EXTENSION_DIR/Contents/MacOS"
mkdir -p "$EXTENSION_DIR/Contents/Resources"

# Copy Info.plist and update for .qlgenerator
cp Info.plist "$EXTENSION_DIR/Contents/Info.plist"

# Update the Info.plist for standalone .qlgenerator
/usr/libexec/PlistBuddy -c "Set :CFBundleExecutable $EXTENSION_NAME" "$EXTENSION_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundlePackageType BNDL" "$EXTENSION_DIR/Contents/Info.plist"

# Compile the Swift code for macOS 12+
swiftc -target x86_64-apple-macos12.0 \
       -framework Cocoa \
       -framework Quartz \
       -framework UniformTypeIdentifiers \
       -o "$EXTENSION_DIR/Contents/MacOS/$EXTENSION_NAME" \
       PreviewProvider.swift

echo "Built extension at: $EXTENSION_DIR"
echo "To install: cp -r $EXTENSION_DIR ~/Library/QuickLook/"
echo "Then run: qlmanage -r && qlmanage -r cache"