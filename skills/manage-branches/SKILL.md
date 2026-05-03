---
name: manage-branches
description: "Deprecated; do not create repo-wide feature branches. Use create-workspace or git-worktree-isolation instead."
user-invocable: false
disable-model-invocation: true
---

# Deprecated: Manage Feature Branches

This skill is deprecated and must not create, switch, pull, fetch, stash, delete, or push branches.

CRISPY no longer creates one feature branch across all affected repositories during planning. That behavior conflicts with feature-slice branch isolation and slows down planning runs.

## Replacement Paths

- During planning, use `create-workspace` to create a focused VS Code workspace for the affected repositories.
- During implementation fleet mode, use `git-worktree-isolation` to create per-slice worktree branches only for the slices that need isolation.
- For sequential implementation, work on the user's current branch after the clean-worktree precondition passes.

## Required Behavior

If invoked, return a clear deprecation result and do not modify git state.

```yaml
status: failed
agent: manage-branches
artifact_path: null
summary: |
  manage-branches is deprecated and did not modify any repositories.
  Use create-workspace during planning or git-worktree-isolation during implementation fleet mode.
metadata:
  deprecated: true
  branch_created: false
```
