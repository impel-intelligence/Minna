#!/bin/zsh

set -euo pipefail

# Idea from: cgontijo @ https://stackoverflow.com/a/78572430
# We use build tool plugins & swift macros which both require plugin fingerprint validation. Xcode cloud is not able to approve these automatically. To get around this, we copy macros.json and plugins.json from the swiftpm security directory into this project. This should be done every time a new macro or plugin is added into the project.

# Create the swiftpm security directory.
mkdir -p ~/Library/org.swift.swiftpm/security/

# Trust the macros we have manually trusted.
cp macros.json ~/Library/org.swift.swiftpm/security/

# Copy the plugins we have manually trusted.
cp plugins.json ~/Library/org.swift.swiftpm/security/


# Write an XCConfig with variables from Xcode clouds' environment. We generate the file directly rather than sed-substituting into the example template: values like SENTRY_DSN contain slashes, which sed reads as its own delimiter (the DSN's trailing project ID then overflows the s///N occurrence flag on BSD sed).
# Edited by Claude Fable 5 (Anthropic) on 2026-09-09
cat > ../Config.local.xcconfig <<EOF
DEVELOPMENT_TEAM = ${DEVELOPMENT_TEAM:-}
SENTRY_DSN = ${SENTRY_DSN:-}
TELEMETRY_DECK_ID = ${TELEMETRY_DECK_ID:-}
EOF
