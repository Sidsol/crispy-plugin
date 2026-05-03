---
name: run-tdd-slice
description: "Execute one vertical slice via the test-author (RED) → implementer (GREEN) → spec-review → code-review loop"
user-invocable: false
---

# Run a TDD Slice

Encapsulates the per-slice implementation loop used by `crispy-implement` (`SUBAGENTS.md` §9, row "Slice implementation"). Each invocation drives one slice from failing test → green tests → reviewed diff and returns a single `crispy-result` for the orchestrator to consume.

All sub-agent spawns inside this skill go through the `spawn-subagent` skill and use the six-block prompt skeleton at `C:\repos\crispy-plugin\templates\subagent-prompt.template.md`. The six mandatory blocks (Role, Goal, Inputs, Scope guardrails, Output contract, Failure handling) are non-negotiable (`SUBAGENTS.md` §2).

## Worktree assumptions and rollback responsibility

This skill **assumes the caller has enforced the clean-worktree precondition** before invoking it (see `crispy-implement.agent.md` → "Worktree Discipline"). The skill will not check `git status` itself, will not stash, and will not commit.

When `worktree_path` is provided (fleet mode), all file paths in sub-agent prompts are resolved relative to that worktree. The skill itself does not create or remove worktrees — that remains the caller's responsibility.

On any failure (test-author fails, implementer fails, build/lint/tests fail, `spec-review` or `code-review` returns `severity: high`), the **caller** is responsible for rollback (`git reset --hard HEAD`) and for the per-slice checkpoint commit on success. This skill itself does NOT modify git state — it only edits source/test files via its sub-agents and runs verification commands.

## Inputs

