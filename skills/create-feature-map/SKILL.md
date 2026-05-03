---
name: create-feature-map
description: "Decompose a project into a dependency graph of feature folders, with an auto-split rule for oversized features"
user-invocable: false
---

# Create Feature Map

Generate `feature-map.md` in the project folder using `templates/feature-map-template.md`.

## When to use

- CRISPY **project** workstream Structure phase. Invoked by `crispy-feature-map`.

## Process

1. Read `vision.md`, `domain-research.md`, `architecture.md`.
2. Instantiate `templates/feature-map-template.md` at `<project-folder>/feature-map.md`.
3. For each `vision.md §4` theme, propose 1+ features. Estimate slice count per feature using the same rubric `crispy-structure` uses (3–8 slices = normal feature; >10 = oversized).
4. **Auto-split rule:** if a candidate feature's estimated slice count exceeds **10**, split it into sibling features (e.g., `payments-core` + `payments-refunds`). Record each child with `auto_split_from: <parent-name>` in the machine-readable graph and add a row to the **Auto-Split Log**. Sibling features inherit the parent's theme; their `depends_on` reflects the natural ordering.
5. Build the dependency graph from feature-to-feature relationships ONLY (not slice-to-slice).
6. Pre-create empty feature folders at `<project-folder>/features/NNN-feature-name/` so feature-level CRISPY runs can resume into them.
7. **Soft warning:** if total feature count exceeds **15**, surface a `medium` finding in the agent's `crispy-result` — but do NOT block. There is no hard project-size cap.

## Critical Rules

- Every feature in the overview table MUST appear in the machine-readable graph (`features:` block) exactly once.
- Every feature MUST have an `estimated_slices` integer.
- Every auto-split feature MUST have an `auto_split_from` value AND an entry in the Auto-Split Log.
- Folder names are kebab-case; folder ID is zero-padded 3 digits matching the `id` field.

## Hand-off

After this artifact, the orchestrator runs the feature-map review gate. Then `crispy-roadmap` sequences the features into milestones.
