#!/bin/sh
set -eu # Fail on errors and unset variables

APP_PATH=$1
OUTPUT_DIR=$2

### Pre-flight Checks ###

if [ ! -d "Minna.xcodeproj" ]; then
    echo "This script must be run from the root directory of the project: './scripts/release.sh'!"
    exit 1
fi

### Directory Management ###
STAGE_DIR=stage
DMG_OUTPUT="$OUTPUT_DIR/minna.dmg"
TAR_OUTPUT="$OUTPUT_DIR/minna.tar.xz"

# Delete existing artifacts
rm -f $DMG_OUTPUT
rm -f $TAR_OUTPUT

### CREATE DMG ###

# Create a staging directory
rm -rf $STAGE_DIR
mkdir $STAGE_DIR

# Create output directory
mkdir -p $OUTPUT_DIR

# Copy the app into the staging directory
ditto "$APP_PATH" "$STAGE_DIR/Minna.app"

create-dmg \
	--volname "Minna" \
	--volicon scripts/dmg/icon.icns \
	--background scripts/dmg/background.png \
	--window-size 540 440 \
	--icon "Minna.app" 130 170  \
	--app-drop-link 410 170  \
	--hide-extension "Minna.app" \
	--no-internet-enable \
	$DMG_OUTPUT \
	$STAGE_DIR \

### CREATE TAR ###

# Create a tar for the sparkle updater.
printf "%s\n" "Creating Tarball"
tar --no-xattrs -cJf $TAR_OUTPUT -C $STAGE_DIR Minna.app
printf "%s\n" "Tarball done"

rm -rf $STAGE_DIR
