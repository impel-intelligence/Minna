#!/bin/sh
# Edited by Claude Sonnet 5 (Anthropic) on 2026-07-10
# Extracts a specific version from CHANGELOG.md

VERSION=$1

START=$(command grep -n "^## \[v\?$VERSION\]" CHANGELOG.md | head -1 | cut -d: -f1)

if [ -z "$START" ]; then
  echo "NOT FOUND: $pattern"
  exit 1
fi

END=$(command grep -n "^## \[" CHANGELOG.md | awk -F: -v s="$START" '$1 > s {print $1; exit}')

# Grab the header line and pull out its title (text between the version and the date)
HEADER=$(sed -n "${START}p" CHANGELOG.md)
TITLE=$(printf '%s' "$HEADER" | sed -E 's/^## \[[^]]+\] - (.*) - [0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]]*$/\1/')

# Remove the header
START=$((START + 1))
# Remove the next section's header, or if there isn't one, go to the end of the file
if [ -z "$END" ]; then
  END=$(wc -l < CHANGELOG.md)
else
  END=$((END - 1))
fi

# Grab the actual notes
NOTES=$(sed -n "${START},${END}p" CHANGELOG.md)

# Remove whitespace surronding the output
TRIMMED=$(printf '%s' "$NOTES" | sed '/./,$!d' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

# Only prepend the title if the header actually matched the "title" format
if [ "$TITLE" != "$HEADER" ] && [ -n "$TITLE" ]; then
  printf '%s\n\n%s\n' "$TITLE" "$TRIMMED"
else
  printf '%s\n' "$TRIMMED"
fi
