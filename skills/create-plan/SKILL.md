---
name: create-plan
description: "Generate a plan.md with file-level tactical implementation plan"
user-invocable: false
---

# Create Tactical Implementation Plan

Generate a `plan.md` with a file-level implementation plan that maps directly from the outline's vertical slices to specific code changes.

## Process

1. Read all prior documents: `spec.md`, `research.md`, `intent.md`, `outline.md`.
2. For each slice, identify the exact files to create, modify, or delete.
3. Define implementation phases with specific file paths and change descriptions.
4. Write `plan.md` in the feature's spec directory.

## Template Structure

```markdown
# Implementation Plan: {Feature Name}

## Technical Context
- Language/Framework: {e.g., TypeScript / React / Express}
- Key Dependencies: {packages critical to implementation}
- Test Framework: {e.g., Jest, pytest, xUnit}
- Build System: {e.g., webpack, vite, MSBuild}

## Project Structure
Relevant portions of the directory tree with annotations for new/modified files.

```
src/
├── components/
│   ├── Auth/
│   │   ├── Login.tsx        ← MODIFY: add OAuth flow
│   │   └── OAuthCallback.tsx ← NEW
│   └── ...
├── services/
│   └── auth.service.ts      ← MODIFY: add token refresh
└── ...
```

## Implementation Phases

### Phase 1: {Slice 1 Name}

#### Step 1.1: {Description}
- **File:** `src/services/auth.service.ts`
- **Action:** Modify
- **Changes:** {Specific description of what to add/change}

#### Step 1.2: {Description}
- **File:** `src/components/Auth/OAuthCallback.tsx`
- **Action:** Create
- **Changes:** {What this new file contains and why}

### Phase 2: {Slice 2 Name}
...

## Complexity Tracking

| Phase | Files Changed | New Files | Estimated Effort | Risk |
|---|---|---|---|---|
| Phase 1 | 3 | 1 | 2 hours | Low |
| Phase 2 | 5 | 2 | 4 hours | Medium |

## Dependencies & Prerequisites
- {External dependency that must be installed}
- {Database migration that must run first}
- {Environment variable that must be configured}

## Rollback Strategy
How to safely revert changes if implementation fails at any phase.
```

## Machine-Readable Task Graph

The produced `plan.md` MUST also include a fenced ` ```yaml task_graph: ...``` ` block. This block is consumed by `crispy-implement` to identify tasks that can run in parallel within and across slices.

Schema:

```yaml
task_graph:
  - id: TASK-001
    slice: 1
    story: <story-name>
    depends_on: []
    parallelizable_with: [TASK-002]
    files: [path/to/file.ext]
```

Rules:

- One entry per implementation step in the plan.
- `depends_on` lists task IDs that must complete before this task starts.
- `parallelizable_with` lists task IDs safe to run concurrently (no shared file writes, no logical conflicts).
- `files` lists every file the task creates or modifies; used to detect write conflicts when fleeting.

## Guidelines

- Every file mentioned must include its full relative path from the repo root.
- Use action verbs: Create, Modify, Delete, Rename, Move.
- Change descriptions should be specific enough for a developer to implement without guessing.
- Complexity tracking helps prioritize and schedule work.
- Include a rollback strategy for each phase when possible.
- Flag any changes that require database migrations or infrastructure updates.
