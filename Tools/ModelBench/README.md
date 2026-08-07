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
./scripts/fetch-benchmark-models.sh            # download the whole 12-model slate (56 GB)
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

## Output

Every run writes four files:

| File | Contents |
|------|----------|
| `run-<stamp>-tasks.csv` | One row per task attempt, every raw measurement |
| `run-<stamp>-checks.csv` | One row per individual check — the rawest form of the grading |
| `run-<stamp>.json` | Everything, including full answers and tool call arguments |
| `run-<stamp>.md` | Raw measurements table, weighted scores, per-model check tallies |

**Prefer the raw numbers to the percentages.** The percentage scores are weighted pass ratios
whose denominator changes per task — a task with two expected facts carries different total
weight than one with none — so they compare models on the same task but not tasks with each
other. The CSVs exist so you can recompute, reweight, or ignore the scoring entirely.

## What gets scored

Four axes, combined with the weights in `suite.json`. Everything is deterministic — no judge
model is involved, because `AskMinnaInstructions` specifies an exact citation format, forbids
answering from outside the corpus, and caps the number of searches.

Each axis score is a weighted pass ratio, `Σ(weight × passed) / Σ(weight)`:

| Axis | Default weight | Measures |
|------|----------------|----------|
| Prompt adherence | 0.35 | Citation tags well-formed; every `doc_id` real *and* actually retrieved; excerpt index in range; expected facts present; no world-knowledge answers; clarification when asked something ambiguous |
| Tool adherence | 0.35 | Not aborted on a tool loop; tool called at all; no invented tool names; search-first; within the search cap; no repeated identical calls; `nItems > 0`; no errored calls; task-specific tool used |
| Speed | 0.20 | `0.6 × min(1, tok_s / target) + 0.4 × max(0, 1 − ttft / max_ttft)` |
| Size | 0.10 | `max(0, 1 − bytes / max_bytes)` |

The speed and size budgets (60 tok/s, 12s, 12 GB) are chosen, not empirical — a model at 60
tok/s and one at 200 tok/s both score 1.0. Read the raw `tokens_per_second` instead.

Per model, scores are aggregated as the median across repeats within a task, then the mean
across tasks. The composite is `0.35·prompt + 0.35·tools + 0.20·speed + 0.10·size`.

## Energy

Energy cost is measured per task and reported raw, but is **not** part of the composite score,
because it is not measurable in every configuration and a zero would corrupt the ranking.

There are two independent sources, and the harness records whichever are available.

### On-die counters (works everywhere, including a Mac mini)

Read from the `Energy Model` group of the private IOReport framework — the same counters
`powermetrics` reports, but without needing root, so an unattended run can use them. Available on
any Apple Silicon Mac, on a desktop, and while plugged in.

| Column | Meaning |
|--------|---------|
| `package_watts` | CPU + GPU + ANE, matching powermetrics' combined power |
| `cpu_watts`, `gpu_watts`, `ane_watts`, `dram_watts` | Per-block averages |
| `package_watt_hours` | Energy over the task |
| `cpu_energy_raw` + `cpu_energy_unit` (and gpu/ane/dram) | The counter delta exactly as IOReport reported it |

The raw counters are carried through in their native units because channels disagree — CPU
reports millijoules while GPU reports nanojoules on the same machine — so nothing is lost to the
watt conversion. Expect GPU to dominate: MLX inference measured about 19 W GPU against 5 W CPU.

### Battery (laptops only, and only unplugged)

Read from `AppleSmartBattery`. Gives whole-system draw rather than just the SoC, which is the
better figure for "how much battery does this cost" — but it does not exist on a desktop, and
while charging the current reflects the adapter rather than the model.

| Column | Derivation |
|--------|------------|
| `battery_percent_drop` | `AppleRawCurrentCapacity / AppleRawMaxCapacity × 100` |
| `battery_mah` | Raw capacity delta |
| `avg_watts` | Mean of `Voltage × InstantAmperage`, sampled each second |
| `watt_hours`, `watt_hours_per_minute` | Derived from the above |
| `on_ac_power` | `ExternalConnected` — when 1, the battery columns are meaningless |

`IOPSCopyPowerSourcesInfo` is deliberately not used: it reports only whole percentage points,
too coarse to resolve a task lasting under a minute. The raw mAh keys give about 0.02%
resolution on a 4900 mAh pack.

The per-model summary reports **Wh per 1000 generated tokens**, which is the figure that actually
compares models: a faster model can draw more watts and still cost less energy overall because it
finishes sooner.

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
