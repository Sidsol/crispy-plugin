---
name: create-intent
description: "Generate an intent.md with architecture analysis and recommendations"
user-invocable: false
---

# Create Architecture Intent Document

Generate an `intent.md` that bridges the gap between the feature specification and the implementation plan. This document captures the architectural reasoning and chosen approach.

## Process

1. Read the existing `spec.md` and `research.md` for the feature.
2. Analyze the gap between current state (research) and desired state (spec).
3. Propose multiple architecture options and recommend one.
4. Write `intent.md` in the feature's spec directory.

## Template Structure

```markdown
# Architecture Intent: {Feature Name}

## Current State
Summary of the relevant existing architecture from research.md.

## Desired State
Summary of what the system should look like after implementation, derived from spec.md.

## Gap Analysis
| Area | Current | Desired | Gap |
|---|---|---|---|
| {Component} | {What exists} | {What's needed} | {What must change} |

## Architecture Options

### Option A: {Name}
**Approach:** {Description}
- ✅ Pros: {advantages}
- ❌ Cons: {disadvantages}
- 🔧 Effort: {Low / Medium / High}

### Option B: {Name}
**Approach:** {Description}
- ✅ Pros: {advantages}
- ❌ Cons: {disadvantages}
- 🔧 Effort: {Low / Medium / High}

### Option C: {Name}
**Approach:** {Description}
- ✅ Pros: {advantages}
- ❌ Cons: {disadvantages}
- 🔧 Effort: {Low / Medium / High}

## Selected Approach
**Option {X}: {Name}**

Rationale: {Why this option was selected over the others.}

## Anti-Patterns to Avoid
- {Anti-pattern}: {Why it's tempting and why it must be avoided}

## Affected Repositories
| Repository | Impact | Confidence |
|---|---|---|
| {repo-name} | {What changes are needed} | High / Medium / Low |

## Risks & Mitigations
| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| {Risk description} | {H/M/L} | {H/M/L} | {How to address} |
```

## Guidelines

- Always present at least 3 architecture options — even if one is obviously better.
- Include a "do nothing" or minimal option when appropriate.
- Anti-patterns should be specific to this feature, not generic advice.
- The gap analysis should map directly to spec requirements.
- Affected repositories should include confidence levels (High, Medium, Low).
- Risks should have concrete mitigations, not just acknowledgments.
