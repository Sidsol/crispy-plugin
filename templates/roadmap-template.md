# Project Roadmap: [PROJECT_NAME]

<!-- CRISPY Project Phase: PLAN → produces roadmap.md -->
<!-- Sequencing of features into milestones. NOT a calendar — no dates. -->

**Created:** [DATE]
**Sources:** vision.md, domain-research.md, architecture.md, feature-map.md

---

## Milestones

### M1 — Walking Skeleton (MVP cut)

- **Goal:** Smallest end-to-end vertical that proves the architecture and delivers user-visible value.
- **Features included:** [001, 002]
- **Exit criteria:**
  - …
- **Risk notes:** …

### M2 — [Name]

- **Goal:** …
- **Features included:** [003, 004]
- **Exit criteria:**
  - …

### M3 — …

---

## Sequencing Rationale

[Why these milestones in this order. Reference the feature dependency graph in feature-map.md.]

---

## Parallelization Plan

<!-- Which features within a milestone can be run as a feature fleet (independent, no cross-feature file conflicts). -->

| Milestone | Sequential features | Parallel waves                         |
|-----------|---------------------|----------------------------------------|
| M1        | 001                 | wave-1: [002]                          |
| M2        | —                   | wave-1: [003, 004] · wave-2: [005]     |

---

## Cross-Repo Coordination

| Repo (architecture §4)| Touched by features      | Coordination notes                    |
|-----------------------|--------------------------|---------------------------------------|
| api-server            | 001, 002, 003            | …                                     |
| web-app               | 001, 003                 | …                                     |

---

## Risk Mitigation

| Risk                                          | Mitigation                              | Owner-feature |
|-----------------------------------------------|-----------------------------------------|---------------|
| …                                             | …                                       | …             |

---

## Reviewer Findings

<!-- Populated by orchestrator from spec-review + code-review at the roadmap gate. -->
