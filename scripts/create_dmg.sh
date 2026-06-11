#!/bin/sh
set -eu # Fail on errors and unset variables

# Builds tmp/apps/iris.dmg from the notarized tmp/apps/Iris.app using create-dmg.
# Layout (window, icon size, positions) mirrors the old DropDMG configuration.

APP="tmp/apps/Iris.app"
DMG="tmp/apps/iris.dmg"
STAGING="tmp/dmg"
BACKGROUND="scripts/dmg/background.png"
VOLUME_ICON="scripts/dmg/volume.icns"

if [ ! -d "$APP" ]; then
    echo "error: $APP not found (run notarize.sh first)"
    exit 1
fi

echo "Creating DMG"

# create-dmg copies the contents of the source folder into the disk image, so
# stage a clean folder containing only the app (tmp/apps also holds the tarball).
rm -rf "$STAGING" "$DMG"
mkdir -p "$STAGING"
cp -R "$APP" "$STAGING/"

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
    "$DMG" \
    "$STAGING"

rm -rf "$STAGING"
echo "Created $DMG"
