---
name: create-checklist
description: "Generate a checklist.md with CRISPY quality gates"
user-invocable: false
---

# Create CRISPY Quality Checklist

Generate a `checklist.md` with quality gates aligned to the CRISPY methodology. This checklist ensures that each phase of the workflow was completed with rigor before implementation begins.

## Process

1. Review all existing spec documents for the feature.
2. Generate a checklist that validates each CRISPY phase.
3. Write `checklist.md` in the feature's spec directory.

## Template Structure

```markdown
# Quality Checklist: {Feature Name}

## CRISPY Phase Gates

### 🔬 C — Blind Research
- [ ] Research was conducted WITHOUT reading the feature spec
- [ ] research.md documents existing architecture objectively
- [ ] All logic flows include file path references
- [ ] Integration points are catalogued with connection details
- [ ] Technical debt items are noted with specific locations

### 🎯 R — Sound Intent
- [ ] Gap analysis maps current state to desired state
- [ ] At least 3 architecture options were evaluated
- [ ] Selected approach has clear rationale
- [ ] Anti-patterns are identified with explanations
- [ ] Affected repositories are listed with confidence levels

### 🍕 I — Vertical Slices
- [ ] Each slice delivers end-to-end testable functionality
- [ ] Slice dependencies are mapped and ordered correctly
- [ ] Context management boundaries are defined
- [ ] No slice requires more than one focused session

### 📋 S — Tactical Plan
- [ ] Every change references a specific file path
- [ ] New files and modified files are clearly distinguished
- [ ] Complexity estimates are provided per phase
- [ ] Rollback strategy is documented

### 🧹 P — Fresh Context
- [ ] Context reset points are identified between slices
- [ ] Each slice lists the key files needed in context
- [ ] No slice assumes knowledge from a previous session

### 📝 Y — Task Yield
- [ ] Tasks are organized by user story
- [ ] Every task is completable in < 2 hours
- [ ] Dependencies between tasks are explicit
- [ ] Parallel opportunities are identified
- [ ] Test tasks exist for each functional task

## Pre-Implementation Checks
- [ ] All spec documents are complete and consistent
- [ ] Implementation base/current branch identified in affected repos
- [ ] No repo-wide feature branches created during planning
- [ ] Development environment is set up and working
- [ ] Required dependencies are installed
- [ ] No unresolved open questions in spec.md

## Implementation Checks (per task)
- [ ] Task matches the plan — no scope creep
- [ ] Tests written before or alongside implementation
- [ ] No unrelated changes included
- [ ] Code follows existing patterns from research.md
- [ ] Checkpoint criteria from outline.md are met
```

## Guidelines

- Each checkbox must be verifiable — no subjective assessments.
- The checklist should be used as a living document during implementation.
- Mark items as they are verified; add notes for any exceptions.
- If a gate cannot be passed, document why and get explicit approval to proceed.
- This checklist is the final quality assurance step before coding begins.
