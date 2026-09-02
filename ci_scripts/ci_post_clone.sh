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


# Write an XCConfig with variables from Xcode clouds' environment
cp "../Config.local.example.xcconfig" "../Config.local.xcconfig"

sed -i '' -E "s/^DEVELOPMENT_TEAM[[:space:]]*=.*/DEVELOPMENT_TEAM = ${DEVELOPMENT_TEAM:-}/" ../Config.local.xcconfig
sed -i '' -E "s/^SENTRY_DSN[[:space:]]*=.*/SENTRY_DSN = ${SENTRY_DSN:-}/" ../Config.local.xcconfig
sed -i '' -E "s/^TELEMETRY_DECK_ID[[:space:]]*=.*/TELEMETRY_DECK_ID = ${TELEMETRY_DECK_ID:-}/" ../Config.local.xcconfig
