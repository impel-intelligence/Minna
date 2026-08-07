<!-- Authored by Claude Opus 5 (Anthropic) on 2026-08-06 -->

# ModelBench

A harness for picking the best on-device MLX model for Minna.

Every model runs through Minna's real chat stack — the same `MLXProvider`, the same
`AskMinnaInstructions`, the same four tools, the same `GenerationOptions` — against a fixed
corpus indexed with the same `bge_small_en_v1.5` embedder the app ships. Retrieval is therefore
identical across models, so score differences are attributable to the model rather than to
search noise or prompt drift.

## Setup

```bash
# 1. Submodules (IrisSearch, LookAtMe) must be checked out.
git submodule update --init --recursive

# 2. MLX's Metal kernels are compiled by Xcode, not SwiftPM. Build Minna in Xcode once (⌘B),
#    then copy the shader bundle next to the ModelBench binary.
./scripts/prepare-metal.sh
```

Without step 2 every run dies with `MLX error: Failed to load the default metallib`. See the
script's header for why.

## Usage

```bash
swift run ModelBench list                      # models available on this machine
swift run ModelBench discover --search qwen    # find candidates, screened for tool support
swift run ModelBench fetch mlx-community/Qwen3-4B-Instruct-2507-4bit
swift run ModelBench run                       # benchmark every downloaded model
swift run ModelBench run --model Nanbeige4.1-3B-8bit --verbose
swift run ModelBench report bench-results/run-*.json
```

Models land in Minna's shared model storage
(`~/Library/Group Containers/group.com.tryminna/Library/Caches/Models`), so anything fetched
here is immediately selectable in the app, and anything the app has is benchmarkable here.

## What gets scored

Four axes, combined with the weights in `suite.json`. Everything is deterministic — no judge
model is involved, because `AskMinnaInstructions` specifies an exact citation format, forbids
answering from outside the corpus, and caps the number of searches.

| Axis | Default weight | Measures |
|------|----------------|----------|
| Prompt adherence | 0.35 | Citation tags well-formed; every `doc_id` real *and* actually retrieved; excerpt index in range; expected facts present; no world-knowledge answers; clarification when asked something ambiguous |
| Tool adherence | 0.35 | Tool called at all; no invented tool names; search-first; within the search cap; no repeated identical calls; `nItems > 0`; no errored calls; task-specific tool used |
| Speed | 0.20 | Median decode tok/s (counted with the model's own tokenizer) and median time-to-first-token, against the suite's budgets |
| Size | 0.10 | Weights on disk, against the suite's byte budget |

Peak memory and cold-load time are recorded and reported but not scored.

### The corpus

`Resources/corpus/*.md` — ten fixture documents with fixed UUIDs and planted facts. Format is a
`---` delimited header (`uuid`, `title`, `summary`) followed by excerpts separated by `%%`. The
excerpt index in a citation refers to position in that list, so citation validity is checkable.

### The tasks

`Resources/suite.json` — twelve tasks across six kinds:

- `retrieval` — a fact in one document
- `multiHop` — a fact requiring two documents joined on a shared key
- `excerptContext` — the answer sits beside the matched excerpt, so `getExcerptContext` is needed
- `refusal` — nothing in the corpus answers it; answering from world knowledge fails the task
- `ambiguous` — underspecified; the model should search, then ask
- `citationStress` — several claims from several documents, each needing its own tag

Tasks are bounded by `taskTimeoutSeconds` (default 180). Weak models loop on tool calls
indefinitely; without the bound a run never finishes.

### Repeats, and why they are not optional

These models sample non-deterministically. The same model on the same task was observed scoring
38% and 82% on consecutive runs, so a single sample cannot tell a better model from a luckier
one. Each task therefore runs `repeats` times (default 3, `--repeats` to override), scores are
aggregated by median within a task before averaging across tasks, and the per-model table
reports the min–max spread alongside the median. Failures are counted across repeats — a check
that fails 3/3 is a real weakness, one that fails 1/3 is noise.

Raising `repeats` is the single most effective way to make two close models distinguishable.

## Notes

- `Package.resolved` is pinned to match `Packages/MinnaChat`. A fresh resolve picks a newer
  SwiftFaiss whose binary artifacts fail to extract under SwiftPM.
- Each model's weights are evicted from the MLX cache before the next model loads, so a
  multi-model run does not walk off the end of unified memory.
