# 🧊 CRISPY Workflow — Copilot CLI Plugin

> **Clarify → Research → Intention → Structure → Plan → Yield**

A GitHub Copilot CLI plugin that implements the CRISPY framework for structured, high-quality AI-assisted software development. Produces spec-kit-style artifacts, **coordinates hidden sub-agents across phases** to keep contexts clean and parallelize work, drives slice-by-slice TDD execution after planning is done, and creates focused multi-repo workspaces without planning-time repo-wide branch creation. See the [installation verification checklist](crispy-docs/specs/002-official-cli-conformance/install-checklist.md) for loading-path acceptance tests.

> 🆕 **v0.2 — Sub-Agent Orchestration.** The orchestrator now spawns each phase as its own sub-agent, runs research in the background while clarification continues, gates with two-stage `spec-review` + `code-review` passes, and chains into a new `crispy-implement` agent that drives slice-by-slice TDD using sub-agent pairs. See [`SUBAGENTS.md`](./SUBAGENTS.md) for the protocol.
>
> 🆕 **v0.4 — Greenfield Project Workstream.** A second orchestrator, `@crispy-project`, drives the same 6 CRISPY phases at the **project** level: vision → domain-research → architecture (+ local repo scaffold) → feature-map (DAG of features, with >10-slice auto-split) → roadmap (milestones, no dates) → project-checklist/manifest. Each decomposed feature then runs through the existing `@crispy` workflow with **inherited project context** (architecture.md and domain-research.md become MUST-READ for feature-level Intent and Research). Both workstreams remain available standalone. See [`SUBAGENTS.md §11`](./SUBAGENTS.md).
>
> 🆕 **v0.5 — Focused Public Surface.** Only the top-level agents are user-invocable: `@crispy`, `@crispy-project`, and `@crispy-implement`. Phase agents and implementation helpers are hidden via `user-invocable: false` per the Agent Skills/custom agents docs. Repo-wide branch setup is deprecated; multi-repo planning now creates workspaces only, while implementation fleet mode uses per-slice worktree branches.

## Modes

