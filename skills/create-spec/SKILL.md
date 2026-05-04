---
name: create-spec
description: "Generate a spec.md feature specification from user input"
user-invocable: false
---

# Create Feature Specification

Generate a `spec.md` file in the designated feature folder using the CRISPY specification template. This skill mirrors the `crispy-clarify` agent's one-question-at-a-time decision-tree flow (L3).

## Process

1. **Interactive clarification** (if not already provided):
   - Ask **one primary question at a time** covering business context, user stories, acceptance criteria, constraints, scope boundaries, dependencies, and edge cases
   - For each question, provide:
     - A **recommended answer** with rationale (e.g., "reduces coupling", "aligns with existing patterns")
     - References to relevant **canonical terms** from `CONTEXT.md` or emerging context
   - Update working context notes after each answer before asking the next question
   
2. **Create or update CONTEXT.md** (L2):
   - After gathering requirements, create/update `CONTEXT.md` in the feature folder with:
     - Canonical Terms: resolved domain vocabulary with definitions
     - Unresolved Ambiguities: known unknowns
     - Resolved Decisions: key choices made during clarification
     - Domain Relationships: how entities/concepts relate
     - Source References: traceability to user input or external sources
   
3. **Create spec.md** in the feature's spec directory (e.g., `crispy-docs/specs/NNN-feature-name/spec.md`).

## Standalone Mode (Missing Input Fallback)

When invoked directly by a user (not orchestrated):

**Required inputs**: Feature name, feature folder path.

**Missing CONTEXT.md**: Proceed without canonical terms. Create `CONTEXT.md` from scratch during clarification.

**Interactive mode**: Ask one question at a time as documented. This is the normal behavior.

**Batch mode** (if user provides full requirements upfront): Parse provided text, extract stories/requirements, create `spec.md` and `CONTEXT.md`. Return success with note: *"Batch mode: spec generated from provided requirements without interactive clarification."*

**Partial status**: If requirements are too vague or contradictory, return:
```yaml
status: partial
reason: "Requirements incomplete or contradictory: <specific issues>."
next_action: "Clarify <specific ambiguities> before generating spec."
partial_output: "<path to CONTEXT.md with documented ambiguities>"
```

**Normal orchestrated flow**: When called by `crispy-clarify` or `crispy` agent, follow interactive decision-tree flow as documented.

## Template Structure

```markdown
# Feature Specification: {Feature Name}

## Overview
Brief description of what this feature does and why it matters.

## User Stories

### [US-1] {Story Title} — Priority: P1
**As a** {role}, **I want** {capability}, **so that** {benefit}.

#### Acceptance Scenarios
- **Given** {precondition}, **When** {action}, **Then** {expected result}
- **Given** {precondition}, **When** {action}, **Then** {expected result}

### [US-2] {Story Title} — Priority: P2
...

## Functional Requirements
- [FR-1] {Requirement description}
- [FR-2] {Requirement description}

## Non-Functional Requirements
- [NFR-1] {Performance, security, accessibility, etc.}

## Out of Scope
- Items explicitly excluded from this feature.

## Success Criteria
- [ ] {Measurable criterion that defines "done"}
- [ ] {Measurable criterion that defines "done"}

## Open Questions
- {Any unresolved decisions or unknowns}
```

## Guidelines

- Assign priorities: P1 (must-have), P2 (should-have), P3 (nice-to-have).
- Each user story must have at least one acceptance scenario in Given/When/Then format.
- Functional requirements should be specific and testable.
- Success criteria must be measurable and verifiable.
- List anything intentionally excluded under Out of Scope.
- Capture unresolved decisions under Open Questions so they are not forgotten.
