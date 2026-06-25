#!/bin/zsh

// We use build tool plugins & swift macros which both require plugin fingerprint validation. For some reason the correct default is spelled incorrectly... so yes it is supposed to be "Validatation" not "Validation"
defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES
