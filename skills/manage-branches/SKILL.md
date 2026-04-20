---
name: manage-branches
description: "Create and manage feature branches across multiple repositories"
---

# Manage Feature Branches

Create and manage consistent feature branches across multiple repositories for a CRISPY feature.

## Process

### 1. Verify Develop Branch Status

For each repository in the provided list:

- Check the current branch with `git branch --show-current`.
- If not on `develop`, notify the user and request permission to switch.
- Check for uncommitted changes with `git status --porcelain`.
- If changes exist, offer to stash them with a descriptive message.

### 2. Pull Latest Develop

- Run `git pull origin develop` for each repo.
- If conflicts occur, **stop immediately** for that repo.
- Report the conflicting files and ask the user how to proceed.
- Continue processing other repos independently.

### 3. Check Branch Naming Convention

- Look for `AGENTS.md` in each repo root for branch naming rules.
- If no convention is found, suggest the default format: `feature/NNN-feature-name`.
- Confirm the branch name with the user before creating.

### 4. Create Feature Branches

- Create the branch with `git checkout -b {branch-name}`.
- Verify the branch was created successfully.
- If a branch with the same name already exists, inform the user and offer options:
  - Check out the existing branch.
  - Delete and recreate it.
  - Use an alternative name.

### 5. Report Summary

Present a summary table showing the result for each repository:

```markdown
| Repository | Status | Branch | Notes |
|---|---|---|---|
| {name} | ✅ Created | feature/042-auth | — |
| {name} | ⚠️ Skipped | — | Conflicts on develop |
| {name} | ℹ️ Existing | feature/042-auth | Already existed, checked out |
```

## Guidelines

- Process each repository independently — one failure should not block others.
- Always use Windows-style paths.
- Never force-push or perform destructive git operations without explicit consent.
- Keep a record of any stashed changes so the user can restore them later.
- Validate that the feature name follows the `NNN-feature-name` convention before proceeding.
