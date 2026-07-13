#!/bin/sh
# A script to run the whole release pipeline for self-distributed Minna :)
# This script should be run on a development computer, it will not support CI/CD.
set -eu
set -o pipefail

TEMPORARY_DIRECTORY=tmp
OUTPUT_DIRECTORY="out"
BASE=$(PWD)
NOTARY_PROFILE="Impel-Intelligence"
PROGRESS_FILE="$TEMPORARY_DIRECTORY/progress.txt"


# Notarytool only exits with a failing code if the transport steps fail.
# It will always succeed after that, even if the notarization is valid.
# Check here to see if it was accepted, if not print the logs.
check_notarization_result() {
    RESULT_OUTPUT="$1"

    if ! (echo $RESULT_OUTPUT | grep -Eo 'status: Accepted'); then
        echo "🙅‍♀️ Failed to notarize!"
        RESULT_ID=$(echo "$RESULT_OUTPUT" | grep -m 1 'id: ' | awk '{print $2}')
        xcrun notarytool log "$RESULT_ID" --keychain-profile "$NOTARY_PROFILE"
        exit 1
    fi
}

### Pre-flight Checks ###
if [ ! -d "Minna.xcodeproj" ]; then
    printf "🙅‍♀️ This script must be run from the root directory of the project: './scripts/release.sh'!"
    exit 1
fi

# Check to make sure we are on a clean branch.
GIT_STATUS=$(git status --porcelain)

if [ -n "$GIT_STATUS" ]; then
    printf "🙅‍♀️ The git working directory is not clean! You must run this script on a clean working copy of main.\n"
    exit 1
fi

# Check to make sure we are on the main branch.
GIT_BRANCH=$(git branch --show-current)

if [ "$GIT_BRANCH" != "main" ]; then
    printf "🙅‍♀️ The git branch should be main!\n"
    exit 1
fi

# Check to make sure the user has setup notarytool
if ! xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" > /dev/null 2>&1; then
    printf "🙅‍♀️ You have not setup notarytool to use the %s credentials.\n" $NOTARY_PROFILE
    printf "👩‍💻 Run: 'xcrun notarytool store-credentials %s'\n" $NOTARY_PROFILE
    exit 1
fi

# Check to make sure the projec tag is correct.
SEM_VER_REGEX="(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?"
APP_VERSION=$(grep -oE -m 1 "MARKETING_VERSION = $SEM_VER_REGEX" Minna.xcodeproj/project.pbxproj | sed 's/.*MARKETING_VERSION = \([0-9.]*\).*/\1/')

printf "%s\n" "Does $APP_VERSION look like the correct version?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) break;;
        No ) printf "🙅‍♀️ Update the version of Minna in the Xcode project and commit!\n"; exit 1;;
    esac
done

# Grab the release title and notes from CHANGELOG.md instead of asking for them manually.
CHANGELOG_OUTPUT=$(./scripts/extract_changelog.sh "$APP_VERSION")
VERSION_TITLE=$(printf '%s\n' "$CHANGELOG_OUTPUT" | sed -n '1p')
VERSION_NOTES=$(printf '%s\n' "$CHANGELOG_OUTPUT" | sed '1,2d')

if [ -z "$VERSION_NOTES" ]; then
    printf "🙅‍♀️ There are no version notes for this version! Add notes in CHANGELOG.md.\n"
    exit 1
fi

printf "%s\n" "Is \"$VERSION_TITLE\" the correct title for this release?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) break;;
        No ) printf "🙅‍♀️ Update the title for this version in CHANGELOG.md and commit!\n"; exit 1;;
    esac
done

XCODE_BUILD_VERSION=$(xcrun agvtool what-version -terse)

if [ "$XCODE_BUILD_VERSION" != "$APP_VERSION" ]; then
    printf "🙅‍♀️ The build version does not match the App Version! This can lead to problems with sparkle not recognizing versions as different from each other.\n"
    exit 1
fi

# Check to see if the Sparkle Framework is the newest verison
SPARKLE_GITHUB=sparkle-project/Sparkle
SPARKLE_LOCATION=$(PWD)/Frameworks/Sparkle.framework
SPARKLE_INFO_PLIST="$SPARKLE_LOCATION/Resources/Info.plist"
SPARKLE_VERSION=$(plutil -extract CFBundleShortVersionString raw $SPARKLE_INFO_PLIST)

LATEST_SPARKLE=$(gh release view --repo "$SPARKLE_GITHUB" --json tagName --jq .tagName)

if [ "$SPARKLE_VERSION" != "$LATEST_SPARKLE" ]; then
    printf "🙅‍♀️ Sparkle is not up to date. Please update it before publishing a new app version.\n"
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
touch "$PROGRESS_FILE"

