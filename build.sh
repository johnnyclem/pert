#!/bin/bash

set -e

BUILD_DIR=".build/release"
APPS_DIR="build/Apps"

echo "Building project..."
swift build -c release

echo "Creating app bundles..."

# Clean and create apps directory
rm -rf "$APPS_DIR"
mkdir -p "$APPS_DIR"

# Create Pert.app from PertCLI
echo "Creating Pert.app..."
PERT_APP="$APPS_DIR/Pert.app"
mkdir -p "$PERT_APP/Contents/MacOS"
mkdir -p "$PERT_APP/Contents/Resources"

# Copy executable
cp "$BUILD_DIR/pert" "$PERT_APP/Contents/MacOS/Pert"

# Create Info.plist for Pert
cat > "$PERT_APP/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Pert</string>
    <key>CFBundleIdentifier</key>
    <string>com.pert.cli</string>
    <key>CFBundleName</key>
    <string>Pert</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# Create PertGUI.app
echo "Creating PertGUI.app..."
PERTGUI_APP="$APPS_DIR/PertGUI.app"
mkdir -p "$PERTGUI_APP/Contents/MacOS"
mkdir -p "$PERTGUI_APP/Contents/Resources"

# Copy executable
cp "$BUILD_DIR/PertGUI" "$PERTGUI_APP/Contents/MacOS/PertGUI"

# Copy Info.plist
cp "Sources/PertGUI/Info.plist" "$PERTGUI_APP/Contents/Info.plist"

echo ""
echo "Build complete! App bundles created:"
echo "  - $PERT_APP"
echo "  - $PERTGUI_APP"