CRISPY mode tokens map to official GitHub Copilot CLI modes as follows. The official mode vocabulary is defined in the [GitHub Copilot CLI documentation](https://docs.github.com/en/copilot/using-github-copilot/using-github-copilot-in-the-command-line) (see `agent-orchestration.txt` from the Copilot CLI runtime for the authoritative source).

| CRISPY token | Closest official mode | Relationship | Notes |
|---|---|---|---|
| (default invocation) | Interactive | alias | CRISPY interactive mode is the official Interactive mode. Confirmation prompts, full context. |
| `autopilot` | Autopilot | layered_above | CRISPY's autopilot adds severity-gated review behavior on top of official Autopilot. `continueOnAutoMode` is recommended for long runs. |
| `mode:fleet` | Fleet | divergent | CRISPY's fleet is a CRISPY-level concept layered above the runtime; it adds `git worktree` isolation + DAG-aware conflict detection. **NOT** the official Fleet. May borrow Fleet's "hide subagent thinking" semantic. |
| `autopilot_fleet` | Autopilot + Fleet | layered_above + divergent | Combination shorthand. Inherits both rows above. |
| `fast_mode` | (n/a) | divergent | Independent of any official mode; CRISPY-specific TDD-loop variant (skips test-author sub-agent). |

**Plan mode:** CRISPY does not currently invoke the official Plan mode explicitly. It could be a future fit for `crispy-clarify` → `crispy-plan` flows.

## Installation

```shell
# From GitHub repository
copilot plugin install your-org/crispy-plugin

# From local path
copilot plugin install ./crispy-plugin

# Verify installation
copilot plugin list
```

## Quick Start

### Two Workstreams

CRISPY ships two parallel orchestrators. Pick by **what kind of work you're doing**, not by team size or repo count:

| Workstream | Entry point        | Use when                                                          |
|------------|--------------------|-------------------------------------------------------------------|
| Feature    | `@crispy`          | Adding/changing a feature in an **existing codebase**.            |
| Project    | `@crispy-project`  | **Greenfield**, large-scale, multi-feature builds from scratch.   |

Both follow the same 6-phase CRISPY protocol with the same sub-agent orchestration; they differ in artifacts and the extra scaffold step in Phase 3.

### Greenfield Project Workflow

```
@crispy-project "Build a B2B invoicing platform from scratch"
```

The project orchestrator walks 6 PROJECT phases:

1. **Clarify** — `vision.md` (themes, MVP, constraints — NOT a feature list)
2. **Research** — `domain-research.md` (blind to vision; problem domain, prior art, regulatory, reference architectures)
3. **Intention** — `architecture.md` (tech stack, repos, service boundaries, data model) → then `crispy-scaffold` initializes local repos
4. **Structure** — `feature-map.md` (DAG of features; oversized features auto-split when estimate > 10 slices)
5. **Plan** — `roadmap.md` (milestones + parallel waves, **no calendar dates**)
6. **Yield** — `project-checklist.md` + `project-manifest.yaml`

Then per-feature: `@crispy crispy-docs/projects/NNN/features/MMM/` runs the standard CRISPY feature workflow with **inherited project context** (architecture.md + domain-research.md become MUST-READ for feature-level Intent and Research). Or invoke `@crispy-project autopilot chain:true` to walk the feature DAG automatically (independent features fan out as a feature-fleet).

> **Scaffold defaults (locked):** `crispy-scaffold` reads stack from `architecture.md`, asks only on ambiguity, initializes **local** git repos, and prints copy-paste commands for remote creation (e.g., `gh repo create …`) — it does NOT call remote APIs.

### Standalone Feature Workflow (Recommended for existing codebases)

```
@crispy "Add user authentication to the platform"
```

The orchestrator walks you through all 6 phases:
1. **Clarify** — Interactive decision-tree questioning (one question at a time with recommended answers), produces `spec.md` and optional `CONTEXT.md` for ubiquitous language
2. **Research** — Blind codebase analysis (no feature goal revealed), produces `research.md`
3. **Intention** — Architecture analysis with 3 options, produces `intent.md`
4. **Structure** — Vertical slices and checkpoints, produces `outline.md`
5. **Plan** — File-level tactical plan, produces `plan.md` + `tasks.md` + `contracts/`
6. **Yield** — Quality gate checklist, produces `checklist.md`

## Loading model

The CRISPY plugin loads into GitHub Copilot CLI via the standard plugin registration mechanism. Understanding the loading paths is critical for troubleshooting and ensuring your custom agents are discoverable.

### Plugin Registration

The plugin manifest (`plugin.json`) is referenced from `~/.copilot/settings.json`. When you run `copilot plugin install <path>`, the CLI adds an entry to this settings file pointing at the plugin's install location. The plugin name is `crispy-workflow` per `plugin.json`.

**Verify installation:** Run `copilot plugin list` to confirm `crispy-workflow` appears in the installed plugins.

### Repo-Scoped Instructions

The runtime automatically discovers `.github/instructions/*.instructions.md` files in any repository where you invoke Copilot CLI. Each instruction file uses frontmatter to scope itself to specific file patterns via the `applyTo` glob field (e.g., `applyTo: "**/*.test.ts"` for test files only).

CRISPY itself does not ship repo-scoped instructions in the plugin directory — these are user-authored per consuming repository. The plugin's shipped agents and skills are always available regardless of which repository you're working in.

### `~/.claude/` Exclusion

Per GitHub Copilot CLI changelog 36 and 70, custom agents placed in `~/.claude/` are **explicitly excluded** from the loading path. The runtime ignores this directory to avoid conflicts with Claude Desktop. CRISPY agents are installed via the plugin manifest and `~/.copilot/settings.json` only; they do NOT use `~/.claude/` for agent discovery.

If you have legacy agent definitions in `~/.claude/`, they will not shadow or interfere with CRISPY. The runtime's precedence order is: (1) plugin-shipped agents from `plugin.json`, (2) repo-scoped instructions from `.github/instructions/`, (3) `~/.claude/` excluded.

**Troubleshooting:** If CRISPY agents are not discoverable after `copilot plugin install`, verify `~/.copilot/settings.json` contains the correct path to `plugin.json` and that `plugin.json` references `agents: "agents/"`. Agents in `~/.claude/` will never be loaded.

### Public Agents

CRISPY intentionally exposes only three agents to keep the user-facing picker small:

| Agent | Use when |
|---|---|
| `@crispy` | Plan a feature in an existing codebase. |
| `@crispy-project` | Plan a greenfield multi-feature project. |
| `@crispy-implement` | Execute a completed feature plan slice-by-slice after Yield. |

All phase agents (`crispy-clarify`, `crispy-research`, `crispy-intent`, etc.) are internal implementation details. They remain installed so the orchestrators can spawn them, but they are hidden from user selection via `user-invocable: false` AND prevented from runtime auto-inference via `disable-model-invocation: true` (the official replacement for the now-retired `infer: false` key — see [Custom agents configuration](https://docs.github.com/en/copilot/reference/custom-agents-configuration)).

**Per-agent MCP attachment.** A custom agent may attach Model Context Protocol servers via an `mcpServers` block in its frontmatter, scoping which MCP capabilities the agent has access to. CRISPY uses this in `agents/crispy-clarify.agent.md` to attach the `workiq` MCP server (Microsoft 365 context for early Clarify research) without granting it to other phase agents that should remain blind to user M365 data:

```yaml
---
name: crispy-clarify
tools: ["execute", "edit", "read", "search", "workiq/*"]
user-invocable: false
disable-model-invocation: true
mcpServers:
  workiq:
    description: "Microsoft 365 context (emails, meetings, files) for early Clarify research"
---
```

This per-agent scoping is the recommended pattern for any MCP server that should be available to one role but not all roles.

### Path-scoped instructions (`.instructions.md`)

In addition to repo-scoped instructions under `.github/instructions/`, the Copilot CLI runtime also discovers **plugin-shipped instructions** under any directory listed in `plugin.json`'s `instructions` field. CRISPY ships one exemplar at `instructions/crispy-slice.instructions.md`.

Frontmatter schema (per `contracts/instructions-files.yaml`):

| Key | Required? | Description |
|---|:---:|---|
| `applyTo` | required | Glob pattern (e.g., `crispy-docs/specs/**/tasks.md`) — the runtime applies the instructions only when the active file matches. |
| `description` | required | One-liner (≤200 chars) describing what the instructions encode. |
| `priority` | optional | `low` \| `medium` \| `high` (default `medium`) — resolves ordering when multiple files match. |
| `model_hint` | optional | `default` \| `high-capability` (advisory) — hints the runtime about model selection for matching files. |

Example (`instructions/crispy-slice.instructions.md`):

```yaml
---
applyTo: "crispy-docs/specs/**/tasks.md"
description: "CRISPY slice-editing reminders for tasks.md files"
priority: medium
---
```

If `plugin.json` omits the `instructions` field, the runtime falls back to discovering `instructions/**/*.instructions.md` automatically.

### Hook delivery channels

CRISPY hooks are registered in `hooks.json` and run as either local script executions (the default) or remote HTTP calls (additive, opt-in).

**Script-based hooks** (default): each entry has a `bash` and/or `powershell` command line. The runtime invokes the script, which may emit either a `permissionDecision` JSON shape on stdout (see below) or signal `deny` via `exit 1`. CRISPY's `dangerous-command-guard.{sh,ps1}` uses the `exit 1` mechanism for backward-compat.

**HTTP hooks** (additive): a hook entry may also carry an `http` block that POSTs the runtime's tool-call payload to a remote URL. The remote service may return a `permissionDecision` JSON to gate the tool call, or `additionalContext` to enrich it. Per `contracts/http-hooks.yaml`:

| Field | Default | Notes |
|---|---|---|
| `http.url` | required | Endpoint receiving the JSON POST. |
| `http.timeoutMs` | `2500` | Per-hook timeout in milliseconds (range 100–30000). On timeout the runtime fails open. |
| `http.mode` | `http-and-local` | `http-only` skips the script; `http-and-local` runs both and merges decisions. |

**Failure semantics: `timeout-then-fail-open`.** If the HTTP POST times out, returns a non-2xx response, or fails with a network error, the runtime treats the hook as if it had not run (no `permissionDecision`, no `additionalContext`, no error to the agent). A `WARN`-level log line is emitted with `hookOutcome: 'http_timeout'` (or the equivalent failure-mode string). See [`contracts/http-hooks.yaml#failure_semantics`](contracts/http-hooks.yaml) FS-001..FS-006 for the full rule list. Worked example at `hooks/fixtures/http-hook-example.json`; fail-open demonstration at `hooks/fixtures/http-hook-fail-open.json`.

### `permissionDecision` JSON convention

Hook scripts may return a structured decision on stdout instead of (or in addition to) signalling via exit code. The canonical shape:

```json
{
  "permissionDecision": "allow" | "deny" | "ask",
  "reason": "<one-line explanation>"
}
```

The runtime parses this JSON when the hook exits 0; an `ask` decision triggers an interactive user prompt with the supplied `reason`. Hooks that exit non-zero (the `dangerous-command-guard.{sh,ps1}` mechanism) are treated as a hard deny without parsing stdout — both mechanisms are valid; `permissionDecision` is more expressive.

CRISPY's active `dangerous-command-guard.{sh,ps1}` retains the `exit 1` mechanism for backward-compat (NFR-001 / NFR-005). The reference example using the `permissionDecision` JSON shape lives at `hooks/scripts/examples/pre-branch-check.{sh,ps1}` — see `hooks/scripts/examples/README.md` for the worked walkthrough.

### Implementation Agent (post-Yield)

After Yield produces an `implementation-manifest.yaml`, run the implementation agent to actually build the feature:

```
@crispy-implement crispy-docs/specs/003-graphql-support/                  # default sequential TDD per slice
@crispy-implement crispy-docs/specs/003-graphql-support/ mode:fleet       # parallel slices when independent
@crispy-implement crispy-docs/specs/003-graphql-support/ mode:fast_mode   # skip the test-author sub-agent
```

`crispy-implement` walks the slice graph from the `implementation-manifest.yaml` and drives a TDD pair per slice:
**test-author** → **implementer** → **spec-review** → **code-review**, then runs build/lint/tests between slices.

Successful slice checkpoint commits include the manifest feature id as well as the slice number, e.g. `crispy: 003-graphql-support slice 2 — Resolver wiring`. Fleet-mode merge commits use the same feature-qualified convention, e.g. `Merge crispy 003-graphql-support slice 2`.

Each slice carries an `automation: HITL | AFK` classification. In autopilot or fleet mode, HITL (human-in-the-loop) slices pause for user confirmation before proceeding, ensuring safety-critical changes receive explicit human review. AFK (away-from-keyboard) slices proceed automatically.

### Public Skills

Most skills are internal implementation helpers and are hidden from the slash-command menu. The intentionally user-invocable skills are:

| Skill | Use when |
|---|---|
| `create-workspace` (`/crispy-workflow:create-workspace` in VS Code) | Recreate or open a focused multi-root workspace for confirmed affected repos. |
| `generate-metrics-report` (`/crispy-workflow:generate-metrics-report` in VS Code) | Generate static HTML reports from CRISPY metrics JSONL files. |

The deprecated `manage-branches` skill is hidden and disabled; it will not create branches if invoked.

### Autopilot Mode

Invoke the orchestrator in autopilot to skip interactive gate prompts:

```
@crispy autopilot "Add user authentication to the platform"
```

In autopilot:
- Each phase produces a 3–5 line **checkpoint summary** instead of asking for confirmation.
- Two-stage `spec-review` + `code-review` gates after Intent and Plan only block on `severity: high` findings (medium/low are appended to the artifact's `## Reviewer Findings` section, then continue).
- Multi-repo planning creates/opens a focused workspace automatically; it does **not** create, switch, pull, stash, or push repo-wide feature branches.
- `crispy-implement` auto-recommends **`autopilot_fleet`** when the slice graph shows ≥ 2 independent slices.

### Using with `/fleet`

CRISPY has its own parallel execution (`mode:fleet` on `crispy-implement`, with `autopilot_fleet` as the auto-recommended composite mode) that is **layered above** Copilot CLI's native `/fleet` command — it is not a delegation. See [SUBAGENTS.md §5.3 Fleet Identity](SUBAGENTS.md#53-fleet-identity-crispy-modefleet-vs-copilot-cli-fleet) for the full identity decision and the three behaviors CRISPY borrows from the runtime Fleet pattern (changelog 82 documents the runtime Fleet agent; changelog 73 documents the Task-tool `MULTI_TURN_AGENTS` semantics CRISPY relies on).

| Aspect | CRISPY `mode:fleet` (and `autopilot_fleet`) | Copilot CLI `/fleet` |
|:--|:--|:--|
| Spawn semantics | DAG-aware from slice dependency graph; one Task-tool background spawn per slice in a wave (changelog 73 `MULTI_TURN_AGENTS`) | AI auto-splits from prompt; runtime-managed parallel sub-agent fan-out (changelog 82) |
| Worktree handling | `git worktree` per slice via `git-worktree-isolation` skill — no silent overwrites; per-slice branch `crispy/<feature-id>/slice-<N>` | None; sub-agents share the working tree (last writer wins) |
| Summary aggregation | Per-wave summary banner (B-3) merging `crispy-result` blocks from each slice; HITL pauses surface explicitly | Runtime aggregation; subagent thinking hidden from main timeline (CRISPY borrows this as B-1) |
| Parallelism guarantees | Pre-wave file-set check + post-wave diff verification; `parallelizable: false` flag on contended same-file tasks | None — relies on prompt-level isolation |

**Recommendation:**
- Use `@crispy-implement mode:fleet` for slice execution — it has worktree isolation and conflict detection.
- Use `/fleet` for the planning phases if you want to parallelize independent work (e.g., multi-repo scans, bulk documentation generation) where file conflicts aren't a concern.
- Do NOT use `/fleet @crispy-implement` — let CRISPY manage its own parallelism via the slice dependency graph.

## Artifact Output

Artifacts are stored in a `crispy-docs` directory. Two top-level subfolders, one per workstream:

```
crispy-docs/
├── specs/                                 # Feature workstream
│   ├── 001-user-authentication/
│   │   ├── spec.md                       # C: User stories, requirements, acceptance criteria
│   │   ├── research.md                   # R: Blind codebase analysis (with optional fan-out merge)
│   │   ├── intent.md                     # I: Architecture direction, affected repos
│   │   ├── outline.md                    # S: Vertical slices + machine-readable slice dependency graph
│   │   ├── plan.md                       # P: File-level tactical plan + machine-readable task graph
│   │   ├── tasks.md                      # P: Task breakdown by user story
│   │   ├── checklist.md                  # Y: Quality gates, pre-implementation checks
│   │   ├── implementation-manifest.yaml  # Y: Hand-off manifest consumed by crispy-implement
│   │   ├── NNN-feature-name.code-workspace  # VSCode multi-root workspace (multi-repo only)
│   │   └── contracts/                    # API/interface contracts
│   │       └── auth-api.md
│   └── 002-graphql-support/
│       └── ...
└── projects/                              # Project workstream (greenfield)
    └── 001-acme-platform/
        ├── vision.md                     # C: Themes, MVP, constraints (NOT a feature list)
        ├── domain-research.md            # R: Blind problem-domain research (no vision leakage)
        ├── architecture.md               # I: Tech stack, repos, service boundaries (with stable section anchors)
        ├── scaffold-report.md            # I: Local repos initialized + remote-creation commands
        ├── feature-map.md                # S: Feature DAG + auto-split log
        ├── roadmap.md                    # P: Milestones + parallel waves (no dates)
        ├── project-checklist.md          # Y: Project-level quality gates
        ├── project-manifest.yaml         # Y: Hand-off manifest consumed by per-feature @crispy runs
        ├── review-gates.yaml
        └── features/
            ├── 001-user-accounts/        # Each feature inherits architecture.md + domain-research.md
            │   ├── spec.md ... implementation-manifest.yaml   # Standard feature artifacts
            │   └── contracts/
            └── 002-billing-core/
                └── ...
```

### Location Behavior

| Context | crispy-docs Location | Notes |
|:--------|:--------------------|:------|
| **Multi-repo root** (e.g., `D:\Repos\`) | `D:\Repos\crispy-docs\` | Sibling to all repos |
| **Inside a single repo** | `{repo-root}\crispy-docs\` | Auto-added to `.gitignore` |

Feature folders are auto-numbered (001, 002, 003...).

## Multi-Repo Support

When the orchestrator detects cross-repo impact:

1. **Auto-scans** sibling directories for git repositories
2. **Analyzes** which repos are affected based on feature + research
3. **Presents findings** for user confirmation
4. **Workspace setup** (if approved):
   - Creates a `.code-workspace` containing only `crispy-docs` and confirmed affected repos
   - Opens the workspace automatically in autopilot mode
   - Does not mutate git state

### VSCode Workspace

After affected repos are confirmed, CRISPY can generate a `.code-workspace` file in the feature folder containing only those repos plus `crispy-docs`. It then opens the workspace in VSCode so you can monitor code changes across all repos in one window.

The workspace file uses relative paths, so it works across machines if repo layouts are consistent.

### Branching

Planning no longer creates one feature branch across every affected repo. Sequential implementation uses the current clean branch. Fleet implementation creates temporary per-slice worktree branches (for example, `crispy/<feature-id>/slice-<N>`) and merges them back into the recorded integration branch after each wave. Slice checkpoint commits and fleet merge commits include `<feature-id>` so multiple CRISPY features remain distinguishable in Git history.

## CRISPY Framework Summary

| Phase | Artifact | AI Role | Your Role |
|:------|:---------|:--------|:----------|
| **C**larify | `spec.md` | Identifies knowledge gaps | Provides business context |
| **R**esearch | `research.md` | Maps existing truth (blind) | Verifies the "Truth" |
| **I**ntention | `intent.md` | Proposes architecture | Steers away from bad patterns |
| **S**tructure | `outline.md` | Defines vertical phases | Approves the "Checkpoints" |
| **P**lan | `plan.md` + `tasks.md` | Line-by-line tactics | Spot-checks for surprises |
| **Y**ield | `checklist.md` | Validates readiness | **Owns the code** |

### Key Principles

- **Blind Research**: The Research phase must NOT know the feature goal — this keeps analysis objective. Fan-out sub-agents inherit the same blindness rule.
- **Smart Zone**: Keep AI context below 40% — sub-agent delegation is the primary mechanism for this. The orchestrator trusts sub-agent `crispy-result` summaries instead of re-loading artifacts.
- **Vertical Slices**: Build end-to-end (DB → API → UI) in small, testable pieces. Independent slices run in parallel under `autopilot_fleet`.
- **No Slop**: Every line of generated code is reviewed by `spec-review` and `code-review` sub-agents before the slice is accepted.
- **Source-Learning Traceability**: Workflow improvements applied from public learnings (e.g., L1-L10 IDs in feature 001-pocock-learning-improvement) are explicitly documented and referenced in change context. Transcripts or captions unavailable due to platform limitations; requirements derived from public video framing and companion materials only.
- **No Horizontal Slicing (L3)**: Within each slice, implementation proceeds behavior-by-behavior through RED (failing tests) → GREEN (passing implementation) → review before the next behavior begins. Fleet mode parallelizes independent slices but forbids batching "all tests first, all implementations later" inside any slice worker. This discipline prevents premature abstractions, keeps test failures tightly scoped, and ensures reviewers can validate behavioral correctness incrementally.

### Sub-Agent Orchestration

The orchestrator (`crispy`) is the primary spawner. Phase agents run as sync or background sub-agents and return a structured `crispy-result` block. Reviewer findings use a fixed severity vocabulary (`high` / `medium` / `low`) so autopilot gating is deterministic.

| Spawn site | Mode | Trigger |
|:---|:---|:---|
| `crispy-research` (background) | bg | Area identified during Clarify |
| `explore` × N (researcher fan-out) | parallel | areas ≥ 3 OR repos ≥ 2 |
| `spec-review` then `code-review` after Intent | sync | After `intent.md` written |
| `spec-review` then `code-review` after Plan | sync | After `plan.md` + `tasks.md` written |
| `create-workspace` | sync | After Intent confirms multiple affected repos |
| `test-author (RED) → implementer (GREEN) → spec-review → code-review` | sync per slice | Each slice in `crispy-implement` |
| TDD pair × N (slice fleet) | parallel | ≥ 2 slices with no pending deps |

Full protocol — input contract, return shape, severity gating, failure handling, anti-patterns — is in [`SUBAGENTS.md`](./SUBAGENTS.md).

### Out of Scope

CRISPY is a **planning and implementation orchestration plugin** for GitHub Copilot CLI. The following are explicitly out of scope:

- **Direct orchestration of `gh copilot agent`**: CRISPY does not invoke the runtime's experimental `agent` command directly. Phase agents and the TDD implementation pair are spawned via the `task` tool (sync / background / parallel modes).
- **Autopilot wrapper**: CRISPY's `autopilot` mode is a CRISPY-level orchestration flag that gates reviewer findings and phase confirmations. It is not a wrapper around the runtime's Autopilot agent.
- **Re-implementing CRISPY's fleet on runtime Fleet**: CRISPY's `mode:fleet` is layered above the runtime and adds `git worktree` isolation + DAG-aware conflict detection. It does not delegate to the official Fleet agent (see [README §Modes](#modes) for the divergence note).
- **Repo-wide feature-branch creation at planning time**: Deprecated. Multi-repo planning now creates workspaces only. Implementation fleet mode uses per-slice worktree branches.
- **Calendar-dated project roadmaps**: `crispy-roadmap` sequences features into milestones with parallel waves but does NOT assign calendar dates or time estimates.

## Plugin Structure

```
crispy-plugin/
├── plugin.json                       # Plugin manifest
├── hooks.json                        # Hook config (delegates to hooks/scripts/*.sh + *.ps1)
├── hooks/scripts/                    # NEW — cross-platform hook scripts (bash + PowerShell pairs)
├── SUBAGENTS.md                      # Sub-agent orchestration protocol (authoritative)
├── agents/                           # 18 custom agents (3 public, 15 internal)
│   ├── crispy.agent.md               # Public: feature planning orchestrator
│   ├── crispy-project.agent.md       # Public: greenfield project orchestrator
│   ├── crispy-implement.agent.md     # Public: post-Yield TDD slice executor
│   ├── crispy-*.agent.md             # Internal phase agents (user-invocable: false)
│   ├── crispy-scan.agent.md          # Internal utility
│   └── crispy-branch.agent.md        # Deprecated, hidden, branch creation disabled
├── skills/                           # 25 reusable skills (2 public, 23 internal)
│   ├── create-spec/
│   ├── create-research/              # Now supports fan-out mode
│   ├── create-intent/
│   ├── create-outline/               # Emits slice dependency graph yaml
│   ├── create-plan/                  # Emits task graph yaml
│   ├── create-tasks/
│   ├── create-checklist/
│   ├── create-contracts/
│   ├── detect-repos/
│   ├── manage-branches/              # Deprecated, hidden, branch creation disabled
│   ├── init-crispy-docs/
│   ├── spawn-subagent/               # NEW — wraps the spawn protocol
│   ├── create-workspace/             # NEW — generates VSCode multi-root workspace for affected repos
│   ├── aggregate-research/           # NEW — merges fan-out research fragments
│   ├── run-tdd-slice/                # test-author (RED) → implementer (GREEN) → spec-review → code-review loop
│   ├── git-worktree-isolation/       # NEW — isolated worktrees for parallel slices
│   ├── finish-branch/                # NEW — verify, present PR/push/keep/discard, cleanup
│   └── generate-metrics-report/      # NEW — static HTML reports of token/time/premium-request usage per phase
├── templates/                        # 9 artifact templates
│   └── subagent-prompt.template.md   # NEW — required skeleton for every sub-agent prompt
└── .github/plugin/
    └── marketplace.json              # Marketplace manifest
```

## Configuration

The plugin works out of the box. Optional configuration:

- **Marketplace**: Update `.github/plugin/marketplace.json` with your org details
- **Hooks**: Customize `hooks.json` for metrics or lifecycle instrumentation


### Metrics & Reporting

CRISPY automatically captures per-phase **wall-clock time** and an **estimated premium-request count** for every CRISPY sub-agent invocation (via the bundled `crispy-metrics-start` / `crispy-metrics-record` hooks). Records land in `<feature-folder>/.metrics.jsonl`.

Generate static HTML reports at any time:

```shell
# VS Code chat
/crispy-workflow:generate-metrics-report

# Copilot CLI
skill generate-metrics-report
```

This writes one `metrics.html` per feature, one per project (rolling up its child features), and a top-level `crispy-docs/reports/index.html` index linking everything. Standalone features and projects each get their own page; everything is self-contained (no JS frameworks, no CDN).

- **Premium Requests** are computed as `invocations × per-model multiplier` using a built-in table aligned with [GitHub's billing docs](https://docs.github.com/en/copilot/how-tos/manage-and-track-spending/monitor-premium-requests). This is a **lower bound** because each sub-agent makes many internal LLM turns the hook cannot observe — cross-check the authoritative number at `github.com/settings/billing` → Premium Request Analytics.
- **Multipliers are overridable** via `crispy-docs/.metrics-multipliers.json`.
- **Disable capture** with `CRISPY_METRICS_DISABLED=1`.

### Hooks

Hook commands live in `hooks.json` and delegate to cross-platform scripts under `hooks/scripts/` (each hook ships a `.sh` + `.ps1` pair). Scripts read their JSON payload from stdin and may emit `{"permissionDecision": "deny", "permissionDecisionReason": "..."}` to block the tool call (see [hooks-configuration](https://docs.github.com/en/copilot/reference/hooks-configuration)).

Active hooks:

- `preToolUse: dangerous-command-guard` — **Safety guardrail** that blocks destructive operations (`git push`, `git reset --hard`, `git clean`, `git stash drop`, `rm -rf`, and detectable equivalents) before tool execution. If you genuinely need a blocked operation, exit CRISPY CLI and run the command directly in a standard shell. To disable (NOT RECOMMENDED): remove the guard hook from `hooks.json` or modify `hooks/scripts/dangerous-command-guard.{ps1,sh}`.
- `preToolUse: crispy-metrics-start` — records the start timestamp of every CRISPY sub-agent invocation (`task` tool) into `$TEMP/crispy-metrics-pending/`.
- `postToolUse: crispy-metrics-record` — pairs with the start record, computes elapsed time + token approximations + premium-request estimate, and appends a JSONL row to the owning feature/project's `.metrics.jsonl`. Disable with `CRISPY_METRICS_DISABLED=1`.
- `userPromptSubmit: inject-crispy-protocol` — telemetry only. Per the docs, `userPromptSubmit` output is ignored, so the protocol reminder lives in `templates/subagent-prompt.template.md` and `SUBAGENTS.md`, not in this hook.

**Dangerous-command guard details:**
- Blocked operations: `git push`, `git reset --hard`, `git clean -f/-fd/-fdx`, `git stash drop/clear`, `git branch -D/-d`, `git remote remove`, `git tag -d`, `rm -rf`, `Remove-Item -Recurse -Force`, `rd /s /q`, `del /f /s /q`, and pattern-equivalent forms.
- **Override path**: None built-in. If a blocked operation is genuinely required, document the reason, exit CRISPY CLI, and run it in a standard shell.
- **Why no override?** Allowing inline bypasses (e.g., `--force` flags) defeats the safety purpose. The friction of exiting the CLI ensures deliberate action.

See `hooks/scripts/dangerous-command-guard.fixtures.md` for tested examples of blocked and allowed commands.

### Two-stage review

Reviewer gates are split into `spec-review` (correctness vs spec/intent/contracts) and `code-review` (quality, idioms, security). Both share the same severity vocabulary (`high` / `medium` / `low`); the orchestrator gates on the **union** of `high` findings. See `SUBAGENTS.md` §1, §6, §9.

### MCP allowlist enforcement

The plugin ships no MCP servers of its own, but downstream consumers using [MCP allowlist enforcement](https://docs.github.com/en/copilot/reference/mcp-allowlist-enforcement) should reference MCP tools in agent `tools:` arrays as `<server-name>/<tool>` (e.g., `workiq/ask_work_iq`). Agent `tools:` arrays in this plugin already use canonical aliases (`execute`, `search`, `read`, `edit`, `agent`, `web`, `todo`) per [custom-agents-configuration](https://docs.github.com/en/copilot/reference/custom-agents-configuration).

## License

MIT
