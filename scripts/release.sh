#!/bin/sh
# A script to run the whole release pipeline for self-distributed Minna :)
# This script should be run on a development computer, it will not support CI/CD.
set -eu
TEMPORARY_DIRECTORY=tmp
OUTPUT_DIRECTORY="out"
BASE=$(PWD)
NOTARY_PROFILE="Impel-Intelligence"
PROGRESS_FILE="$OUTPUT_DIRECTORY/progress.txt"

### Pre-flight Checks ###
if [ ! -d "Minna.xcodeproj" ]; then
    echo "This script must be run from the root directory of the project: './scripts/release.sh'!"
    exit 1
fi

# Check to make sure we are on a clean branch.
GIT_STATUS=$(git status --porcelain)

if [ -n "$GIT_STATUS" ]; then
    printf "%s\n" "The git working directory is not clean! You must run this script on a clean working copy of main."
    # exit 1
fi

# Check to make sure we are on the main branch.
GIT_BRANCH=$(git branch --show-current)

if [ "$GIT_BRANCH" != "main" ]; then
    printf "%s\n" "The git branch should be main!"
    # exit 1
fi

# Check to make sure the user has setup notarytool
if ! xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" > /dev/null 2>&1; then
    printf "%s\n" "You have not setup notarytool to use the $NOTARY_PROFILE credentials."
    printf "%s\n" "Run: 'xcrun notarytool store-credentials $NOTARY_PROFILE'"
    exit 1
fi

# Check to make sure the projec tag is correct.
SEM_VER_REGEX="(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?"
APP_VERSION=$(grep -oE -m 1 "MARKETING_VERSION = $SEM_VER_REGEX" Minna.xcodeproj/project.pbxproj | sed 's/.*MARKETING_VERSION = \([0-9.]*\).*/\1/')

printf "%s\n" "Does $APP_VERSION look like the correct version?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) break;;
        No ) printf "%s\n" "Update the version of Minna in the Xcode project and commit!"; exit 1;;
    esac
done

# Grab the release title and notes from CHANGELOG.md instead of asking for them manually.
CHANGELOG_OUTPUT=$(./scripts/extract_changelog.sh "$APP_VERSION")
VERSION_TITLE=$(printf '%s\n' "$CHANGELOG_OUTPUT" | sed -n '1p')
VERSION_NOTES=$(printf '%s\n' "$CHANGELOG_OUTPUT" | sed '1,2d')

if [ -z "$VERSION_NOTES" ]; then
    printf "%s\n" "There are no version notes for this version! Add notes in CHANGELOG.md."
    exit 1
fi

printf "%s\n" "Is \"$VERSION_TITLE\" the correct title for this release?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) break;;
        No ) printf "%s\n" "Update the title for this version in CHANGELOG.md and commit!"; exit 1;;
    esac
done

# Check to see if the Sparkle Framework is the newest verison
SPARKLE_GITHUB=sparkle-project/Sparkle
SPARKLE_LOCATION=$(PWD)/Frameworks/Sparkle.framework
SPARKLE_INFO_PLIST="$SPARKLE_LOCATION/Resources/Info.plist"
SPARKLE_VERSION=$(plutil -extract CFBundleShortVersionString raw $SPARKLE_INFO_PLIST)

LATEST_SPARKLE=$(gh release view --repo "$SPARKLE_GITHUB" --json tagName --jq .tagName)

if [ "$SPARKLE_VERSION" != "$LATEST_SPARKLE" ]; then
    printf "%s\n" "Sparkle is not up to date. Please update it before publishing a new app version."
    gh release view --repo "$SPARKLE_GITHUB" --web
    exit 1
fi

### Setup Directories ###
# Clear directories if there is no progress.
if [ ! -f "$PROGRESS_FILE" ]; then
    rm -rf "$OUTPUT_DIRECTORY"
    rm -rf "$TEMPORARY_DIRECTORY"
fi

mkdir -p "$OUTPUT_DIRECTORY"
mkdir -p "$TEMPORARY_DIRECTORY"

### Tag Creation ###
TAG_EXIST=$(git tag -l "$APP_VERSION")
if [ -z "$TAG_EXIST" ]; then
    printf "%s\n" "Created Git Tag for $APP_VERSION"
    git tag "v$APP_VERSION" -m "$VERSION_NOTES"
fi

### Build ###
SPM_BUILD_DIRECTORY="$(PWD)/$TEMPORARY_DIRECTORY/spm"

