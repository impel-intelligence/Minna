#!/bin/sh
set -eu # Fail on errors and unset variables

echo "Upload Symbols To Sentry"

DSYM_FOLDER="tmp/archive/iris.xcarchive/dSYMs/"

# NOTE: SENTRY_ORG / SENTRY_PROJECT are external Sentry identifiers and must
# match the project configured in Sentry. Update them there if renamed to Iris.
export SENTRY_ORG=impel-intelligence-inc
export SENTRY_PROJECT=iris-macos
export SENTRY_AUTH_TOKEN=$1

sentry-cli debug-files upload --include-sources --force-foreground "$DSYM_FOLDER"
