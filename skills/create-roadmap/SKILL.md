---
name: create-roadmap
description: "Sequence project features into milestones (no calendar dates) with parallelization waves"
user-invocable: false
---

# Create Project Roadmap

Generate `roadmap.md` in the project folder using `templates/roadmap-template.md`.

## When to use

- CRISPY **project** workstream Plan phase. Invoked by `crispy-roadmap`.

## Process

1. Read `vision.md`, `architecture.md`, `feature-map.md`.
2. Instantiate `templates/roadmap-template.md` at `<project-folder>/roadmap.md`.
3. Define milestones starting with **M1 — Walking Skeleton** (smallest end-to-end vertical that proves the architecture). Pull walking-skeleton scope from `vision.md §5 MVP Definition` and `feature-map.md`'s lowest-dependency P1 features.
4. For each milestone, list features (by ID), exit criteria, and risk notes.
5. Compute **parallelization waves** within each milestone using the feature dependency graph in `feature-map.md` AND a per-repo file-conflict heuristic from `architecture.md §4 Repositories` (features touching the same repo's same area should not be in the same wave).
6. Cross-repo coordination table: for each repo from `architecture.md §4`, list which features touch it.

## Critical Rules

- **No dates, no time estimates.** Roadmaps are sequencing-only. Use phase/milestone names like "M1", "M2", not "Q3 2026".
- Walking-skeleton (M1) MUST be the smallest end-to-end vertical. Resist scope creep.
- Every feature in `feature-map.md` MUST appear in some milestone here.

## Hand-off

After this artifact, the orchestrator runs the roadmap review gate, then `crispy-project-yield` validates everything and writes `project-manifest.yaml`.
