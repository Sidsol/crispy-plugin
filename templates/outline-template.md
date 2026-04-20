# Structure: [FEATURE_NAME]

<!-- CRISPY Phase: STRUCTURE → produces outline.md -->
<!-- This document breaks the feature into vertical slices — small, end-to-end -->
<!-- increments that each deliver testable value. Each slice should be completable -->
<!-- within a single AI context window (stay under 40% context usage per slice). -->

| Field              | Value                                   |
|--------------------|-----------------------------------------|
| **Feature**        | [FEATURE_NAME]                          |
| **Date**           | [DATE]                                  |
| **Spec Reference** | `[NNN-FEATURE-NAME]/spec.md`           |
| **Intent Ref**     | `[NNN-FEATURE-NAME]/intent.md`         |
| **Architecture**   | [Selected approach from intent.md]      |

---

## 1. Vertical Slices Overview

<!-- Each slice is a thin, end-to-end piece of functionality. -->
<!-- Order slices so each builds on the previous one. -->
<!-- Map stories from spec.md to slices. -->

| Slice   | Name                    | Stories Covered | Estimated Effort | Depends On |
|---------|-------------------------|-----------------|------------------|------------|
| Slice 1 | [e.g., Data Foundation] | —               | [S/M/L]          | —          |
| Slice 2 | [e.g., Core CRUD]      | S-001           | [S/M/L]          | Slice 1    |
| Slice 3 | [e.g., Business Logic]  | S-001, S-002    | [S/M/L]          | Slice 2    |
| Slice 4 | [e.g., UI Integration]  | S-002           | [S/M/L]          | Slice 2    |
| Slice 5 | [e.g., Polish & Edge]  | S-003           | [S/M/L]          | Slice 3, 4 |

---

## 2. Slice Definitions

### Slice 1: [Name — e.g., "Data Foundation"]

**Scope:** [What this slice delivers — keep it narrow and testable]

**Stories addressed:** [None — infrastructure / S-001 / etc.]

#### Deliverables

- [ ] [Deliverable 1 — e.g., Database migration for new table]
- [ ] [Deliverable 2 — e.g., Entity model and repository]
- [ ] [Deliverable 3 — e.g., Unit tests for repository]

#### End-to-End Flow

```
[DB Layer]          → [Service Layer]      → [API Layer]         → [UI Layer]
──────────────────────────────────────────────────────────────────────────────
Create table/model  → Repository methods   → (not yet exposed)  → (not yet)
```

#### Checkpoint Criteria

<!-- All must be true before moving to the next slice. -->

- [ ] [Criterion 1 — e.g., Migration runs successfully up and down]
- [ ] [Criterion 2 — e.g., Repository CRUD tests pass]
- [ ] [Criterion 3 — e.g., No regressions in existing test suite]

---

### Slice 2: [Name — e.g., "Core CRUD API"]

**Scope:** [What this slice delivers]

**Stories addressed:** [S-001]

#### Deliverables

- [ ] [Deliverable 1 — e.g., REST endpoints for CRUD operations]
- [ ] [Deliverable 2 — e.g., Input validation middleware]
- [ ] [Deliverable 3 — e.g., Integration tests for endpoints]

#### End-to-End Flow

```
[DB Layer]          → [Service Layer]      → [API Layer]         → [UI Layer]
──────────────────────────────────────────────────────────────────────────────
(from Slice 1)      → Business logic       → REST endpoints      → (not yet)
```

#### Checkpoint Criteria

- [ ] [Criterion 1 — e.g., All CRUD endpoints return correct responses]
- [ ] [Criterion 2 — e.g., Validation rejects invalid input]
- [ ] [Criterion 3 — e.g., Integration tests pass]

---

### Slice 3: [Name — e.g., "Business Logic & Rules"]

**Scope:** [What this slice delivers]

**Stories addressed:** [S-001, S-002]

#### Deliverables

- [ ] [Deliverable 1]
- [ ] [Deliverable 2]
- [ ] [Deliverable 3]

#### End-to-End Flow

```
[DB Layer]          → [Service Layer]      → [API Layer]         → [UI Layer]
──────────────────────────────────────────────────────────────────────────────
(from Slice 1)      → [New logic]          → [Updated endpoints] → (not yet)
```

#### Checkpoint Criteria

- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] [Criterion 3]

---

### Slice 4: [Name — e.g., "UI Integration"]

**Scope:** [What this slice delivers]

**Stories addressed:** [S-002]

#### Deliverables

- [ ] [Deliverable 1]
- [ ] [Deliverable 2]

#### End-to-End Flow

```
[DB Layer]          → [Service Layer]      → [API Layer]         → [UI Layer]
──────────────────────────────────────────────────────────────────────────────
(from Slice 1)      → (from Slice 2-3)    → (from Slice 2-3)   → Components
```

#### Checkpoint Criteria

- [ ] [Criterion 1]
- [ ] [Criterion 2]

---

### Slice 5: [Name — e.g., "Polish, Edge Cases & Hardening"]

**Scope:** [What this slice delivers]

**Stories addressed:** [S-003, edge cases]

#### Deliverables

- [ ] [Deliverable 1 — e.g., Edge case handling from EC-001, EC-002]
- [ ] [Deliverable 2 — e.g., Error states and fallback UI]
- [ ] [Deliverable 3 — e.g., Performance optimization for NFR-001]

#### Checkpoint Criteria

- [ ] [Criterion 1 — e.g., All edge cases from spec.md §3 covered]
- [ ] [Criterion 2 — e.g., Performance meets NFR targets]
- [ ] [Criterion 3 — e.g., Full regression suite green]

---

## 3. Dependency Graph

<!-- Visual representation of slice dependencies. -->

```
Slice 1 (Data Foundation)
   │
   ├──→ Slice 2 (Core CRUD)
   │       │
   │       ├──→ Slice 3 (Business Logic)
   │       │       │
   │       └──→ Slice 4 (UI Integration)
   │               │
   └───────────────┴──→ Slice 5 (Polish & Edge Cases)
```

### Parallel Opportunities

<!-- Which slices can be worked on simultaneously? -->

- Slices [3] and [4] can be developed in parallel after Slice 2 is complete
- [Any other parallelization opportunities]

---

## 4. Context Management Notes

<!-- CRISPY guideline: stay under 40% context usage per AI session. -->
<!-- Plan context boundaries so the AI starts fresh when needed. -->

| AI Session | Slices to Complete | Context Strategy                           |
|------------|--------------------|--------------------------------------------|
| Session 1  | Slice 1            | Fresh context. Load: spec.md, intent.md    |
| Session 2  | Slice 2            | Fresh context. Load: spec.md, Slice 1 code |
| Session 3  | Slice 3            | Fresh context. Load: spec.md, Slice 1-2 interfaces |
| Session 4  | Slice 4            | Fresh context. Load: spec.md, API contracts |
| Session 5  | Slice 5            | Fresh context. Load: spec.md, all test files |

### Context Reset Triggers

<!-- When to start a new AI context session: -->

- [ ] Current context exceeds ~40% usage
- [ ] Switching to a different vertical slice
- [ ] AI output quality degrades (repetition, hallucination)
- [ ] Major direction change after human review

---

<!-- NOTE FOR AI AGENT: -->
<!-- After completing the outline, the next CRISPY phase is PLAN. -->
<!-- Each slice defined here will become a detailed implementation phase in plan.md -->
<!-- and a set of ordered tasks in tasks.md. -->
<!-- Ensure every story from spec.md maps to at least one slice. -->
