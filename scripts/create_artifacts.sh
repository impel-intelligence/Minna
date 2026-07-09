#!/bin/sh
set -eu # Fail on errors and unset variables

APP_PATH=$1

STAGE_DIR=stage

# Delete existing artifacts
rm minna.dmg
rm minna.tar.xz

### CREATE DMG ###

# Create a staging directory
rm -rf $STAGE_DIR
mkdir $STAGE_DIR

# Copy the app into the staging directory
cp -r $APP_PATH stage/Minna.app

create-dmg \
	--volname "Minna" \
	--volicon dmg/icon.icns \
	--background dmg/background.png \
	--window-size 540 440 \
	--icon "Minna.app" 130 170  \
	--app-drop-link 410 170  \
	--hide-extension "Minna.app" \
	--no-internet-enable \
	minna.dmg \
	$STAGE_DIR \

### CREATE TAR ###

# Create a tar for the sparkle updater.
tar --no-xattrs -cJf minna.tar.xz -C $STAGE_DIR Minna.app

rm -rf $STAGE_DIR
