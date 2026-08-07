<!-- Authored by Claude Opus 5 (Anthropic) on 2026-08-06 -->

# On-device LLM candidates for Minna

Research date: **2026-08-06**. All sizes computed from Hugging Face blob metadata
(`/api/models/<repo>?blobs=true`, sum of every file in the repo). All tool-calling claims
verified by fetching `chat_template.jinja` (or `tokenizer_config.json` when there is no
standalone `.jinja`) and reading the actual Jinja source — not from model cards.

---

## 0. The decisive constraint nobody documents: format inference

Minna loads models through `mlx-swift-lm`. It does **not** set `ToolCallFormat` anywhere
(`grep -rn "ToolCallFormat" Packages/MinnaChat/Sources Minna` → no hits), so the parser is
auto-inferred from `config.json`'s `model_type` at
`Packages/MinnaChat/.build/checkouts/mlx-swift-lm/Libraries/MLXLLM/LLMModelFactory.swift:593`
via `ToolCallFormat.infer(from:configData:)`.

The mapping (`Libraries/MLXLMCommon/Tool/ToolCallFormat.swift`) is:

| `model_type` | inferred parser | expects |
|---|---|---|
| `llama` + `vocab_size >= 128000` | `.llama3` | inline JSON / `<\|python_tag\|>`, **no wrapper tag** |
| `lfm2*` | `.lfm2` | `<\|tool_call_start\|>[f(a='b')]<\|tool_call_end\|>` |
| `glm4*` | `.glm4` | `f<arg_key>k</arg_key>…` |
| `gemma4*` | `.gemma4` | `<\|tool_call>call:f{k:<\|"\|>v<\|"\|>}<tool_call\|>` |
| `nemotron*`, `qwen3_5*`, `qwen3_next*` | `.xmlFunction` | `<tool_call><function=f><parameter=k>v…` |
| `mistral3*` | `.mistral` | `[TOOL_CALLS]f [ARGS]{…}` |
| **everything else** | `.json` (default) | `<tool_call>{"name":…}</tool_call>` |

**Two consequences that drive the ranking below:**

1. A model is only a good bet if the format its template emits matches the parser its
   `model_type` selects. Several otherwise-fine models mismatch (see §3).
2. The Swift `LLMModelFactory` registry only knows ~58 `model_type` strings. Anything else
   fails to load regardless of quality. Verified rejects: `nanbeige`, `internlm3`, `laguna`,
   `inkling_mm_model`, `ernie4_5_moe`, `qwen3_5_mtp`.

**Note on the current baseline.** `Nanbeige4.1-3B-8bit` has `model_type: llama` and
`vocab_size: 166144`, so it is inferred as `.llama3` (inline, `startTag == nil`) while its
template actually emits `<tool_call>\n{"name":…}\n</tool_call>`. It still works — the inline
processor buffers from the first `{` and `JSONDecoder` succeeds on the balanced object before
the closing `</tool_call>` arrives — but the literal `<tool_call>` prefix leaks into visible
text and parallel/multiple calls in one turn will not be recovered. Any candidate on this
list whose format matches natively is strictly better plumbing than the baseline.

---

## 1. Ranked shortlist

Tool column key: **confirmed-yes** = template consumes the `tools` variable *and* emits a
tool-call syntax that the inferred parser handles. **confirmed-yes (mismatch)** = template
does tools properly but the inferred parser is wrong; needs an explicit format override.