- `slice_number` — integer index of the slice in `outline.md`.
- `slice_section` — the slice's markdown section pulled from `C:\repos\crispy-plugin\crispy-docs\<feature>\outline.md` (includes scope, checkpoint criteria, declared test paths).
- `contracts` — list of contract paths from `C:\repos\crispy-plugin\crispy-docs\<feature>\contracts\` that this slice must satisfy.
- `plan_excerpt` — the relevant slice block from `C:\repos\crispy-plugin\crispy-docs\<feature>\plan.md` (file-level technical context, including which test files to write).
- `fast_mode` — optional boolean flag (default `false`). See "Fast mode opt-out" below.
- `worktree_path` — optional absolute path to the git worktree for this slice (used in fleet mode). Defaults to the repo root when omitted (sequential mode). When provided, ALL sub-agent prompts (`test-author`, `implementer`, `spec-review`, `code-review`) MUST use this path as their working directory for file reads and writes. The `slice_section` file references are relative to this worktree, not the main checkout.

## Process

### 1. Spawn `test-author` (sync)

Skip this step entirely if `fast_mode = true`.

Use the prompt skeleton — all six blocks. Key contents:

- **Role**: `test-author`.
- **Goal**: write failing tests for slice {N} that encode its checkpoint criteria and contracts.
- **Inputs / MUST READ**: `slice_section`, every path in `contracts`, the `plan_excerpt`. **MUST NOT READ**: existing implementation files for the slice (so tests describe behavior, not current code).
- **Scope guardrails — May**: create new test files at the paths declared in `plan.md` (resolved relative to `worktree_path` if provided, else repo root). **Must NOT**: modify production code, modify other slices' tests, spawn other sub-agents.
- **Output contract**: standard `crispy-result` (§3) with `artifact_path` set to the test directory and `metadata.test_files: [...]` listing every file written.
- **Failure handling**: per template defaults.

Spawn **sync**. Capture `metadata.test_files`.

### 2. Run the test suite (RED verification)

**RED gate:** the new tests MUST fail. If the test command exits 0 on the first run after step 1, treat it as a TDD violation: the tests are not actually exercising new behavior. Return `status: failed` with `next_actions: [test-author must write tests that actually fail before implementer is spawned]`. Do NOT skip to step 3.

Run the project's existing test command (do not invent one). Confirm the new tests **fail** for the expected reason (missing implementation), not for unrelated errors (import errors, syntax issues).

- If they **fail as expected** → continue to step 3.
- If they **pass already** → stop and return:

  ```yaml
  status: failed
  agent: run-tdd-slice
  summary: |
    New tests for slice {N} pass without any implementation change.
    Either the slice is already implemented, or the tests are not actually
    exercising the new behavior.
  next_actions:
    - Re-scope slice {N} or rewrite the failing tests to target the new behavior.
  ```

- If they **error** (not assert-fail) → return `status: failed` with the error excerpt (`SUBAGENTS.md` §8).

### 3. Spawn `implementer` (sync)

Skeleton fields:

- **Role**: `implementer`.
- **Goal**: write the minimum production code to make the failing tests for slice {N} pass.
- **Inputs / MUST READ**: the failing test files (paths from step 1), `slice_section`, `contracts`, `plan_excerpt`.
- **Scope guardrails — May**: create/modify production files within the slice's declared file scope from `plan.md` (resolved relative to `worktree_path` if provided, else repo root). **Must NOT**: modify any test file (that breaks the TDD invariant), modify files outside the slice scope, spawn other sub-agents.
- **Output contract**: `crispy-result` with `metadata.changed_files: [...]`.
- **Failure handling**: per template defaults.

Spawn **sync**.

### 4. Run build / lint / tests (GREEN verification)

**GREEN gate:** the same test command from step 2 MUST now exit 0, AND the test names from `metadata.test_files` MUST appear as passing in the output. If the implementer "fixed" tests by deleting or weakening them rather than implementing the behavior, the test count will have dropped — flag this as `status: failed` with `next_actions: [implementer weakened or removed failing tests; revert and re-spawn]`.

Use only commands that already exist in the repo. **Flake retry**: allow exactly ONE identical re-run of any verification command before classifying it as a persistent failure. If the second run also fails, treat as `status: failed`. This is distinct from the `SUBAGENTS.md` §8 sub-agent retry rule (which applies to sub-agent spawns) — this rule applies to direct command invocations inside this skill.

If anything fails (after the one allowed re-run):

- Return `status: failed` with the offending command and tail of its output.
- Do **not** loop or re-spawn the implementer. Surface to the caller (`SUBAGENTS.md` §8: persistent failure → surface, do not silently fall back).

### 5. Spawn `spec-review` (sync)

Skeleton fields:

- **Role**: `spec-review` (correctness reviewer).
- **Goal**: review the slice {N} diff against `spec.md`, `intent.md`, `contracts`, and the slice's checkpoint criteria. Verify behavioral correctness and contract conformance.
- **Inputs / MUST READ**: the diff (changed_files from step 3 + test_files from step 1, resolved relative to `worktree_path` if provided), `spec.md`, `intent.md`, `contracts`, `slice_section`.
- **Scope guardrails — May**: read-only analysis, return findings. **Must NOT**: edit code, spawn other sub-agents.
- **Output contract**: `findings[]` is **required** (§3). Severity values must come from the §6 vocabulary: `high` / `medium` / `low` only.
- **Failure handling**: per template defaults.

Spawn **sync**.

### 5b. Spawn `code-review` (sync)

Skeleton fields:

- **Role**: `code-review` (quality reviewer).
- **Goal**: review the slice {N} diff for code quality, idiomatic patterns, security, and maintainability. Do NOT re-evaluate behavioral correctness — that is the `spec-review` pass.
- **Inputs / MUST READ**: same diff as step 5; the project's style/lint config files if present.
- **Scope guardrails — May**: read-only analysis, return findings. **Must NOT**: edit code, spawn other sub-agents.
- **Output contract**: `findings[]` required, same §6 vocabulary.
- **Failure handling**: per template defaults.

Spawn **sync**, after step 5 returns.

### 6. Aggregate into one `crispy-result`

Combine the four sub-results (test-author, implementer, spec-review, code-review) into a single block for `crispy-implement`:

```yaml
status: ok | partial | failed
agent: run-tdd-slice
artifact_path: null
summary: |
  Slice {N} implemented via TDD.
  Tests: {count} added at {paths}. Implementation: {file_count} files changed.
  Reviewer findings (spec+code union): {high} high / {medium} medium / {low} low.
