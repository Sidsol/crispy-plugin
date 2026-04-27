# Feature Map: [PROJECT_NAME]

<!-- CRISPY Project Phase: STRUCTURE → produces feature-map.md -->
<!-- Decomposes the project into FEATURES. Each feature is the unit a feature-level CRISPY run consumes. -->

**Created:** [DATE]
**Project:** [PROJECT_NAME]
**Sources:** vision.md, domain-research.md, architecture.md

---

## Feature Decomposition Rules

- Each feature is INDEPENDENTLY DELIVERABLE end-to-end.
- Features are sized to fit within a feature-level CRISPY run (3–8 vertical slices each).
- Estimated slice count per feature MUST appear in the table.
- If a feature's estimate exceeds **10 slices**, AUTO-SPLIT into sibling features (e.g., `payments-core` + `payments-refunds`) and record both rows here.
- Project-size cap: none. Surface complexity warnings but do not block.

---

## Features Overview

| ID  | Feature                   | Theme (vision §4) | Est. slices | Depends on    | Parallelizable | Priority |
|-----|---------------------------|-------------------|-------------|---------------|----------------|----------|
| 001 | [user-accounts]           | TH-01             | 5           | []            | true           | P1       |
| 002 | [billing-core]            | TH-02             | 6           | [001]         | false          | P1       |
| 003 | [billing-refunds]         | TH-02             | 4           | [002]         | true           | P2       |
| 004 | …                         | …                 | …           | …             | …              | …        |

`Depends on` lists feature IDs from this same table. `Parallelizable: true` is a hint for autopilot fan-out — `crispy-project` decides waves at runtime from the dependency graph.

---

## Feature Dependency Graph (Machine-Readable)

```yaml
features:
  - id: 001
    name: user-accounts
    folder: features/001-user-accounts
    theme: TH-01
    priority: P1
    estimated_slices: 5
    depends_on: []
    parallelizable: true
    auto_split_from: null
  - id: 002
    name: billing-core
    folder: features/002-billing-core
    theme: TH-02
    priority: P1
    estimated_slices: 6
    depends_on: [001]
    parallelizable: false
    auto_split_from: null
  - id: 003
    name: billing-refunds
    folder: features/003-billing-refunds
    theme: TH-02
    priority: P2
    estimated_slices: 4
    depends_on: [002]
    parallelizable: true
    auto_split_from: 002    # was split off because parent estimate exceeded 10 slices
```

Every feature in the overview table MUST appear here exactly once.

---

## Per-Feature Briefs

<!-- 1 paragraph per feature: enough for the feature-level Clarify phase to start with context, NOT a full spec. -->

### 001 · user-accounts

- **Goal:** …
- **Architecture sections relevant:** §3 tech-stack, §6 data-model
- **Key user stories from vision:** TH-01 / [story refs]
- **Open questions for feature-level Clarify:** …

### 002 · billing-core

- …

---

## Auto-Split Log

<!-- One entry per feature created via the >10-slice auto-split heuristic. -->

| Original theme | Split into          | Reason                                       |
|----------------|---------------------|----------------------------------------------|
| billing        | billing-core (002), billing-refunds (003) | Combined estimate was 12 slices |

---

## Risk & Complexity Notes

- **Highest-complexity features:** [list]
- **Cross-feature integration risks:** …
- **Soft warning thresholds tripped:** [e.g., >15 features in project]

---

## Reviewer Findings

<!-- Populated by orchestrator from spec-review + code-review at the feature-map gate. -->
