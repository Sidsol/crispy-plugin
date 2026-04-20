# Blind Research: [FEATURE_AREA]

<!-- CRISPY Phase: RESEARCH → produces research.md -->
<!-- ⚠️ IMPORTANT: This research was conducted WITHOUT knowledge of the intended -->
<!-- feature goal to maintain objectivity. The AI was given only the area of the -->
<!-- codebase to investigate, not what changes are planned. This prevents -->
<!-- confirmation bias and ensures the research captures the true current state. -->

> **🔬 BLIND RESEARCH NOTICE**
> This document was produced by mapping the codebase in the area of **[FEATURE_AREA]**
> without knowledge of the intended feature or desired changes. All findings reflect
> the objective current state.

| Field            | Value                     |
|------------------|---------------------------|
| **Feature Area** | [FEATURE_AREA]            |
| **Date**         | [DATE]                    |
| **Researcher**   | [AI_MODEL / AUTHOR]       |
| **Repo(s)**      | [REPOSITORY_NAMES]        |

---

## 1. Current Architecture

### 1.1 File Structure

<!-- Map the relevant files and directories. Include line counts where useful. -->

```
[root]/
├── [dir]/
│   ├── [file.ext]          — [brief purpose]
│   ├── [file.ext]          — [brief purpose]
│   └── [subdir]/
│       └── [file.ext]      — [brief purpose]
├── [dir]/
│   └── [file.ext]          — [brief purpose]
└── [config-file.ext]       — [brief purpose]
```

### 1.2 Key Modules & Responsibilities

| Module / File          | Responsibility                          | Lines | Last Modified |
|------------------------|-----------------------------------------|-------|---------------|
| `[path/to/file.ext]`  | [What this module does]                 | ~NNN  | [DATE]        |
| `[path/to/file.ext]`  | [What this module does]                 | ~NNN  | [DATE]        |

### 1.3 Dependencies

<!-- External and internal dependencies relevant to this area. -->

| Dependency          | Version  | Purpose                          | Used In              |
|---------------------|----------|----------------------------------|----------------------|
| [package-name]      | [x.y.z]  | [Why it's used]                  | [file(s)]            |
| [internal-module]   | —        | [What it provides]               | [file(s)]            |

---

## 2. Logic Flows

<!-- Trace how existing features work step-by-step. Use numbered flows. -->

### Flow 1: [Flow Name — e.g., "User Login"]

```
1. [Entry point — e.g., POST /api/auth/login]
2. [Validation step — e.g., validateCredentials() in auth.service.ts]
3. [Data access — e.g., UserRepository.findByEmail()]
4. [Processing — e.g., bcrypt.compare() for password]
5. [Response — e.g., JWT token generated and returned]
```

**Key observations:**
- [Observation about this flow]
- [Potential concern or pattern noticed]

### Flow 2: [Flow Name]

```
1. [Step]
2. [Step]
3. [Step]
```

---

## 3. Data Models

<!-- Document existing schemas, entities, and their relationships. -->

### 3.1 Database Schema

#### Table: `[table_name]`

| Column        | Type         | Constraints       | Notes                    |
|---------------|--------------|-------------------|--------------------------|
| `id`          | [type]       | PK                | [notes]                  |
| `[column]`    | [type]       | [constraints]     | [notes]                  |

#### Relationships

```
[Entity A] 1──────* [Entity B]    (one-to-many via foreign_key)
[Entity B] *──────* [Entity C]    (many-to-many via junction_table)
```

### 3.2 In-Memory Models / DTOs

<!-- Document TypeScript interfaces, Python dataclasses, etc. -->

```
[Model Name]:
  - field: type (constraints)
  - field: type (constraints)
```

---

## 4. Integration Points

<!-- APIs, services, and external systems this area interacts with. -->

| Integration         | Type        | Direction | Protocol  | Notes                    |
|---------------------|-------------|-----------|-----------|--------------------------|
| [Service/API name]  | External    | Outbound  | REST      | [What data flows]        |
| [Service/API name]  | Internal    | Inbound   | Event     | [What triggers it]       |
| [Database]          | Internal    | Both      | SQL       | [Connection details]     |

### API Endpoints Found

| Method | Path                  | Handler                    | Auth     | Notes         |
|--------|-----------------------|----------------------------|----------|---------------|
| GET    | `/api/[resource]`     | `[controller.method]`      | [Yes/No] | [notes]       |
| POST   | `/api/[resource]`     | `[controller.method]`      | [Yes/No] | [notes]       |

---

## 5. Test Coverage

<!-- What tests exist for this area? What's missing? -->

### Existing Tests

| Test File                     | Type        | Coverage Area            | Passing? |
|-------------------------------|-------------|--------------------------|----------|
| `[path/to/test.ext]`         | Unit        | [What it tests]          | [Yes/No] |
| `[path/to/test.ext]`         | Integration | [What it tests]          | [Yes/No] |
| `[path/to/test.ext]`         | E2E         | [What it tests]          | [Yes/No] |

### Coverage Gaps

- [Area with no test coverage]
- [Area with insufficient test coverage]

---

## 6. Technical Debt

<!-- Issues, smells, or concerns noticed during research. -->

| ID     | Category        | Description                                    | Severity     | Location             |
|--------|-----------------|------------------------------------------------|--------------|----------------------|
| TD-001 | Code Smell      | [e.g., God class with 800+ lines]              | Medium       | `[file:line]`        |
| TD-002 | Missing Tests   | [e.g., No unit tests for payment service]      | High         | `[directory]`        |
| TD-003 | Deprecated API  | [e.g., Using v1 API that's end-of-life]        | High         | `[file:line]`        |
| TD-004 | Inconsistency   | [e.g., Mix of callback and async/await styles]  | Low          | `[directory]`        |

---

## 7. Patterns & Conventions

<!-- Document the patterns used in this area of the codebase. -->

- **Architecture pattern:** [e.g., MVC, Clean Architecture, Feature Slices]
- **Naming conventions:** [e.g., camelCase for files, PascalCase for classes]
- **Error handling:** [e.g., Custom error classes, global error middleware]
- **State management:** [e.g., Redux, Context API, MobX]
- **API style:** [e.g., REST with resource-based routes, GraphQL]

---

## 8. Key Findings Summary

<!-- Top findings that will matter most for any future work in this area. -->

1. **[Finding]:** [One-sentence summary of the most important discovery]
2. **[Finding]:** [One-sentence summary]
3. **[Finding]:** [One-sentence summary]
4. **[Finding]:** [One-sentence summary]
5. **[Finding]:** [One-sentence summary]

---

<!-- NOTE FOR AI AGENT: -->
<!-- This research is now complete. The next CRISPY phase is INTENTION. -->
<!-- The spec.md and this research.md should both be provided to the Intention phase -->
<!-- so the AI can compare desired state (spec) against current state (research). -->
<!-- Do NOT skip findings or sanitize technical debt — honesty here prevents "slop." -->
