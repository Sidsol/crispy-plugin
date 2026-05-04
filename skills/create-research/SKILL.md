---
name: create-research
description: "Generate a research.md from blind codebase analysis"
user-invocable: false
---

# Create Blind Research Document

Generate a `research.md` by analyzing the codebase **without knowledge of the feature goal**. This ensures unbiased documentation of the current system state.

## Process

1. Identify the target repository or repositories to analyze.
2. Conduct a thorough read-only scan of the codebase.
3. Document findings in `research.md` in the feature's spec directory.

## Critical Rule

**Do NOT read the spec.md or any feature description before completing the research.** The analysis must be conducted blind to avoid confirmation bias. Only after the research document is complete should it be compared against the feature specification.

## Template Structure

```markdown
# Codebase Research: {Repository Name}

## Architecture Overview
High-level description of the system architecture, patterns, and design philosophy.

## Directory Structure
Key directories and their purposes.

## Logic Flows
Document the primary execution paths and data flows through the system.

### Flow: {Flow Name}
1. Entry point: {file:line}
2. {Step description} → {file:line}
3. ...

## Data Models
Existing data models, schemas, and their relationships.

### Model: {Name}
- Location: {file path}
- Fields: {key fields and types}
- Relationships: {references to other models}

## Integration Points
External services, APIs, databases, message queues, and other system boundaries.

| Integration | Type | Location | Notes |
|---|---|---|---|
| {Name} | REST API / DB / Queue | {file path} | {Details} |

## Configuration & Environment
Environment variables, config files, and feature flags in use.

## Technical Debt & Observations
Issues, inconsistencies, or areas of concern discovered during analysis.

- {Observation with file reference}
- {Observation with file reference}

## Key Patterns
Design patterns, conventions, and idioms used consistently in the codebase.
```

## Fan-Out Mode

When the caller (typically `crispy-research`) determines that the work meets the **fan-out threshold** — **areas ≥ 3 OR repos ≥ 2** — this skill is invoked **after fan-out** rather than running the analysis itself.

Workflow:

1. The caller spawns one `explore` sub-agent per area or repo (see `SUBAGENTS.md` §5.1). Each sub-agent inherits the **blindness rule** (MUST NOT read `spec.md` or the feature goal) and writes a partial-research markdown fragment to a temp file.
2. Once all fragments are produced, invoke the `aggregate-research` skill on the fragment paths to merge them into the single canonical `research.md` for the feature.
3. Below threshold (areas < 3 AND repos < 2), run this skill as documented above — no fan-out, no aggregation.

The aggregation step is mandatory in fan-out mode: do not concatenate fragments by hand and do not skip straight to writing `research.md` from one fragment.

## Guidelines

### Research Vocabulary Sidecar (L2 source-learning traceability)

Research discovers only **codebase-observed vocabulary with evidence**. Do NOT write to `CONTEXT.md` (Clarify owns that artifact). Instead, write discovered terms to `CONTEXT.research-vocabulary.md` in the feature folder.

Each vocabulary entry must include:
- **Evidence**: code snippet, pattern, or observable fact
- **Source**: file path and line number

After writing the vocabulary sidecar, reference it in `research.md`'s preamble:

```markdown
# Codebase Research: [Area Name]

> **Vocabulary sidecar**: See `CONTEXT.research-vocabulary.md` for codebase-discovered technical terms.
```

- Reference specific file paths and line numbers wherever possible.
- Document what **is**, not what **should be**.
- Note any inconsistencies between different parts of the codebase.
- Include observations about test coverage and testing patterns.
- Flag any hardcoded values, magic numbers, or configuration that lives in code.
- Keep the tone objective and factual — avoid recommendations at this stage.
