# CRISPY Sub-Agent Orchestration Protocol

> Status: Authoritative. Every CRISPY agent that spawns other agents MUST follow this protocol.

The CRISPY framework uses **sub-agents** to keep contexts clean, run independent work in parallel, and validate decisions before they compound. This document defines the contract every spawn site obeys.

---

## 1. Roles

| Role | Who spawns | Concurrency | Purpose |
|---|---|---|---|
| **Orchestrator** | User | n/a | `crispy` (planning) and `crispy-implement` (execution). Owns the workflow, fans out work. |
| **Phase agent** | Orchestrator | sync (mostly) | `crispy-clarify`, `crispy-research`, `crispy-intent`, `crispy-structure`, `crispy-plan`, `crispy-yield`. Each owns one CRISPY phase. |
| **Internal explorer** | Phase agent | parallel | `explore` sub-agents the Research phase fans out to (one per area/repo) when the fan-out threshold is hit. |
| **Reviewer** | Orchestrator / `crispy-implement` | sync | `rubber-duck` agent invoked at gates. |
| **Implementer pair** | `crispy-implement` | sync per slice | `test-author` (writes failing tests) → `implementer` (makes tests pass) → `rubber-duck` (reviews). |
| **Utility** | Orchestrator | sync | `crispy-scan`, `crispy-branch`. |

**Primary fan-out rule:** The orchestrator (`crispy` or `crispy-implement`) is the primary spawner. Phase agents only fan out internally for clearly bounded work — currently only the researcher, only when the fan-out threshold is met.

---

## 2. Prompt Contract (Input)

Every sub-agent prompt MUST contain these blocks, in this order. Use `templates/subagent-prompt.template.md` as the skeleton.

1. **Role** — one line: which agent type this is (e.g., `crispy-research`, `rubber-duck`, `explore`).
2. **Goal** — one paragraph: the outcome the caller needs.
3. **Inputs** — explicit list of files to read (absolute or feature-folder-relative paths). If the agent must NOT read a file (e.g., research must not read `spec.md`), list it under `MUST NOT READ`.
4. **Scope guardrails** — what the sub-agent may and may not do (e.g., "read-only", "write only `research.md`", "do not invoke other sub-agents").
5. **Output contract** — the exact return shape (see §3).
6. **Failure handling** — what to do if a step fails (return a structured error vs. ask user vs. retry).

> If a block is missing, the spawn is non-conforming and should be rejected by the receiver.

---

## 3. Return Shape (Output)

Every sub-agent returns a final message containing a fenced ```` ```crispy-result ```` block at the end with this YAML schema:

```yaml
status: ok | partial | failed
agent: <agent-name>
artifact_path: <path or null>          # File written, if any
summary: |
  <2-6 line human summary of what was done>
findings:                               # Optional list; required for reviewers
  - severity: high | medium | low
    location: <file:line or section>
    description: <one sentence>
    suggested_action: <one sentence>
next_actions:                           # Optional. What the caller should do next.
  - <imperative one-liner>
metadata: {}                            # Free-form for caller use
```

**Why structured:** The orchestrator must decide gating (block / continue / ask user) without re-reading the artifact. Severity in `findings` drives autopilot behavior (see §6).

---

## 3.1 Interim Signals

In addition to the FINAL `crispy-result` block, an agent MAY emit one or more **interim signals** to the caller mid-message using a fenced ```` ```crispy-signal ```` block (NOT `crispy-result`). Signals are advisory: the caller is permitted (but not required) to act on them as soon as they appear, and the agent MUST still emit the standard final `crispy-result` block at the end of its message.

Schema:

```yaml
signal: <signal-name>
payload: { ... }
```

Currently-defined signal names:

| Signal | Emitter | Payload | Purpose |
|---|---|---|---|
| `research_area_identified` | `crispy-clarify` | `{ research_area: <area> }` | Authorize the orchestrator to background-spawn `crispy-research` while Clarify continues. |

Rules:

- A signal does NOT replace the final `crispy-result`. If an agent emits signals but no final `crispy-result`, the spawn is non-conforming (§3) and should be retried (§8).
- Callers MUST tolerate the absence of any signal — signals are opportunistic optimizations. A caller that depends on a signal must define the synchronous fallback path.
- Signal names are reserved: do not invent new signal names without adding them to this table.

