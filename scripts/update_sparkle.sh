#!/bin/zsh
set -e # Fail if any failures are returned

REPO_ROOT=$PWD
SPARKLE_KEY=$1
VERSION=$2
NOTES=$3
UPDATER_DIR="iris-sparkle-updater"

RELEASE_DIR="public"
DMG_DIR="${RELEASE_DIR}/dmg"
APPCAST_TOOL_PATH="Tuist/.build/artifacts/sparkle/Sparkle/bin"

echo "Resetting release server ($UPDATER_DIR)"
cd "$UPDATER_DIR"
git fetch --all
git reset --hard HEAD

mkdir -p $RELEASE_DIR
mkdir -p $DMG_DIR

# Create the release notes page if it does not already exist.
NOTES_PATH="${RELEASE_DIR}/iris_${VERSION}.html"
if [ ! -f "$NOTES_PATH" ]; then
    cp templates/update.html "$NOTES_PATH"
    printf "<p>\n%s\n</p>" "$NOTES" >> "$NOTES_PATH"
fi

echo $PWD

echo "Publishing dmg"
cp "$REPO_ROOT/tmp/iris.dmg" "${DMG_DIR}/iris_${VERSION}.dmg"
ln -sf "${DMG_DIR}/iris_${VERSION}.dmg" "iris_current.dmg"

echo "Publishing tar"
cp "${REPO_ROOT}/tmp/iris.tar.xz" "${RELEASE_DIR}/iris_${VERSION}.tar.xz"

# Create the private key file for sparkle
echo ${SPARKLE_KEY} >> private_key_file

echo "Loading Private Key"
"${REPO_ROOT}/${APPCAST_TOOL_PATH}/generate_keys" -f private_key_file

echo "Creating appcast"
"${REPO_ROOT}/${APPCAST_TOOL_PATH}/generate_appcast" $RELEASE_DIR

echo "Committing changes to updater repository"
git add .
git commit -m "$VERSION"
git tag -a "$VERSION" -m "Version $VERSION"
git push
git push origin "$VERSION"

cd "$REPO_ROOT"
