#!/bin/sh
# This patches a bug in GitHub runners that results in binary artifact downloads never compleing. The following GitHub issues track this.
#  - https://github.com/tuist/tuist/issues/9967
#  - https://github.com/actions/runner-images/issues/13175
#
# Credit: Claude Opus 4.8 & Taylor Lineman

set -uo pipefail
CACHE="$HOME/Library/Caches/org.swift.swiftpm/artifacts"
mkdir -p "$CACHE"


# Let SPM clone all source packages, and resolve the binary download links. When this process outputs "Downloading binary artifact" kill the process.
swift package resolve --package-path Tuist >> (tee /tmp/spm.log) 2>&1 &
SPM_PID=$!
for _ in $(seq 1 120); do
  grep -q "Downloading binary artifact" /tmp/spm.log && break
  # Liveliness probe, check to see if the process is running.
  kill -0 "$SPM_PID" 2>/dev/null || break
  sleep 2
done
echo "--- reached binary-download phase, stopping first-pass resolve ---"
kill "$SPM_PID" 2>/dev/null || true # Kill the SPM process
wait "$SPM_PID" 2>/dev/null || true # Wait until the process actually dies.

# Fetch every binary artifact URL from the resolved checkouts with curl.
grep -rhoE 'https://[^"]+\.xcframework\.zip' Tuist/.build/checkouts/*/Package.swift \
  | sort -u | while read -r url; do
    name="$(printf '%s' "$url" | sed 's/[^A-Za-z0-9]/_/g')"
    if [ -s "$CACHE/$name" ]; then
      echo "Already cached: $url"
      continue
    fi
    echo "Caching $url"
    curl -fSL --retry 5 --retry-all-errors -o "$CACHE/$name" "$url"
  done