APP_STORE_BUILD_DIR="$(PWD)/$TEMPORARY_DIRECTORY/app-store-build"
APP_STORE_ARCHIVE="$APP_STORE_BUILD_DIR/Minna.xcarchive"
APP_STORE_EXPORT_OPTIONS=$(PWD)/scripts/export_options/AppStoreExportOptions.plist

SPARKLE_BUILD_DIR="$(PWD)/$TEMPORARY_DIRECTORY/sparkle-build"
SPARKLE_ARCHIVE="$SPARKLE_BUILD_DIR/Minna.xcarchive"
SPARKLE_EXPORT_OPTIONS=$(PWD)/scripts/export_options/SparkleExportOptions.plist

# Archive the App Store configuration of Minna.
ARCHIVE_APP_STORE_PROGRESS_MARKER="archive-app-store"
if ! grep -qF "$ARCHIVE_APP_STORE_PROGRESS_MARKER" $PROGRESS_FILE; then
    xcodebuild archive -project Minna.xcodeproj -scheme "Minna" -configuration "Release" -archivePath "$APP_STORE_ARCHIVE/Minna.xcarchive"  -derivedDataPath "$APP_STORE_BUILD_DIR" -clonedSourcePackagesDirPath "$SPM_BUILD_DIRECTORY" | xcbeautify

    # Save the build progress
    echo "$ARCHIVE_APP_STORE_PROGRESS_MARKER" >> "$OUTPUT_DIRECTORY/progress.txt"
else
    printf "%s\n" "Not archiving for app store because the progress file states it has already been done."
fi

# Archive the Direct Distribution configuration of Minna.
ARCHIVE_SPARKLE_PROGRESS_MARKER="archive-sparkle"
if ! grep -qF "$ARCHIVE_SPARKLE_PROGRESS_MARKER" $PROGRESS_FILE; then
    xcodebuild archive -project Minna.xcodeproj -scheme "Minna" -configuration "Release Sparkle" -archivePath "$SPARKLE_ARCHIVE" -derivedDataPath "$SPARKLE_BUILD_DIR" -clonedSourcePackagesDirPath "$SPM_BUILD_DIRECTORY" | xcbeautify

    # Save the build progress
    echo "$ARCHIVE_SPARKLE_PROGRESS_MARKER" >> "$OUTPUT_DIRECTORY/progress.txt"
else
    printf "%s\n" "Not archiving for direct distribution because the progress file states it has already been done."
fi

# Export Archives
APP_STORE_APP_EXPORT_DIRECTORY="$OUTPUT_DIRECTORY/app-store"
SPARKLE_APP_EXPORT_DIRECTORY="$OUTPUT_DIRECTORY/sparkle"

# Upload the App Store archive to App Store Connect
APP_STORE_UPLOAD_PROGRESS_MARKER="app-store-upload"
if ! grep -qF "$APP_STORE_UPLOAD_PROGRESS_MARKER" $PROGRESS_FILE; then
    xcodebuild -exportArchive -archivePath "$APP_STORE_ARCHIVE" -exportOptionsPlist "$APP_STORE_EXPORT_OPTIONS"  | xcbeautify

    # Save the build progress
    echo "$APP_STORE_UPLOAD_PROGRESS_MARKER" >> "$OUTPUT_DIRECTORY/progress.txt"
else
    printf "%s\n" "Not uploading to app store because the progress file states it has already been done."
fi

# Export Direct Distribution Copy
SPARKLE_EXPORT_PROGRESS_MARKER="sparkle-export"
if ! grep -qF "$SPARKLE_EXPORT_PROGRESS_MARKER" $PROGRESS_FILE; then
    xcodebuild -exportArchive -archivePath "$SPARKLE_ARCHIVE" -exportOptionsPlist "$SPARKLE_EXPORT_OPTIONS" -exportPath "$SPARKLE_APP_EXPORT_DIRECTORY" | xcbeautify

    # Save the build progress
    echo "$SPARKLE_EXPORT_PROGRESS_MARKER" >> "$OUTPUT_DIRECTORY/progress.txt"
else
    printf "%s\n" "Not exporting direct distribution copy because the progress file states it has already been done."
fi

# We need to wrap the app in a .zip for notary tool. We use ditto to preserve the symlinks and metadata.
SPARKLE_APP_NOTARY_ZIP_LOCATION="$SPARKLE_APP_EXPORT_DIRECTORY/Minna.zip"
SPARKLE_APP_LOCATION="$SPARKLE_APP_EXPORT_DIRECTORY/Minna.app"

printf "%s\n" "Copying Sparkle App to a zip for notarization."
ditto -c -k --keepParent "$SPARKLE_APP_LOCATION" "$SPARKLE_APP_NOTARY_ZIP_LOCATION"

