#!/bin/zsh
set -e # Fail if any failures are returned

REPO_ROOT=$PWD
SPARKLE_KEY=$1
VERSION=$2
NOTES=$3
UPDATER_DIR="minna-sparkle-updater"

RELEASE_DIR="public"
DMG_DIR="${RELEASE_DIR}/dmg"

echo "Resetting release server ($UPDATER_DIR)"
cd "$UPDATER_DIR"
git fetch --all
git reset --hard HEAD

mkdir -p $RELEASE_DIR
mkdir -p $DMG_DIR

# Create the release notes page if it does not already exist.
NOTES_PATH="${RELEASE_DIR}/minna_${VERSION}.html"
if [ ! -f "$NOTES_PATH" ]; then
    cp templates/update.html "$NOTES_PATH"
    printf "<p>\n%s\n</p>" "$NOTES" >> "$NOTES_PATH"
fi

echo $PWD

echo "Publishing dmg"
cp "$REPO_ROOT/tmp/minna.dmg" "${DMG_DIR}/minna_${VERSION}.dmg"
ln -sf "${DMG_DIR}/minna_${VERSION}.dmg" "minna_current.dmg"

echo "Publishing tar"
cp "${REPO_ROOT}/tmp/minna.tar.xz" "${RELEASE_DIR}/minna_${VERSION}.tar.xz"

# Create the private key file for sparkle
rm -f private_key_file
echo ${SPARKLE_KEY} >> private_key_file

echo "Loading Private Key"
set +e # It is okay if something here fails so just ignore it and keep going
"${REPO_ROOT}/${UPDATER_DIR}/bin/generate_keys" -f private_key_file
set -e # Re-enable errors

echo "Creating appcast"
"${REPO_ROOT}/${UPDATER_DIR}/bin/${APPCAST_TOOL_PATH}/generate_appcast" $RELEASE_DIR

echo "Committing changes to updater repository"
git add .
git commit -m "$VERSION"
git tag -a "$VERSION" -m "Version $VERSION"
git push
git push origin "$VERSION"