| # | Repo id | Params | Quant | Size (GB) | Tool calling | Why test it |
|---|---|---|---|---|---|---|
| 1 | `mlx-community/AREX-Turbo-4bit` | 4B (Qwen3.5-4B base) | 4bit affine g64 (vision tower bf16) | **3.06** | confirmed-yes — `{%- if tools %}` + `<tool_call><function=…><parameter=…>`; `qwen3_5` → `.xmlFunction`, exact match | BAAI deep-research agent: RL-trained for search-then-verify-then-cite loops. Closest published training objective to what Minna asks of the model. |
| 2 | `mlx-community/Qwen3.5-4B-MLX-4bit` | 4B | 4bit | **3.06** | confirmed-yes — same Qwen3.5 template, `.xmlFunction` | Clean same-family scaling point against the 9B you already have; 27k downloads. |
| 3 | `mlx-community/granite-4.1-8b-mxfp4` | 8B | mxfp4 | **4.46** | confirmed-yes — 14 `tools` refs, `<tools>…</tools>` + `<tool_call>` JSON; `granite` → `.json`, exact match | IBM tunes Granite explicitly for tool calling and cited RAG; densest tool machinery of any template checked. |
| 4 | `mlx-community/Ministral-3-8B-Instruct-2512-4bit` | 8B | 4bit | **5.63** | confirmed-yes — `[TOOL_CALLS]`; `mistral3` → `.mistral`, exact match | Best-in-class strict instruction following at 8B; the `[TOOL_CALLS]` path is the least ambiguous to parse. |
| 5 | `mlx-community/LFM2.5-2.6B-8bit` | 2.6B | 8bit | **2.88** | confirmed-yes — `<\|tool_call_start\|>` pythonic; `lfm2` → `.lfm2`, exact match | Purpose-built for on-device agents; 2.6B at 8bit will be the throughput champion on M1 Max. Released 2026-08-04. |
| 6 | `mlx-community/Ornith-1.0-9B-4bit` | 9B (Qwen3.5-9B post-train) | 4bit | **5.98** | confirmed-yes — Qwen3.5 template, `.xmlFunction` | RL-trained agentic model (Terminal-Bench 2.1 / SWE-Bench / OpenClaw); 9.8k downloads, top agentic 9B. Tests whether agentic RL transfers to doc search. |
| 7 | `mlx-community/Qwen3-4B-Instruct-2507-4bit` | 4B | 4bit | **2.28** | confirmed-yes — `<tool_call>{json}</tool_call>`; `qwen3` → `.json`, exact match | The proven small tool-caller. 41k downloads. Cheapest credible floor for the 4-tool loop. |
| 8 | `mlx-community/Qwen3.5-4B-MLX-8bit` | 4B | 8bit | **5.16** | confirmed-yes — `.xmlFunction` | Quantization-sensitivity control for #2: isolates whether citation-tag errors are model or 4bit. |
| 9 | `mlx-community/Macaw-OptiQ-4bit` | 2.6B (LFM2.5-2.6B derivative) | OptiQ mixed 4/8bit | **2.01** | confirmed-yes — inherits LFM2.5 template, `.lfm2` | A tool-calling *Mac assistant* fine-tune; quant was explicitly tuned to keep tool calls well formed rather than for benchmarks. |
| 10 | `mlx-community/granite-4.1-3b-4bit` | 3B | 4bit | **2.13** | confirmed-yes — `.json`, exact match | Granite's tool discipline at Nanbeige-baseline size; direct head-to-head with the 4.2 GB incumbent. |
| 11 | `mlx-community/NVIDIA-Nemotron-3-Nano-4B-8bit` | 4B | 8bit | **4.24** | confirmed-yes — `<tool_call><function=><parameter=>`; `nemotron_h` → `.xmlFunction`, exact match | Hybrid Mamba/attention: cheap long-context, which matters when you paste document excerpts back as tool results. |
| 12 | `mlx-community/gemma-4-e4b-it-8bit` | E4B (MatFormer, ~4B effective) | 8bit | **8.91** | confirmed-yes — full `<\|tool>` declaration block + `<\|tool_call>call:` ; `gemma4` → `.gemma4`, exact match | You already run the 4bit; 8bit is the cheapest test of whether Gemma 4's citation-format failures are quantization noise. |
| 13 | `mlx-community/Ministral-3-3B-Instruct-2512-8bit` | 3B | 8bit | **4.50** | confirmed-yes — `.mistral`, exact match | 3B/8bit Mistral at baseline size; 16.5k downloads on the 4bit sibling. |
| 14 | `mlx-community/SmolLM3-3B-8bit` | 3B | 8bit | **3.28** | confirmed-yes — `<tools>` + `<tool_call>` JSON; `smollm3` → `.json`, exact match | Fully-open 3B with a clean XML-tools template; good low-variance control in the 3B bracket. |
| 15 | `mlx-community/Falcon-H1R-7B-4bit` | 7B | 4bit | **4.28** | confirmed-yes — `<tool_call>` JSON; `falcon_h1` → `.json`, exact match | Hybrid-SSM 7B, reasoning-tuned (H1**R**), 130k vocab. Architecturally distinct from every Qwen on the list. |
| 16 | `mlx-community/Qwen3.5-9B-6bit` | 9B | 6bit | **8.22** | confirmed-yes — `.xmlFunction` | Upper quality bound inside the 10 GB budget; pairs with the 4bit 9B you have to price the 6bit step. |
| 17 | `mlx-community/FastContext-1.0-4B-SFT-8bit` | 4B (Qwen3-4B-Instruct-2507 base) | 8bit | **4.29** | confirmed-yes — Qwen3 template, `.json`, exact match | Trained to explore with read-only tools and return a compact block of `file:line` **citations**. Nearest analogue to Minna's `<cite …/>` contract. |
| 18 | `mlx-community/granite-4.0-h-tiny-4bit` | 7B-A1B MoE | 4bit | **3.92** | confirmed-yes — `granitemoehybrid` → `.json`, exact match | MoE: 7B knowledge at ~1B active. Tests whether sparse activation costs tool reliability. |
| 19 | `mlx-community/Qwen3-8B-4bit` | 8B | 4bit | **4.62** | confirmed-yes — `.json`, exact match | 35k-download workhorse; the "known good, boring" reference point. |
| 20 | `mlx-community/Qwen3.5-2B-MLX-8bit` | 2B | 8bit | **2.69** | confirmed-yes — `.xmlFunction` | Speed floor. If 2B/8bit holds the citation format, latency stops being a design constraint. |

