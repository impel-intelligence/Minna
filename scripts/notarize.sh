#!/bin/sh
set -eu # Fail on errors and unset variables
set -o pipefail # Fail if xcodebuild fails, even when piped to xcpretty

ARCHIVE_PATH="tmp/archive/iris.xcarchive"
APP_EXPORT_DIRECTORY="tmp/apps"



if [ ! -d "$ARCHIVE_PATH" ]; then
    echo "error: $ARCHIVE_PATH not found (run archive.sh first)"
    exit 1
fi

xcrun notarytool submit "$ARCHIVE_PATH" \
                    --apple-id username \
                    --password password \
                    --team-id team      \
                    --wait              \

# # Requires ExportOptions.plist in the repo root (signing/export configuration).
# xcodebuild -exportArchive \
#     -archivePath "$ARCHIVE_PATH" \
#     -exportOptionsPlist ExportOptions.plist | xcpretty -c

# # Notarization is asynchronous; retry the export until Apple finishes processing.
# until xcodebuild -exportNotarizedApp \
#     -archivePath "$ARCHIVE_PATH" \
#     -exportPath "$APP_EXPORT_DIRECTORY" | xcpretty -c
# do
#     echo "Waiting for notarization..."
#     sleep 30
# done