### Tag Creation ###
TAG_EXIST=$(git tag -l "v$APP_VERSION")
if [ -z "$TAG_EXIST" ]; then
    printf "%s\n" "✅ Created Git Tag for v$APP_VERSION"
    git tag -s "v$APP_VERSION" -m "$VERSION_NOTES"
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
    xcodebuild archive -project Minna.xcodeproj -scheme "Minna" -configuration "Release" -archivePath "$APP_STORE_ARCHIVE"  -derivedDataPath "$APP_STORE_BUILD_DIR" -clonedSourcePackagesDirPath "$SPM_BUILD_DIRECTORY" | xcbeautify

    # Save the build progress
    echo "$ARCHIVE_APP_STORE_PROGRESS_MARKER" >> "$PROGRESS_FILE"
    printf "✅ Finished app store archive!"
else
    printf "⏩ Not archiving for app store because the progress file states it has already been done.\n"
fi

# Archive the Direct Distribution configuration of Minna.
ARCHIVE_SPARKLE_PROGRESS_MARKER="archive-sparkle"
if ! grep -qF "$ARCHIVE_SPARKLE_PROGRESS_MARKER" $PROGRESS_FILE; then
    xcodebuild archive -project Minna.xcodeproj -scheme "Minna" -configuration "Release Sparkle" -archivePath "$SPARKLE_ARCHIVE" -derivedDataPath "$SPARKLE_BUILD_DIR" -clonedSourcePackagesDirPath "$SPM_BUILD_DIRECTORY" | xcbeautify

    # Save the build progress
    echo "$ARCHIVE_SPARKLE_PROGRESS_MARKER" >> "$PROGRESS_FILE"
    printf "✅ Finished direct distribution archive!\n"
else
    printf "⏩ Not archiving for direct distribution because the progress file states it has already been done.\n"
fi

# Export Archives
APP_STORE_APP_EXPORT_DIRECTORY="$OUTPUT_DIRECTORY/app-store"
SPARKLE_APP_EXPORT_DIRECTORY="$OUTPUT_DIRECTORY/sparkle"

# Upload the App Store archive to App Store Connect
APP_STORE_UPLOAD_PROGRESS_MARKER="app-store-upload"
if ! grep -qF "$APP_STORE_UPLOAD_PROGRESS_MARKER" $PROGRESS_FILE; then
    xcodebuild -exportArchive -archivePath "$APP_STORE_ARCHIVE" -exportOptionsPlist "$APP_STORE_EXPORT_OPTIONS"  | xcbeautify

    # Save the build progress
    echo "$APP_STORE_UPLOAD_PROGRESS_MARKER" >> "$PROGRESS_FILE"
    printf "✅ Finished app store upload!\n"
else
    printf "⏩ Not uploading to app store because the progress file states it has already been done.\n"
fi

# Export Direct Distribution Copy
SPARKLE_EXPORT_PROGRESS_MARKER="sparkle-export"
if ! grep -qF "$SPARKLE_EXPORT_PROGRESS_MARKER" $PROGRESS_FILE; then
    printf "⚙️ Exporting archive for direct distribution"
    xcodebuild -exportArchive -archivePath "$SPARKLE_ARCHIVE" -exportOptionsPlist "$SPARKLE_EXPORT_OPTIONS" -exportPath "$SPARKLE_APP_EXPORT_DIRECTORY" | xcbeautify

    # Save the build progress
    echo "$SPARKLE_EXPORT_PROGRESS_MARKER" >> "$PROGRESS_FILE"
    printf "✅ Finished direct distribution .app export!\n"
else
    printf "⏩ Not exporting direct distribution copy because the progress file states it has already been done.\n"
fi

# We need to wrap the app in a .zip for notary tool. We use ditto to preserve the symlinks and metadata.
SPARKLE_APP_NOTARY_ZIP_LOCATION="$SPARKLE_APP_EXPORT_DIRECTORY/Minna.zip"
SPARKLE_APP_LOCATION="$SPARKLE_APP_EXPORT_DIRECTORY/Minna.app"

