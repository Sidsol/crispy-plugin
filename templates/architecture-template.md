# Project Architecture: [PROJECT_NAME]

<!-- CRISPY Project Phase: INTENTION → produces architecture.md -->
<!-- System-of-record for tech stack, service boundaries, data, deployment. -->
<!-- Section anchors are STABLE — feature-level intent.md files will reference them by anchor. -->

| Field         | Value                              |
|---------------|------------------------------------|
| **Project**   | [PROJECT_NAME]                     |
| **Folder**    | `crispy-docs/projects/NNN-PROJECT` |
| **Date**      | [DATE]                             |
| **Status**    | Draft · In Review · Approved       |
| **Vision**    | vision.md                          |
| **Research**  | domain-research.md                 |

---

## 1. Architecture Summary

<!-- One paragraph: shape of the system in plain English. -->

---

## 2. Architecture Options Considered

### Option A — [Name]

- **Approach:** …
- **Pros:** …
- **Cons:** …
- **Effort:** S / M / L
- **Risk:** Low / Medium / High

### Option B — [Name]
…

### Option C — [Name]
…

### Recommendation
**Selected:** Option [X] — [Name]

**Justification:** …

---

## 3. Tech Stack {#tech-stack}

| Layer            | Choice                | Version | Rationale |
|------------------|-----------------------|---------|-----------|
| Language(s)      |                       |         |           |
| Backend framework|                       |         |           |
| Frontend         |                       |         |           |
| Database         |                       |         |           |
| Cache / queue    |                       |         |           |
| Auth             |                       |         |           |
| Build / package  |                       |         |           |
| Test framework   |                       |         |           |
| CI / CD          |                       |         |           |
| Infra / hosting  |                       |         |           |

> **`crispy-scaffold` reads this section verbatim.** Be specific: include framework versions and any scaffolder commands the section's choices imply (e.g., `npm create vite@latest`, `dotnet new webapi`, `cargo new --bin`). If a choice is genuinely undecided, mark it `TBD — needs user input` so scaffold pauses.

---

## 4. Repositories {#repositories}

<!-- Each row becomes a repo crispy-scaffold will initialize locally. -->

| Repo name (kebab-case) | Purpose | Stack subset | Public deps | Notes |
|------------------------|---------|--------------|-------------|-------|
| [api-server]           | …       | …            | …           |       |
| [web-app]              | …       | …            | …           |       |
| [shared-types]         | …       | …            | …           |       |

---

## 5. Service Boundaries {#service-boundaries}

[How responsibilities are split between repos / services. Diagrams as text or mermaid.]

---

## 6. Data Model (High-Level) {#data-model}

[Key entities, ownership, relationships. Detailed schemas live in feature-level plans.]

---

## 7. Cross-Cutting Concerns {#cross-cutting}

- **Auth & authz:** …
- **Logging / observability:** …
- **Error handling:** …
- **Configuration / secrets:** …
- **Internationalization:** …
- **Accessibility:** …

---

## 8. Deployment & Environments {#deployment}

| Environment | Purpose       | Hosting | Notes |
|-------------|---------------|---------|-------|
| local       | dev           |         |       |
| staging     | pre-prod      |         |       |
| prod        | production    |         |       |

---

## 9. Anti-Patterns to Avoid {#anti-patterns}

<!-- Pulled from domain-research.md "Common Failure Modes". Feature intents must respect these. -->

- …

---

## 10. Open Architectural Questions

- …

---

## Reviewer Findings

<!-- Populated by orchestrator from spec-review + code-review at the architecture gate. -->
