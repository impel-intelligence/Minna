#!/bin/bash
set -euo pipefail # Fail on errors, unset variables, and any failure in a pipeline
set -x            # Echo each command before running it so the CI log shows progress

ARCHIVE_PATH="tmp/archive/iris.xcarchive"
APP_EXPORT_DIRECTORY="tmp/apps"
APP_PATH="$APP_EXPORT_DIRECTORY/Iris.app"
ZIP_PATH="$APP_EXPORT_DIRECTORY/Iris.zip"

# Raw, unfiltered xcodebuild output is teed here. xcpretty condenses the console
# view and drops the actual compiler/signing diagnostics on failure, so on a
# failed run the workflow uploads these logs (see prerelease.yml) to read the
# real error.
LOG_DIR="tmp/logs"
mkdir -p "$LOG_DIR"

# Make sure all of the environment options we need exist.

: "${APPLE_API_KEY_ID:?Please set APPLE_API_KEY_ID (the App Store Connect key ID)}"

: "${APPLE_API_ISSUER_ID:?Please set APPLE_API_ISSUER_ID (the issuer UUID)}"

: "${APPLE_API_KEY_BASE64:?Please set APPLE_API_KEY_BASE64 (base64 of the .p8 key file)}"

API_KEY_PATH="$(mktemp -t notary_key).p8"
trap 'rm -f "$API_KEY_PATH"' EXIT
printf '%s' "$APPLE_API_KEY_BASE64" | base64 --decode > "$API_KEY_PATH"

# 1. Build the app using xcodebuild.
echo "::group::Archive"
xcodebuild archive \
    -derivedDataPath tmp/derived \
    -destination generic/platform=macOS \
    -workspace Iris.xcworkspace \
    -scheme "Iris" \
    -archivePath "$ARCHIVE_PATH" 2>&1 | xcbeautify
echo "::endgroup::"

# 2. Export the signed Developer ID app from the archive.
#  - Requires ExportOptions.plist in the repo root (signing/export configuration).
echo "::group::Export Archive"
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$APP_EXPORT_DIRECTORY" \
    -exportOptionsPlist ExportOptions.plist 2>&1 | xcbeautify
echo "::endgroup::"

# 3. notarytool excepts a zip/pkg/dmg so we wrap the .app in a zip. We use ditto to preseve the symlinks nad metadata.
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

# 4. Submit to apple, block until it is done.
xcrun notarytool submit "$ZIP_PATH" \
    --key "$API_KEY_PATH" \
    --key-id "$APPLE_API_KEY_ID" \
    --issuer "$APPLE_API_ISSUER_ID" \
    --wait

# # 4. Staple the ticket onto the .app so it validates offline.
xcrun stapler staple "$APP_PATH"

# 5. Delete the zip since it was only used for uploading to notary tool.
rm -f "$ZIP_PATH"
