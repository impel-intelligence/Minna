#!/bin/sh
set -eu # Fail on errors and unset variables

# Builds tmp/apps/iris.dmg from the notarized tmp/apps/Iris.app using create-dmg.
# Layout (window, icon size, positions) mirrors the old DropDMG configuration.

TMP_PATH="tmp/apps"

APP_NAME="Iris.app"
APP_PATH="${TMP_PATH}/${APP_NAME}"

DMG_NAME="iris.dmg"
DMG_PATH="${TMP_PATH}/${DMG_NAME}"

TAR_NAME="iris.tar.xz"
TAR_PATH="${TMP_PATH}/${TAR_NAME}"

STAGING_PATH="tmp/dmg"
BACKGROUND="scripts/dmg/background.png"
VOLUME_ICON="scripts/dmg/volume.icns"

if [ ! -d "$APP_PATH" ]; then
    echo "error: $APP_PATH not found (run notarize.sh first)"
    exit 1
fi

echo "Creating DMG"

# create-dmg copies the contents of the source folder into the disk image, so
# stage a clean folder containing only the app (tmp/apps also holds the tarball).
rm -rf "$STAGING_PATH" "$DMG_PATH"
mkdir -p "$STAGING_PATH"
cp -R "$APP_PATH" "$STAGING_PATH/"

create-dmg \
    --volname "Iris" \
    --volicon "$VOLUME_ICON" \
    --background "$BACKGROUND" \
    --window-pos 100 100 \
    --window-size 740 494 \
    --icon-size 128 \
    --text-size 12 \
    --icon "Iris.app" 208 208 \
    --app-drop-link 544 208 \
    --hide-extension "Iris.app" \
    --no-internet-enable \
    "$DMG_PATH" \
    "$STAGING_PATH"

rm -rf "$STAGING_PATH"
echo "Created $DMG_PATH"

# Create a tar for the sparkle updater.
tar --no-xattrs -cJf "$TAR_PATH" -C "$TMP_PATH" "$APP_NAME"

echo "Created $TAR_PATH"
