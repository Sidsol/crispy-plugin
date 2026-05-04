# Pre-Implementation Checklist: [FEATURE_NAME]

<!-- CRISPY Phase: YIELD → produces checklist.md -->
<!-- This is the final gate before writing production code. -->
<!-- Every box must be checked or explicitly waived with justification. -->
<!-- "Yield" means: pause, verify everything is solid, THEN proceed. -->

| Field              | Value                                   |
|--------------------|-----------------------------------------|
| **Feature**        | [FEATURE_NAME]                          |
| **Implementation Branch** | Current branch at implementation start |
| **Date**           | [DATE]                                  |
| **Gate Decision**  | 🟢 GO · 🟡 GO WITH CAVEATS · 🔴 NO-GO |

---

## Part 1: CRISPY Quality Gates

<!-- These gates validate that the CRISPY process was followed correctly. -->
<!-- If any gate fails, the corresponding artifact needs rework. -->

### 🔬 Research is Blind

- [ ] AI mapped the codebase **before** knowing the feature goal
- [ ] Research document captures objective current state
- [ ] No confirmation bias detected (research doesn't "pre-solve" the feature)
- [ ] Technical debt was honestly documented
- [ ] Research vocabulary sidecar (`CONTEXT.research-vocabulary.md`) contains only codebase-discovered terms with evidence

> **If failed:** Redo research.md with a fresh AI context that has no knowledge of spec.md.

### 📚 Source-Learning Traceability (L1)

- [ ] Workflow changes reference explicit learning IDs (L1-L10) or research findings
- [ ] Transcript/caption limitations are preserved in documentation (no direct transcript coverage claims)
- [ ] Public-agent boundary documented (only `@crispy`, `@crispy-project`, `@crispy-implement` user-invocable)

> **If failed:** Add source-learning IDs or research citations to changed prompts/docs.

### 🎯 Intent is Sound

- [ ] Current state accurately reflects research findings
- [ ] Gap analysis is complete (nothing missing between current → desired)
- [ ] At least 2 architecture options were evaluated
- [ ] Selected approach has clear justification
- [ ] Anti-patterns from codebase were identified and documented
- [ ] Architecture choice was reviewed (and corrected if needed)

> **If failed:** Update intent.md with missing analysis. If architecture was wrong, document the correction.

### 🔪 Vertical Slices

- [ ] Feature is broken into end-to-end slices (not horizontal layers)
- [ ] Each slice delivers independently testable value
- [ ] Slices are ordered by dependency (no circular dependencies)
- [ ] Every story from spec.md maps to at least one slice
- [ ] Checkpoint criteria defined for each slice

> **If failed:** Restructure outline.md. Each slice should be: DB → Service → API → UI (as applicable).

### 📋 Plan is Tactical

- [ ] Every task specifies exact file paths (CREATE / MODIFY / DELETE)
- [ ] No vague tasks (e.g., "implement the service" is not acceptable)
- [ ] Verification method defined for each task
- [ ] Complexity estimates provided
- [ ] Dependencies between tasks are explicit

> **If failed:** Add file-level detail to plan.md and tasks.md until an AI can execute without asking questions.

### 🧠 Context is Fresh

- [ ] Plan accounts for context resets between slices
- [ ] No single slice requires > 40% of AI context window
- [ ] Context management notes included in outline.md
- [ ] Large slices are broken into sub-slices if needed

> **If failed:** Split oversized slices in outline.md. Add context boundary markers.

---

## Part 2: Artifact Completeness

<!-- Verify all CRISPY artifacts exist and are consistent with each other. -->

### Documents

- [ ] `spec.md` — Feature specification complete and reviewed
- [ ] `research.md` — Blind research complete
- [ ] `intent.md` — Architecture decisions documented
- [ ] `outline.md` — Vertical slices defined
- [ ] `plan.md` — Line-level implementation plan
- [ ] `tasks.md` — Ordered task list with verification steps
- [ ] `contracts/` directory — API/interface contracts (if applicable; **prefer `contracts/` over `contracts.md`**)
- [ ] `CONTEXT.md` — Ubiquitous language artifact (if present; legacy feature folders may not have it)
- [ ] `checklist.md` — This file, all gates passing

### Cross-Reference Consistency

- [ ] All stories in spec.md are referenced in outline.md slices
- [ ] All outline.md slices have corresponding plan.md phases
- [ ] All plan.md steps have corresponding tasks.md entries
- [ ] Requirements (FR-xxx) trace through to implementation tasks
- [ ] Success criteria (SC-xxx) trace to verification steps

---

## Part 3: Pre-Implementation Checks

<!-- Environment and repository readiness. -->

### Repository Setup

- [ ] Implementation base/current branch identified for each affected repo
- [ ] No repo-wide feature branch was created during planning
- [ ] Working tree is clean in each affected repo
- [ ] CI or local verification baseline is known before any changes

### Affected Repos Confirmed

| Repository       | Current Branch | Clean Tree | Baseline Known | Notes           |
|------------------|----------------|------------|----------------|-----------------|
| `[repo-name]`   | `[branch]`     | [ ]        | [ ]            |                 |
| `[repo-name]`   | `[branch]`     | [ ]        | [ ]            |                 |

### Environment

- [ ] Local development environment working
- [ ] Required services/databases accessible
- [ ] API keys / secrets available (not hardcoded)
- [ ] Test data or seed scripts ready

---

## Part 4: Implementation Checks

<!-- To be completed DURING and AFTER implementation. -->

### During Implementation

- [ ] Working through tasks.md in order
- [ ] Committing after each phase gate
- [ ] Running tests after each task
- [ ] Updating tasks.md checkboxes as completed
- [ ] Resetting AI context at slice boundaries

### Post-Implementation

- [ ] All tasks in tasks.md marked complete
- [ ] Full test suite passes (`[test command]`)
- [ ] No linting errors (`[lint command]`)
- [ ] Code reviewed line-by-line (self-review)
- [ ] All acceptance scenarios from spec.md verified
- [ ] Edge cases from spec.md §3 covered
- [ ] NFRs from spec.md §4 verified
- [ ] No hardcoded secrets, URLs, or credentials
- [ ] No TODO/FIXME/HACK comments left unresolved
- [ ] API documentation updated (if applicable)

---

## Part 5: PR Readiness

- [ ] PR title follows convention: `[NNN] [FEATURE_NAME]: [Brief description]`
- [ ] PR description includes:
  - [ ] Summary of changes
  - [ ] Link to spec.md
  - [ ] Testing instructions
  - [ ] Screenshots (if UI changes)
  - [ ] Breaking changes noted (if any)
- [ ] All CI checks passing
- [ ] Reviewer(s) assigned
- [ ] Labels applied

---

## Part 6: Category Checks

<!-- Domain-specific checks based on what this feature touches. -->

### Database Changes

- [ ] Migration tested: up AND down
- [ ] Indexes added for query patterns
- [ ] No breaking schema changes (or migration path documented)
- [ ] Backup/rollback plan for production data

### API Changes

- [ ] Contracts.md matches implementation
- [ ] Backward compatibility maintained (or versioned)
- [ ] Error responses follow standard format
- [ ] Rate limiting considered
- [ ] Authentication/authorization verified

### UI Changes

- [ ] Responsive design tested
- [ ] Loading states implemented
- [ ] Error states implemented
- [ ] Accessibility basics checked (keyboard nav, alt text, contrast)
- [ ] Browser compatibility verified

### Security

- [ ] Input validation on all user-provided data
- [ ] SQL injection prevention (parameterized queries)
- [ ] XSS prevention (output encoding)
- [ ] CSRF protection (if applicable)
- [ ] Sensitive data not logged

---

## Gate Decision

### Summary

| Gate                  | Status | Notes                                    |
|-----------------------|--------|------------------------------------------|
| Research is Blind     | [✅/❌] | [notes]                                  |
| Intent is Sound       | [✅/❌] | [notes]                                  |
| Vertical Slices       | [✅/❌] | [notes]                                  |
| Plan is Tactical      | [✅/❌] | [notes]                                  |
| Context is Fresh      | [✅/❌] | [notes]                                  |
| Artifacts Complete    | [✅/❌] | [notes]                                  |
| Pre-Impl Ready        | [✅/❌] | [notes]                                  |

### Decision: [🟢 GO / 🟡 GO WITH CAVEATS / 🔴 NO-GO]

**Rationale:** [Why this decision was made]

**Caveats (if GO WITH CAVEATS):**
- [Caveat 1 — what to watch for]
- [Caveat 2 — what to revisit]

---

<!-- NOTE FOR AI AGENT: -->
<!-- This checklist is the FINAL gate before writing production code. -->
<!-- If the gate decision is GO, proceed to implement tasks.md in order. -->
<!-- If GO WITH CAVEATS, note the caveats and proceed carefully. -->
<!-- If NO-GO, identify which artifact needs rework and fix it first. -->
<!-- Do NOT skip this checklist — it's the "No Slop" guarantee. -->
