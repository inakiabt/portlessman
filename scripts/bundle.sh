#!/bin/bash
set -e

APP_NAME="Portless"
BUILD_DIR="build"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "🔨 Compiling Portless in release mode..."
swift build -c release

echo "📦 Creating .app bundle structure..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

echo "📋 Copying executable and Info.plist..."
cp .build/release/Portless "${MACOS_DIR}/${APP_NAME}"
chmod +x "${MACOS_DIR}/${APP_NAME}"
cp Resources/Info.plist "${CONTENTS_DIR}/Info.plist"

echo "🔐 Ad-hoc code signing..."
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "✅ Successfully built ${APP_BUNDLE}"