# Submit the app to Apple for Notarization.
NOTARIZE_APP_SUBMIT_PROGRESS_MARKER="notarize-app-submit"
if ! grep -qF "$NOTARIZE_APP_SUBMIT_PROGRESS_MARKER" $PROGRESS_FILE; then
    printf "⚙️ Copying direct distribution app to a zip for notarization.\n"
    ditto -c -k --keepParent "$SPARKLE_APP_LOCATION" "$SPARKLE_APP_NOTARY_ZIP_LOCATION"
    printf "✅ Copied app for notarization!\n"

    printf "⚙️ Submitting direct distribution app Apple Notary.\n"
    # Capture the notary tool results so we can analyze it for a failure. Pipe to stderr since piping to stdout will duplicate the captured text.
    NOTARIZE_APP_RESULT=$(xcrun notarytool submit "$SPARKLE_APP_NOTARY_ZIP_LOCATION" --keychain-profile "$NOTARY_PROFILE" --wait | tee /dev/stderr)
    check_notarization_result "$NOTARIZE_APP_RESULT"

    # Save the notarization progress
    echo "$NOTARIZE_APP_SUBMIT_PROGRESS_MARKER" >> "$PROGRESS_FILE"
    printf "✅ Finished notarizing direct distribution app!"
else
    printf "⏩ Not submitting sparkle app for notarization because the progress file states it has already been done.\n"
fi

# Staple the notarization ticket to the app.
NOTARIZE_APP_STAPLE_PROGRESS_MARKER="notarize-app-staple"
if ! grep -qF "$NOTARIZE_APP_STAPLE_PROGRESS_MARKER" $PROGRESS_FILE; then
    printf "⚙️ Stapling notarization ticket to sparkle app.\n"
    xcrun stapler staple "$SPARKLE_APP_LOCATION"

    # Save the notarization progress
    echo "$NOTARIZE_APP_STAPLE_PROGRESS_MARKER" >> "$PROGRESS_FILE"
    printf "✅ Finished app store upload!\n"
else
    printf "⏩ Not stapling sparkle app because the progress file states it has already been done.\n"
fi

### Create Direct Distribution Artifacts ###
# The output paths of the DMG and Tar from create artifacts
SPARKLE_DMG_LOCATION="$OUTPUT_DIRECTORY/minna.dmg"
SPARKLE_TAR_LOCATION="$OUTPUT_DIRECTORY/minna.tar.xz"

CREATE_ARTIFACTS_PROGRESS_MARKER="create-artifacts"
if ! grep -qF "$CREATE_ARTIFACTS_PROGRESS_MARKER" $PROGRESS_FILE; then
    printf "⚙️ Creating Distribution Artifacts.\n"
    ./scripts/create_artifacts.sh "$SPARKLE_APP_LOCATION" $OUTPUT_DIRECTORY

    # Save the artifact creation progress
    echo "$CREATE_ARTIFACTS_PROGRESS_MARKER" >> "$PROGRESS_FILE"
    printf "✅ Created direct distribution artifacts!\n"
else
    printf "⏩ Not creating direct distribution artifacts because the progress file states it has already been done.\n"
fi

# Submit the dmg to apple for notarization.
NOTARIZE_DMG_SUBMIT_PROGRESS_MARKER="notarize-dmg-submit"
if ! grep -qF "$NOTARIZE_DMG_SUBMIT_PROGRESS_MARKER" $PROGRESS_FILE; then
    printf "⚙️ Submitting direct distribution dmg to Apple Notary.\n"
    # Capture the notary tool results so we can analyze it for a failure. Pipe to stderr since piping to stdout will duplicate the captured text.
    NOTARIZE_DMG_RESULT=$(xcrun notarytool submit "$SPARKLE_DMG_LOCATION" --keychain-profile "$NOTARY_PROFILE" --wait | tee /dev/stderr)
    check_notarization_result "$NOTARIZE_DMG_RESULT"

    # Save the dmg notarization progress
    echo "$NOTARIZE_DMG_SUBMIT_PROGRESS_MARKER" >> "$PROGRESS_FILE"
    printf "✅ Finished notarizing direct distribution dmg!\n"
else
    printf "⏩ Not submitting direct distribution dmg for notarization because the progress file states it has already been done.\n"
fi

# Staple the notarization ticket to the dmg.
NOTARIZE_DMG_STAPLE_PROGRESS_MARKER="notarize-dmg-staple"
if ! grep -qF "$NOTARIZE_DMG_STAPLE_PROGRESS_MARKER" $PROGRESS_FILE; then
    printf "⚙️ Stapling notarization ticket to direct distrubtion dmg.\n"
    xcrun stapler staple "$SPARKLE_DMG_LOCATION"

    # Save the dmg stapling progress
    echo "$NOTARIZE_DMG_STAPLE_PROGRESS_MARKER" >> "$PROGRESS_FILE"
    printf "✅ Finished stapling notarization ticket to direct distribution dmg!\n"
else
    printf "⏩ Not stapling sparkle app dmg because the progress file states it has already been done.\n"
fi

