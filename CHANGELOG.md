# Changelog
All notable changes to Minna will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [v0.8.0] - Document Locations for Citations - 2026-07-13
### Added
- Citations now report their original position in the document. This allows you to see where in a document information actually came from.

### Fixed
- Added support for resumable releases in the event of a crash or cancelation.

## [v0.7.2] - Split Builds - 2026-07-10

### Added

- Split builds between Mac App Store and Sparkle

## [0.7.1] - Model Chatting - 2026-07-09

### Added

- Basics for URL handling
- Sub folders now show in Folder View

### Fixed

- Fatal error caused by bad FAISS memory access

## [0.7.0] - Model Chatting - 2026-07-09

### Added

- Ask Minna chatting
- App icon

## [0.6.1] - Build System - 2026-06-26

### Added

- Initial build system setup
- Working build GitHub Action
- Sparkle framework and release actions
- SwiftLint, Sentry SPM, and Swift 6 support
- Welcome to Minna
- Post-clone scripts for Xcode Cloud

[Unreleased]: https://github.com/impel-intelligence/Minna/compare/0.7.1...HEAD
[0.7.2]: https://github.com/impel-intelligence/Minna/compare/0.7.0...v0.7.2
[0.7.1]: https://github.com/impel-intelligence/Minna/compare/0.7.0...0.7.1
[0.7.0]: https://github.com/impel-intelligence/Minna/compare/0.6.1...0.7.0
[0.6.1]: https://github.com/impel-intelligence/Minna/releases/tag/0.6.1
