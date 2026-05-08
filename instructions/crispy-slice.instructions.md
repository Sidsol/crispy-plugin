---
applyTo: "crispy-docs/specs/**/tasks.md"
description: "CRISPY slice-editing reminders for tasks.md files"
priority: medium
---

# CRISPY tasks.md editing reminders

When editing a `tasks.md` file under `crispy-docs/specs/<NNN-feature-name>/`:

1. **Task IDs are immutable once issued.** Do not renumber `TASK-NNN` IDs even if a task is removed — leave a one-line note instead, so dependency graphs in `plan.md` and `implementation-manifest.yaml` stay valid.
2. **Slice column must match outline.md.** Every task's `slice: S<n>` must correspond to a slice defined in `outline.md`. If you reslot a task between slices, also update `plan.md`'s `task_graph` block and the per-slice file lists.
3. **Priority must trace to a parent FR.** Every P1 task must trace to a P1 spec story or P1 FR. Re-prioritizing requires updating the priority counts in the file's summary line.
4. **`parallelizable: true` requires zero same-slice file overlap.** When marking a task parallelizable, verify no other parallelizable task in the same slice touches the same files in `files_touched`. If they do, either set `parallelizable: false` or add an explicit `depends_on` edge.
5. **Verification before commit.** Run any spec-review / code-review gates the feature requires before merging tasks.md edits — this file is consumed by `crispy-yield` and `crispy-implement` and silent inconsistencies surface as Yield blockers.
6. **HITL flags on irreversible operations.** Any task that deletes a file, mutates `hooks.json` schema, renames a public agent, or touches contracts in a breaking way must carry `automation: HITL` and an explicit "requires user confirmation" note.

See `agents/crispy-plan.agent.md`, `agents/crispy-yield.agent.md`, and `SUBAGENTS.md` §6 for the broader contract.