### Upload to GitHub Release ###
GITHUB_RELEASE_PROGRESS_MARKER="github-release"
if ! grep -qF "$GITHUB_RELEASE_PROGRESS_MARKER" $PROGRESS_FILE; then
    printf "⚙️ Creating a new release for v%s on GitHub.\n" "$APP_VERSION"
    git push origin "v$APP_VERSION"
    gh release create "v$APP_VERSION" "$SPARKLE_DMG_LOCATION" "$SPARKLE_TAR_LOCATION" --title "$APP_VERSION - $VERSION_TITLE" --notes "$VERSION_NOTES"

    # Save the github release progress
    echo "$GITHUB_RELEASE_PROGRESS_MARKER" >> "$PROGRESS_FILE"
    printf "✅ Finished creating GithHub release for v%s!\n" "$APP_VERSION"
else
    printf "⏩ Not creating GitHub release because the progress file states it has already been done.\n"
fi

### Upload To Sparkle ###
UPDATER_GIT_REPO=impel-intelligence/minna-sparkle-updater

UPDATER_LOCATION="$TEMPORARY_DIRECTORY/updater"
UPDATER_RELEASE_DIR="$UPDATER_LOCATION/public"
UPDATER_DMG_DIR="$UPDATER_RELEASE_DIR/dmg"

if [ ! -d "$UPDATER_LOCATION" ]; then
    printf "⚙️ Cloning sparkle updater repository.\n"
    git clone --depth 1 "https://github.com/$UPDATER_GIT_REPO" $UPDATER_LOCATION
    printf "✅ Cloned sparkle updater repository!\n"
else
    printf "⚙️ Updating existing sparkle updater repository.\n"
    cd $UPDATER_LOCATION
    git fetch --all
    git reset --hard HEAD
    cd $BASE
    printf "✅ Finished updating sparkle updater repository.\n"
fi

mkdir -p "$UPDATER_RELEASE_DIR"
mkdir -p "$UPDATER_DMG_DIR"

UPDATER_NOTES_PATH="${UPDATER_RELEASE_DIR}/minna_${APP_VERSION}.md"
printf "## %s - %s\n\n%s\n" "$APP_VERSION" "$VERSION_TITLE" "$VERSION_NOTES" > $UPDATER_NOTES_PATH

printf "⚙️ Copying DMG\n"
cp "$SPARKLE_DMG_LOCATION" "$UPDATER_DMG_DIR/minna_$APP_VERSION.dmg"
printf "✅ Finished copying DMG.\n"

printf "⚙️ Copying Tarball\n"
cp "$SPARKLE_TAR_LOCATION" "$UPDATER_RELEASE_DIR/minna_$APP_VERSION.tar.xz"
printf "✅ Finished copying Tarball.\n"

printf "⚙️ Generating Appcast\n"
"${UPDATER_LOCATION}/bin/generate_appcast" $UPDATER_RELEASE_DIR --embed-release-notes
printf "✅ Finished generating appcast!\n"

UPDATER_PUSH_PROGRESS_MARKER="updater-push"
if ! grep -qF "$UPDATER_PUSH_PROGRESS_MARKER" $PROGRESS_FILE; then
    printf "⚙️ Commiting changes to the updater repository.\n"

    # Change directory into the updater, commit, tag then push.
    cd $UPDATER_LOCATION
    git add .
    git commit -m "v$APP_VERSION"
    git tag  -s "v$APP_VERSION" -m "Version $APP_VERSION"
    git push
    git push origin "v$APP_VERSION"
    cd $BASE

    # Save the build progress
    echo "$UPDATER_PUSH_PROGRESS_MARKER" >> "$PROGRESS_FILE"
    printf "✅ Succesfully commited changes to updater repo and created tag.\n"
else
    printf "⏩ Not committing to the updater repository because the progress file states it has already been done.\n"
fi

# Watch the GitHub deploy action run.
printf "⚙️ Waiting for update to become public.\n"
gh run watch --repo $UPDATER_GIT_REPO $(gh run list --limit 1 --json databaseId --jq '.[0].databaseId' --repo $UPDATER_GIT_REPO)
printf "✅ Update is public!.\n"

### Completion ###
rm -rf "$OUTPUT_DIRECTORY"
rm -rf "$TEMPORARY_DIRECTORY"
rm -f "$PROGRESS_FILE"

DMG_DOWNLOAD_URL=$(gh release view --json assets --jq '(.assets.[] | select(.name == "minna.dmg")).url')
TAR_DOWNLOAD_URL=$(gh release view --json assets --jq '(.assets.[] | select(.name == "minna.tar.xz")).url')

printf "✅ Succesfully released %s!\n" "$APP_VERSION"
printf "   - DMG: %s.\n" "$DMG_DOWNLOAD_URL"
printf "   - TAR: %s.\n" "$TAR_DOWNLOAD_URL"
