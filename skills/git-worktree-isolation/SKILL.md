---
name: git-worktree-isolation
description: "Create and clean up isolated git worktrees for parallel slice execution"
---

# Git Worktree Isolation

Creates a per-slice isolated `git worktree` so multiple slices can be implemented in parallel without file-system conflicts. Used by `crispy-implement` in fleet mode (`SUBAGENTS.md` §5.2) and by any sequential slice that wants worktree-based rollback safety.

## When to use

- `crispy-implement` is about to dispatch >= 2 independent slices in parallel (fleet mode).
- Operator wants worktree isolation for a high-blast-radius sequential slice.

## When NOT to use

- Sequential mode with low-risk slices.
- Repositories that predate `git worktree` (git < 2.5; rare).

## Inputs

- `slice_id` (string, kebab-case) — used to name the worktree directory and branch.
- `base_branch` (string) — the branch to fork from. Defaults to the current branch.
- `feature_branch` (string, optional) — explicit branch name to create. Defaults to `crispy/<slice_id>`.
- `worktree_root` (string, optional) — parent directory for worktrees. Defaults to `<repo>/.crispy-worktrees/`.

## Process

### 1. Precondition checks

Run these in the main checkout:

- `git rev-parse --show-toplevel` to confirm we are in a git repo. Fail with `status: failed` if not.
- `git status --porcelain` — if non-empty AND `CRISPY_ALLOW_DIRTY` is not set, return `status: failed` with `next_actions: ["Commit or stash changes before creating an isolated worktree"]`.
- `git worktree list --porcelain` — if a worktree already exists at the target path, return `status: partial` with `metadata.worktree_path` pointing at the existing one (idempotent reuse).

### 2. Create the worktree

```
mkdir -p <worktree_root>
git worktree add -b <feature_branch> <worktree_root>/<slice_id> <base_branch>
```

If the branch already exists locally, drop the `-b` flag and just check it out:

```
git worktree add <worktree_root>/<slice_id> <feature_branch>
```

### 3. Verify

- `git -C <worktree_root>/<slice_id> rev-parse HEAD` returns the expected SHA.
- `git -C <worktree_root>/<slice_id> branch --show-current` returns `<feature_branch>`.

### 4. Return

```yaml
status: ok
agent: git-worktree-isolation
artifact_path: <absolute worktree path>
summary: |
  Created isolated worktree for slice <slice_id> at <path> on branch <feature_branch>.
metadata:
  slice_id: <slice_id>
  worktree_path: <absolute path>
  feature_branch: <feature_branch>
  base_branch: <base_branch>
```

## Cleanup mode

When invoked with `mode: cleanup` and `worktree_path`:

1. `git -C <worktree_path> status --porcelain` — if non-empty, return `status: partial` (do not silently drop work).
2. `git worktree remove --force <worktree_path>` from the main checkout.
3. Optionally delete the branch: `git branch -D <feature_branch>` (only if `delete_branch: true` and the branch has been merged or the operator explicitly requested it).
4. Return `status: ok` with `metadata.removed: true`.

## Failure handling

| Symptom | Action |
|---|---|
| `git worktree add` fails (path exists, locked, etc.) | `status: failed`, surface stderr, do not retry. |
| Branch name collision | If a worktree already exists for that branch, return `status: partial` with the existing path (let caller decide). |
| Dirty working tree | `status: failed` with `next_actions` instructing commit/stash. |
| Cleanup with uncommitted changes | `status: partial`, do not force-remove. Caller decides. |

## Anti-patterns

- ❌ Creating a worktree without checking `git status` first (loses uncommitted work).
- ❌ Calling `git worktree remove --force` when the worktree has uncommitted changes (silent data loss).
- ❌ Reusing a single worktree path across overlapping slices (defeats isolation).
- ❌ Hard-coding the worktree root inside the skill — the caller may need a tmpfs path.
