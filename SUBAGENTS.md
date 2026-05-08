# CRISPY Sub-Agent Orchestration Protocol

> Status: Authoritative. Every CRISPY agent that spawns other agents MUST follow this protocol.

The CRISPY framework uses **sub-agents** to keep contexts clean, run independent work in parallel, and validate decisions before they compound. This document defines the contract every spawn site obeys.

---

## 1. Roles

CRISPY orchestrators and their orchestration modes are documented in [README §Modes](../README.md#modes). This section defines the role table.

| Role | Who spawns | Concurrency | Purpose |
|---|---|---|---|
| **Orchestrator** | User | n/a | `crispy` (planning) and `crispy-implement` (execution). Owns the workflow, fans out work. |
| **Phase agent** | Orchestrator | sync (mostly) | `crispy-clarify`, `crispy-research`, `crispy-intent`, `crispy-structure`, `crispy-plan`, `crispy-yield`. Each owns one CRISPY phase. |
| **Internal explorer** | Phase agent | parallel | `explore` sub-agents the Research phase fans out to (one per area/repo) when the fan-out threshold is hit. |
| **Reviewer (spec)** | Orchestrator / `crispy-implement` | sync | `spec-review` agent focused on correctness vs spec/intent/contracts. Invoked at gates. |
| **Reviewer (code)** | Orchestrator / `crispy-implement` | sync | `code-review` agent focused on quality, idioms, security. Runs after `spec-review` at the same gate. |
| **Implementer pair** | `crispy-implement` | sync per slice | `test-author` (writes failing tests, RED verified) → `implementer` (makes tests pass, GREEN verified) → `spec-review` → `code-review`. |
| **Utility** | Orchestrator | sync | `crispy-scan`; `create-workspace` skill for focused multi-root workspaces. |

**Primary fan-out rule:** The orchestrator (`crispy` or `crispy-implement`) is the primary spawner. Phase agents only fan out internally for clearly bounded work — currently only the researcher, only when the fan-out threshold is met.

### 1.1 Model Recommendations

By default, Copilot CLI subagents use a low-cost model. Quality-sensitive phases benefit from a higher-capability model. The spawner MAY pass a `model` hint when invoking the sub-agent.

| Role / Agent | Recommended model | Rationale |
|---|---|---|
| `spec-review` (reviewer) | Higher-capability (e.g., Sonnet-class or above) | Spec/contract/requirement-coverage judgment requires strong reasoning. |
| `code-review` (reviewer) | Higher-capability | Security and design-quality findings degrade quickly on low-cost models. |
| `crispy-intent` | Higher-capability | Architecture analysis with 3 options + recommendation requires strong reasoning. |
| `crispy-research` (aggregation) | Default is acceptable | Aggregation is mostly mechanical (merge + dedup). |
| `test-author` | Default is acceptable | Test generation from clear checkpoint criteria is well-scoped. |
| `implementer` | Default or higher | Depends on slice complexity. Default for S-effort slices; consider higher for M/L. |
| `explore` (fan-out) | Default | Read-only exploration is well-suited to low-cost models. |
| `crispy-clarify`, `crispy-structure`, `crispy-plan`, `crispy-yield` | Default is acceptable | Structured output from clear inputs. |

These are recommendations, not hard requirements. The orchestrator should respect any user-specified model override (e.g., `model:claude-opus-4.5` in the invocation). Cost-conscious users can ignore these hints — the protocol works with any model, but quality-sensitive gates (`spec-review`, `code-review`, `crispy-intent`) are the most likely to degrade on low-cost models.

---

## 2. Prompt Contract (Input)

Every sub-agent prompt MUST contain these blocks, in this order. Use `templates/subagent-prompt.template.md` as the skeleton.

1. **Role** — one line: which agent type this is (e.g., `crispy-research`, `spec-review`, `explore`).
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

### Forward-Compatibility Reservation

The `crispy-result` fence label is reserved by CRISPY and SHALL NOT be renamed. Any runtime `task_complete`-style summary is a separate, wire-level artifact emitted at the protocol layer; whether (and how) it interacts with message-body content is empirically variable and outside CRISPY's control. The literal label `crispy-result` (not `task_complete` or any other reserved word) is preserved precisely so that a future runtime version that begins sniffing message bodies for completion shapes cannot collide with the fence label by accident.

---

## 4. Background vs Sync

Use **background** spawning when:
- The orchestrator can do meaningful, non-conflicting work in the same wall-clock window.
- The sub-agent's output is not needed for the next ~3 steps.
- Example: kick off `crispy-research` in the background as soon as Clarify identifies the area to research; orchestrator continues clarifying questions while research runs.

Use **sync** spawning when:
- The next step needs the sub-agent's result.
- The sub-agent is a reviewer (`spec-review` or `code-review`) — the gate must complete before continuing.
- The sub-agent is small enough that the wait is shorter than coordination overhead.

**Never** background a writer whose artifact a sibling sub-agent is about to read.

**UX cue (long-running spawns).** Background sub-agents (and any sync sub-agent whose wall time exceeds 30s) should be accompanied by an orchestrator-side note that the user can press `ctrl+x → b` (Copilot CLI changelog 5) to send the running task to the background and continue interacting. Orchestrators emit this hint once per session when the first long-running spawn occurs.

**Project-workstream conformance.** All project-level orchestrators (`crispy-project`, `crispy-vision`, `crispy-domain-research`, `crispy-feature-map`, `crispy-roadmap`, `crispy-architecture`, `crispy-scaffold`, `crispy-project-yield`) follow the same spawn rules above. Project-orchestrator body text (mode mappings, fleet semantics, `chain: true` autopilot semantics) MUST use canonical vocabulary from §13 — references to runtime Fleet must cite §5.3 *Fleet Identity* rather than re-deriving the layered-above decision per orchestrator. The 7 internal project-workstream agents carry `infer: false` (the public `crispy-project` does not — see [README §Modes](../README.md#modes)).

---

## 5. Fan-out Rules

### 5.1 Researcher internal fan-out

The researcher fans out to multiple `explore` sub-agents when **areas ≥ 3 OR repos ≥ 2**. Below threshold, it does the work itself.

- One sub-agent per area or repo. Each writes a partial-research markdown fragment to a temp file.
- Researcher then runs the `aggregate-research` skill to merge fragments into the single `research.md`.
- Each fan-out sub-agent inherits the **blindness rule**: it MUST NOT read the spec or the feature goal.

### 5.2 Implement-time slice fan-out

`crispy-implement` reads the slice dependency graph from the `implementation-manifest.yaml`. When **≥ 2 slices have no pending dependencies**, it recommends `autopilot_fleet`. In non-autopilot mode it asks the user; in autopilot it proceeds with the fleet.

Each slice in the manifest includes `automation: HITL | AFK` and `automation_reason`. Before starting any `automation: HITL` slice in autopilot or fleet mode, `crispy-implement` pauses and prompts the user for confirmation. `automation: AFK` slices proceed immediately. This ensures safety-critical slices (those touching orchestration, manifest semantics, review gates, blindness rules, or dangerous commands) receive explicit human review before proceeding.

**Loading note:** CRISPY agents are loaded via `~/.copilot/settings.json` + `plugin.json` registration. The runtime also discovers `.github/instructions/*.instructions.md` files in consuming repos. `~/.claude/` is excluded per Copilot CLI changelog 36/70. See [README §Loading Model](../README.md#loading-model) for details.

### 5.3 Fleet Identity (CRISPY `mode:fleet` vs Copilot CLI `/fleet`)

CRISPY's `mode:fleet` is **layered above** the Copilot CLI runtime — it is NOT a delegation to the official Fleet agent. Evidence: `mode:fleet` is referenced 9 times across CRISPY agent and skill source files; the runtime `/fleet` command is referenced 0 times. Migration to runtime-Fleet would lose the `git worktree` isolation and the DAG-aware conflict detection that CRISPY's slice graph provides (changelog 82 documents the runtime Fleet agent; changelog 73 documents the Task-tool `MULTI_TURN_AGENTS` semantics CRISPY relies on).

CRISPY borrows three behaviors from the runtime Fleet pattern without delegating:

- **B-1: hide sub-agent thinking** from the main timeline; surface only `crispy-result` summaries to the orchestrator.
- **B-2: surface background progress** via `read_agent` when a backgrounded sub-agent emits an interim `crispy-signal` block.
- **B-3: emit per-wave `task_complete`-style summary** at the end of each fleet wave (slice-completion banner with task counts, durations, and any HITL pauses).

**Project workstream:** the `crispy-project` orchestrator's `chain: true` autopilot path is the **project-workstream** analog of `autopilot_fleet`. It walks the feature DAG and spawns one `crispy.agent.md` per feature (independent features fan out as a feature-fleet). The same layered-above identity decision applies — `crispy-project` runs at the CRISPY layer, never delegates to runtime Fleet, and inherits B-1/B-2/B-3 borrow semantics analogously per project-feature wave.

---

## 6. Severity Vocabulary (Reviewer Gating)

`spec-review`, `code-review`, and any other reviewer MUST classify each finding using this fixed vocabulary. Both reviewers share the same vocabulary and the same Mandatory High classes; the orchestrator gates on the **union** of `high` findings from both passes.

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

| Site | Caller | Mode | Sub-agent | Trigger | Runtime primitive |
|---|---|---|---|---|---|
| 1. `crispy` → `crispy-clarify` | `crispy` | sync | `crispy-clarify` | Phase 1 entry | Task tool (sync) |
| 2. Background research | `crispy` | background | `crispy-research` | Area identified during Clarify | Task tool (background) [^1] |
| 3. Research sync fallback | `crispy` | sync | `crispy-research` | Signal never fired | Task tool (sync) |
| 4. `crispy` → `crispy-intent` | `crispy` | sync | `crispy-intent` | Phase 3 entry | Task tool (sync) |
| 5. Intent review gate | `crispy` | sync | `spec-review` then `code-review` | After `intent.md` written | Task tool (sync) × 2 |
| 6. Cross-repo scan | `crispy` | sync | `crispy-scan` | During Intent (multi-repo mode) | Read Agent tool [^1] |
| 7. Workspace setup | `crispy` | sync (skill) | `create-workspace` | After Intent confirms multiple affected repos | n/a (sync prose) |
| 8. `crispy` → `crispy-structure` | `crispy` | sync | `crispy-structure` | Phase 4 entry | Task tool (sync) |
| 9. `crispy` → `crispy-plan` | `crispy` | sync | `crispy-plan` | Phase 5 entry | Task tool (sync) |
| 10. Plan review gate | `crispy` | sync | `spec-review` then `code-review` | After `plan.md` + `tasks.md` written | Task tool (sync) × 2 |
| 11. `crispy` → `crispy-yield` | `crispy` | sync | `crispy-yield` | Phase 6 entry | Task tool (sync) |
| 12. Hand-off to implement | `crispy` | sync | `crispy-implement` | Autopilot `chain: true` | Task tool (sync) |
| 13. Internal area split | `crispy-research` | parallel | `explore` × N | areas ≥ 3 OR repos ≥ 2 | Task tool (parallel) |
| 14. Research aggregation | `crispy-research` | sync (skill) | `aggregate-research` | After fan-out fragments return | n/a (sync prose) |
| 15. `crispy-project` → `crispy-vision` | `crispy-project` | sync | `crispy-vision` | Project Phase 1 entry | Task tool (sync) |
| 16. Background domain research | `crispy-project` | background | `crispy-domain-research` | `domain_area_identified` signal | Task tool (background) [^1] |
| 17. Domain research sync fallback | `crispy-project` | sync | `crispy-domain-research` | Signal never fired | Task tool (sync) |
| 18. `crispy-project` → `crispy-architecture` | `crispy-project` | sync | `crispy-architecture` | Project Phase 3 entry | Task tool (sync) |
| 19. Architecture review gate | `crispy-project` | sync | `spec-review` then `code-review` | After `architecture.md` written | Task tool (sync) × 2 |
| 20. Repo scaffold | `crispy-project` | sync | `crispy-scaffold` | After architecture gate passes | Task tool (sync) |
| 21. `crispy-project` → `crispy-feature-map` | `crispy-project` | sync | `crispy-feature-map` | Project Phase 4 entry | Task tool (sync) |
| 22. Feature-map review gate | `crispy-project` | sync | `spec-review` then `code-review` | After `feature-map.md` written | Task tool (sync) × 2 |
| 23. `crispy-project` → `crispy-roadmap` | `crispy-project` | sync | `crispy-roadmap` | Project Phase 5 entry | Task tool (sync) |
| 24. Roadmap review gate | `crispy-project` | sync | `spec-review` then `code-review` | After `roadmap.md` written | Task tool (sync) × 2 |
| 25. `crispy-project` → `crispy-project-yield` | `crispy-project` | sync | `crispy-project-yield` | Project Phase 6 entry | Task tool (sync) |
| 26. Feature hand-off / Feature fleet | `crispy-project` | sync OR parallel | `crispy.agent.md` × N | Autopilot `chain: true` | Task tool (sync OR parallel) |
| 27. Slice implementation (sequential) | `crispy-implement` | sync per slice | `run-tdd-slice` (skill) | Sequential per-slice loop | n/a (sync prose) |
| 28. Slice fleet | `crispy-implement` | parallel | `run-tdd-slice` × N | Fleet wave | Task tool (parallel) |
| 29. TDD: test-author | `run-tdd-slice` | sync | `test-author` | Step 1 of TDD loop | Task tool (sync) |
| 30. TDD: implementer | `run-tdd-slice` | sync | `implementer` | Step 3 of TDD loop | Task tool (sync) |
| 31. TDD: spec-review | `run-tdd-slice` | sync | `spec-review` | Step 5 of TDD loop | Task tool (sync) |
| 32. TDD: code-review | `run-tdd-slice` | sync | `code-review` | Step 5b of TDD loop | Task tool (sync) |
| 33. Finish implementation branch | `crispy-implement` | sync (skill) | `finish-branch` | After last slice succeeds | n/a (sync prose) |
| 34. Scaffold delegation | `crispy-scaffold` | sync (skill) | `scaffold-repos` | Always (this agent delegates entirely) | n/a (sync prose) |
| 35. Worktree cleanup | `finish-branch` | sync (skill) | `git-worktree-isolation` (cleanup) | When `worktree_path` was provided | n/a (sync prose) |
| 36. Worktree isolation | `crispy-implement` | sync (skill) | `git-worktree-isolation` | Per-slice in fleet mode | n/a (sync prose) |

[^1]: Target primitive — currently emulated by Task tool. See `agent-orchestration.txt` for the runtime's evolving sub-agent invocation surface.

---

## 10. Anti-Patterns

- ❌ Orchestrator re-doing the work of a sub-agent because it didn't trust the summary.
- ❌ A phase agent spawning `spec-review` or `code-review` itself (only the orchestrator gates).
- ❌ Spawning a single legacy `rubber-duck` reviewer at a gate — protocol now requires the **two-stage** `spec-review` then `code-review` pair (§6, §9). The `rubber-duck` role was removed from the metrics classifier in `_crispy-metrics-common.{sh,ps1}` as part of feature 002 (AMD-001) — there are no remaining spawn sites in the protocol, and references in older artifacts should be migrated to the two-stage pair. The two new role-agent files `agents/spec-review.agent.md` and `agents/code-review.agent.md` (added in feature 002 S6) make the two-stage pair concrete.
- ❌ Background-spawning a writer whose output is needed in the very next step.
- ❌ Researcher fan-out sub-agents reading `spec.md` (breaks blindness).
- ❌ Reviewer using ad-hoc severity words ("nit", "critical", "🚨"). Use the §6 vocabulary.
- ❌ Sub-agents writing artifacts the orchestrator didn't authorize.
- ❌ Leaking the feature name or feature folder path into a blind sub-agent prompt (e.g., `crispy-docs/specs/003-graphql-support/`). Use opaque temp paths (e.g., `<workdir>/research-fragment-<uuid>.md`) and an `area:` description that does not contain the feature name.
- ❌ **Spec-derived context leakage into blind Research** (L2 source-learning traceability): Passing `CONTEXT.md` content, feature goals, desired-state terms, or spec-derived vocabulary into blind Research or `explore` prompts. This is a **high-severity blindness violation**. Research discovers only codebase-observed vocabulary with evidence and writes only to `CONTEXT.research-vocabulary.md`.
- ❌ Creating one repo-wide feature branch across all affected repos during planning. Branch creation is deferred to implementation, and only per-slice worktree branches are automatic.
- ❌ **Horizontal slicing within a slice** (L3): Batching "all tests first, then all implementations" inside a single slice. Each distinct behavior must complete its full RED → GREEN → review cycle before the next behavior's tests are written. Reviewers should flag tests for future behaviors, premature abstractions, or broad unrelated edits as implementation-boundary violations.

---

## 11. Project Workstream (Greenfield)

The CRISPY plugin ships **two parallel orchestrators**:

| Orchestrator      | Workstream | Entry point        | Folder root              | When to use                                                            |
|-------------------|------------|--------------------|--------------------------|------------------------------------------------------------------------|
| `crispy`          | Feature    | `@crispy`          | `crispy-docs/specs/`     | Adding/changing features in an existing codebase.                      |
| `crispy-project`  | Project    | `@crispy-project`  | `crispy-docs/projects/`  | Greenfield builds, multi-feature programs, "from scratch" architectures.|

Both follow this protocol verbatim — same prompt contract (§2), same `crispy-result` shape (§3), same severity gating (§6), same background-vs-sync rules (§4), same failure handling (§8).

### 11.1 Project-level role table (extends §1)

| Role                  | Agent                       | Spawned by         | Concurrency | Purpose                                                                                                  |
|-----------------------|-----------------------------|--------------------|-------------|----------------------------------------------------------------------------------------------------------|
| Project orchestrator  | `crispy-project`            | User               | n/a         | Owns the project-level 6 phases; decomposes into features; chains into per-feature `crispy` runs.        |
| Project Clarify       | `crispy-vision`             | `crispy-project`   | sync        | Produces `vision.md`. May emit `domain_area_identified` interim signal.                                  |
| Project Research      | `crispy-domain-research`    | `crispy-project`   | sync or bg  | Produces `domain-research.md`. **Blind to `vision.md`.** Internal fan-out at areas ≥ 3.                  |
| Project Intention     | `crispy-architecture`       | `crispy-project`   | sync        | Produces `architecture.md` with stable section anchors that feature-level intents inherit.               |
| Repo scaffold         | `crispy-scaffold`           | `crispy-project`   | sync        | Initializes local repos per `architecture.md §3, §4`. **No remote API calls** (locked default).          |
| Project Structure     | `crispy-feature-map`        | `crispy-project`   | sync        | Produces `feature-map.md` (DAG of features). Auto-splits oversized features (>10 estimated slices).     |
| Project Plan          | `crispy-roadmap`            | `crispy-project`   | sync        | Produces `roadmap.md` (milestones + parallel waves; no calendar dates).                                  |
| Project Yield         | `crispy-project-yield`      | `crispy-project`   | sync        | Produces `project-checklist.md` and `project-manifest.yaml` (machine-readable hand-off).                |

### 11.2 Project-level spawn sites (extends §9)

| Site                            | Caller                | Mode        | Sub-agent                         | Trigger                                                       |
|---------------------------------|-----------------------|-------------|-----------------------------------|---------------------------------------------------------------|
| Background domain research      | `crispy-project`      | background  | `crispy-domain-research`          | `domain_area_identified` signal during Vision (Phase 1).      |
| Architecture review gate        | `crispy-project`      | sync        | `spec-review` then `code-review`  | After `architecture.md` written.                              |
| Repo scaffold                   | `crispy-project`      | sync        | `crispy-scaffold` (autopilot opt) | After architecture gate passes; only if user opts in (interactive) or autopilot. |
| Feature-map review gate         | `crispy-project`      | sync        | `spec-review` then `code-review`  | After `feature-map.md` written.                               |
| Roadmap review gate             | `crispy-project`      | sync        | `spec-review` then `code-review`  | After `roadmap.md` written.                                   |
| Feature hand-off (sequential)   | `crispy-project`      | sync (chain)| `crispy.agent.md` per feature     | Autopilot `chain: true`; one feature at a time.               |
| Feature fleet                   | `crispy-project`      | parallel    | `crispy.agent.md` × N             | Autopilot `chain: true`; ≥ 2 features in same wave with no pending project-level deps. |

### 11.3 Inherited project context (additive feature workstream changes)

When `@crispy <feature-folder>` is invoked with a path matching `**/crispy-docs/projects/NNN-*/features/MMM-*/`, the feature orchestrator detects the project parent and:

- Adds `<project-folder>/domain-research.md` to `crispy-research`'s inline context as `inherited_domain_research`. The researcher then scopes blind code analysis to the (now-scaffolded) repo only and skips redundant domain queries. Blindness against `spec.md` is unchanged.
- Adds `<project-folder>/architecture.md` to `crispy-intent`'s MUST READ. Intent must reference architecture sections by anchor and MUST NOT contradict project-level decisions; the two-stage review gate enforces this.

Standalone feature runs (no project parent) are byte-for-byte unchanged.

### 11.4 Auto-split rule for oversized features

`crispy-feature-map` estimates a slice count per feature. If the estimate exceeds **10 slices**, the feature is auto-split into sibling features (e.g., `payments-core` + `payments-refunds`). Each child carries `auto_split_from: <parent-name>` in the machine-readable graph and an entry in the **Auto-Split Log**. Combined with `crispy-structure`'s soft cap of 3–8 slices per feature, this keeps every feature within the existing slice-execution pipeline.

### 11.5 Anti-patterns (extends §10)

- ❌ Project orchestrator re-running phase work inline instead of spawning the appropriate project-level agent.
- ❌ `crispy-domain-research` reading `vision.md` (breaks blindness — same rule as feature-level researcher and `spec.md`).
- ❌ `crispy-feature-map` enumerating features the project's themes don't cover.
- ❌ `crispy-roadmap` including calendar dates or time estimates.
- ❌ `crispy-scaffold` calling remote APIs (locked default: local-only).
- ❌ Feature-level `crispy-intent` overriding decisions in the inherited `architecture.md` without flagging a `high` finding first.
- ❌ Re-deriving `feature_graph` from `feature-map.md` prose instead of using the verbatim block in `project-manifest.yaml`.

---

## 12. Reference

- Prompt skeleton: `templates/subagent-prompt.template.md`
- Spawn skill: `skills/spawn-subagent/SKILL.md`
- Aggregation skill: `skills/aggregate-research/SKILL.md`
- TDD slice skill: `skills/run-tdd-slice/SKILL.md`

---

## 13. Runtime Mode Mapping

The CRISPY framework operates across three runtime modes and several CRISPY-layer orchestration states. The canonical mode mapping lives in [README §Modes](../README.md#modes); this table shows how CRISPY phases map to runtime modes.

| CRISPY Phase | Runtime Mode | Notes |
|---|---|---|
| Planning phases (Clarify, Research, Intent, Structure, Plan, Yield) | `agent` mode (non-interactive) | The orchestrator (`crispy`, `crispy-project`) runs in `agent` mode and spawns phase agents. User invocation determines interactive vs autopilot at the orchestrator level. |
| Implementation slice execution (sequential) | `agent` mode (non-interactive) | `crispy-implement` spawns TDD quad per slice. |
| Implementation slice execution (fleet) | `autopilot` mode or `agent` mode (non-interactive) | Fleet waves use Task tool (parallel); each slice runs in its own worktree. The runtime's Fleet agent is NOT invoked — CRISPY's fleet is layered above per §11.3 borrow list. |
