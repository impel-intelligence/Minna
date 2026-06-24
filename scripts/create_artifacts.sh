#!/bin/sh
set -eu # Fail on errors and unset variables

# Builds tmp/apps/iris.dmg from the notarized tmp/apps/Iris.app using create-dmg.
# Layout (window, icon size, positions) mirrors the old DropDMG configuration.

APP_PATH="tmp/apps/Iris.app"
DMG_PATH="tmp/apps/iris.dmg"
STAGING_PATH="tmp/dmg"
BACKGROUND="scripts/dmg/background.png"
VOLUME_ICON="scripts/dmg/volume.icns"

TAR_PATH="$APP_EXPORT_DIRECTORY/iris.tar.xz"

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
tar --no-xattrs -cJf "$TAR_PATH" "$APP_PATH"

echo "Created $TAR_PATH"
