#!/bin/zsh

# Idea from: cgontijo @ https://stackoverflow.com/a/78572430
# We use build tool plugins & swift macros which both require plugin fingerprint validation. Xcode cloud is not able to approve these automatically. To get around this, we copy macros.json and plugins.json from the swiftpm security directory into this project. This should be done every time a new macro or plugin is added into the project.

# Create the swiftpm security directory.
mkdir -p ~/Library/org.swift.swiftpm/security/

# Trust the macros we have manually trusted.
cp macros.json ~/Library/org.swift.swiftpm/security/

# Copy the plugins we have manually trusted.
cp plugins.json ~/Library/org.swift.swiftpm/security/
