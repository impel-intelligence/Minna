#!/bin/zsh
set -e # Fail if any failures are returned

REPO_ROOT=$PWD
VERSION=$1
NOTES=$2
UPDATER_DIR=iris-sparkle-updater

echo "Resetting release server ($UPDATER_DIR)"
cd "$UPDATER_DIR"
git fetch --all
git reset --hard HEAD

# Create the release notes page if it does not already exist.
NOTES_PATH="public/iris_${VERSION}.html"
if [ ! -f "$NOTES_PATH" ]; then
    cp templates/update.html "$NOTES_PATH"
    printf "<p>\n%s</p>\n" "$NOTES" >> "$NOTES_PATH"
fi

echo "Publishing dmg"
cp "$REPO_ROOT/tmp/iris.dmg" "public/dmg/iris_${VERSION}.dmg"
ln -sf "iris_${VERSION}.dmg" "public/dmg/iris_current.dmg"

echo "Publishing tar"
cp "$REPO_ROOT/tmp/iris.tar.xz" "public/iris_${VERSION}.tar.xz"

echo "Creating appcast"
"$REPO_ROOT/scripts/generate_appcast" public

echo "Committing changes to updater repository"
git add .
git commit -m "$VERSION"
git tag -a "$VERSION" -m "Version $VERSION"
git push
git push origin "$VERSION"

cd "$REPO_ROOT"
