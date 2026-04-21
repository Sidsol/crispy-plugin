---
name: init-crispy-docs
description: "Initialize crispy-docs folder structure for a new feature"
---

# Initialize CRISPY Docs Structure

Set up the `crispy-docs/` folder structure for a new feature, handling both single-repo and multi-repo project configurations.

## Process

### 1. Detect Project Mode

Determine whether this is a **multi-repo** or **single-repo** project:

- **Multi-repo:** A dedicated `crispy-docs` repository exists as a sibling directory (e.g., `D:\Repos\crispy-docs\`). Specs live there and reference other repos.
- **Single-repo:** No dedicated docs repo exists. Create `crispy-docs/` inside the current repository.

### 2. Auto-Increment Feature Number

Scan the `crispy-docs/specs/` directory for existing feature folders:

- Feature folders follow the `NNN-feature-name` pattern (e.g., `001-user-auth`, `002-dashboard`).
- Find the highest existing number and increment by 1.
- If no features exist yet, start at `001`.
- Pad the number to 3 digits.

### 3. Create Folder Structure

```
crispy-docs/
└── specs/
    └── NNN-feature-name/
        ├── spec.md               (empty placeholder)
        ├── research.md           (empty placeholder)
        ├── intent.md             (empty placeholder)
        ├── outline.md            (empty placeholder)
        ├── plan.md               (empty placeholder)
        ├── tasks.md              (empty placeholder)
        ├── checklist.md          (empty placeholder)
        ├── review-gates.yaml     (empty gate placeholder)
        └── contracts/            (empty directory)
```

Each placeholder file should contain a YAML front matter header:

```markdown
---
feature: NNN-feature-name
document: {document type}
status: not-started
created: {YYYY-MM-DD}
---

# {Document Title}: {Feature Name}

> This document has not been started yet. Use the `create-{type}` skill to generate it.
```

The `review-gates.yaml` placeholder uses a different format:

```yaml
# Review gates — populated by crispy orchestrator after rubber-duck reviews
gates: {}
```

This file is required by `crispy-yield` and `crispy-implement`. Creating it at init time prevents a "missing review-gates.yaml" blocker during Yield validation.

### 4. Handle Single-Repo .gitignore

In **single-repo mode only**, check if `crispy-docs/` should be added to `.gitignore`:

- If `.gitignore` exists and does not already contain `crispy-docs/`, ask the user if they want to add it.
- Rationale: In single-repo mode, CRISPY docs are planning artifacts that may not belong in version control.
- In multi-repo mode, the docs repo is version-controlled by design — do not modify `.gitignore`.

### 5. Confirmation

After creation, display the resulting structure and confirm:

```
✅ Created feature folder: crispy-docs/specs/003-new-feature/
   Mode: single-repo
   Files: 7 placeholders + contracts/ directory
```

## Guidelines

- Always ask the user for the feature name if not provided.
- Feature names should be lowercase, hyphenated, and descriptive (e.g., `user-authentication`, `payment-refunds`).
- Never overwrite an existing feature folder — if the number or name conflicts, alert the user.
- The `contracts/` directory starts empty and is populated by the `create-contracts` skill.
- Preserve any existing content in `crispy-docs/specs/` — only add, never remove.