**Streaming assumption:** Signals are useful only when the caller can observe the sub-agent's partial output mid-stream. This requires the sub-agent to be spawned **sync** and the runtime to support incremental output reading. If the runtime delivers the sub-agent's entire message as a single block (no streaming), signals collapse to no-ops — the caller will see them only after the final `crispy-result`, at which point the optimization window has closed. Every signal-dependent workflow MUST define a synchronous fallback path (per the rule above) so the workflow completes correctly regardless of streaming support.

---

## 4. Background vs Sync

Use **background** spawning when:
- The orchestrator can do meaningful, non-conflicting work in the same wall-clock window.
- The sub-agent's output is not needed for the next ~3 steps.
- Example: kick off `crispy-research` in the background as soon as Clarify identifies the area to research; orchestrator continues clarifying questions while research runs.

Use **sync** spawning when:
- The next step needs the sub-agent's result.
- The sub-agent is a reviewer (rubber-duck) — the gate must complete before continuing.
- The sub-agent is small enough that the wait is shorter than coordination overhead.

**Never** background a writer whose artifact a sibling sub-agent is about to read.

---

## 5. Fan-out Rules

### 5.1 Researcher internal fan-out

The researcher fans out to multiple `explore` sub-agents when **areas ≥ 3 OR repos ≥ 2**. Below threshold, it does the work itself.

- One sub-agent per area or repo. Each writes a partial-research markdown fragment to a temp file.
- Researcher then runs the `aggregate-research` skill to merge fragments into the single `research.md`.
- Each fan-out sub-agent inherits the **blindness rule**: it MUST NOT read the spec or the feature goal.

### 5.2 Implement-time slice fan-out

`crispy-implement` reads the slice dependency graph from `outline.md`. When **≥ 2 slices have no pending dependencies**, it recommends `autopilot_fleet`. In non-autopilot mode it asks the user; in autopilot it proceeds with the fleet.

---

## 6. Severity Vocabulary (Reviewer Gating)

`rubber-duck` and other reviewers MUST classify each finding using this fixed vocabulary:

| Severity | Definition | Autopilot behavior |
|---|---|---|
| **high** | Bug, security flaw, contract violation, missing requirement, or design choice that will break a downstream phase. | **Block.** Orchestrator must stop and surface to the user. |
| **medium** | Risk, ambiguity, or missing edge case that won't break the current artifact but should be fixed before implementation. | Append to artifact `## Reviewer Findings` section, continue. |
| **low** | Style, naming, minor clarity. | Append to artifact `## Reviewer Findings` section, continue. |

In **interactive mode**, all severities are surfaced to the user before continuing past the gate.

### Mandatory High classes

Certain finding classes MUST be classified as `high` regardless of perceived likelihood or impact at first glance. Reviewers MUST escalate findings in any of these classes to `high`:

- **Security vulnerability** — auth bypass, injection (SQL/command/template), secret leak, missing authorization, unsafe deserialization, etc.
- **Privacy / PII handling defect** — PII written to logs, telemetry, or unauthorized stores; missing redaction; cross-tenant leakage.
- **Data loss or destructive operation without confirmation** — unguarded `DELETE`/`DROP`, unconfirmed file removal, irreversible state change without idempotency or rollback.
- **Schema or API contract break** — divergence from an existing contract under `contracts/` (request/response shape, status codes, field semantics, breaking enum change).
- **Missing P1 requirement coverage** — a P1 user story or acceptance criterion in `spec.md` has no corresponding implementation path or test.
- **Unsafe or irreversible migration** — schema migration without backward-compatible read path, no rollback script, or destructive backfill without dry-run.

These are floors, not ceilings: a finding may still be `high` for other reasons. But a finding that fits any class above MAY NOT be downgraded to `medium` or `low`.

---

## 7. Context Discipline

- A sub-agent receives only what its prompt declares in `Inputs`. Do not bulk-paste artifacts.
- The orchestrator does NOT re-read what a sub-agent already summarized in `crispy-result`. Trust the structured summary; only re-read the artifact if a finding requires it.
- A sub-agent does not load files outside its `Scope guardrails`. If it needs more context, it returns `status: partial` with `next_actions: [request additional input]`.