---

## 2. Download list

```
mlx-community/AREX-Turbo-4bit
mlx-community/Qwen3.5-4B-MLX-4bit
mlx-community/granite-4.1-8b-mxfp4
mlx-community/Ministral-3-8B-Instruct-2512-4bit
mlx-community/LFM2.5-2.6B-8bit
mlx-community/Ornith-1.0-9B-4bit
mlx-community/Qwen3-4B-Instruct-2507-4bit
mlx-community/Qwen3.5-4B-MLX-8bit
mlx-community/Macaw-OptiQ-4bit
mlx-community/granite-4.1-3b-4bit
mlx-community/NVIDIA-Nemotron-3-Nano-4B-8bit
mlx-community/gemma-4-e4b-it-8bit
mlx-community/Ministral-3-3B-Instruct-2512-8bit
mlx-community/SmolLM3-3B-8bit
mlx-community/Falcon-H1R-7B-4bit
mlx-community/Qwen3.5-9B-6bit
mlx-community/FastContext-1.0-4B-SFT-8bit
mlx-community/granite-4.0-h-tiny-4bit
mlx-community/Qwen3-8B-4bit
mlx-community/Qwen3.5-2B-MLX-8bit
```

---

## 3. Rejected

### Template does not accept a `tools` argument

- **`mlx-community/Phi-4-mini-instruct-4bit` / `-8bit` / `-6bit` / `-mlx-*`** — hard reject.
  The entire template is one line and it never references the `tools` variable. It only emits
  tools when a *message* carries a `tools` key: `{% if message['role'] == 'system' and 'tools'
  in message %}… '<|tool|>' + message['tools'] + '<|/tool|>' …{% endif %}`. Passing
  `tools=[…]` through mlx-swift-lm is silently dropped. Every Phi-4-mini quant shares this.
