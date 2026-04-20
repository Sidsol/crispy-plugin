# Tasks: [FEATURE_NAME]

<!-- CRISPY Phase: PLAN → produces tasks.md (companion to plan.md) -->
<!-- This is the ordered, checkable task list derived from plan.md. -->
<!-- Format: [ID] [Priority] [Story] Description -->
<!-- Each task should be independently completable and verifiable. -->

| Field              | Value                                   |
|--------------------|-----------------------------------------|
| **Feature**        | [FEATURE_NAME]                          |
| **Branch**         | `[NNN-FEATURE-NAME]`                   |
| **Date**           | [DATE]                                  |
| **Plan Reference** | `[NNN-FEATURE-NAME]/plan.md`           |

---

## Task Format

```
- [ ] [T-NNN] [P?] [S-NNN] Description of the task
       └─ Files: path/to/file.ext (CREATE/MODIFY)
       └─ Verify: How to confirm this task is done
```

- **T-NNN**: Task ID (sequential within phase)
- **P?**: Priority from spec (P1/P2/P3)
- **S-NNN**: Story reference from spec.md (or "Infra" for infrastructure)

---

## Phase 1: Setup & Infrastructure

<!-- Shared infrastructure that all stories depend on. -->
<!-- These tasks have no story reference — they're foundational. -->

- [ ] **T-101** · P1 · Infra · [e.g., Create database migration for `[table_name]`]
       - Files: `[path/to/migration.ext]` (CREATE)
       - Verify: Migration runs up and down without errors

- [ ] **T-102** · P1 · Infra · [e.g., Create entity model `[EntityName]`]
       - Files: `[path/to/model.ext]` (CREATE)
       - Verify: Model compiles, type-checks correctly

- [ ] **T-103** · P1 · Infra · [e.g., Create repository with CRUD methods]
       - Files: `[path/to/repository.ext]` (CREATE)
       - Verify: Unit tests for all repository methods pass

- [ ] **T-104** · P1 · Infra · [e.g., Write repository unit tests]
       - Files: `[path/to/repository.test.ext]` (CREATE)
       - Verify: `[test command]` passes, coverage > [X]%

**Phase 1 gate:** All infrastructure tests pass. No regressions.

---

## Phase 2: Foundational Prerequisites

<!-- Tasks that are blocking prerequisites for story implementation. -->
<!-- E.g., service layer, auth middleware, shared utilities. -->

- [ ] **T-201** · P1 · Infra · [e.g., Create service layer with business logic]
       - Files: `[path/to/service.ext]` (CREATE)
       - Verify: Service methods work with mocked repository

- [ ] **T-202** · P1 · Infra · [e.g., Create validation middleware/schemas]
       - Files: `[path/to/validation.ext]` (CREATE)
       - Verify: Validation rejects invalid input, passes valid input

- [ ] **T-203** · P1 · Infra · [e.g., Create shared error handling]
       - Files: `[path/to/errors.ext]` (CREATE/MODIFY)
       - Verify: Error responses match API contract format

**Phase 2 gate:** Service layer tested. Validation working. Error handling consistent.

---

## Phase 3: Story S-001 — [Story Title]

<!-- Tasks implementing the first (highest priority) user story. -->

- [ ] **T-301** · P1 · S-001 · [e.g., Create REST endpoint `POST /api/[resource]`]
       - Files: `[path/to/controller.ext]` (CREATE/MODIFY)
       - Verify: Endpoint returns 201 with correct response body

- [ ] **T-302** · P1 · S-001 · [e.g., Create REST endpoint `GET /api/[resource]/:id`]
       - Files: `[path/to/controller.ext]` (MODIFY)
       - Verify: Endpoint returns 200 for existing, 404 for missing

- [ ] **T-303** · P1 · S-001 · [e.g., Write integration tests for S-001 endpoints]
       - Files: `[path/to/controller.test.ext]` (CREATE)
       - Verify: All acceptance scenarios from spec.md S-001 pass

- [ ] **T-304** · P1 · S-001 · [e.g., Handle edge case EC-001: empty input]
       - Files: `[path/to/validation.ext]` (MODIFY)
       - Verify: Empty input returns 400 with descriptive error