findings:
  # passthrough from spec-review + code-review (union), severity vocabulary preserved (§6)
  - severity: ...
    location: ...
    description: ...
    suggested_action: ...
next_actions:
  - {derived from highest-severity finding, or "Proceed to next slice."}
metadata:
  slice_number: {N}
  fast_mode: {true|false}
  test_files: [...]
  changed_files: [...]
  worktree_path: {worktree_path or null}
```

Gating rules the caller will apply (§6):

- Any `severity: high` → `crispy-implement` blocks autopilot and surfaces to the user.
- `medium` / `low` → appended to the slice's `## Reviewer Findings` section in `tasks.md`, continue.

## Fast mode opt-out

Caller may pass `fast_mode = true` to skip step 1 (the `test-author` spawn). The loop becomes: implementer → build/lint/tests → spec-review → code-review. Use only when:

- The slice has pre-existing tests that already encode the checkpoint criteria, OR
- The slice is purely refactor/cleanup with no new behavior.

In fast mode the implementer's `MUST READ` should list the existing tests it must keep green, and the aggregated `crispy-result` must set `metadata.fast_mode: true` so the orchestrator can record reduced-rigor slices.

## Failure handling (per `SUBAGENTS.md` §8)

| Where | Sub-result | This skill returns |
|---|---|---|
| Any sub-agent: tool/runtime error (one shot) | `status: failed` | Retry that one sub-agent's spawn once with the same prompt. |
| Any sub-agent: persistent failure after retry | `status: failed` | Aggregate as `status: failed`, surface to caller. Do not silently continue. |
| Any sub-agent: missing input | `status: partial` + `next_actions` | Provide the missing input from this skill's `Inputs` and re-spawn; if not available, propagate `status: partial` upward. |
| Reviewer returned `high` finding | `status: ok` with `severity: high` | Aggregate as `status: ok` with the finding intact; orchestrator will block per §6. |
| Sub-agent went out of scope | unexpected artifacts | Discard out-of-scope output, log in `metadata`, re-spawn with tightened guardrails (§8). |

Never loop the test-author/implementer pair beyond one retry per spawn. The TDD slice is a single-pass loop by design.

## Worked example: slice 3 of feature `session-refresh`

Inputs:

- `slice_number = 3`
- `slice_section` — the "Slice 3: Refresh-token rotation" block from `C:\repos\crispy-plugin\crispy-docs\session-refresh\outline.md`. Checkpoint: rotated token invalidates predecessor; new token honors original TTL.
- `contracts = [C:\repos\crispy-plugin\crispy-docs\session-refresh\contracts\token-rotation.md]`
- `plan_excerpt` — names test path `tests\session\test_refresh_rotation.py` and impl path `src\session\refresh.py`.
- `fast_mode = false`

Flow:

1. Spawn `test-author` sync. It writes `tests\session\test_refresh_rotation.py` with three failing cases (rotation success, predecessor invalidation, TTL preservation). Returns `crispy-result` with `metadata.test_files`.
2. Run `pytest tests\session\test_refresh_rotation.py`. All three fail with `ModuleNotFoundError: src.session.refresh` — expected. Continue.
3. Spawn `implementer` sync. It creates `src\session\refresh.py` and wires it into the existing session module. Returns `metadata.changed_files: [src\session\refresh.py, src\session\__init__.py]`.
4. Run `pytest` (full suite) and `ruff check src tests`. Both pass.
5. Spawn `spec-review` sync with the diff + `spec.md`, `intent.md`, and `token-rotation.md`. Returns one `medium` finding: "Predecessor token invalidation is not idempotent; second rotation attempt with the same token returns 200 instead of 401."
6. Spawn `code-review` sync with the same diff for quality/security review. Returns no findings.
7. Aggregate: `status: ok`, one `medium` finding, `next_actions: [Append finding to slice 3 section in tasks.md and proceed to slice 4]`. `crispy-implement` continues per §6.
