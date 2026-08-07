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
# directory, which is enough to make `swift run ModelBench` work.
#
# Kept to plain ASCII on purpose: under a UTF-8 locale bash folds a multibyte character that
# directly follows a variable into the variable name, so "$BUNDLE_NAME..." with a real ellipsis
# aborts under `set -u` with an unbound variable error.
#
# Created by Claude Opus 5 (Anthropic) on 2026-08-06.
# Edited by Claude Opus 5 (Anthropic) on 2026-08-07: removed non-ASCII, braced expansions.

set -euo pipefail

BUNDLE_NAME="mlx-swift_Cmlx.bundle"
PACKAGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIGURATION="${1:-debug}"

BUILD_DIR="$(swift build --package-path "${PACKAGE_DIR}" --configuration "${CONFIGURATION}" --show-bin-path)"

if [ -d "${BUILD_DIR}/${BUNDLE_NAME}" ]; then
    echo "OK: ${BUNDLE_NAME} already installed in ${BUILD_DIR}"
    exit 0
fi

echo "Searching DerivedData for ${BUNDLE_NAME} ..."

SOURCE_BUNDLE="$(
    find "${HOME}/Library/Developer/Xcode/DerivedData" \
        -type d -name "${BUNDLE_NAME}" \
        -path "*/Build/Products/*" \
        2>/dev/null \
    | head -1
)"

if [ -z "${SOURCE_BUNDLE}" ]; then
    cat >&2 <<'EOF'
error: could not find a prebuilt mlx-swift_Cmlx.bundle.

MLX's Metal kernels are compiled by Xcode, not by SwiftPM. Build the Minna app in Xcode once
(Cmd-B is enough - it does not need to run), then re-run this script.
EOF
    exit 1
fi

echo "  found ${SOURCE_BUNDLE}"
cp -R "${SOURCE_BUNDLE}" "${BUILD_DIR}/"
echo "OK: installed into ${BUILD_DIR}"
