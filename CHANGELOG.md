# Changelog
All notable changes to Minna will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
The format has been adjusted to include a release Title. This has been inserted between the [version] and date.

## [Unreleased]

## [0.14.1] - File Chat Fixes - 2026-08-21

### Added
- You can now reset file chats.

### Fixed
- The file chat is more reliable and will now always search.

## [0.14.0] - Drag and Drop - 2026-08-18

### Added
- Files can be drag and dropped into Minna.
  - Not all files are supported because of issues in macOS drag and drop behaviors.
- Minna is now licensed under the Apache License 2.0.

### Changed
- Crash reporting and analytics are now configured at build time and are turned off entirely in builds made from source, so a build you compile yourself reports nothing anywhere.

## [0.13.1] - Database Hardening - 2026-08-13

### Fixed
- The app will no longer crash if you have a malformed databse.

## [0.13.0] - Onboarding & Improvements - 2026-08-12

### Added
- Added an onboarding experience that will direct you through setting up Minna.
- Automatically install necessary on-device models.

### Fixed
- Fixed a bug where IrisSearch was not using the proper embed queries for BGE.

## [0.12.0] - Support for MLX & many bug fixes - 2026-08-07

### Added
- Added direct support for markdown with proper chunking.
- Added on-device models through MLX.
- Privacy Focused Analytics

### Fixed
- You can now open the dashboard from the menu bar.
- Fixed a bug where the search tool would return UUIDs in the wrong format, confusing on-device models.
- Hopefully fixed a bug where the Sparkle app would update in a sandbox.
- Fixed generating text jumping across the chat view.
- Fixed long load times for saved Minna Chats.
- Fixed a bug where chats would not match their file theme if you changed the file's theme.
- Logs are logged into `Console.app`

## [0.11.0] - Support for Ollama, OpenAI & Gemini - 2026-08-04

### Added
- Added support for OpenAI as a provider.
- Added support for local and remote Ollama servers as a provider.
- Added support for Gemini as a provider.

## [0.10.2] - Fix Upload Crash - 2026-07-27

### Added
- Search results are now shown before any LLM chat is entered.
- IrisDB has been upgrade with a better offline-embedding model. Search results are much more accurate now.
- On-device models can now download in the background.

### Fixed
- Fixed a bug where the app would crash when loading files because of an unknown Type Identifier.
- Fixed User Message text color in Dark Mode.
- Subfolders now use a more readable text color for their background.
- Citation sections now properly update in real-time.

## [0.10.1] - Fix Startup Crash - 2026-07-23

### Fixed
- Fixed a crash on app startup when the user did not have Apple Intelligence enabled.

## [0.10.0] - HTML & XML Support (The Building Blocks) - 2026-07-22

### Added
- You can now press enter to open a file you have selected.
- Markdown can now be viewed in the preview window
- HTML can now be viewed in the preview window
- HTML documents are now supported in the search index
- XML documents are now supported in the search index

### Fixed
- Keyboard navigation no longer dings everytime a key is pressed.
- Keyboard navigation now scrolls the list to the file you have selected.
- Minor speed improvements to loading folders
- Text display in the Preview Window

## [v0.9.0] - Preview Window - 2026-07-17

### Added
- Added a Preview Window for documents that have been added to Minna.
- The preview window is now the default action when you double click on a document.

#### Preview Window
- Shows PDF & Text Document content
- A simplified chat experience, where you can chat with just the open document.

### Changed
- Citations now open in the Preview Windo

### Fixed
- Fixed an issue where citation locations would not always appear.

## [v0.8.1] - Document locations for Citations + Bug Fixes - 2026-07-13

### Added
- Citations now report their original position in the document. This allows you to see where in a document information actually came from.

### Fixed
- Added support for resumable releases in the event of a crash or cancelation.
- Internal Release Scripts

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
