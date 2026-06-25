#!/bin/bash
# This patches a bug in GitHub runners that results in binary artifact downloads never compleing. The following GitHub issues track this.
#  - https://github.com/tuist/tuist/issues/9967
#  - https://github.com/actions/runner-images/issues/13175
#
# Credit: Claude Opus 4.8 & Taylor Lineman

set -uo pipefail
CACHE="$HOME/Library/Caches/org.swift.swiftpm/artifacts"
mkdir -p "$CACHE"


# Let SPM clone all source packages, and resolve the binary download links. When this process outputs "Downloading binary artifact" kill the process.
swift package resolve --package-path Tuist > >(tee /tmp/spm.log) 2>&1 &
SPM_PID=$!
# Wait for the binary-download phase, then until the count of artifact URLs stops
# growing. SwiftPM prints them together when the phase starts, so a count that
# holds steady across two polls means we've captured them all - we observe that
# rather than guessing with a fixed sleep. We also stop early if the resolve
# exits on its own (e.g. everything was already cached).
prev=-1
stable=0
for _ in $(seq 1 150); do
  count=$(grep -c "Downloading binary artifact" /tmp/spm.log 2>/dev/null)
  count=${count:-0}
  if [ "$count" -gt 0 ] && [ "$count" -eq "$prev" ]; then
    stable=$((stable + 1))
    [ "$stable" -ge 2 ] && break
  else
    stable=0
  fi
  prev=$count
  # Liveliness probe: if resolve already finished, there's nothing left to wait for.
  kill -0 "$SPM_PID" 2>/dev/null || break
  sleep 1
done
echo "--- captured ${prev} binary artifact url(s); stopping first-pass resolve ---"
kill "$SPM_PID" 2>/dev/null || true # Kill the SPM process
wait "$SPM_PID" 2>/dev/null || true # Wait until the process actually dies.

# Collect every binary-artifact URL SwiftPM needs, from two sources, then curl
# each into SwiftPM's cache:
#  1. The "Downloading binary artifact <url>" lines SwiftPM logged - authoritative
#     and matches any filename (*.xcframework.zip, Sparkle's plain .zip, etc.).
#  2. Any binaryTarget .zip url in the resolved manifests - a timing-independent
#     safety net for artifacts SwiftPM hadn't printed before we stopped it.
# Drop URLs containing a backslash: some manifests build the url with Swift string
# interpolation (e.g. Sparkle's ".../\(tag)/..."), so the manifest grep yields a
# non-fetchable template - the real resolved url comes from the log instead.
{
  awk '/Downloading binary artifact/ {print $NF}' /tmp/spm.log
  grep -rhoE 'https://[^"]+\.zip' Tuist/.build/checkouts/*/Package.swift
} | grep -vF '\' | sort -u | while read -r url; do
    name="$(printf '%s' "$url" | sed 's/[^A-Za-z0-9]/_/g')"
    if [ -s "$CACHE/$name" ]; then
      echo "Already cached: $url"
      continue
    fi
    echo "Caching $url"
    curl -fSL --retry 5 --retry-all-errors -o "$CACHE/$name" "$url"
  done
