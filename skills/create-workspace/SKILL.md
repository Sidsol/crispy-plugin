---
name: create-workspace
description: "Generate and optionally open a VS Code multi-root workspace for affected CRISPY repositories. Use after Intent identifies multiple repos."
---

# Create VSCode Workspace

Generates a `.code-workspace` file that contains only the repositories relevant to the current CRISPY feature, plus the `crispy-docs` folder. This gives the user a focused, scoped view of exactly the repos being changed without mutating git branches.

## When to use

- After Intent confirms multiple affected repositories.
- When the user wants a focused multi-repo VSCode view for a CRISPY feature.
- Can be called standalone by any agent that knows the affected repos and feature folder.

## When NOT to use

- Single-repo mode where only one repo is affected — a regular `code <repo>` is simpler.
- When no affected repositories were confirmed.

## Inputs

- `feature_folder` — absolute path to the feature's spec folder (e.g., `D:\Repos\crispy-docs\specs\003-graphql-support\`).
- `feature_name` — the kebab-case feature name (e.g., `003-graphql-support`).
- `repos` — list of objects, each with:
  - `name` — human-readable repo name (e.g., `API Server`)
  - `path` — absolute path to the repo root (e.g., `D:\Repos\api-server`)
- `crispy_docs_path` — absolute path to the `crispy-docs` root folder (e.g., `D:\Repos\crispy-docs\`).
- `auto_open` — boolean (default `true`). When `true`, open the workspace in VSCode after creation.

## Process

### 1. Compute relative paths

The workspace file will live at `{feature_folder}\{feature_name}.code-workspace`. All folder entries use **relative paths** from the workspace file's directory so the workspace is portable across machines.

For each repo in `repos`, compute the relative path from `feature_folder` to `repo.path`. On Windows, use backslash-to-forward-slash conversion since `.code-workspace` files use forward slashes (JSON standard).

For `crispy_docs_path`, compute the relative path from `feature_folder` to the crispy-docs root.

Example: if the workspace file is at `D:\Repos\crispy-docs\specs\003-graphql-support\003-graphql-support.code-workspace` and a repo is at `D:\Repos\api-server`, the relative path is `../../../api-server`.

### 2. Build the workspace JSON

Construct the `.code-workspace` file with this structure:

```json
{
  "folders": [
    {
      "name": "📋 CRISPY Docs",
      "path": "<relative-path-to-crispy-docs>"
    },
    {
      "name": "<repo-name>",
      "path": "<relative-path-to-repo>"
    }
  ],
  "settings": {
    "files.autoSave": "afterDelay",
    "explorer.sortOrder": "type",
    "scm.defaultViewMode": "tree"
  },
  "extensions": {
    "recommendations": []
  }
}
```

Rules:

- The `📋 CRISPY Docs` folder is always first — it's the user's reference material.
- Repo folders follow in the order they were provided in `repos`.
- Use the `name` field from `repos` for display names. If no name was provided, derive one from the repo directory name (e.g., `api-server` → `Api Server`).
- All paths use forward slashes, even on Windows (VSCode `.code-workspace` format requires this).
- The `settings` block provides sensible defaults. Do NOT override user-level settings that are opinionated (e.g., theme, font size).
- The `extensions.recommendations` array is left empty — repos' own `.vscode/extensions.json` files take precedence.

### 3. Write the file

Write the JSON to `{feature_folder}\{feature_name}.code-workspace`.

If a workspace file already exists at that path:
- **Interactive mode:** ask the user whether to overwrite or skip.
- **Autopilot mode:** overwrite and log a `severity: low` finding noting the overwrite.

### 4. Open the workspace in VSCode

If `auto_open` is `true`:

```powershell
code "{feature_folder}\{feature_name}.code-workspace"
```

If `code` is not on PATH or the command fails:
- Do NOT treat this as a failure of the skill.
- Emit a `severity: low` finding: "Could not auto-open workspace. Open manually: `code <path>`."
- Continue to return `status: ok` — the workspace file was still created successfully.

### 5. Emit `crispy-result`

```yaml
status: ok | partial | failed
agent: create-workspace
artifact_path: <feature_folder>\<feature_name>.code-workspace
summary: |
  Created VSCode workspace with {N} repos + crispy-docs.
  Workspace file: <path>
  Auto-opened: true | false
findings: []
next_actions:
  - Monitor code changes across repos in the VSCode workspace.
metadata:
  workspace_path: <absolute-path-to-workspace-file>
  repo_count: <N>
  auto_opened: true | false
  repos_included:
    - name: <repo-name>
      path: <abs-path>
```

## Failure handling

Per `SUBAGENTS.md` §8:

- If `feature_folder` doesn't exist → `status: failed`, instruct caller to create it first.
- If write fails (permissions, disk full) → `status: failed` with the error.
- If `code` CLI fails → `status: ok` (workspace file still created), `severity: low` finding.
- If no repos provided → `status: partial`, nothing to create.

## Anti-patterns

- ❌ Using absolute paths in the `.code-workspace` file (breaks portability).
- ❌ Creating, switching, pulling, fetching, stashing, deleting, or pushing git branches.
- ❌ Including repos that were not confirmed as affected by Intent or `crispy-scan`.
- ❌ Overriding user-level VSCode settings (theme, keybindings, etc.) in the workspace settings.
- ❌ Treating a `code` CLI failure as a skill failure — the artifact was still created.