---

## 8. Failure Handling

| Failure | Sub-agent returns | Orchestrator behavior |
|---|---|---|
| Tool/runtime error (one shot) | `status: failed` + reason | Wait 5–10 seconds, then retry once with same prompt. |
| Persistent failure | `status: failed` after retry | Surface to user with the failure summary; do not silently fall back. |
| Missing input | `status: partial` + `next_actions: [provide X]` | Provide the missing input and re-spawn, or ask user. |
| Reviewer found `high` | `status: ok`, `findings[*].severity: high` | Block; ask user how to proceed. |
| Sub-agent went out of scope | `status: ok` but produced unexpected artifacts | Discard out-of-scope output, log, re-spawn with tightened guardrails. |

**Backoff rule:** The 5–10 second wait before retry helps avoid transient failures caused by rate limiting, temporary network issues, or resource contention. The wait applies to both sub-agent spawns and direct tool/command invocations within skills (e.g., the flake retry in `run-tdd-slice` step 4).

## 8.1 Timeout Policy

| Spawn mode | Timeout | Action on timeout |
|---|---|---|
| **Sync** | 10 minutes wall-clock | Treat as `status: failed`. Apply the §8 retry rule (with backoff). If the retry also times out, surface to the user. |
| **Background** | 15 minutes wall-clock | Check progress via `read_agent`. If no new tool calls since last check, treat as stuck → cancel the agent, treat as `status: failed`, apply §8 retry. |
| **Fleet wave** | 20 minutes per wave | If any slice in the wave exceeds 20 minutes, cancel it. Allow remaining slices to complete. Surface the timed-out slice as `status: failed` with a timeout reason. |

Timeouts are safety nets for infrastructure failures (hung processes, unresponsive LLM). They should rarely trigger under normal operation. If a phase routinely approaches the timeout, the work should be split into smaller units.

---

## 9. Spawn Sites (Reference)

| Site | Caller | Mode | Sub-agent | Trigger |
|---|---|---|---|---|
| Background research | `crispy` | background | `crispy-research` | Area identified during Clarify |
| Internal area split | `crispy-research` | parallel | `explore` × N | areas ≥ 3 OR repos ≥ 2 |
| Intent review gate | `crispy` | sync | `rubber-duck` | After `intent.md` written |
| Plan review gate | `crispy` | sync | `rubber-duck` | After `plan.md` + `tasks.md` written |
| Cross-repo scan | `crispy` | sync | `crispy-scan` | During Intent (multi-repo mode) |
| Auto branch setup | `crispy` | sync | `crispy-branch` (non-interactive) | After Intent confirms repos (autopilot) |
| Slice implementation | `crispy-implement` | sync per slice (or fleet) | `test-author` → `implementer` → `rubber-duck` | Each slice in `outline.md` |
| Slice fleet | `crispy-implement` | parallel | one TDD pair per independent slice | ≥ 2 slices with no pending deps |

---

## 10. Anti-Patterns

- ❌ Orchestrator re-doing the work of a sub-agent because it didn't trust the summary.
- ❌ A phase agent spawning rubber-duck itself (only the orchestrator gates).
- ❌ Background-spawning a writer whose output is needed in the very next step.
- ❌ Researcher fan-out sub-agents reading `spec.md` (breaks blindness).
- ❌ Reviewer using ad-hoc severity words ("nit", "critical", "🚨"). Use the §6 vocabulary.
- ❌ Sub-agents writing artifacts the orchestrator didn't authorize.
- ❌ Leaking the feature name or feature folder path into a blind sub-agent prompt (e.g., `crispy-docs/specs/003-graphql-support/`). Use opaque temp paths (e.g., `<workdir>/research-fragment-<uuid>.md`) and an `area:` description that does not contain the feature name.

---

## 11. Reference

- Prompt skeleton: `templates/subagent-prompt.template.md`
- Spawn skill: `skills/spawn-subagent/SKILL.md`
- Aggregation skill: `skills/aggregate-research/SKILL.md`
- TDD slice skill: `skills/run-tdd-slice/SKILL.md`
