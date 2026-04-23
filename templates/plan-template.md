# Implementation Plan: [FEATURE_NAME]

<!-- CRISPY Phase: PLAN → produces plan.md -->
<!-- This is the line-level tactical plan. Every file to create or modify is listed. -->
<!-- No vague tasks — each item is concrete enough for an AI to execute without -->
<!-- further clarification. -->

| Field              | Value                                   |
|--------------------|-----------------------------------------|
| **Feature**        | [FEATURE_NAME]                          |
| **Branch**         | `[NNN-FEATURE-NAME]`                   |
| **Date**           | [DATE]                                  |
| **Spec Reference** | `[NNN-FEATURE-NAME]/spec.md`           |
| **Intent Ref**     | `[NNN-FEATURE-NAME]/intent.md`         |
| **Outline Ref**    | `[NNN-FEATURE-NAME]/outline.md`        |

---

## 1. Summary

<!-- One paragraph from the feature spec describing what we're building. -->

[Concise summary of the feature, its purpose, and expected outcome.]

---

## 2. Technical Context

<!-- Everything an AI agent needs to know about the tech stack and constraints. -->

| Aspect          | Detail                                               |
|-----------------|------------------------------------------------------|
| **Language**    | [e.g., TypeScript 5.x, Python 3.12]                 |
| **Framework**   | [e.g., Express.js, FastAPI, React 18]                |
| **Storage**     | [e.g., PostgreSQL 15, Redis 7, S3]                   |
| **Testing**     | [e.g., Jest + Supertest, pytest, Playwright]          |
| **Platform**    | [e.g., AWS Lambda, Docker + ECS, Vercel]             |
| **CI/CD**       | [e.g., GitHub Actions, CircleCI]                     |
| **Constraints** | [e.g., Must support Node 18+, no new dependencies > 50KB] |

### Key Dependencies