**Phase 3 gate:** All S-001 acceptance scenarios pass. Edge cases covered.

---

## Phase 4: Story S-002 — [Story Title]

- [ ] **T-401** · P2 · S-002 · [Task description]
       - Files: `[path/to/file.ext]` (CREATE/MODIFY)
       - Verify: [Verification method]

- [ ] **T-402** · P2 · S-002 · [Task description]
       - Files: `[path/to/file.ext]` (CREATE/MODIFY)
       - Verify: [Verification method]

- [ ] **T-403** · P2 · S-002 · [Write tests for S-002]
       - Files: `[path/to/test.ext]` (CREATE)
       - Verify: All acceptance scenarios from spec.md S-002 pass

**Phase 4 gate:** All S-002 acceptance scenarios pass.

---

## Phase 5: Story S-003 — [Story Title]

- [ ] **T-501** · P3 · S-003 · [Task description]
       - Files: `[path/to/file.ext]` (CREATE/MODIFY)
       - Verify: [Verification method]

- [ ] **T-502** · P3 · S-003 · [Write tests for S-003]
       - Files: `[path/to/test.ext]` (CREATE)
       - Verify: All acceptance scenarios from spec.md S-003 pass

**Phase 5 gate:** All S-003 acceptance scenarios pass.

---

## Phase 6: Polish & Cross-Cutting

<!-- Final hardening: performance, documentation, cleanup. -->

- [ ] **T-601** · P2 · Cross · [e.g., Add API documentation / OpenAPI spec]
       - Files: `[path/to/docs.ext]` (CREATE)
       - Verify: Documentation matches implemented endpoints

- [ ] **T-602** · P2 · Cross · [e.g., Performance optimization for NFR-001]
       - Files: `[path/to/file.ext]` (MODIFY)
       - Verify: Response time < [target] under load

- [ ] **T-603** · P1 · Cross · [e.g., Full regression test pass]
       - Files: — (no file changes)
       - Verify: `[full test command]` passes with zero failures

- [ ] **T-604** · P1 · Cross · [e.g., PR preparation and self-review]
       - Files: — (no file changes)
       - Verify: PR description complete, all checks green

**Phase 6 gate:** All tests pass. PR ready for review.

---

## Dependencies & Execution Order

```
T-101 → T-102 → T-103 → T-104
                   │
                   ↓
         T-201 → T-202 → T-203
                   │
            ┌──────┴──────┐
            ↓             ↓
     Phase 3 (S-001)  Phase 4 (S-002)  ← can parallelize if independent
            │             │
            └──────┬──────┘
                   ↓
            Phase 5 (S-003)
                   ↓
            Phase 6 (Polish)
```

### Parallel Opportunities

<!-- Tasks within the same phase that can be done simultaneously. -->

| Task A  | Task B  | Safe to Parallelize? | Notes                          |
|---------|---------|----------------------|--------------------------------|
| T-301   | T-302   | ✅ Yes               | Independent endpoints          |
| T-401   | T-301   | ⚠️ Maybe             | [Only if stories are independent] |

---

## Implementation Strategy

### MVP First

> Implement all P1 tasks (Phases 1-3) before starting P2 tasks.
> This ensures a working, testable feature at every milestone.

### Incremental Delivery

1. **After Phase 1:** Infrastructure verified, foundation solid
2. **After Phase 3:** MVP complete — core story works end-to-end
3. **After Phase 5:** Full feature — all stories implemented
4. **After Phase 6:** Production-ready — polished, tested, documented

### Checkpoint Protocol

After each phase:
1. Run full test suite
2. Verify checkpoint criteria from outline.md
3. Commit with descriptive message referencing task IDs
4. If context > 40%, start fresh AI session for next phase

---

<!-- NOTE FOR AI AGENT: -->
<!-- Work through tasks IN ORDER within each phase. -->
<!-- Do NOT skip ahead to a later phase before the current phase gate passes. -->
<!-- Mark tasks with [x] as you complete them. -->
<!-- If a task is blocked, document why and move to the next non-blocked task. -->
<!-- After completing all tasks, proceed to checklist.md (YIELD phase). -->
