---
name: scaffold-repos
description: "Initialize local git repos and run framework scaffolders per architecture.md (no remote API calls)"
---

# Scaffold Local Repositories

Initialize each repo from `architecture.md §4 Repositories` as a local git repo, run the framework scaffolder dictated by `§3 Tech Stack`, and produce a `scaffold-report.md`. Print copy-paste commands for remote creation; do NOT call remote APIs.

## When to use

- CRISPY **project** workstream Intention phase, after the architecture review gate passes. Invoked by `crispy-scaffold`.

## When NOT to use

- For per-feature branch creation in existing repos — that's `crispy-branch`'s job.
- For projects where repos already exist (in that case skip; record `status: pre-existing` in `scaffold-report.md`).

## Process

### 1. Read inputs

- `architecture.md §3 Tech Stack` — stack decisions and scaffolder commands.
- `architecture.md §4 Repositories` — list of repos to initialize.
- The CWD (multi-repo root). Each repo will be created as a sibling directory.

### 2. Per-repo workflow

For each row in `§4 Repositories`, **sequentially**:

1. **Pre-flight:**
   - If `<cwd>/<repo-name>` already exists, record `status: pre-existing`, continue.
   - If `§3` choices contain any `TBD — needs user input` row, **stop the entire run** and ask the user to resolve those rows first (per locked default: ask only on ambiguity).

2. **Create directory:** `mkdir <cwd>/<repo-name>`

3. **Run scaffolder:** execute the command implied by `§3 Tech Stack` (e.g., `npm create vite@latest <repo-name> -- --template react-ts`, `dotnet new webapi -o <repo-name>`, `cargo new <repo-name>`). The command MUST be quoted verbatim from `§3` — if it isn't there, stop and ask the user.

4. **`git init`** inside the new repo.

5. **Drop in baseline files:** `.gitignore` appropriate to the stack, `README.md` skeleton (one paragraph from the row's `Purpose`), CI skeleton if `§3` names a CI tool (e.g., `.github/workflows/ci.yml` for GitHub Actions). Do NOT generate runtime application code beyond what the scaffolder already produced.

6. **Initial commit:** `git add . && git commit -m "chore: initial scaffold from CRISPY"` (include the standard Co-authored-by trailer if running in this CLI).

7. **Record outcome** for the report.

### 3. Write `scaffold-report.md`

```markdown
# Scaffold Report — [PROJECT_NAME]

**Date:** YYYY-MM-DD

## Repos Initialized

| Repo | Status | Stack | Initial commit | Notes |
|------|--------|-------|----------------|-------|

## Remote Creation Commands (Copy-Paste)

> CRISPY does not create remote repos. Run these commands yourself when ready.

```bash
# GitHub example
gh repo create <org>/<repo-name> --private --source=./<repo-name> --push
```

(Repeat per repo. Adapt to your host: `az repos create` for ADO, etc.)

## Skipped / Failed

| Repo | Reason |
|------|--------|
```

### 4. Failure handling

Per `SUBAGENTS.md §8`: retry once on transient failure (network, file lock), surface persistent failures. A skipped repo (e.g., already exists) is `status: skipped`, NOT a failure — other repos continue.

## Critical Rules

- **Local-only.** No `gh repo create`, no GitHub/ADO REST calls, no SSH-key creation.
- **No autonomous tech-stack picking.** If `§3` is ambiguous, stop and ask. Never guess.
- **Idempotent on re-run.** If a repo already exists, leave it alone — record `pre-existing` and continue.
- **Co-authored-by** trailer on the initial commit when running in this CLI environment.

## Hand-off

After scaffolding, the orchestrator runs `crispy-feature-map` (which now has real repo paths to reference). Feature-level CRISPY runs use the existing `crispy-branch` agent against these scaffolded repos.
