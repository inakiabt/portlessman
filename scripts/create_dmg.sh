#!/bin/bash
set -e

VERSION="${1:-1.0.0}"
APP_NAME="Portlessman"
BUILD_DIR="build"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
DMG_PATH="${BUILD_DIR}/${DMG_NAME}"
ZIP_NAME="${APP_NAME}-${VERSION}.zip"
ZIP_PATH="${BUILD_DIR}/${ZIP_NAME}"

if [ ! -d "${APP_BUNDLE}" ]; then
    echo "❌ ${APP_BUNDLE} not found. Running bundle.sh first..."
    ./scripts/bundle.sh
fi

echo "📦 Creating ZIP archive using ditto..."
rm -f "${ZIP_PATH}"
ditto -c -k --sequesterRsrc --keepParent "${APP_BUNDLE}" "${ZIP_PATH}"

echo "💿 Creating DMG..."
rm -f "${DMG_PATH}"
TMP_DMG_DIR=$(mktemp -d /tmp/portlessman-dmg.XXXXXX)

cp -R "${APP_BUNDLE}" "${TMP_DMG_DIR}/"
ln -s /Applications "${TMP_DMG_DIR}/Applications"

hdiutil create -volname "${APP_NAME}" -srcfolder "${TMP_DMG_DIR}" -ov -format UDZO "${DMG_PATH}"
rm -rf "${TMP_DMG_DIR}"

echo "🔒 Calculating checksums..."
cd "${BUILD_DIR}"
shasum -a 256 "${ZIP_NAME}" > "${ZIP_NAME}.sha256"
shasum -a 256 "${DMG_NAME}" > "${DMG_NAME}.sha256"
cd ..

echo "✅ Created:"
echo "   - ${ZIP_PATH} (SHA-256: $(cat "${BUILD_DIR}/${ZIP_NAME}.sha256" | awk '{print $1}'))"
echo "   - ${DMG_PATH} (SHA-256: $(cat "${BUILD_DIR}/${DMG_NAME}.sha256" | awk '{print $1}'))"
