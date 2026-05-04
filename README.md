# 🧊 CRISPY Workflow — Copilot CLI Plugin

> **Clarify → Research → Intention → Structure → Plan → Yield**

A GitHub Copilot CLI plugin that implements the CRISPY framework for structured, high-quality AI-assisted software development. Produces spec-kit-style artifacts, **coordinates hidden sub-agents across phases** to keep contexts clean and parallelize work, drives slice-by-slice TDD execution after planning is done, and creates focused multi-repo workspaces without planning-time repo-wide branch creation.

> 🆕 **v0.2 — Sub-Agent Orchestration.** The orchestrator now spawns each phase as its own sub-agent, runs research in the background while clarification continues, gates with two-stage `spec-review` + `code-review` passes, and chains into a new `crispy-implement` agent that drives slice-by-slice TDD using sub-agent pairs. See [`SUBAGENTS.md`](./SUBAGENTS.md) for the protocol.
>
> 🆕 **v0.4 — Greenfield Project Workstream.** A second orchestrator, `@crispy-project`, drives the same 6 CRISPY phases at the **project** level: vision → domain-research → architecture (+ local repo scaffold) → feature-map (DAG of features, with >10-slice auto-split) → roadmap (milestones, no dates) → project-checklist/manifest. Each decomposed feature then runs through the existing `@crispy` workflow with **inherited project context** (architecture.md and domain-research.md become MUST-READ for feature-level Intent and Research). Both workstreams remain available standalone. See [`SUBAGENTS.md §11`](./SUBAGENTS.md).
>
> 🆕 **v0.5 — Focused Public Surface.** Only the top-level agents are user-invocable: `@crispy`, `@crispy-project`, and `@crispy-implement`. Phase agents and implementation helpers are hidden via `user-invocable: false` per the Agent Skills/custom agents docs. Repo-wide branch setup is deprecated; multi-repo planning now creates workspaces only, while implementation fleet mode uses per-slice worktree branches.

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

### Public Agents

CRISPY intentionally exposes only three agents to keep the user-facing picker small:

| Agent | Use when |
|---|---|
| `@crispy` | Plan a feature in an existing codebase. |
| `@crispy-project` | Plan a greenfield multi-feature project. |
| `@crispy-implement` | Execute a completed feature plan slice-by-slice after Yield. |

All phase agents (`crispy-clarify`, `crispy-research`, `crispy-intent`, etc.) are internal implementation details. They remain installed so the orchestrators can spawn them, but they are hidden from user selection.

### Implementation Agent (post-Yield)

After Yield produces an `implementation-manifest.yaml`, run the implementation agent to actually build the feature:

```
@crispy-implement crispy-docs/specs/003-graphql-support/                  # default sequential TDD per slice
@crispy-implement crispy-docs/specs/003-graphql-support/ mode:fleet       # parallel slices when independent
@crispy-implement crispy-docs/specs/003-graphql-support/ mode:fast_mode   # skip the test-author sub-agent
```

`crispy-implement` walks the slice graph from the `implementation-manifest.yaml` and drives a TDD pair per slice:
**test-author** → **implementer** → **spec-review** → **code-review**, then runs build/lint/tests between slices.

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

CRISPY has its own parallel execution (`mode:fleet` on `crispy-implement`) that is distinct from Copilot CLI's native `/fleet` command:

| Feature | `crispy-implement mode:fleet` | Copilot CLI `/fleet` |
|:--------|:------------------------------|:---------------------|
| Task splitting | DAG-aware from slice dependency graph | AI auto-splits from prompt |
| File isolation | `git worktree` per slice (no silent overwrites) | None (last writer wins) |
| Conflict detection | Pre-wave file-set check + post-wave diff verification | None |
| Rollback | Per-slice `git reset --hard` | None |

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

Planning no longer creates one feature branch across every affected repo. Sequential implementation uses the current clean branch. Fleet implementation creates temporary per-slice worktree branches (for example, `crispy/<feature-id>/slice-<N>`) and merges them back into the recorded integration branch after each wave.

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

- `preToolUse: crispy-metrics-start` — records the start timestamp of every CRISPY sub-agent invocation (`task` tool) into `$TEMP/crispy-metrics-pending/`.
- `postToolUse: crispy-metrics-record` — pairs with the start record, computes elapsed time + token approximations + premium-request estimate, and appends a JSONL row to the owning feature/project's `.metrics.jsonl`. Disable with `CRISPY_METRICS_DISABLED=1`.
- `userPromptSubmit: inject-crispy-protocol` — telemetry only. Per the docs, `userPromptSubmit` output is ignored, so the protocol reminder lives in `templates/subagent-prompt.template.md` and `SUBAGENTS.md`, not in this hook.

### Two-stage review

Reviewer gates are split into `spec-review` (correctness vs spec/intent/contracts) and `code-review` (quality, idioms, security). Both share the same severity vocabulary (`high` / `medium` / `low`); the orchestrator gates on the **union** of `high` findings. See `SUBAGENTS.md` §1, §6, §9.

### MCP allowlist enforcement

The plugin ships no MCP servers of its own, but downstream consumers using [MCP allowlist enforcement](https://docs.github.com/en/copilot/reference/mcp-allowlist-enforcement) should reference MCP tools in agent `tools:` arrays as `<server-name>/<tool>` (e.g., `workiq/ask_work_iq`). Agent `tools:` arrays in this plugin already use canonical aliases (`execute`, `search`, `read`, `edit`, `agent`, `web`, `todo`) per [custom-agents-configuration](https://docs.github.com/en/copilot/reference/custom-agents-configuration).

## License

MIT
