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
# It installs into every configuration by default. The bundle has to sit beside the binary that
# loads it, and debug and release have separate build directories, so installing into only one
# leaves the other failing at runtime with the error above.
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
# Edited by Claude Opus 5 (Anthropic) on 2026-08-07: install into every configuration, because
#   installing into debug alone left the release binary failing.

set -euo pipefail

BUNDLE_NAME="mlx-swift_Cmlx.bundle"
PACKAGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ "$#" -gt 0 ]; then
    CONFIGURATIONS=("$@")
else
    CONFIGURATIONS=(debug release)
fi

# Find the bundle once; it is the same for every configuration.
SOURCE_BUNDLE="$(
    find "${HOME}/Library/Developer/Xcode/DerivedData" \
        -type d -name "${BUNDLE_NAME}" \
        -path "*/Build/Products/*" \
        2>/dev/null \
    | head -1
)"

if [ -z "${SOURCE_BUNDLE}" ]; then
    cat >&2 <<'EOF'
error: could not find a prebuilt mlx-swift_Cmlx.bundle in DerivedData.

MLX's Metal kernels are compiled by Xcode, not by SwiftPM, so this script copies the bundle
Xcode produces. Open Minna.xcodeproj and build once (Cmd-B is enough - it does not need to
run), then re-run this script.

If this machine has no Xcode, build the bundle on a machine that does and copy it over:

    scp -r '<other-mac>:~/Library/Developer/Xcode/DerivedData/Minna-*/Build/Products/Debug/mlx-swift_Cmlx.bundle' .
    ./scripts/prepare-metal.sh   # after placing it in DerivedData, or copy it into .build by hand
EOF
    exit 1
fi

echo "Found ${SOURCE_BUNDLE}"

INSTALLED=0
for configuration in "${CONFIGURATIONS[@]}"; do
    # --show-bin-path does not build; it just reports where the binary would go.
    if ! BUILD_DIR="$(swift build --package-path "${PACKAGE_DIR}" --configuration "${configuration}" --show-bin-path 2>/dev/null)"; then
        echo "  skipping ${configuration}: could not resolve its build path" >&2
        continue
    fi

    if [ ! -d "${BUILD_DIR}" ]; then
        echo "  skipping ${configuration}: ${BUILD_DIR} does not exist yet (build it first)"
        continue
    fi

    if [ -d "${BUILD_DIR}/${BUNDLE_NAME}" ]; then
        echo "  ${configuration}: already installed"
        INSTALLED=$((INSTALLED + 1))
        continue
    fi

    cp -R "${SOURCE_BUNDLE}" "${BUILD_DIR}/"
    echo "  ${configuration}: installed into ${BUILD_DIR}"
    INSTALLED=$((INSTALLED + 1))
done

if [ "${INSTALLED}" -eq 0 ]; then
    echo >&2
    echo "error: nothing installed. Build ModelBench first, then re-run:" >&2
    echo "    swift build --package-path '${PACKAGE_DIR}'" >&2
    exit 1
fi

echo "OK: ${BUNDLE_NAME} present in ${INSTALLED} configuration(s)"
