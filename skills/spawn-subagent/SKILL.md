---
name: spawn-subagent
description: "Spawn a CRISPY sub-agent using the standard prompt skeleton and parse its structured result"
---

# Spawn a CRISPY Sub-Agent

Reusable wrapper around the spawn protocol defined in `SUBAGENTS.md`. Every CRISPY agent that needs to delegate work MUST go through this skill so the prompt contract (§2), background-vs-sync choice (§4), and result parsing (§3) stay consistent.

## When to use

- An orchestrator (`crispy`, `crispy-implement`) needs to delegate a phase, review, or implementation pair.
- A phase agent needs an internal fan-out that the protocol explicitly authorizes (currently only `crispy-research` when areas ≥ 3 OR repos ≥ 2 — see `SUBAGENTS.md` §5.1).

## When NOT to use

- The current agent could finish the work itself in less time than the spawn + result-parse round-trip.
- The would-be sub-agent has no clearly bounded scope (vague prompt → vague result).
- A phase agent wants to spawn a `rubber-duck` reviewer — only the orchestrator gates (§10).
- Researcher fan-out below the threshold: if **areas < 3 AND repos < 2**, the researcher does the work itself. Do NOT spawn `explore` sub-agents in that case.

## Process

### 1. Copy the prompt skeleton

Copy `C:\repos\crispy-plugin\templates\subagent-prompt.template.md` and fill in **all six required blocks**. Missing any block makes the spawn non-conforming and the receiver should reject it (§2).

The six mandatory blocks, in order:

1. **Role** — agent type on one line.
2. **Goal** — one paragraph describing the deliverable.
3. **Inputs** — explicit `MUST READ` list, plus a `MUST NOT READ` list when blindness or scope demands it.
4. **Scope guardrails** — May / Must NOT / Tooling restrictions.
5. **Output contract** — point to the `crispy-result` YAML schema; do not invent your own.
6. **Failure handling** — what to return on missing inputs, tool errors, or out-of-scope discoveries.

### 2. Choose background vs sync (`SUBAGENTS.md` §4)

Decide before spawning:

- **Background** when the caller has ≥ 3 useful steps to perform without the result, AND no sibling sub-agent will read the same artifact in that window.
- **Sync** when the next step depends on the result, when the sub-agent is a reviewer (gate must complete), or when the sub-agent is small enough that wait < coordination overhead.

Never background a writer whose artifact a sibling sub-agent is about to read (§4, §10).

### 3. Spawn

Invoke the sub-agent with the fully-filled prompt. For background spawns, record the agent ID so you can poll/read it after your in-window work completes.

### 4. Parse the `crispy-result` block

Every sub-agent ends its final message with a fenced ```` ```crispy-result ```` YAML block (§3). It MAY also emit zero or more interim ```` ```crispy-signal ```` blocks earlier in the message (§3.1).

When parsing:

- Scan the entire message for ```` ```crispy-signal ```` blocks first. Each is advisory — act on signals you recognize (e.g., `research_area_identified`) opportunistically, but never depend on a signal arriving. If the signal never appears, fall back to the synchronous path defined for that workflow.
- Then locate the FINAL ```` ```crispy-result ```` block. This is the authoritative gate. Extract:

- `status` — drives gating: `ok` → continue, `partial` → supply missing input and re-spawn (or ask user), `failed` → retry once then surface (§8).
- `artifact_path` — trust this; do NOT re-read the artifact unless a finding requires it (§7).
- `findings[*].severity` — apply the §6 vocabulary: `high` blocks autopilot, `medium`/`low` are appended to the artifact's `## Reviewer Findings` section.
- `next_actions` — execute or surface.

If the block is missing or malformed, treat the spawn as `failed` and retry once (§8).

If the sub-agent has not returned within the §8.1 timeout window, treat as `status: failed` and apply the retry rule with backoff.

### 5. Honor the failure table

Apply `SUBAGENTS.md` §8 verbatim. Do not silently fall back; do not loop forever.

## Worked example: orchestrator backgrounds research during Clarify

`crispy` has just finished the first round of Clarify questions and identified the area to research as `auth/session-handling` in repo `crispy-plugin`. It wants to keep clarifying while research runs.

1. Copy the skeleton, fill it in:

   ```markdown
   ## Role
   You are **crispy-research** (CRISPY Phase R: blind codebase research).

   ## Goal
   Produce `C:\repos\crispy-plugin\crispy-docs\session-refresh\research.md` documenting the current state of session/auth handling in this repo, written without knowledge of the feature goal.

   ## Inputs
   ### MUST READ
   - `C:\repos\crispy-plugin\` — source tree, read-only.
   ### MUST NOT READ
   - `C:\repos\crispy-plugin\crispy-docs\session-refresh\spec.md` — preserves blind research (§5.1).
   ### Context provided inline
   Area to research: `auth/session-handling`. Repo count: 1. (Below fan-out threshold — do the work yourself, do NOT spawn `explore` sub-agents.)

   ## Scope Guardrails
   - **May**: read source files, write the single `research.md` artifact.
   - **Must NOT**: read `spec.md`, spawn other sub-agents (below threshold), modify source code.

   ## Output Contract
   End with a `crispy-result` block per `SUBAGENTS.md` §3.

   ## Failure Handling
   Per template defaults.
   ```

2. Spawn **background** (mode = background; the orchestrator has ≥ 3 clarifying questions left to ask).
3. Continue Clarify. Do not poll mid-question.
4. When Clarify finishes, read the agent's `crispy-result`. On `status: ok`, move to Intent.

## Worked example: sync `rubber-duck` review gate

After `crispy-plan` writes `plan.md` and `tasks.md`, the orchestrator gates with `rubber-duck` before exiting Plan.

1. Fill skeleton with Role = `rubber-duck`, Goal = "Review plan.md and tasks.md against intent.md and spec.md; surface contract violations, missing requirements, and design choices that will break a downstream phase."
2. `MUST READ`: `intent.md`, `spec.md`, `plan.md`, `tasks.md`. Scope: read-only, findings only.
3. Output contract reminder: `findings[]` is **required** for reviewers, severity from §6 vocabulary only — no "nit" / "critical" / emoji (§10).
4. Spawn **sync**. Block on the result.
5. On any `severity: high`, halt and surface to user (§6, §8). On `medium`/`low`, append to `plan.md`'s `## Reviewer Findings` and continue.

## Reminders

- Six blocks. Always six. (§2)
- Trust the `crispy-result` summary; do not re-read the artifact "just to be sure" (§7, §10).
- Reviewer severity vocabulary is fixed: `high` / `medium` / `low` (§6).
- Researcher fan-out only when **areas ≥ 3 OR repos ≥ 2** (§5.1). Below threshold the researcher works alone.
