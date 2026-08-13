# Code review guidelines

<!-- Edited by Claude Opus 5 (Anthropic) on 2026-08-13 -->

Project-specific criteria for the automated reviewer in `.github/workflows/claude-code-review.yml`, and a useful checklist for human reviewers too.

These are **in addition to** ordinary code review. Correctness, clarity, and test coverage still matter; this file covers the things specific to Minna that are easy to miss and expensive to discover after a release.

Report only what a change actually warrants. A one-line bug fix should not attract a lecture about trademark policy. If nothing in a section applies, say nothing about it.

## Licensing, NOTICE, and TRADEMARK

Minna is Apache-2.0 and commercially distributed, so licensing drift is a real cost rather than a formality. Flag a PR when:

- **A new third-party component is vendored into the repository** — a binary framework, a bundled model, copied source, an icon set, a font — and `NOTICE` is not updated to record it. Vendored code carries its own license, and most licenses require the notice travel with the code.
- **Code is copied from an external source** (Stack Overflow, a blog, another project) without an attribution comment naming the source and its license. Stack Overflow answers are CC BY-SA, which is not Apache-2.0. See `Minna/objc/CatchException.m` for the expected form.
- **A new local Swift package is added** without an Apache-2.0 `LICENSE` file of its own.
- **A dependency is added whose license is not Apache-2.0-compatible.** MIT, BSD, and Apache-2.0 are fine. GPL, LGPL, AGPL, and source-available licenses (BUSL, SSPL, PolyForm) are not, and need a decision before merge.
- **New brand assets are added** — a logo, an app icon, a wordmark — and `TRADEMARK.md` still lists only the old ones. That file enumerates what a fork must replace, so it has to stay current or it stops being useful.
- **The product or company name changes**, or a new name is introduced, without `TRADEMARK.md` and `NOTICE` following.
- **`LICENSE` is edited.** It is verbatim canonical Apache-2.0 and should not be modified. The same goes for `Frameworks/Sparkle.framework/LICENSE` and `CODE_OF_CONDUCT.md`, which are verbatim third-party text.
- **A copyright header is removed or reassigned.** Attribution gets added alongside, never replaced.

## Secrets and configuration

- No credentials, API keys, tokens, DSNs, or Apple Team IDs in tracked files. They belong in `Config.local.xcconfig`, which is gitignored.
- `Config.xcconfig` must keep every value **blank**. It is committed, and a populated value there ships credentials to everyone. Real values go only in `Config.local.xcconfig`.
- New telemetry or network calls must fail closed when unconfigured, matching `BuildConfiguration.swift`: absent configuration means the feature is off, not that it falls back to a default endpoint.
- Any new network destination must be added to the list in `SECURITY.md`. That list is a promise to users about what leaves their machine, and an undocumented endpoint makes it false.
- Watch for secrets passed as command-line arguments in scripts and workflows — they leak into process listings and logs. Use environment variables.
- GitHub Actions workflows that consume secrets must stay gated to trusted actors, and must not switch from `pull_request` to `pull_request_target`, which would expose secrets to fork code.

## Privacy

Minna's central claim is that documents and chats stay local. Flag anything that could weaken it:

- Document contents, chat contents, file paths, or index data being sent anywhere.
- Telemetry that grows beyond aggregate counts, or that could carry user content in an event property or error message.
- `sendDefaultPii` being enabled, or PII scrubbing being weakened.
- Logging that writes document contents or full paths, since users are asked to paste logs into bug reports.

## Documentation currency

Documentation that contradicts the code is worse than none, and this repo has already shipped a README claiming Anthropic was the only supported provider months after that stopped being true. Flag when:

- A user-visible feature changes and `README.md` still describes the old behavior.
- An AI provider is added or removed and the provider lists in `README.md`, `SECURITY.md`, and `docs/ARCHITECTURE.md` are not updated.
- A package is added, removed, or substantially restructured and `docs/ARCHITECTURE.md` still describes the old layout, including its "where to look" table.
- The build or setup process changes and `CONTRIBUTING.md` still gives the old steps.
- The minimum macOS or Xcode version changes and the requirements in `README.md` and `CONTRIBUTING.md` do not follow.

## Changelog

- Every user-facing change needs an entry under `## [Unreleased]` in `CHANGELOG.md`, in Keep a Changelog format.
- Entries should be written for a Minna user, not a developer reading the diff. "Fixed a crash when opening a malformed database" is right; "Fixed nil unwrap in IrisDBController" is not.
- Internal refactors with no user-visible effect don't need one — don't insist.

## Agent attribution

Per `AGENTS.md`, AI-authored work identifies itself. Flag when:

- A file created or meaningfully edited by an agent has no attribution comment in its header.
- A doc comment written by an agent lacks its attribution line.
- A commit authored by an agent lacks a `Co-Authored-By` trailer naming the specific model.
- An agent added a `Signed-off-by` line for itself. DCO sign-off belongs to the human submitting the work.
- `CLAUDE.md` was replaced with a regular file instead of remaining a symlink to `AGENTS.md`.

## Formatting

- Prose must not be hard wrapped — paragraphs, comments, doc comments, and commit bodies are single continuous lines. The exception is verbatim external text, where the original wrapping is preserved.
- Match the surrounding code's style. SwiftLint and SwiftFormat cover the rest.
- Use `SFSafeSymbols` (`systemSymbol:`) rather than `Image(systemName:)`.

## Build and release integrity

- Changes to `Minna.xcodeproj/project.pbxproj` that reintroduce a hardcoded `DEVELOPMENT_TEAM`, or that drop the `baseConfigurationReference` to `Config.xcconfig`, silently defeat the credential externalization. Inline `buildSettings` override an xcconfig.
- The `SPARKLE` compilation condition must keep Sparkle out of App Store builds.
- Changes to `scripts/release.sh` deserve close attention: it signs, notarizes, and uploads.
- New Swift files land automatically via file-system synchronized groups. A manual `PBXFileReference` addition for a source file usually indicates a mistake.

## Extending this file

Add a section when a class of mistake becomes worth catching automatically. Keep each item concrete enough to check against a diff — "flag when X changes but Y doesn't" is actionable; "ensure good architecture" is not. Sections are independent, so new feature areas can be appended without disturbing what's here.
