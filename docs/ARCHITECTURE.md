# Minna Architecture

<!-- Edited by Claude Opus 5 (Anthropic) on 2026-08-13 -->

An orientation guide for people reading the code for the first time. It covers how the pieces fit together and where to look for a given behavior, rather than documenting every type.

## The shape of the thing

Minna is a **local-first** macOS app. You point it at folders of documents; it reads and indexes them on your machine, then lets you ask questions that are answered against that index. The only thing that leaves your computer is the prompt you send to whichever AI provider you configured — and if you use an on-device model, not even that.

That constraint drives the architecture. Indexing, storage, search, and document rendering are all local. The AI provider is a pluggable edge, deliberately kept at arm's length.

```
      ┌────────────────────────────────────────────────┐
      │  Minna (app target)                            │
      │  SwiftUI views, windows, onboarding, settings  │
      └───────┬─────────────┬──────────────┬───────────┘
              │             │              │
      ┌───────▼──────┐ ┌────▼─────┐ ┌──────▼────────┐
      │  IrisSearch  │ │ MinnaChat│ │   LookAtMe    │
      │  index and   │ │ RAG chat │ │ render source │
      │  search      │ │ + tools  │ │ + highlight   │
      └───────┬──────┘ └────┬─────┘ └───────────────┘
              │             │
      ┌───────▼──────┐ ┌────▼──────────┐ ┌────────────┐
      │  .irisdb     │ │ ModelManager  │ │ ModelCDN   │
      │  file package│ │ providers     │ │ downloads  │
      └──────────────┘ └───────────────┘ └────────────┘
```

## Packages

Local Swift packages under `Packages/`. Two are git submodules, because they're useful independently of Minna.

### `IrisSearch` (submodule)

The search engine, and the most substantial piece of the system. Hybrid retrieval: keyword and semantic search over the same corpus.

- **`Digester`** — turns files into text. Handles PDF, TXT, HTML, XML, OPML, and Markdown, then chunks the result. Markdown gets structure-aware chunking; prose falls back to sentence chunking.
- **`Embedder`** — produces vectors. Two backends: `CoreMLEmbedder` (a bundled BGE model) and `AppleIntelligenceEmbedder` (system-provided).
- **`IrisSearch`** — the index and query layer. SQLite via GRDB, with FTS5 for full-text search and FAISS for vector search. Results from both are combined.
- **`IrisCommon`** — shared types.

The whole index is a single macOS **file package** with the `.irisdb` extension. It looks like one file in Finder and can be moved between machines by dragging it. This is a deliberate product decision, not just a storage detail — your index is a document you own, not hidden application state.

### `MinnaChat`

RAG chat on top of `IrisSearch`.

- **`MinnaChat`** — conversation flow, prompt construction (`Instructions/`), and the tools exposed to the model: `SearchTool`, `GetDocumentTool`, `SearchInDocumentTool`, `GetExcerptContextTool`. The model doesn't receive your corpus; it receives the ability to *search* it, and pulls in only what it asks for.
- **`ModelManager`** — provider abstraction. Six implementations in `Providers/`: Anthropic, OpenAI, Gemini, Ollama, Apple Foundation Models, and MLX. The first three are remote APIs using your key; the last three run locally.

### `LookAtMe` (submodule)

Renders source documents and highlights the passage a citation points at, so an answer can be traced back to where it came from.

### `ModelCDN`

Fetches on-device model weights from `cdn.tryminna.com`. No dependencies — deliberately small and auditable.

### `DatabaseSchema`

SwiftData schema for application state — files, chats, configured providers. Provider API keys are **stored in the macOS Keychain**, not in this database and not in `UserDefaults` (see `Functions/Chats/ConfiguredProvider.swift`).

## App targets

- **`Minna`** — the app. `IrisApp.swift` is the entry point; `Views/` holds the UI by feature area (Chat, Search, Dashboard, Onboarding, Settings). `Local Search/` bridges the app to `IrisSearch` via `IrisContext` and `IrisDBController`.
- **`SearchModelAssets`** — a Background Assets extension that downloads embedding and language models outside the app's lifetime, so a first run isn't blocked on a large download.
- **`Tools/ModelUploader`** — a maintainer-side CLI for publishing models to the CDN. Not part of the app.

## Build flavors

Two distribution channels, separated by the `SPARKLE` compilation condition:

| | Mac App Store | Direct download |
|---|---|---|
| Configuration | `Release` | `Release Sparkle` |
| Updates | App Store | Sparkle (`Frameworks/Sparkle.framework`) |
| `SPARKLE` flag | off | on |

`Frameworks/Sparkle.framework` is vendored as a prebuilt binary and is excluded from App Store builds, where Sparkle would be both unnecessary and disallowed.

## Configuration

`Config.xcconfig` supplies build settings and ships with every value blank. Blank is the supported default: telemetry stays off and signing is local, so a build from source reports nothing anywhere. `Config.local.xcconfig` is a gitignored override for maintainers. `BuildConfiguration.swift` reads the values back and treats blank or unsubstituted values as "not configured".

## Where to look

| To change… | Start at |
|---|---|
| How a file type is parsed or chunked | `Packages/IrisSearch/Sources/Digester/` |
| Search ranking or index schema | `Packages/IrisSearch/Sources/IrisSearch/` |
| What the model can do during a chat | `Packages/MinnaChat/Sources/MinnaChat/Tools/` |
| Prompts | `Packages/MinnaChat/Sources/MinnaChat/Instructions/` |
| Adding an AI provider | `Packages/MinnaChat/Sources/ModelManager/Providers/` |
| Persisted app state | `Packages/DatabaseSchema/Sources/DatabaseSchema/Schema/` |
| Citation rendering | `Packages/LookAtMe/Sources/` |
| Telemetry | `Minna/TelemetryWrapper.swift` — small on purpose, read it in full |
| Release pipeline | `scripts/release.sh` |
