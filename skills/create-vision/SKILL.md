---
name: create-vision
description: "Generate a vision.md project specification from user input (greenfield project workstream)"
---

# Create Project Vision

Generate a `vision.md` file in the designated project folder using the CRISPY project vision template (`templates/vision-template.md`).

## When to use

- The CRISPY **project** workstream Clarify phase needs to produce `vision.md`.
- Invoked by `crispy-vision`.

## When NOT to use

- For per-feature specs — use `create-spec` instead.

## Process

1. Confirm the resolved project folder (e.g., `crispy-docs/projects/NNN-project-name/`).
2. Read `templates/vision-template.md` and instantiate it at `<project-folder>/vision.md`.
3. Replace bracketed placeholders with content gathered from the user.
4. Use **WorkIQ** when stakeholders, prior PRDs, or design discussions are referenced (cite source).

## Guidelines

- Themes in §4 are coarse. Each theme will become 1+ features in `feature-map.md`. Don't try to enumerate features here.
- The MVP definition (§5) drives the walking-skeleton choice in `roadmap.md`.
- Success metrics (§6) must be measurable, not aspirational.
- Open Questions (§10) is a live list — do NOT fabricate answers; flag for the user.

## Hand-off

The next phase is **Domain Research**, which is **blind** (must NOT read `vision.md`). Make sure stakeholders confirm vision.md before the orchestrator backgrounds `crispy-domain-research`.
