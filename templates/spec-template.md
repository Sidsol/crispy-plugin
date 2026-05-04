# Feature Spec: [FEATURE_NAME]

<!-- CRISPY Phase: CLARIFY → produces spec.md and optional CONTEXT.md -->
<!-- This document captures the full requirements for the feature. -->
<!-- All user stories should be prioritized and independently testable. -->
<!-- See CONTEXT.md (if present) for canonical terms and ubiquitous language. -->

| Field       | Value                          |
|-------------|--------------------------------|
| **Feature** | [FEATURE_NAME]                 |
| **Branch**  | `[NNN-FEATURE-NAME]`          |
| **Date**    | [DATE]                         |
| **Status**  | Draft · In Review · Approved   |
| **Author**  | [AUTHOR]                       |

---

## 1. Overview

<!-- One-paragraph summary of what this feature does and why it matters. -->

[Brief description of the feature and the problem it solves.]

---

## 2. User Scenarios

<!-- List all user stories grouped by priority. Each story must be independently testable. -->
<!-- P1 = Must-have for MVP, P2 = Important but deferrable, P3 = Nice-to-have -->

### Story S-001 · P1 · [Short Story Title]

**As a** [role], **I want** [action], **so that** [benefit].

- **Why this priority:** [Explain why P1/P2/P3]
- **Independent test:** [Can this be tested without other stories? Yes/No + explanation]

**Acceptance Scenarios:**

```gherkin
Scenario: [Happy path name]
  Given [precondition]
  When [action taken]
  Then [expected outcome]

Scenario: [Alternate path name]
  Given [precondition]
  When [action taken]
  Then [expected outcome]
```

---

### Story S-002 · P2 · [Short Story Title]

**As a** [role], **I want** [action], **so that** [benefit].

- **Why this priority:** [Explain why P1/P2/P3]
- **Independent test:** [Can this be tested without other stories? Yes/No + explanation]

**Acceptance Scenarios:**

```gherkin
Scenario: [Happy path name]
  Given [precondition]
  When [action taken]
  Then [expected outcome]
```

---

### Story S-003 · P3 · [Short Story Title]

**As a** [role], **I want** [action], **so that** [benefit].

- **Why this priority:** [Explain why P1/P2/P3]
- **Independent test:** [Can this be tested without other stories? Yes/No + explanation]

**Acceptance Scenarios:**

```gherkin
Scenario: [Scenario name]
  Given [precondition]
  When [action taken]
  Then [expected outcome]
```

---

## 3. Edge Cases

<!-- List edge cases that acceptance scenarios must cover. Reference the story they belong to. -->

| ID     | Story | Edge Case Description                    | Expected Behavior          |
|--------|-------|------------------------------------------|----------------------------|
| EC-001 | S-001 | [e.g., Empty input submitted]            | [e.g., Show validation error] |
| EC-002 | S-001 | [e.g., Concurrent modification conflict] | [e.g., Last-write-wins]   |
| EC-003 | S-002 | [e.g., Network timeout during save]      | [e.g., Retry with backoff] |

---

## 4. Requirements

### Functional Requirements

| ID     | Story | Requirement                                          | Priority |
|--------|-------|------------------------------------------------------|----------|
| FR-001 | S-001 | [e.g., System shall validate email format on input]  | P1       |
| FR-002 | S-001 | [e.g., System shall persist user preferences]        | P1       |
| FR-003 | S-002 | [e.g., System shall support bulk import of records]  | P2       |

### Non-Functional Requirements

| ID      | Requirement                                              | Target            |
|---------|----------------------------------------------------------|--------------------|
| NFR-001 | [e.g., API response time under normal load]              | < 200ms p95       |
| NFR-002 | [e.g., Support concurrent users]                         | 100 simultaneous  |
| NFR-003 | [e.g., Data retention]                                   | 90 days           |

---

## 5. Key Entities

<!-- Define the domain objects this feature introduces or modifies. -->

### [EntityName]

| Field       | Type     | Constraints          | Description              |
|-------------|----------|----------------------|--------------------------|
| `id`        | UUID     | PK, auto-generated   | Unique identifier        |
| `name`      | string   | required, max 255    | [description]            |
| `status`    | enum     | active/inactive      | [description]            |
| `createdAt` | datetime | auto-set             | Creation timestamp       |

### [AnotherEntity]

| Field       | Type     | Constraints          | Description              |
|-------------|----------|----------------------|--------------------------|
| `id`        | UUID     | PK, auto-generated   | Unique identifier        |

---

## 6. Success Criteria

<!-- Measurable outcomes that determine if the feature is complete and successful. -->

| ID     | Criterion                                                      | Measurement               |
|--------|----------------------------------------------------------------|---------------------------|
| SC-001 | [e.g., Users can complete the workflow end-to-end]             | Manual test pass          |
| SC-002 | [e.g., All P1 stories pass acceptance tests]                   | Automated test suite      |
| SC-003 | [e.g., API response time meets NFR-001]                        | Load test results < 200ms |
| SC-004 | [e.g., Zero regression in existing test suite]                 | CI pipeline green         |

---

## 7. Assumptions

<!-- List assumptions made during spec creation. Flag any that need validation. -->

| ID    | Assumption                                                     | Validated? | Risk if Wrong         |
|-------|----------------------------------------------------------------|------------|-----------------------|
| A-001 | [e.g., Users have modern browsers with JS enabled]             | Yes        | —                     |
| A-002 | [e.g., Existing auth system supports role-based access]        | No         | May need auth rework  |
| A-003 | [e.g., Database can handle 10x current write volume]           | No         | Need load testing     |

---

## 8. Out of Scope

<!-- Explicitly list what this feature does NOT cover to prevent scope creep. -->

- [Item 1 — e.g., Admin dashboard for managing X]
- [Item 2 — e.g., Mobile-native implementation]
- [Item 3 — e.g., Migration of legacy data]

---

<!-- NOTE FOR AI AGENT: -->
<!-- After completing this spec, the next CRISPY phase is RESEARCH. -->
<!-- Hand this spec to the stakeholder for review before proceeding. -->
<!-- Do NOT share the spec with the research phase — research must be blind. -->
