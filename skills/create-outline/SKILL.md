---
name: create-outline
description: "Generate an outline.md with vertical slice definitions"
---

# Create Vertical Slice Outline

Generate an `outline.md` that breaks the feature into vertical implementation slices. Each slice delivers end-to-end functionality that can be independently verified.

## Process

1. Read `spec.md`, `research.md`, and `intent.md` for the feature.
2. Decompose the selected architecture approach into vertical slices.
3. Define checkpoint criteria for each slice.
4. Write `outline.md` in the feature's spec directory.

## Template Structure

```markdown
# Implementation Outline: {Feature Name}

## Slice Strategy
Brief explanation of how the feature was decomposed and why this slicing approach was chosen.

## Slices

### Slice 1: {Name}
**Scope:** {What this slice delivers end-to-end}
**User Stories:** US-1, US-3
**Deliverables:**
- {Concrete deliverable with file/component reference}
- {Concrete deliverable with file/component reference}

**Checkpoint Criteria:**
- [ ] {Verifiable condition that proves this slice works}
- [ ] {Verifiable condition that proves this slice works}

**Context Notes:**
- Key files: {files the implementer needs open}
- Dependencies: {what must exist before this slice starts}
- Estimated complexity: {Low / Medium / High}

### Slice 2: {Name}
...

## Slice Dependency Graph
```
Slice 1 ──→ Slice 3
Slice 2 ──→ Slice 3
Slice 3 ──→ Slice 4
```

## Context Management
- Maximum files open per slice: {recommendation}
- Recommended context window reset points: {between which slices}
- State that must carry across slices: {shared knowledge}

## Verification Strategy
How the complete feature will be verified after all slices are implemented.
```

## Guidelines

- Each slice must be independently testable and verifiable.
- Slices should be ordered to build on each other — foundational work first.
- Keep slices small enough to implement in a single focused session.
- Context management notes help AI assistants maintain coherence across sessions.
- The dependency graph should make parallel work opportunities visible.
- Checkpoint criteria must be concrete and verifiable, not vague ("it works").
