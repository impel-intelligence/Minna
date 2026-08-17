# Security Policy

<!-- Edited by Claude Opus 5 (Anthropic) on 2026-08-13 -->

Minna is published as open source specifically so that its privacy and security behavior can be verified. Reports are welcome and taken seriously.

## Reporting a vulnerability

**Please do not open a public issue.**

Report privately through either channel:

- [GitHub private security advisories](https://github.com/impel-intelligence/Minna/security/advisories/new) - preferred, since it keeps discussion and the eventual fix in one place.
- Email <support@tryminna.com> with `SECURITY` in the subject line.

Please include:

- What the issue is and why you believe it is a security problem
- Steps to reproduce, ideally with a minimal case
- The Minna version (**Minna -> About**) and your macOS version
- Whether you intend to disclose publicly, and on what timeline

### What to expect

- **Acknowledgement within 3 business days.**
- An assessment and a rough remediation timeline within 10 business days.
- Credit in the release notes and the advisory, unless you prefer otherwise.

We ask that you give us a reasonable opportunity to ship a fix before disclosing publicly. We will keep you informed of progress and will not ask for open-ended delays.

## Scope

Minna is a local-first macOS application. The following are in scope:

- Unintended exposure of indexed document contents, chat history, or the `.irisdb` index
- Mishandling of user-supplied AI provider API keys, which are stored in the macOS Keychain
- Telemetry or network traffic that transmits more than what is documented below
- Sandbox escapes, privilege escalation, or code execution via crafted documents during indexing
- Weaknesses in the Sparkle auto-update path, including update signature verification

Out of scope:

- Vulnerabilities in third-party AI providers (Anthropic, OpenAI, Google, Ollama) themselves - report those to the provider
- Issues that require an already-compromised machine or physical access to an unlocked device
- Findings from automated scanners without a demonstrated impact on Minna

## What Minna sends over the network

Stated here so that reports can be measured against intended behavior. If you observe traffic that contradicts this, that is a reportable issue.

- **Your documents and chats stay on your machine.** They are indexed locally into an `.irisdb` package and are never uploaded by Minna.
- **AI provider requests** go directly from your machine to whichever provider you configured, using your own API key. On-device models (MLX, Apple Foundation Models) make no network requests at all.
- **Model downloads** come from `cdn.tryminna.com`.
- **Update checks** (direct-download builds only) come from the Sparkle appcast.
- **Crash reporting and analytics** are opt-in at build time and are disabled in builds from source. In official release builds they collect aggregate counts and a model name - no document contents, no chat contents, and no personally identifying information (`sendDefaultPii` is off). See `Minna/TelemetryWrapper.swift`, which is deliberately small enough to read in full.

## Supported versions

Security fixes are issued for the latest released version. Please update to the current release before reporting.
