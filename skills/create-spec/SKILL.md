---
name: create-spec
description: "Generate a spec.md feature specification from user input"
user-invocable: false
---

# Create Feature Specification

Generate a `spec.md` file in the designated feature folder using the CRISPY specification template.

## Process

1. Ask the user for the feature description if not already provided.
2. Create the `spec.md` file in the feature's spec directory (e.g., `crispy-docs/specs/NNN-feature-name/spec.md`).

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
