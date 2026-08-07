#!/bin/bash
# Downloads every model in the benchmark slate into Minna's shared model storage.
#
# Sizes are the sum of the .safetensors/.json/.jinja blobs the downloader actually fetches,
# read from the Hugging Face API on 2026-08-07. Every repo id below was verified to exist.
#
# Already-present models are skipped, so this is safe to re-run after an interruption.
#
# Usage:
#   ./scripts/fetch-benchmark-models.sh            # the 12-model slate, 56.1 GB
#   ./scripts/fetch-benchmark-models.sh --with-ornith   # adds Ornith-1.0-9B-4bit, 62.1 GB
#
# Kept to plain ASCII: under a UTF-8 locale bash folds a multibyte character that directly
# follows a variable into the variable name.
#
# Created by Claude Opus 5 (Anthropic) on 2026-08-07.

set -euo pipefail

PACKAGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# repo id : download size in GB
MODELS=(
    "mlx-community/Nanbeige4.1-3B-8bit:4.20"                # current baseline
    "mlx-community/granite-4.1-3b-4bit:2.13"
    "mlx-community/Qwen3-4B-Instruct-2507-4bit:2.28"
    "mlx-community/LFM2.5-2.6B-8bit:2.88"
    "mlx-community/AREX-Turbo-4bit:3.06"
    "mlx-community/Qwen3.5-4B-MLX-4bit:3.06"
    "mlx-community/granite-4.1-8b-mxfp4:4.46"
    "mlx-community/gemma-4-e4b-it-4bit:5.18"
    "mlx-community/Ministral-3-8B-Instruct-2512-4bit:5.63"
    "mlx-community/Qwen3.5-9B-MLX-4bit:5.98"
    "mlx-community/Qwen3.5-9B-OptiQ-4bit:8.22"
    "mlx-community/gemma-4-12B-it-OptiQ-4bit:9.00"
)

if [ "${1:-}" = "--with-ornith" ]; then
    MODELS+=("mlx-community/Ornith-1.0-9B-4bit:5.98")
fi

REQUIRED_GB=0
for entry in "${MODELS[@]}"; do
    REQUIRED_GB="$(echo "${REQUIRED_GB} + ${entry##*:}" | bc)"
done

STORAGE="${HOME}/Library/Group Containers/group.com.tryminna/Library/Caches/Models"
AVAILABLE_GB="$(df -g /System/Volumes/Data | awk 'NR==2 {print $4}')"

echo "Models to fetch: ${#MODELS[@]}"
echo "Download size:   ${REQUIRED_GB} GB"
echo "Free space:      ${AVAILABLE_GB} GB"
echo "Destination:     ${STORAGE}"
echo

# Leave headroom: macOS misbehaves when the boot volume runs to zero, and the benchmark
# itself needs room for temp files.
NEEDED="$(echo "${REQUIRED_GB} + 15" | bc)"
if [ "$(echo "${AVAILABLE_GB} < ${NEEDED}" | bc)" -eq 1 ]; then
    echo "warning: less than ${NEEDED} GB free (download + 15 GB headroom)." >&2
    echo "Free some space, or fetch a subset with: swift run ModelBench fetch <repo-id> ..." >&2
    echo >&2
    read -r -p "Continue anyway? [y/N] " reply
    case "${reply}" in
        [yY]*) ;;
        *) echo "Aborted."; exit 1 ;;
    esac
fi

echo "Building ModelBench..."
swift build --package-path "${PACKAGE_DIR}" --configuration release
BINARY="$(swift build --package-path "${PACKAGE_DIR}" --configuration release --show-bin-path)/ModelBench"

# Downloading does not touch MLX, but the benchmark that follows does, and the metallib has to
# sit beside whichever binary loads it. Install it now so `run` does not fail hours later.
"${PACKAGE_DIR}/scripts/prepare-metal.sh" release || \
    echo 'warning: metallib not installed; downloads will still work but the benchmark will not' >&2

# Smallest first, so an interrupted run still leaves the most models usable.
FAILED=()
for entry in "${MODELS[@]}"; do
    repo="${entry%:*}"
    if ! "${BINARY}" fetch "${repo}"; then
        echo "warning: ${repo} failed, continuing" >&2
        FAILED+=("${repo}")
    fi
done

echo
echo "Done. Models on disk:"
"${BINARY}" list

if [ "${#FAILED[@]}" -gt 0 ]; then
    echo
    echo "Failed (${#FAILED[@]}):" >&2
    for repo in "${FAILED[@]}"; do
        echo "  ${repo}" >&2
    done
    exit 1
fi
