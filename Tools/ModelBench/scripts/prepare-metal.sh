#!/bin/bash
# Installs MLX's Metal shader library next to the ModelBench binary.
#
# mlx-swift's SwiftPM manifest never compiles its .metal sources - only its Xcode project does
# (see the "PrepareMetalShaders" comment in mlx-swift/Package.swift). A binary produced by
# `swift build` therefore starts up and immediately fails with:
#
#     MLX error: Failed to load the default metallib. library not found
#
# This script copies the metallib Xcode already produced for Minna into the SwiftPM build
# directory, which is enough to make ModelBench work.
#
# Two traps this script exists to avoid:
#
#   1. Xcode's *indexing* build (DerivedData/.../Index.noindex/...) produces a bundle with the
#      right name and no default.metallib inside it. Copying that satisfies a directory check
#      and still fails at runtime with the error above, so every candidate is validated by
#      looking for a non-empty default.metallib rather than trusting its path.
#
#   2. The bundle has to sit beside the binary that loads it, and debug and release have
#      separate build directories, so both are installed by default.
#
# Kept to plain ASCII on purpose: under a UTF-8 locale bash folds a multibyte character that
# directly follows a variable into the variable name, so "$BUNDLE_NAME..." with a real ellipsis
# aborts under `set -u` with an unbound variable error.
#
# Usage:
#   ./scripts/prepare-metal.sh              # install into debug and release
#   ./scripts/prepare-metal.sh debug        # just one
#
# Created by Claude Opus 5 (Anthropic) on 2026-08-06.
# Edited by Claude Opus 5 (Anthropic) on 2026-08-07: validate the metallib, install into every
#   configuration, and replace an already-installed but empty bundle.

set -euo pipefail

BUNDLE_NAME="mlx-swift_Cmlx.bundle"
METALLIB_PATH="Contents/Resources/default.metallib"
PACKAGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ "$#" -gt 0 ]; then
    CONFIGURATIONS=("$@")
else
    CONFIGURATIONS=(debug release)
fi

# A bundle counts only if it actually carries compiled shaders.
is_valid_bundle() {
    [ -s "${1}/${METALLIB_PATH}" ]
}

SOURCE_BUNDLE=""
CANDIDATES=0

while IFS= read -r candidate; do
    [ -n "${candidate}" ] || continue
    CANDIDATES=$((CANDIDATES + 1))
    if is_valid_bundle "${candidate}"; then
        SOURCE_BUNDLE="${candidate}"
        break
    fi
done < <(
    find "${HOME}/Library/Developer/Xcode/DerivedData" \
        -type d -name "${BUNDLE_NAME}" \
        -path "*/Build/Products/*" \
        2>/dev/null
)

if [ -z "${SOURCE_BUNDLE}" ]; then
    if [ "${CANDIDATES}" -gt 0 ]; then
        cat >&2 <<EOF
error: found ${CANDIDATES} copy of ${BUNDLE_NAME} in DerivedData, but none contains a
compiled ${METALLIB_PATH}.

That is what Xcode's *indexing* build produces: opening the project is not enough. Open
Minna.xcodeproj and run an actual build (Cmd-B), wait for it to finish, then re-run this
script.
EOF
    else
        cat >&2 <<EOF
error: could not find ${BUNDLE_NAME} in DerivedData.

MLX's Metal kernels are compiled by Xcode, not by SwiftPM, so this script copies the bundle
Xcode produces. Open Minna.xcodeproj and build once (Cmd-B is enough - it does not need to
run), then re-run this script.

If this machine has no Xcode, copy a built bundle from one that does:

    scp -r '<other-mac>:~/Library/Developer/Xcode/DerivedData/Minna-*/Build/Products/Debug/${BUNDLE_NAME}' /tmp/
    cp -R /tmp/${BUNDLE_NAME} "\$(swift build --package-path '${PACKAGE_DIR}' --show-bin-path)/"
EOF
    fi
    exit 1
fi

echo "Found ${SOURCE_BUNDLE}"
echo "  metallib: $(stat -f%z "${SOURCE_BUNDLE}/${METALLIB_PATH}") bytes"

INSTALLED=0
for configuration in "${CONFIGURATIONS[@]}"; do
    # --show-bin-path does not build; it just reports where the binary would go.
    if ! BUILD_DIR="$(swift build --package-path "${PACKAGE_DIR}" --configuration "${configuration}" --show-bin-path 2>/dev/null)"; then
        echo "  skipping ${configuration}: could not resolve its build path" >&2
        continue
    fi

    if [ ! -d "${BUILD_DIR}" ]; then
        echo "  skipping ${configuration}: not built yet"
        continue
    fi

    TARGET="${BUILD_DIR}/${BUNDLE_NAME}"

    if [ -d "${TARGET}" ]; then
        if is_valid_bundle "${TARGET}"; then
            echo "  ${configuration}: already installed"
            INSTALLED=$((INSTALLED + 1))
            continue
        fi
        echo "  ${configuration}: replacing an installed bundle with no metallib"
        rm -rf "${TARGET}"
    fi

    cp -R "${SOURCE_BUNDLE}" "${BUILD_DIR}/"
    echo "  ${configuration}: installed"
    INSTALLED=$((INSTALLED + 1))
done

if [ "${INSTALLED}" -eq 0 ]; then
    echo >&2
    echo "error: nothing installed. Build ModelBench first, then re-run:" >&2
    echo "    swift build --package-path '${PACKAGE_DIR}'" >&2
    exit 1
fi

echo "OK: ${BUNDLE_NAME} present in ${INSTALLED} configuration(s)"
