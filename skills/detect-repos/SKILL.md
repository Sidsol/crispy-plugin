---
name: detect-repos
description: "Scan directories for git repositories and analyze cross-repo impact"
---

# Detect Repositories & Analyze Impact

Scan the workspace for git repositories and determine which ones are affected by a proposed feature change.

## Process

### 1. Scan for Repositories

Search the current directory and sibling directories for git repos:

- Check for `.git` directories to identify repositories.
- For each repo, collect: name, path, primary language, framework, and key dependencies.
- Identify the current branch and whether there are uncommitted changes.

### 2. Build Repository Profile

For each discovered repository, determine:

- **Language:** Inspect file extensions and package manifests (package.json, requirements.txt, *.csproj, go.mod, Cargo.toml, etc.).
- **Framework:** Identify the primary framework from dependencies (React, Express, Django, ASP.NET, etc.).
- **Key Packages:** List significant dependencies, especially shared/internal ones.
- **Entry Points:** Locate main entry files (index.ts, main.py, Program.cs, etc.).

### 3. Analyze Feature Impact

Given a feature description or intent document:

- Search for shared packages or imports across repos.
- Identify API contracts (OpenAPI specs, route definitions, client SDKs).
- Look for shared schemas (database models, protobuf, GraphQL).
- Check for common environment variables or configuration.
- Note any shared CI/CD pipelines or deployment dependencies.

### 4. Report Findings

Present results with confidence levels:

- **High:** Direct code reference or dependency found.
- **Medium:** Shared dependency or naming convention suggests coupling.
- **Low:** Indirect relationship worth verifying.

## Output Format

```markdown
## Detected Repositories

| Repository | Path | Language | Framework | Branch |
|---|---|---|---|---|
| {name} | {path} | {lang} | {framework} | {branch} |

## Impact Analysis for: {Feature Name}

| Repository | Impact Reason | Confidence | Action Needed |
|---|---|---|---|
| {name} | {why affected} | High/Medium/Low | {what to do} |
```

## Guidelines

- Use Windows-style paths with backslashes.
- This is a read-only operation — never modify any repository.
- If a repo cannot be analyzed (e.g., access denied), note it and continue.
- Always report the total count of repos found vs. repos affected.
