---
name: create-architecture
description: "Generate a project-level architecture.md (system shape, tech stack, repos, deployment) for greenfield projects"
user-invocable: false
---

# Create Project Architecture

Generate `architecture.md` in the project folder using `templates/architecture-template.md`.

## When to use

- CRISPY **project** workstream Intention phase. Invoked by `crispy-architecture`.

## Process

1. Read `vision.md` and `domain-research.md` from the project folder.
2. Instantiate `templates/architecture-template.md` at `<project-folder>/architecture.md`.
3. Propose **3 architecture options** with pros/cons/effort/risk (§2). Justify the recommendation.
4. Fill `§3 Tech Stack` with concrete versions and the scaffolder commands they imply. Mark genuinely undecided choices `TBD — needs user input` so `crispy-scaffold` pauses on them.
5. Fill `§4 Repositories` with one row per local repo `crispy-scaffold` should initialize.
6. Pull `§9 Anti-Patterns to Avoid` from `domain-research.md §7 Common Failure Modes`.

## Critical Rules

- Section anchors (`{#tech-stack}`, `{#repositories}`, `{#service-boundaries}`, `{#data-model}`, `{#cross-cutting}`, `{#deployment}`, `{#anti-patterns}`) MUST be preserved verbatim. Feature-level `intent.md` files reference them by anchor.
- The recommendation must be opinionated, not hedged.
- Do NOT enumerate features — that's `feature-map.md`'s job.

## Hand-off

After this artifact, the orchestrator runs the architecture review gate (`spec-review` + `code-review`) and then invokes `crispy-scaffold` to initialize repos.
