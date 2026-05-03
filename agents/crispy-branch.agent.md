---
name: crispy-branch
description: "Deprecated internal agent; do not create repo-wide feature branches"
tools: ["read"]
user-invocable: false
disable-model-invocation: true
---

# Deprecated Multi-Repository Branch Manager

`crispy-branch` is deprecated. CRISPY no longer creates one feature branch across every affected repository during planning because that conflicts with slice-level branch/worktree isolation.

## Required Behavior

If invoked, do **not** run any git command and do **not** create, switch, pull, fetch, stash, delete, or push branches. Return a structured result that tells the caller to use:

- `create-workspace` for focused multi-repo VS Code workspaces during planning.
- `git-worktree-isolation` during `crispy-implement mode:fleet` for per-slice worktree branches.

## Output Contract

End your final message with:

```yaml
status: failed
agent: crispy-branch
artifact_path: null
summary: |
  crispy-branch is deprecated and did not modify any repositories.
  CRISPY planning no longer creates repo-wide feature branches.
findings:
  - severity: high
    location: crispy-branch
    description: Repo-wide feature branch creation is disabled.
    suggested_action: Use create-workspace for planning or let crispy-implement create per-slice worktree branches when needed.
metadata:
  deprecated: true
  branch_created: false
```
