#!/bin/sh
set -eu # Fail on errors and unset variables
set -o pipefail # Fail if xcodebuild fails, even when piped to xcpretty

ARCHIVE_PATH="tmp/archive/iris"

xcodebuild archive \
    -derivedDataPath tmp/derived \
    -destination generic/platform=macOS \
    -workspace Iris.xcworkspace \
    -scheme "Iris" \
    -archivePath "$ARCHIVE_PATH" | xcpretty -c