| Package / Service     | Version  | Purpose                              |
|-----------------------|----------|--------------------------------------|
| [dependency]          | [x.y.z]  | [Why it's needed]                    |
| [dependency]          | [x.y.z]  | [Why it's needed]                    |

---

## 3. Project Structure

### Documentation Tree

```
[NNN-FEATURE-NAME]/
├── spec.md                    ← Feature specification (CLARIFY)
├── research.md                ← Blind codebase research (RESEARCH)
├── intent.md                  ← Architecture decisions (INTENTION)
├── outline.md                 ← Vertical slices (STRUCTURE)
├── plan.md                    ← This file (PLAN)
├── tasks.md                   ← Ordered task list (PLAN)
├── checklist.md               ← Pre-implementation gate (YIELD)
└── contracts.md               ← API/interface contracts (if applicable)
```

### Source Code Tree (Changes)

<!-- Show the file tree of files to CREATE or MODIFY. Mark each as New/Modified. -->

```
[repo-root]/
├── src/
│   ├── [module]/
│   │   ├── [file.ext]        — [New] [Brief purpose]
│   │   ├── [file.ext]        — [Modified] [What changes]
│   │   └── [subdir]/
│   │       └── [file.ext]    — [New] [Brief purpose]
│   └── [module]/
│       └── [file.ext]        — [Modified] [What changes]
├── tests/
│   ├── [test-file.ext]       — [New] [What it tests]
│   └── [test-file.ext]       — [New] [What it tests]
├── migrations/
│   └── [migration-file]      — [New] [Schema change]
└── [config-file]              — [Modified] [What changes]
```

---

## 4. Implementation Phases

<!-- Each phase maps to a vertical slice from outline.md. -->
<!-- Every file operation is explicit: CREATE, MODIFY, or DELETE. -->

### Phase 1: [Slice Name — e.g., "Data Foundation"]

**Outline reference:** Slice 1
**Stories:** [Infrastructure / S-001 / etc.]

#### Step 1.1: [Action — e.g., "Create database migration"]

- **File:** `[path/to/migration_file.ext]` — **CREATE**
- **Action:** [Precise description of what to write]
- **Details:**
  - [Specific field/column/type details]
  - [Constraints and indexes]
  - [Reference: spec.md §5 Key Entities]

#### Step 1.2: [Action — e.g., "Create entity model"]

- **File:** `[path/to/model.ext]` — **CREATE**
- **Action:** [Precise description]
- **Details:**
  - [Fields, types, validation rules]
  - [Relationships to other models]

#### Step 1.3: [Action — e.g., "Create repository layer"]

- **File:** `[path/to/repository.ext]` — **CREATE**
- **Action:** [Precise description]
- **Details:**
  - [Methods to implement: findById, create, update, delete]
  - [Query patterns]

#### Step 1.4: [Action — e.g., "Write unit tests"]

- **File:** `[path/to/tests/model.test.ext]` — **CREATE**
- **Action:** [Precise description]
- **Details:**
  - [Test cases to cover]
  - [Mocking strategy]

**Phase 1 checkpoint:** [What must be true before proceeding]

---

### Phase 2: [Slice Name — e.g., "Core API"]

**Outline reference:** Slice 2
**Stories:** [S-001]

#### Step 2.1: [Action]

- **File:** `[path/to/file.ext]` — **CREATE / MODIFY**
- **Action:** [Precise description]
- **Details:**
  - [Specifics]

#### Step 2.2: [Action]

- **File:** `[path/to/file.ext]` — **CREATE / MODIFY**
- **Action:** [Precise description]

**Phase 2 checkpoint:** [What must be true before proceeding]

---

### Phase 3: [Slice Name]

**Outline reference:** Slice 3
**Stories:** [S-001, S-002]

#### Step 3.1: [Action]

- **File:** `[path/to/file.ext]` — **CREATE / MODIFY**
- **Action:** [Precise description]

**Phase 3 checkpoint:** [What must be true before proceeding]

---

### Phase N: [Polish & Hardening]

**Outline reference:** Slice N
**Stories:** [S-003, edge cases, NFRs]

#### Step N.1: [Action — e.g., "Add error handling for EC-001"]

- **File:** `[path/to/file.ext]` — **MODIFY**
- **Action:** [Precise description]

#### Step N.2: [Action — e.g., "Performance optimization for NFR-001"]

- **File:** `[path/to/file.ext]` — **MODIFY**
- **Action:** [Precise description]

**Final checkpoint:** [All success criteria from spec.md met]

---

## 5. Complexity Tracking

<!-- Track estimated vs actual complexity to improve future estimates. -->

| Phase   | Step | Description              | Est. Complexity | Actual | Notes          |
|---------|------|--------------------------|-----------------|--------|----------------|
| Phase 1 | 1.1  | [Migration]              | Low             |        |                |
| Phase 1 | 1.2  | [Entity model]           | Low             |        |                |
| Phase 2 | 2.1  | [API endpoints]          | Medium          |        |                |
| Phase 3 | 3.1  | [Business logic]         | High            |        |                |
| Phase N | N.1  | [Edge cases]             | Medium          |        |                |

**Total estimated effort:** [S / M / L / XL]

---

## 6. Dependencies & Execution Order

<!-- Explicit ordering constraints beyond the phase sequence. -->

```
Phase 1 ──→ Phase 2 ──→ Phase 3 ──→ Phase N
                  │
                  └──→ Phase 4 (parallel if UI-only)
```

### Hard Dependencies

| Step  | Depends On | Reason                                           |
|-------|------------|--------------------------------------------------|
| 2.1   | 1.3        | [API needs repository layer]                     |
| 3.1   | 2.1        | [Business logic needs API contracts]             |

### Soft Dependencies (Recommended Order)

| Step  | After  | Reason                                           |
|-------|--------|--------------------------------------------------|
| N.1   | 3.1    | [Edge cases easier to add after core logic]      |

---

## 7. Task Graph (Machine-Readable)

<!-- Consumed by crispy-implement to identify parallel tasks within and across slices. -->

```yaml
task_graph:
  - id: TASK-001
    slice: 1
    story: S-001
    depends_on: []
    parallelizable_with: []
    files: [path/to/migration.sql]
  - id: TASK-002
    slice: 1
    story: S-001
    depends_on: [TASK-001]
    parallelizable_with: [TASK-003]
    files: [src/models/user.ts]
```

---

<!-- NOTE FOR AI AGENT: -->
<!-- This plan should be detailed enough that each step can be executed without -->
<!-- further clarification. If a step says "implement the service," that's too vague. -->
<!-- Instead: "Create UserService class with methods: createUser(dto), findById(id), -->
<!-- updateUser(id, dto), deleteUser(id). Each method calls UserRepository." -->
<!-- The companion tasks.md file provides the execution checklist derived from this plan. -->
<!-- The Task Graph (§7) is REQUIRED — crispy-implement uses it to fleet parallel tasks. -->

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
