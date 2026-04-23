---
name: finish-branch
description: "Verify, present options, and clean up after a feature branch is complete"
---

# Finish Branch

Runs at the end of `crispy-implement` once all slices in the manifest have completed successfully. Confirms the branch is in a shippable state, presents the operator with concrete next steps, and (when chosen) opens a PR and cleans up the worktree.

## When to use

- All slices in `implementation-manifest.yaml` returned `status: ok`.
- Operator (or `chain: true` autopilot) wants to wrap up the feature branch.

## When NOT to use

- Mid-implementation. Only call after the last slice's checkpoint commit.
- Branches with failing tests — fix first, then call this.

## Inputs

- `feature_id` (string) — kebab-case feature identifier.
- `feature_branch` (string) — the branch implemented.
- `worktree_path` (string, optional) — if the work happened in an isolated worktree (from `git-worktree-isolation`), the path to it.
- `base_branch` (string) — branch to PR into. Defaults to `develop`, falling back to `main`.
- `mode` (string) — `interactive` (default) or `autopilot`. Autopilot honors `next_action_default`.
- `next_action_default` (string, autopilot only) — one of `pr` / `push` / `keep-local` / `discard`. Required when `mode: autopilot`.

## Process

### 1. Verify branch is green

In the worktree (or repo root if no worktree):

- `git status --porcelain` — must be empty. If not, return `status: failed` (uncommitted work means a slice did not commit).
- Run the project's full test command (the same one `run-tdd-slice` step 4 uses). Must exit 0. If it fails, return `status: failed` with the test output tail.
- Run lint if a lint command exists. Same exit-0 requirement.

### 2. Confirm divergence from base

- `git fetch origin <base_branch>`
- `git log --oneline origin/<base_branch>..HEAD` — must have >= 1 commit. If empty, return `status: partial` with `summary: "Branch has no commits ahead of <base_branch>; nothing to ship."`.

### 3. Present options (interactive mode)

Surface to the user via the standard `crispy-result` `next_actions`:

```
1. pr        — push and open a PR via `gh pr create --base <base_branch>`.
2. push      — push the branch but do not open a PR.
3. keep-local — leave the branch as-is locally; do nothing.
4. discard   — delete the branch and remove the worktree (DESTRUCTIVE — requires explicit confirmation).
```

In autopilot mode, skip the prompt and execute `next_action_default` directly.

### 4. Execute the chosen action

- **pr**: `git push -u origin <feature_branch>`, then `gh pr create --base <base_branch> --head <feature_branch> --title "<feature_id>: <one-line summary from spec.md>" --body-file <crispy-docs/<feature>/spec.md or generated body>`. Capture PR URL into `metadata.pr_url`.
- **push**: `git push -u origin <feature_branch>`. Capture remote ref into `metadata.remote_ref`.
- **keep-local**: no-op.
- **discard**: require `confirm: true` input (or autopilot `next_action_default: discard` is itself the confirmation). Run `git branch -D <feature_branch>` from the main checkout AFTER worktree removal in step 5.

### 5. Worktree cleanup

If `worktree_path` was provided, delegate to the `git-worktree-isolation` skill with `mode: cleanup` and `worktree_path`. Honor its `status: partial` (do not force-remove dirty worktrees).

### 6. Return

```yaml
status: ok | partial | failed
agent: finish-branch
artifact_path: null
summary: |
  Finished <feature_branch> via <action>. <PR URL or remote ref or "kept local" or "discarded">.
findings: []
next_actions:
  - <follow-up if status != ok, else empty>
metadata:
  feature_id: <id>
  feature_branch: <name>
  action: pr | push | keep-local | discard
  pr_url: <if action == pr>
  remote_ref: <if action in [pr, push]>
  worktree_removed: true | false
```

## Failure handling

| Symptom | Action |
|---|---|
| Tests fail in step 1 | `status: failed`. Do NOT push. Surface test output. |
| `gh` not installed and action is `pr` | `status: partial` — fall back to `push` and instruct user to open PR manually. |
| Push rejected (non-fast-forward) | `status: failed`. Surface output. Do not auto-rebase. |
| Worktree cleanup returned `partial` | Propagate `status: partial`; do not force-delete branch. |

## Anti-patterns

- ❌ Skipping step 1 (verify green) — defeats the purpose of the gate.
- ❌ Deleting a branch before the PR is merged.
- ❌ Force-removing a worktree that still has uncommitted changes.
- ❌ Auto-selecting `discard` in autopilot without an explicit `next_action_default: discard` from the operator.
