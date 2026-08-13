# README outline

<!-- Edited by Claude Opus 5 (Anthropic) on 2026-08-13 -->

A structure for the rewritten `README.md`, for you to write in your own voice. The current README is 20 lines, has no build instructions, and states that "Claude / Anthropic is the only provider currently supported" — which stopped being true as of 0.11.0. **Delete this file once the README is rewritten.**

Two audiences land on this page and they want different things in the first ten seconds: a *user* wants to know what Minna does and how to get it; a *developer or privacy reviewer* wants to know how to build it and what it sends over the network. Serve the user first, then the developer.

---

## 1. Title and one-line description

Lead with what Minna **does**, not what it's named after. The Minerva line is charming and worth keeping, but as a subtitle rather than the opening.

Something in the shape of: *a local-first AI assistant for your own documents — your files are indexed and searched on your Mac, never uploaded.*

Badges: license (Apache-2.0), latest release, macOS version.

## 2. Screenshot or short demo

The single highest-value thing on the page, and the current README has none of the app itself. A GIF of asking a question and getting a cited answer would carry more than any paragraph. `Minna/Resources/Videos/` already has recordings made for onboarding.

## 3. What it does

Four or five bullets. Concrete over abstract:

- Index folders of documents — PDF, Markdown, TXT, HTML, XML, OPML
- Ask questions and get answers **with citations back to the source passage**
- Hybrid search: full-text (FTS5) and semantic (vector) over the same corpus
- Your index is one portable `.irisdb` file you can move between machines
- Bring your own AI provider, or run entirely on-device

## 4. Privacy

Give this its own section near the top rather than burying it. It is a primary reason the source is public, and reviewers should not have to hunt for it.

- Documents and chats never leave your machine
- Prompts go directly to the provider *you* chose, with *your* key
- On-device models (MLX, Apple Foundation Models) make no network calls at all
- API keys are stored in the macOS Keychain
- Link to `SECURITY.md`, which enumerates every network destination

## 5. Install

Keep the existing Releases link. Add the Mac App Store link when that ships. State the macOS requirement (26+) plainly — it's a steep floor and people should hit it here rather than after downloading.

## 6. Setup

The existing screenshot walkthrough is good and should survive the rewrite. Two fixes:

- **Correct the provider list.** Minna supports Anthropic, OpenAI, Gemini, Ollama, Apple Foundation Models, and MLX.
- Mention that on-device models need no key at all, which is the fastest path to trying it.

Keep the Open Course Materials sample-data link.

## 7. Build from source

New section — nothing like it exists today, and its absence is the single biggest gap for contributors.

    git clone --recursive https://github.com/impel-intelligence/Minna.git
    cd Minna
    open Minna.xcodeproj

- Requirements: macOS 26+, Xcode 26+, Git LFS
- Note `--recursive` (submodules) and the recovery command for people who forget
- **State clearly that no configuration is needed.** `Config.xcconfig` ships blank, telemetry is off, signing is local. This is worth saying explicitly because most projects do require setup and people assume they've missed a step
- Note that corpus-dependent tests skip when fixtures are absent
- Link to `CONTRIBUTING.md` for detail rather than duplicating it

## 8. Architecture

A short paragraph and the package list, then link to `docs/ARCHITECTURE.md`. Enough that someone can decide whether to read further.

## 9. Contributing

Short. Link `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`. Mention DCO sign-off and that there's no CLA — contributors specifically look for that.

## 10. License

Apache-2.0, link `LICENSE`. Then one sentence that the code license does not cover the Minna name or marks, linking `TRADEMARK.md`. State it plainly rather than defensively — forks are welcome, they just need their own name.

---

## Things to avoid

- Don't claim "open source" and leave the private dependencies unresolved. The build genuinely has to work from a fresh clone before the README says it does.
- Don't over-promise on roadmap. A commercial product's README aging badly is worse than a short one.
- Don't bury macOS 26 as a requirement.
- Don't let the provider list drift again — it's already been wrong once. If anything, link to the settings UI as the source of truth.
