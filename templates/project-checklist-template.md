# Pre-Implementation Project Checklist: [PROJECT_NAME]

<!-- CRISPY Project Phase: YIELD → produces project-checklist.md -->
<!-- Validates that the project-level CRISPY run is ready to fan out into feature-level CRISPY runs. -->

**Validated:** [DATE]
**Project folder:** `crispy-docs/projects/NNN-PROJECT/`

---

## Artifact Completeness

| Phase     | Artifact                  | Status | Notes |
|-----------|---------------------------|--------|-------|
| Clarify   | vision.md                 | ✅ / ❌ |       |
| Research  | domain-research.md        | ✅ / ❌ |       |
| Intention | architecture.md           | ✅ / ❌ |       |
| Intention | scaffold-report.md (or N/A) | ✅ / ❌ / N/A |  |
| Structure | feature-map.md            | ✅ / ❌ |       |
| Plan      | roadmap.md                | ✅ / ❌ |       |

---

## CRISPY Quality Gates

- [ ] **Domain research was blind** — domain-research.md header present; no vision.md leakage.
- [ ] **Review gates passed** — `review-gates.yaml` shows `gates.architecture.status == passed` AND `gates.feature_map.status == passed` AND `gates.roadmap.status == passed`. Reviewer may be `spec-review+code-review` (autopilot) or `user` (interactive).
- [ ] **Architecture has a `## Tech Stack {#tech-stack}` section** that `crispy-scaffold` could parse.
- [ ] **Every feature in feature-map has a folder** under `features/NNN-feature-name/` (orchestrator pre-creates empty folders so feature-level runs find them).
- [ ] **Every feature has a `depends_on` entry** (possibly `[]`) in the machine-readable graph.
- [ ] **No feature's estimated slice count exceeds 10** without an `auto_split_from` entry in the auto-split log.

---

## Consistency Checks

- [ ] Every theme in `vision.md §4` is covered by ≥1 feature in `feature-map.md`.
- [ ] Every feature in `feature-map.md` is included in some milestone in `roadmap.md`.
- [ ] Architecture's listed repos (`§4`) match the repos `crispy-scaffold` actually initialized (or marked deferred).
- [ ] No contradictions between `architecture.md §3 Tech Stack` and per-feature briefs in `feature-map.md`.

---

## Scaffold Status

- [ ] All repos in `architecture.md §4` initialized as local git repos OR explicitly marked deferred in `scaffold-report.md`.
- [ ] `scaffold-report.md` ends with copy-paste commands for remote creation (CRISPY does not call remote APIs).

---

## Hand-off Readiness

- [ ] `project-manifest.yaml` written and `ready: true`.
- [ ] Feature folders pre-created so `@crispy <feature-folder>` can resume into a feature-level run that inherits architecture.md + domain-research.md.

---

## Issues Found

<!-- Each issue MUST also appear as a blocker in project-manifest.yaml when ready=false. -->

---

## Summary

[One paragraph: is this project ready for feature-level runs? Any blockers?]
