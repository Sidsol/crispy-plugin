---
name: create-outline
description: "Generate an outline.md with vertical slice definitions"
user-invocable: false
---

# Create Vertical Slice Outline

Generate an `outline.md` that breaks the feature into vertical implementation slices. Each slice delivers end-to-end functionality that can be independently verified.

## Process

1. Read `spec.md`, `research.md`, and `intent.md` for the feature.
2. Decompose the selected architecture approach into vertical slices.
3. Define checkpoint criteria for each slice.
4. Write `outline.md` in the feature's spec directory.

## Standalone Mode (Missing Input Fallback)

When invoked outside the full CRISPY orchestration:

**Required inputs**: Feature goal, rough architecture approach.

**Missing `spec.md`**: Prompt user for P1 requirements. Document inline in `outline.md` preamble with note: *"spec.md unavailable; requirements gathered directly."*

**Missing `research.md`**: Skip current-state context. Slices will be less informed but still executable. Note: *"research.md unavailable; slicing based on requirements only."*

**Missing `intent.md`**: Prompt user for architecture approach. Document inline in `outline.md` with note: *"intent.md unavailable; approach documented inline."*

**Partial status**: If slicing logic requires deeper architecture analysis, return:
```yaml
status: partial
reason: "Slicing incomplete due to missing architecture context from intent.md."
next_action: "Run crispy-intent or provide architecture approach description."
partial_output: "<path to incomplete outline.md>"
```

**Automation classification**: When missing intent/research, default to `automation: HITL` with reason: *"Conservative HITL classification due to missing prior analysis."*

**Normal orchestrated flow**: When `spec.md`, `research.md`, and `intent.md` are present, proceed as documented with full automation analysis.

## Template Structure

The outline MUST include:

- A **Slices Overview** table with `Parallelizable` (true/false) and `Depends On` columns so `crispy-implement` can decide sequential vs fleet execution at a glance.
- A **Slice Dependency Graph (Machine-Readable)** section emitting a fenced yaml block (schema below).

```markdown
# Implementation Outline: {Feature Name}

## Slice Strategy
Brief explanation of how the feature was decomposed and why this slicing approach was chosen.

## Slices Overview

| Slice | Name | Stories | Estimated Effort | Depends On | Parallelizable | Automation | Automation Reason |
|---|---|---|---|---|---|---|---|
| 1 | {name} | S-001 | M | — | false | HITL | {justification} |
| 2 | {name} | S-002 | S | 1 | false | AFK | {justification} |
| 3 | {name} | S-003 | M | 1 | true | HITL | {justification} |

## Slices

### Slice 1: {Name}
**Scope:** {What this slice delivers end-to-end}
**User Stories:** US-1, US-3
**Automation:** HITL | AFK
**Automation Reason:** {One-sentence justification for the classification}

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

## Slice Dependency Graph (Machine-Readable)

```yaml
slices:
  - id: 1
    name: <name>
    depends_on: []
    parallelizable: false
    automation: HITL
    automation_reason: "<one-sentence justification>"
    checkpoint_criteria_count: <n>
```

> **Note:** `parallelizable` is a static planning-time hint, not a runtime guarantee. `crispy-implement` re-evaluates parallelizability dynamically based on dependency satisfaction and file-set conflict detection at execution time.

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
- **Automation classification**: Every slice must include `automation: HITL | AFK` and `automation_reason`. Use `HITL` (human-in-the-loop) when the slice touches safety-critical orchestration, manifest validation, review-gate behavior, blindness semantics, dangerous commands, or requires human judgment on user experience or policy decisions. Use `AFK` (away-from-keyboard / fully automated) only when the slice is purely additive, has comprehensive test coverage, and introduces no new safety boundaries.
