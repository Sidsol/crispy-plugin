# Intent: [FEATURE_NAME]

<!-- CRISPY Phase: INTENTION → produces intent.md -->
<!-- This document bridges the gap between what exists (research.md) and what -->
<!-- we want (spec.md). It defines the architectural approach and justifies -->
<!-- decisions before any code is written. -->

| Field              | Value                                   |
|--------------------|-----------------------------------------|
| **Feature**        | [FEATURE_NAME]                          |
| **Date**           | [DATE]                                  |
| **Spec Reference** | `[NNN-FEATURE-NAME]/spec.md`           |
| **Research Ref**   | `[NNN-FEATURE-NAME]/research.md`       |
| **Status**         | Draft · In Review · Approved            |

---

## 1. Current State

<!-- Summarize how things work NOW. Reference specific findings from research.md. -->
<!-- Do NOT re-document everything — point to research.md sections and highlight -->
<!-- what matters for this feature. -->

### How It Works Today

[Summarize the relevant current behavior. Reference research.md sections.]

- **Data flow:** [How data currently moves through the system]
- **User experience:** [How users currently interact with this area]
- **Key limitations:** [What can't be done today]

### Relevant Research Findings

<!-- Cherry-pick the findings from research.md that directly impact this feature. -->

| Research Finding              | Impact on This Feature                          |
|-------------------------------|------------------------------------------------|
| [Finding from research.md]    | [How it affects our approach]                  |
| [Finding from research.md]    | [How it affects our approach]                  |

---

## 2. Desired State

<!-- Describe the target state AFTER the feature is implemented. -->
<!-- Reference spec.md stories and requirements. -->

### Target Behavior

[Describe what the system should do after implementation. Be specific.]

- **Data flow:** [How data will move in the new system]
- **User experience:** [How users will interact with the new feature]
- **Key capabilities:** [What becomes possible]

### Spec Requirements Addressed

| Requirement | Description                              | How Addressed              |
|-------------|------------------------------------------|----------------------------|
| FR-001      | [From spec.md]                           | [Approach]                 |
| FR-002      | [From spec.md]                           | [Approach]                 |
| NFR-001     | [From spec.md]                           | [Approach]                 |

---

## 3. Gap Analysis

<!-- What specifically needs to change to get from current → desired state? -->

| Gap ID | Current State               | Desired State                | Change Required              |
|--------|-----------------------------|------------------------------|------------------------------|
| G-001  | [What exists now]           | [What should exist]          | [What to build/modify]       |
| G-002  | [What exists now]           | [What should exist]          | [What to build/modify]       |
| G-003  | [Nothing exists]            | [New capability needed]      | [What to build from scratch] |

---

## 3a. Module Surface Analysis

<!-- L9 source-learning: testability and isolation planning. -->
<!-- For each new or significantly modified module, analyze: -->

| Module | Required Inputs | Optional Inputs | Callers (count) | Deletion Test | Isolated-Test Candidate? |
|--------|-----------------|-----------------|-----------------|---------------|--------------------------|
| [module-name] | [count] | [count] | [≥2 or <2] | [Pass: complexity reappears / Fail: inline] | [Yes: stable interface, no external deps, ≥2 callers OR ≥3 branches / No: unstable or external deps] |

**Deletion test**: "If I delete this module, does the same complexity reappear in ≥ 2 callers?"
- **Pass**: Abstraction justified, keep module.
- **Fail**: Consider inlining into single caller.

**Isolated-test candidate criteria**:
- Interface is stable (not actively changing during implementation).
- Testable without network/filesystem/interactive dependencies.
- ≥ 2 distinct callers OR embeds nontrivial logic (≥ 3 branches or complex transformations).

Plan will consume isolated-test candidates when present; absence is not a blocker.

---

## 4. Architecture Options

<!-- Present at least 2-3 options. Be honest about trade-offs. -->

### Option A: [Name — e.g., "Extend Existing Service"]

**Description:** [How this approach works]

| Pros                                  | Cons                                    |
|---------------------------------------|-----------------------------------------|
| [Pro 1]                               | [Con 1]                                |
| [Pro 2]                               | [Con 2]                                |
| [Pro 3]                               | [Con 3]                                |

**Estimated complexity:** [Low / Medium / High]
**Estimated timeline impact:** [Faster / Neutral / Slower]

---

### Option B: [Name — e.g., "New Microservice"]

**Description:** [How this approach works]

| Pros                                  | Cons                                    |
|---------------------------------------|-----------------------------------------|
| [Pro 1]                               | [Con 1]                                |
| [Pro 2]                               | [Con 2]                                |

**Estimated complexity:** [Low / Medium / High]
**Estimated timeline impact:** [Faster / Neutral / Slower]

---

### Option C: [Name — e.g., "Third-Party Integration"]

**Description:** [How this approach works]

| Pros                                  | Cons                                    |
|---------------------------------------|-----------------------------------------|
| [Pro 1]                               | [Con 1]                                |
| [Pro 2]                               | [Con 2]                                |

**Estimated complexity:** [Low / Medium / High]
**Estimated timeline impact:** [Faster / Neutral / Slower]

---

## 5. Selected Approach

### Decision: **Option [X]: [Name]**

**Justification:**

[Explain WHY this option was selected over the others. Reference specific project
constraints, team capabilities, or timeline requirements that drove the decision.]

1. [Reason 1 — e.g., "Aligns with existing patterns found in research.md §7"]
2. [Reason 2 — e.g., "Meets NFR-001 performance requirement without new infra"]
3. [Reason 3 — e.g., "Lowest risk given current technical debt in TD-002"]

---

## 6. Anti-Patterns to Avoid

<!-- Patterns found in the codebase (or common in the ecosystem) that we should -->
<!-- explicitly NOT follow. Reference research.md technical debt where applicable. -->

| Anti-Pattern                     | Why to Avoid                              | What to Do Instead           |
|----------------------------------|-------------------------------------------|------------------------------|
| [e.g., God class / fat service] | [Found in research TD-001; hard to test]  | [Single-responsibility modules] |
| [e.g., Raw SQL in controllers]  | [Injection risk, hard to maintain]        | [Repository pattern / ORM]   |
| [e.g., Callback nesting]        | [Found in research TD-004; readability]   | [async/await throughout]     |

---

## 7. Affected Repositories

<!-- For multi-repo awareness: list every repo this feature touches. -->

| Repository             | Changes Expected                         | Branch Name            |
|------------------------|------------------------------------------|------------------------|
| `[repo-name]`         | [Brief description of changes]           | `[NNN-FEATURE-NAME]`  |
| `[repo-name]`         | [Brief description of changes]           | `[NNN-FEATURE-NAME]`  |

### Cross-Repo Dependencies

<!-- If changes must be deployed in a specific order, document it here. -->

```
[repo-A] must deploy before [repo-B] because [reason]
[repo-B] and [repo-C] can deploy in parallel
```

---

## 8. Risk Assessment

| Risk ID | Description                              | Probability | Impact | Mitigation                      |
|---------|------------------------------------------|-------------|--------|---------------------------------|
| R-001   | [e.g., Database migration may lock tables] | Medium      | High   | [Run during maintenance window] |
| R-002   | [e.g., Third-party API rate limits]       | Low         | Medium | [Implement circuit breaker]     |
| R-003   | [e.g., Breaking change to public API]     | High        | High   | [Version the API endpoint]      |

---

<!-- NOTE FOR AI AGENT: -->
<!-- After completing this intent document, the next CRISPY phase is STRUCTURE. -->
<!-- The intent.md should be reviewed by a human before proceeding to outline.md. -->
<!-- If the selected approach was corrected during review, update this document -->
<!-- to reflect the final decision — do NOT leave stale architecture choices. -->

---

## Reviewer Findings (Spec)

<!-- Appended by crispy orchestrator after the spec-review pass.
     Reviewer evaluates this artifact against spec.md / intent.md / contracts for correctness.
     Severities follow SUBAGENTS.md §6 vocabulary: high / medium / low.
     high findings block autopilot; medium / low are recorded here and flow continues. -->

| Severity | Location | Description | Suggested Action | Status |
|----------|----------|-------------|------------------|--------|
|          |          |             |                  |        |

## Reviewer Findings (Code)

<!-- Appended by crispy orchestrator after the code-review pass.
     Reviewer evaluates this artifact for quality, idiomatic patterns, and security.
     Same severity vocabulary; same gating rules. -->

| Severity | Location | Description | Suggested Action | Status |
|----------|----------|-------------|------------------|--------|
|          |          |             |                  |        |
