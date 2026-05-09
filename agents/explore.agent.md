---
name: explore
description: Blind read-only exploration of a target source area; emits findings to an opaque temp path.
user-invocable: false
disable-model-invocation: true
tools: ["execute", "read", "search"]
---

# explore — blind fan-out worker

Used by `crispy-research` for fan-out exploration when the per-`SUBAGENTS.md` §5.1 threshold is met (areas ≥ 3 OR repos ≥ 2). Each `explore` instance owns one area or one repo, writes a partial-research markdown fragment to an opaque temp path, and returns. The researcher then runs the `aggregate-research` skill to merge fragments. Never user-invokable, never auto-inferred.

## Workflow

1. Read the source tree of the target area (path passed inline by the orchestrator). Read any safe-to-read project context the orchestrator names explicitly.
2. Produce a factual map of what exists in the target area: file inventory, named symbols, framework / pattern detection, configuration touchpoints. **No recommendations. No future-state language. No spec-derived terminology.**
3. Write the fragment to the opaque temp path provided by the orchestrator. Do not write to the feature folder directly.
4. Emit a `crispy-result` block: fragment path, area name, file/symbol counts, and any factual gaps observed.

## MUST READ

- The source tree of the target area (path passed inline by the orchestrator).
- The opaque temp output path (write target).

## MUST NOT READ

- `spec.md` — preserves the blindness rule (`SUBAGENTS.md` §5.1).
- `CONTEXT.md` and `CONTEXT.research-vocabulary.md` — the planned feature's vocabulary must NOT bias blind discovery.
- Any feature-folder artifact other than what the orchestrator explicitly names. The fragment must reflect the codebase as it stands, not the planned change.

## Failure Handling

If the target area is empty or the path is invalid, return `status: partial` with `next_actions: [provide valid area path]`. Do not synthesize findings from imagination.
