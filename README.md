# 🧊 CRISPY Workflow — Copilot CLI Plugin

> **Clarify → Research → Intention → Structure → Plan → Yield**

A GitHub Copilot CLI plugin that implements the CRISPY framework for structured, high-quality AI-assisted software development. Produces spec-kit-style artifacts, **coordinates sub-agents across phases** to keep contexts clean and parallelize work, drives slice-by-slice TDD execution after planning is done, and manages multi-repo branch operations.

> 🆕 **v0.2 — Sub-Agent Orchestration.** The orchestrator now spawns each phase as its own sub-agent, runs research in the background while clarification continues, gates with rubber-duck reviews, and chains into a new `crispy-implement` agent that drives slice-by-slice TDD using sub-agent pairs. See [`SUBAGENTS.md`](./SUBAGENTS.md) for the protocol.

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

### Full CRISPY Workflow (Recommended)

```
@crispy "Add user authentication to the platform"
```

The orchestrator walks you through all 6 phases:
1. **Clarify** — Asks 5-10 clarifying questions, produces `spec.md`
2. **Research** — Blind codebase analysis (no feature goal revealed), produces `research.md`
3. **Intention** — Architecture analysis with 3 options, produces `intent.md`
4. **Structure** — Vertical slices and checkpoints, produces `outline.md`
5. **Plan** — File-level tactical plan, produces `plan.md` + `tasks.md` + `contracts/`
6. **Yield** — Quality gate checklist, produces `checklist.md`

### Individual Phase Agents

Use any phase independently:

```
@crispy-clarify "Add OAuth login support"
@crispy-research "Examine the auth module and user service"
@crispy-intent "Review spec and research for feature 003"
@crispy-structure "Define slices for feature 003"
@crispy-plan "Create tactical plan for feature 003"
@crispy-yield "Validate feature 003 is ready for implementation"
```

### Implementation Agent (post-Yield)

After Yield produces an `implementation-manifest.yaml`, run the implementation agent to actually build the feature:

```
@crispy-implement crispy-docs/specs/003-graphql-support/                  # default sequential TDD per slice
@crispy-implement crispy-docs/specs/003-graphql-support/ mode:fleet       # parallel slices when independent
@crispy-implement crispy-docs/specs/003-graphql-support/ mode:fast_mode   # skip the test-author sub-agent
```

`crispy-implement` walks the slice graph from `outline.md` and drives a TDD pair per slice:
**test-author** → **implementer** → **rubber-duck**, then runs build/lint/tests between slices.

### Utility Agents

```
@crispy-scan "Which repos are affected by adding GraphQL support?"
@crispy-branch "Create feature branches for 003-graphql-support"
```

### Autopilot Mode

Invoke the orchestrator in autopilot to skip interactive gate prompts:

```
@crispy autopilot "Add user authentication to the platform"
```

