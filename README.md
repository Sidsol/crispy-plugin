# 🧊 CRISPY Workflow — Copilot CLI Plugin

> **Clarify → Research → Intention → Structure → Plan → Yield**

A GitHub Copilot CLI plugin that implements the CRISPY framework for structured, high-quality AI-assisted software development. Produces spec-kit-style artifacts and manages multi-repo branch operations.

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

### Utility Agents

```
@crispy-scan "Which repos are affected by adding GraphQL support?"
@crispy-branch "Create feature branches for 003-graphql-support"
```

## Artifact Output

Artifacts are stored in a `crispy-docs` directory:

```
crispy-docs/
└── specs/
    ├── 001-user-authentication/
    │   ├── spec.md          # C: User stories, requirements, acceptance criteria
    │   ├── research.md      # R: Blind codebase analysis
    │   ├── intent.md        # I: Architecture direction, affected repos
    │   ├── outline.md       # S: Vertical slices, checkpoints
    │   ├── plan.md          # P: File-level tactical plan
    │   ├── tasks.md         # P: Task breakdown by user story
    │   ├── checklist.md     # Y: Quality gates, pre-implementation checks
    │   └── contracts/       # API/interface contracts
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

- **Blind Research**: The Research phase must NOT know the feature goal — this keeps analysis objective
- **Smart Zone**: Keep AI context below 40% — reset context before implementation
- **Vertical Slices**: Build end-to-end (DB → API → UI) in small, testable pieces
- **No Slop**: Every line of generated code must be reviewed by a human

## Plugin Structure

```
crispy-plugin/
├── plugin.json              # Plugin manifest
├── hooks.json               # Branch management hooks
├── agents/                  # 9 custom agents
│   ├── crispy.agent.md      # Orchestrator (full workflow)
│   ├── crispy-clarify.agent.md
│   ├── crispy-research.agent.md
│   ├── crispy-intent.agent.md
│   ├── crispy-structure.agent.md
│   ├── crispy-plan.agent.md
│   ├── crispy-yield.agent.md
│   ├── crispy-scan.agent.md
│   └── crispy-branch.agent.md
├── skills/                  # 11 reusable skills
│   ├── create-spec/
│   ├── create-research/
│   ├── create-intent/
│   ├── create-outline/
│   ├── create-plan/
│   ├── create-tasks/
│   ├── create-checklist/
│   ├── create-contracts/
│   ├── detect-repos/
│   ├── manage-branches/
│   └── init-crispy-docs/
├── templates/               # 8 artifact templates
└── .github/plugin/
    └── marketplace.json     # Marketplace manifest
```

## Configuration

The plugin works out of the box. Optional configuration:

- **Branch naming**: Add conventions to `AGENTS.md` in your repos
- **Marketplace**: Update `.github/plugin/marketplace.json` with your org details
- **Hooks**: Customize `hooks.json` for additional pre-branch checks

## License

MIT
