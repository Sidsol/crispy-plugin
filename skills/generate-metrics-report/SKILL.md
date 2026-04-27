---
name: generate-metrics-report
description: "Generate static HTML reports of CRISPY token usage and time spent per phase, per feature, and per project."
---

# Generate Metrics Report

Builds static HTML reports from the `.metrics.jsonl` files that the `crispy-metrics-record` post-tool hook writes whenever a CRISPY sub-agent finishes. No network, no JS frameworks, no CDNs — pure stdlib Python that ships with the plugin.

## When to use

- After running one or more CRISPY phases or `crispy-implement` slices, when the user wants a visual breakdown of where time and tokens went.
- Periodically during a long-running project to monitor cost and pace.
- Before a retro / handoff to share a single self-contained HTML page.

## When NOT to use

- The user asked for a live dashboard, real-time graphs, or anything beyond a static file.
- No `.metrics.jsonl` files exist anywhere under `crispy-docs/` (run a CRISPY phase first).

## Inputs

- `crispy_docs_root` (optional) — absolute path to the `crispy-docs` directory. If omitted, walks up from `cwd` to find one.
- `feature` (optional) — only regenerate the named feature's report (e.g., `specs/003-graphql-support` or `projects/001-acme/features/002-billing`).
- `open` (optional, default `false`) — open `reports/index.html` in the default browser after generation.

## Process

### 1. Discover the crispy-docs root

If `crispy_docs_root` was supplied, use it. Otherwise, walk up from cwd until a directory NAMED `crispy-docs` is found. If none is found, abort with a clear message ("run a CRISPY phase first").

### 2. Run the renderer

Invoke `python skills/generate-metrics-report/render.py --root <crispy_docs_root> [--feature <rel>] [--open]`. The renderer:

1. Walks the root for any `.metrics.jsonl` (skipping `reports/`).
2. Classifies each owning folder as `standalone`, `project`, or `project_feature` by relative path.
3. Loads the multiplier table (built-in defaults plus optional override at `<root>/.metrics-multipliers.json`).
4. Aggregates by phase per feature, then rolls features up to projects.
5. Writes:
   - `<feature-folder>/metrics.html` for every standalone feature and every project-feature.
   - `<project-folder>/metrics.html` for every project (rolls up its features).
   - `crispy-docs/reports/index.html` — top-level index linking everything.
   - `crispy-docs/reports/standalone/<NNN-feature>.html` — mirror of each standalone feature page.
   - `crispy-docs/reports/projects/<NNN-project>.html` — mirror of each project page.

### 3. Report back

Tell the user how many features/projects were processed and where the index is.

If `open: true`, open the index using Python's `webbrowser` module (cross-platform).

## What gets measured

| Metric | How it's computed | Accuracy |
|---|---|---|
| **Premium Requests** | `Σ (invocations × per-model multiplier)`. Multiplier looked up from a built-in table (Opus 4.7 = 7.5×, Sonnet variants = 1×, Haiku = 0.33×, etc.) or the override file. | **Lower bound.** One captured invocation = one Task tool call; each sub-agent makes many internal LLM turns the hook cannot observe. Cross-check with `github.com/settings/billing` → Premium Request Analytics. |
| **Wall-clock Time** | `ts_end_ms − ts_start_ms` from paired pre/post hook timestamps. | Exact. |
| **Approx Tokens** | `ceil(chars / 4)` over the prompt and the result text. Labelled "approx; not used for billing". | Rough. |
| **Model breakdown** | Counts per model name as recorded from `toolArgs.model`. Invocations without an explicit model fall under `(unknown)` and use the default multiplier. | Depends on whether spawners pass the `model` hint per `SUBAGENTS.md` §1.1. |

## Overriding multipliers

Multipliers change (e.g., the 7.5× Opus 4.7 rate is promotional through April 30, 2026). Override at any time without touching the plugin:

```json
// crispy-docs/.metrics-multipliers.json
{
  "default": 1.0,
  "models": {
    "claude-opus-4.7": 5.0,
    "claude-sonnet-4.6": 1.0,
    "my-private-model": 2.5
  }
}
```

## Disabling capture

Set `CRISPY_METRICS_DISABLED=1` in the environment to skip the hooks entirely. Existing `.metrics.jsonl` files are not deleted.