In autopilot:
- Each phase produces a 3–5 line **checkpoint summary** instead of asking for confirmation.
- Rubber-duck reviews after Intent and Plan only block on `severity: high` findings (medium/low are appended to the artifact's `## Reviewer Findings` section, then continue).
- `crispy-branch` runs **non-interactively** with sensible defaults (auto-stash, default `feature/NNN-feature-name`, skip repos with conflicts).
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

Artifacts are stored in a `crispy-docs` directory:

```
crispy-docs/
└── specs/
    ├── 001-user-authentication/
    │   ├── spec.md                       # C: User stories, requirements, acceptance criteria
    │   ├── research.md                   # R: Blind codebase analysis (with optional fan-out merge)
    │   ├── intent.md                     # I: Architecture direction, affected repos
    │   ├── outline.md                    # S: Vertical slices + machine-readable slice dependency graph
    │   ├── plan.md                       # P: File-level tactical plan + machine-readable task graph
    │   ├── tasks.md                      # P: Task breakdown by user story
    │   ├── checklist.md                  # Y: Quality gates, pre-implementation checks
    │   ├── implementation-manifest.yaml  # Y: Hand-off manifest consumed by crispy-implement
    │   └── contracts/                    # API/interface contracts
    │       └── auth-api.md
    └── 002-graphql-support/
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
4. **Branch management** (if approved):
   - Checks each repo is on `develop` branch
   - If not on `develop`, asks for permission
   - Pulls latest `develop`
   - Reports conflicts before continuing
   - Creates feature branches with consistent naming

### Branch Naming

The agent checks `AGENTS.md` in each repo for branch conventions. If none found, it asks you and defaults to `feature/NNN-feature-name`.

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
- **No Slop**: Every line of generated code is reviewed by a `rubber-duck` sub-agent against the spec/intent before the slice is accepted.

### Sub-Agent Orchestration

The orchestrator (`crispy`) is the primary spawner. Phase agents run as sync or background sub-agents and return a structured `crispy-result` block. Reviewer findings use a fixed severity vocabulary (`high` / `medium` / `low`) so autopilot gating is deterministic.

| Spawn site | Mode | Trigger |
|:---|:---|:---|
| `crispy-research` (background) | bg | Area identified during Clarify |
| `explore` × N (researcher fan-out) | parallel | areas ≥ 3 OR repos ≥ 2 |
| `rubber-duck` after Intent | sync | After `intent.md` written |
| `rubber-duck` after Plan | sync | After `plan.md` + `tasks.md` written |
| `crispy-branch` (autopilot mode) | sync | After Intent confirms repos (autopilot only) |
| `test-author → implementer → rubber-duck` | sync per slice | Each slice in `crispy-implement` |
| TDD pair × N (slice fleet) | parallel | ≥ 2 slices with no pending deps |

Full protocol — input contract, return shape, severity gating, failure handling, anti-patterns — is in [`SUBAGENTS.md`](./SUBAGENTS.md).

## Plugin Structure

```
crispy-plugin/
├── plugin.json                       # Plugin manifest
├── hooks.json                        # Branch management hooks
├── SUBAGENTS.md                      # Sub-agent orchestration protocol (authoritative)
├── agents/                           # 10 custom agents
│   ├── crispy.agent.md               # Orchestrator (planning workflow, spawns phase sub-agents)
│   ├── crispy-clarify.agent.md
│   ├── crispy-research.agent.md      # Internal fan-out at areas ≥ 3 OR repos ≥ 2
│   ├── crispy-intent.agent.md
│   ├── crispy-structure.agent.md     # Emits machine-readable slice dependency graph
│   ├── crispy-plan.agent.md          # Emits machine-readable task graph
│   ├── crispy-yield.agent.md         # Writes implementation-manifest.yaml
│   ├── crispy-implement.agent.md     # Post-Yield TDD slice executor (sequential / fleet / fast_mode)
│   ├── crispy-scan.agent.md
│   └── crispy-branch.agent.md        # Has autopilot non-interactive mode
├── skills/                           # 14 reusable skills
│   ├── create-spec/
│   ├── create-research/              # Now supports fan-out mode
│   ├── create-intent/
│   ├── create-outline/               # Emits slice dependency graph yaml
│   ├── create-plan/                  # Emits task graph yaml
│   ├── create-tasks/
│   ├── create-checklist/
│   ├── create-contracts/
│   ├── detect-repos/
│   ├── manage-branches/              # Has autopilot non-interactive mode
│   ├── init-crispy-docs/
│   ├── spawn-subagent/               # NEW — wraps the spawn protocol
│   ├── aggregate-research/           # NEW — merges fan-out research fragments
│   └── run-tdd-slice/                # NEW — test-author → implementer → rubber-duck loop
├── templates/                        # 9 artifact templates
│   └── subagent-prompt.template.md   # NEW — required skeleton for every sub-agent prompt
└── .github/plugin/
    └── marketplace.json              # Marketplace manifest
```

## Configuration

The plugin works out of the box. Optional configuration:

- **Branch naming**: Add conventions to `AGENTS.md` in your repos
- **Marketplace**: Update `.github/plugin/marketplace.json` with your org details
- **Hooks**: Customize `hooks.json` for additional pre-branch checks

## License

MIT
