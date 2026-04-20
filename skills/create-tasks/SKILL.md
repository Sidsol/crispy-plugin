---
name: create-tasks
description: "Generate a tasks.md with story-organized task breakdown"
---

# Create Task Breakdown

Generate a `tasks.md` with an actionable task list organized by user stories from `spec.md`. Each task maps to a specific implementation step from `plan.md`.

## Process

1. Read `spec.md` (for user stories) and `plan.md` (for implementation steps).
2. Break each plan phase into discrete, actionable tasks.
3. Organize tasks under their corresponding user stories.
4. Write `tasks.md` in the feature's spec directory.

## Template Structure

```markdown
# Task Breakdown: {Feature Name}

## Legend
- **P1** = Must-have | **P2** = Should-have | **P3** = Nice-to-have
- ⬜ Not started | 🔵 In progress | ✅ Done | ❌ Blocked

## Tasks by Story

### US-1: {User Story Title}

| ID | Pri | Task | Status | Notes |
|---|---|---|---|---|
| T-001 | P1 | {Task description} | ⬜ | {Dependencies or context} |
| T-002 | P1 | {Task description} | ⬜ | |
| T-003 | P1 | Write tests for {component} | ⬜ | |

### US-2: {User Story Title}

| ID | Pri | Task | Status | Notes |
|---|---|---|---|---|
| T-004 | P2 | {Task description} | ⬜ | Depends on T-002 |
| T-005 | P2 | {Task description} | ⬜ | |

### Infrastructure / Cross-Cutting

| ID | Pri | Task | Status | Notes |
|---|---|---|---|---|
| T-010 | P1 | {Database migration, config, etc.} | ⬜ | |

## Execution Order
Recommended sequence accounting for dependencies:

1. **Parallel Group A:** T-001, T-010 (no dependencies)
2. **Sequential:** T-002 (depends on T-001)
3. **Parallel Group B:** T-003, T-004 (depend on T-002)
4. **Sequential:** T-005 (depends on T-004)

## Parallel Opportunities
Tasks that can be safely worked on simultaneously:
- {T-001 and T-010}: No shared files or dependencies.
- {T-003 and T-004}: Different components, independent test suites.

## Estimation Summary
| Priority | Count | Estimated Total |
|---|---|---|
| P1 | {n} | {hours} |
| P2 | {n} | {hours} |
| P3 | {n} | {hours} |
```

## Guidelines

- Task IDs must be unique and sequential (T-001, T-002, ...).
- Every task should be completable in a single focused session (< 2 hours).
- If a task is too large, split it into sub-tasks.
- Always include a test task for each functional task.
- Execution order must respect dependencies — never schedule a task before its dependency.
- Parallel opportunities should only list tasks with genuinely zero coupling.
