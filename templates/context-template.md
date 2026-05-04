# Feature Context: [Feature Name]

> **Created**: [YYYY-MM-DD]  
> **Last Updated**: [YYYY-MM-DD]  
> **Owner**: Clarify (writes canonical context) + Research (appends vocabulary sidecar)

This document establishes the **ubiquitous language** for this feature across all CRISPY phases. It is the single source of truth for terminology, ambiguities, resolved decisions, and domain relationships that downstream agents must honor.

## Purpose

- **Clarify** creates and owns this document. As requirements are clarified and ambiguities resolved, Clarify updates this file with canonical terms and decisions.
- **Research** contributes a separate `CONTEXT.research-vocabulary.md` sidecar with codebase-discovered technical vocabulary (never writes to this file directly).
- **Intent, Structure, Plan, Yield, Implement** read this document when present to ensure consistency with established terminology and avoid term drift.

## Canonical Terms

List key domain concepts, technical terms, and acronyms with brief definitions. Mark unresolved ambiguities clearly.

| Term | Definition | Status | Notes |
|------|------------|--------|-------|
| *Example: User Session* | *A stateful server-side record of an authenticated user's activity, distinct from a JWT token.* | *Resolved* | *Clarified in Q3 2026-05-03* |
| *Example: Upload Batch* | *A collection of files uploaded in a single drag-drop gesture.* | *Ambiguous* | *Awaiting decision: should we track individual files or batch-level metadata?* |

## Resolved Decisions

Document important clarifications or decisions made during Clarify that affect terminology, scope, or feature boundaries.

- **Decision**: [Brief decision statement]
  - **Rationale**: [Why this decision was made]
  - **Impact**: [Which terms or relationships this affects]
  - **Source**: [User input / Q&A turn reference / external requirement]

## Unresolved Ambiguities

Track unresolved questions or ambiguities that must be addressed before implementation.

- **Ambiguity**: [Description of unclear requirement or term]
  - **Options**: [List known alternatives]
  - **Blocker for**: [Which downstream phase or task needs this resolved]

## Domain and Workflow Relationships

Describe how terms relate to each other, data flows, state transitions, or important invariants.

- **Relationship**: [Entity A] → [Entity B]
  - **Nature**: [one-to-many, parent-child, depends-on, etc.]
  - **Constraint**: [Required invariants or validation rules]

## Source and Artifact References

Link to the original spec, user input, external docs, or research findings that informed this context.

- `spec.md` — primary requirements source
- `research.md` — codebase-discovered context (read-only from Clarify's perspective)
- `CONTEXT.research-vocabulary.md` — technical vocabulary sidecar written by Research only
- [External doc link] — if applicable

---

**Legacy Behavior**: If this file does not exist, downstream phases proceed without shared context. This is expected for older feature folders created before the CONTEXT.md convention was introduced.