- **`mlx-community/gemma-3-*-it-*` (1b, 4b, 12b, 27b, qat and non-qat)** — zero occurrences of
  `tool` or `function` anywhere in the template. Gemma 3 cannot call tools through MLX. (Gemma
  **4** is a different template entirely and does support tools — see #12.)
- **`mlx-community/MiniCPM4.1-8B-4bit`** — no tool machinery in template.
- **`mlx-community/ERNIE-4.5-21B-A3B-PT-4bit`** — no tool machinery, 12.28 GB, and
  `ernie4_5_moe` is not in the Swift registry (only `ernie4_5` is). Triple reject.
- **`mlx-community/internlm3-8b-instruct-4bit`** — no tool machinery; `internlm3` unsupported
  in Swift (registry has `internlm2` only).
- **`mlx-community/Hermes-3-Llama-3.2-3B-8bit`** — despite Hermes' function-calling reputation,
  this repo's template has **no** tools support at all. Reputation ≠ template.

### Emitted format mismatches the inferred parser (would need an explicit override)

- **`mlx-community/kanana-2-3b-instruct-{4,6,8}bit`, `-mixed_4_6`** — genuinely good tool
  template (`<tool_call><function=…><parameter=…>`, 8 tag hits) but `model_type: qwen3` makes
  mlx-swift-lm pick `.json`, which will fail to decode XML-function bodies. Only worth testing
  if you set `.xmlFunction` explicitly. Also Korean-first (Kakao).
- **`mlx-community/Ministral-8B-Instruct-2410-4bit`** — emits `[TOOL_CALLS]` but `model_type:
  mistral` → `.json`. Superseded by Ministral-3-2512 anyway.
- **`mlx-community/MiniCPM5-1B-{4,8}bit`, `-OptiQ-4bit`** — uses a bespoke
  `<function name="f"><param name="k">v</param></function>` syntax (with CDATA escaping) that
  **no** mlx-swift-lm parser implements. Would require writing a parser.

### Cannot load in mlx-swift-lm (`model_type` not in `LLMModelFactory.shared`)

- **`mlx-community/Nanbeige4.2-3B-OptiQ-4bit`** — `model_type: nanbeige`. The looped-transformer
  arch ships as a vendored *Python* port inside `mlx-optiq`; there is no Swift class. Genuinely
  attractive otherwise (3.32 GB, richest Nanbeige tool template with 7 `<tool_call>` hits) —
  worth revisiting only if mlx-swift-lm adds `nanbeige`.
- **`mlx-community/Laguna-XS-2.1-8bit` (35.54 GB) / `-OptiQ-4bit` (21.01 GB)** — `laguna`
  unsupported, and both are far over budget despite the "XS" name.
- **`mlx-community/Inkling-Small-mlx-4bit`** — `inkling_mm_model` unsupported; **153.47 GB**.
- **`mlx-community/Qwen3.5-9B-MTP-4bit`** — `qwen3_5_mtp` unsupported.

### Broken or empty repos

- **`mlx-community/Nanbeige4.1-3B-6bit`** — repo contains only `.gitattributes` (1519 B) and a
  31-byte `README.md`. No weights, no config. 0 downloads.
- **`mlx-community/Qwen3.5-9B-MTP-4bit`** — single `model.safetensors` of 136.9 MB against a
  multi-shard `model.safetensors.index.json`. Incomplete upload.

### Out of size / parameter budget

- **`mlx-community/gpt-oss-20b-MXFP4-Q8`** — 12.10 GB, 20B. Highest-downloaded model in
  mlx-community (344k) and tools are confirmed in template, but over the ~10 GB cap.
- **`mlx-community/BTL-4-OptiQ-4bit`** — 22.19 GB.
- **`mlx-community/Hermes-4-14B-4bit`** — 8.32 GB fits, but 14B is outside the 1B–9B band and
  it's a 2025-09 Qwen3 finetune with no doc-search-specific advantage.
- **`mlx-community/Ministral-3-8B-Instruct-2512-8bit`** (9.89 GB) and
  **`mlx-community/granite-4.1-8b-8bit`** (9.44 GB) — fit the cap but leave no headroom against
  the 4bit/mxfp4 siblings already on the list. Promote only if the 4bit versions look
  quantization-limited.

### Superseded / low value

- **`mlx-community/Llama-3.2-3B-Instruct-{4,8}bit`, `Llama-3.1-8B-Instruct-4bit`,
  `Llama-3.3-70B-*`** — tools are real (10–11 `tools` refs, JSON-in-user-message style) but the
  template hard-fails on parallel calls: `{{- raise_exception("This model only supports single
  tool-calls at once!") }}`. Combined with 2024-vintage instruction following and the lossy
  `.llama3` inline parser, not worth benchmark slots. 70B is also way over budget.
- **`mlx-community/deepcogito-cogito-v1-preview-llama-{3B,8B}-4bit`** — 2025-04 preview,
  `.llama3` inline parser, superseded by everything above.
- **`mlx-community/LFM2.5-1.2B-Instruct-4bit`** (0.66 GB) and **`LFM2.5-1.2B-Thinking-6bit`** —
  the 1.2B template only stringifies tools into the system prompt (`"List of tools: [" … "]"`)
  and never renders assistant `tool_calls` back into history, so multi-turn tool loops degrade.
  The 2.6B template has the full `<|tool_call_start|>` machinery. Use 2.6B.
- **`mlx-community/Qwen2.5-7B-Instruct-4bit`** (4.30 GB) — works, but Qwen3/Qwen3.5 dominate it
  at equal size.
- **`mlx-community/VibeThinker-3B-OptiQ-4bit`**, **`MagenticBrain-4bit`** (8.32 GB),
  **`Qwen3-4B-Sky-High-Hermes-8bit`**, **`Nanbeige4.1-3B-heretic-8bit`**,
  **`Qwen3.5-9B-Fable-5-v1-oQ4`** — niche/abliterated/roleplay finetunes with no
  instruction-following or tool-use claim relevant to Minna.
- **`mlx-community/AREX-Turbo-8bit`** (5.16 GB) — hold in reserve; run the 4bit first, since its
  card reports 8/8 vs bf16's 7/8 on verifiable-answer tasks and 0.93 top-1 agreement.

---

## 4. Disk cost

| Set | Models | Total |
|---|---|---|
| Top 8 (highest value) | AREX-Turbo-4bit, Qwen3.5-4B-MLX-4bit, granite-4.1-8b-mxfp4, Ministral-3-8B-2512-4bit, LFM2.5-2.6B-8bit, Ornith-1.0-9B-4bit, Qwen3-4B-Instruct-2507-4bit, Qwen3.5-4B-MLX-8bit | **32.51 GB** |
| Remaining 12 | items 9–20 | **53.09 GB** |
| **All 20 recommended** | | **85.60 GB** |

Largest single item: `gemma-4-e4b-it-8bit` at 8.91 GB. Every recommended model is under the
10 GB cap. On a 64 GB M1 Max nothing here comes close to a memory ceiling — the 9B/6bit at
8.22 GB is the peak resident footprint.

### Two size caveats worth knowing before you budget

1. **Qwen3.5 and Gemma 4 repos ship non-text towers.** Verified via
   `model.safetensors.index.json`: `Qwen3.5-4B-MLX-4bit` and `AREX-Turbo-4bit` carry 297
   `vision_tower.*` keys, `Qwen3.5-9B-MLX-4bit` and `Ornith-1.0-9B-4bit` carry 333, and
   `gemma-4-e4b-it-4bit` carries 661 vision keys plus an `audio_tower` and `embed_audio`.
   `mlx-vlm` leaves these towers in **bf16** by design, so a nominal "4bit" Qwen3.5-4B is
   3.06 GB rather than ~2.3 GB. There is no text-only small Qwen3.5 in `mlx-community` — I
   searched `Qwen3.5-text`, `Qwen3.5-*-Text`, and `-text-`; the only text-only Qwen3.5 is the
   27B `qwen3.5-27b-claude-opus-8bit-text-only`. Nothing to reclaim here.
2. **Sizes are whole-repo sums**, including `tokenizer.json` (up to ~20 MB on the 248k-vocab
   Qwen3.5 models) and any `.gguf`-adjacent extras. Weights-only figures run 0.02–0.03 GB lower
   in every case checked.