# Submit the app to Apple for Notarization.
printf "%s\n" "Submitting sparkle app to Apple Notary."
xcrun notarytool submit "$SPARKLE_APP_NOTARY_ZIP_LOCATION" --keychain-profile "Impel-Intelligence" --wait

# Staple the notarization ticket to the app.
printf "%s\n" "Stapling notarization ticket to sparkle app."
xcrun stapler staple "$SPARKLE_APP_LOCATION"

### Create Direct Distribution Artifacts ###
printf "%s\n" "Creating Distribution Artifacts."
./scripts/create_artifacts.sh "$SPARKLE_APP_LOCATION" $OUTPUT_DIRECTORY

# The output paths of the DMG and Tar from create artifacts
SPARKLE_DMG_LOCATION="$OUTPUT_DIRECTORY/minna.dmg"
SPARKLE_TAR_LOCATION="$OUTPUT_DIRECTORY/minna.tar.xz"

# Submit the dmg to apple for notarization.
printf "%s\n" "Submitting sparkle app dmg to Apple Notary."
xcrun notarytool submit "$SPARKLE_DMG_LOCATION" --keychain-profile "Impel-Intelligence" --wait

# Staple the notarization ticket to the dmg.
printf "%s\n" "Stapling notarization ticket to sparkle app dmg."
xcrun stapler staple "$SPARKLE_DMG_LOCATION"

### Upload to GitHub Release ###
gh release create "v$APP_VERSION" "$SPARKLE_DMG_LOCATION" "$SPARKLE_TAR_LOCATION" --title "$APP_VERSION - $VERSION_TITLE" --notes "$VERSION_NOTES"

### Upload To Sparkle ###
UPDATER_GIT_REPO=impel-intelligence/minna-sparkle-updater

UPDATER_LOCATION="$TEMPORARY_DIRECTORY/updater"
UPDATER_RELEASE_DIR="$UPDATER_LOCATION/public"
UPDATER_DMG_DIR="$UPDATER_RELEASE_DIR/dmg"

if [ ! -d "$UPDATER_LOCATION" ]; then
    git clone --depth 1 "https://github.com/$UPDATER_GIT_REPO" $UPDATER_LOCATION
else
    cd $UPDATER_LOCATION
    git fetch --all
    git reset --hard HEAD
    cd $BASE
fi

mkdir -p "$UPDATER_RELEASE_DIR"
mkdir -p "$UPDATER_DMG_DIR"

UPDATER_NOTES_PATH="${UPDATER_RELEASE_DIR}/minna_${APP_VERSION}.md"
printf "## %s - %s\n\n%s\n" "$APP_VERSION" "$VERSION_TITLE" "$VERSION_NOTES" > $UPDATER_NOTES_PATH

printf "%s\n" "Copying DMG"
cp "$SPARKLE_DMG_LOCATION" "$UPDATER_DMG_DIR/minna_$APP_VERSION.dmg"

printf "%s\n" "Copying Tarball"
cp "$SPARKLE_TAR_LOCATION" "$UPDATER_RELEASE_DIR/minna_$APP_VERSION.tar.xz"

printf "%s\n" "Generating Appcast"
"${UPDATER_LOCATION}/bin/generate_appcast" $UPDATER_RELEASE_DIR --embed-release-notes

printf "%s\n" "Commiting changes to the updater repository."

# Change directory into the updater, commit, tag then push.
cd $UPDATER_LOCATION
git add .
git commit -m "v$APP_VERSION"
git tag -a "v$APP_VERSION" -m "Version $APP_VERSION"
git push
git push origin "v$APP_VERSION"
cd $BASE

# Watch the GitHub deploy action run.
gh run watch --repo $UPDATER_GIT_REPO $(gh run list --limit 1 --json databaseId --jq '.[0].databaseId' --repo $UPDATER_GIT_REPO)

### Completion ###
rm -rf "$OUTPUT_DIRECTORY"
rm -rf "$TEMPORARY_DIRECTORY"
rm -f "$PROGRESS_FILE"

DMG_DOWNLOAD_URL=$(gh release view --json assets --jq '(.assets.[] | select(.name == "minna.dmg")).url')
TAR_DOWNLOAD_URL=$(gh release view --json assets --jq '(.assets.[] | select(.name == "minna.tar.xz")).url')

printf "%s\n" "Succesfully released $APP_VERSION."
printf "%s\n" "DMG: $DMG_DOWNLOAD_URL"
printf "%s\n" "TAR: $TAR_DOWNLOAD_URL"
