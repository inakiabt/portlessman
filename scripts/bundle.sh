#!/bin/bash
set -e

APP_NAME="Portlessman"
BUILD_DIR="build"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "🔨 Compiling Portlessman in release mode..."
swift build -c release

echo "📦 Creating .app bundle structure..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

echo "📋 Copying executable, Info.plist, and AppIcon..."
cp .build/release/Portlessman "${MACOS_DIR}/${APP_NAME}"
chmod +x "${MACOS_DIR}/${APP_NAME}"
cp Resources/Info.plist "${CONTENTS_DIR}/Info.plist"

if [ -f "Resources/AppIcon.icns" ]; then
    cp Resources/AppIcon.icns "${RESOURCES_DIR}/AppIcon.icns"
fi

echo "🔐 Ad-hoc code signing..."
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "✅ Successfully built ${APP_BUNDLE}"
