---
name: create-domain-research
description: "Generate a domain-research.md for greenfield projects: blind problem-domain & external-systems analysis"
---

# Create Domain Research (Blind)

Generate a `domain-research.md` file in the project folder using the CRISPY domain-research template (`templates/domain-research-template.md`).

## When to use

- The CRISPY **project** workstream Research phase, where there is no existing code to analyze blindly.
- Invoked by `crispy-domain-research`.

## When NOT to use

- For per-feature blind research of an existing codebase — use `create-research` (which calls `crispy-research`'s code-walk process).

## Critical Rule — Blindness

> You MUST NOT read `vision.md` or ask about the planned product.
> Domain research must be unbiased by the intended product. Investigate the **problem domain** and **prior art** as they exist independently of this project.

## Process

1. Take from the caller: the **domain area** (e.g., `"B2B invoicing"`, `"real-time collaborative editing"`) and the project folder path.
2. Instantiate `templates/domain-research-template.md` at `<project-folder>/domain-research.md`.
3. Use web search for reference architectures, prior-art, regulatory context.
4. Use **WorkIQ** ONLY for the existing domain — internal ADRs, post-mortems, or prior project notes about this domain. Never query about the planned product or its features.
5. Cite sources (URL, file, meeting title) for every reference architecture, regulatory note, or prior-art entry.

## Guidelines

- The Glossary (§2) becomes the project's **ubiquitous language**. Be precise — feature-level CRISPY runs will reuse these terms.
- Reference architectures (§4) must include both strengths AND weaknesses; an architecture-by-comparison is the most useful input to `crispy-architecture`.
- Common failure modes (§7) feed directly into `architecture.md §9 Anti-Patterns to Avoid`.
- Do NOT propose what *should* be built — only document what *exists* in the domain.

## Hand-off

The next phase is **Intention** (`crispy-architecture`), which is the first phase allowed to read both `vision.md` AND `domain-research.md` together.
