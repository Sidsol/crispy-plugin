---
name: create-project-checklist
description: "Generate the pre-implementation project-level CRISPY checklist (parallel to create-checklist for features)"
user-invocable: false
---

# Create Project Checklist

Generate `project-checklist.md` in the project folder using `templates/project-checklist-template.md`.

## When to use

- CRISPY **project** workstream Yield phase. Invoked by `crispy-project-yield`.

## Process

1. Read all project artifacts: `vision.md`, `domain-research.md`, `architecture.md`, `scaffold-report.md` (if present), `feature-map.md`, `roadmap.md`, `review-gates.yaml`.
2. Instantiate `templates/project-checklist-template.md` at `<project-folder>/project-checklist.md`.
3. Run each Quality Gate and Consistency Check. Mark each `✅` or `❌` with a note.
4. Verify all feature folders exist (pre-created by `crispy-feature-map`).
5. Verify `scaffold-report.md` exists (or is explicitly marked deferred for projects that defer scaffolding).

## Critical Rules

- Be strict. If any check fails, the corresponding line MUST be `❌`, the issue MUST appear in **Issues Found**, and the issue MUST be carried to `project-manifest.yaml` as a blocker (set `ready: false`).
- Do NOT auto-fix — the project-level Yield is a gate, not a doctor.
- If `review-gates.yaml` is missing, this is a blocker — instruct the user to re-run the affected project review gates via `@crispy-project`.

## Hand-off

After this artifact, `crispy-project-yield` writes `project-manifest.yaml` with the embedded `feature_graph` (verbatim copy from `feature-map.md`'s machine-readable block) and `review_gates`. That manifest is what feature-level CRISPY runs and the autopilot fan-out consume.
