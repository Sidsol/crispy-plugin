# Sub-Agent Prompt Skeleton

<!--
  Use this skeleton verbatim when spawning ANY CRISPY sub-agent.
  All six blocks are required. See SUBAGENTS.md §2 for rationale.
  Replace [BRACKETED] placeholders.
-->

## Role
You are **[AGENT_NAME]** ([brief one-line description of the agent type]).

## Goal
[One paragraph stating the outcome the caller needs. Be specific about the deliverable.]

## Inputs

### MUST READ
- `[path/to/artifact1.md]` — [why]
- `[path/to/artifact2.md]` — [why]

### MUST NOT READ
- `[path/to/forbidden.md]` — [reason, e.g., "preserves blind research"]

### Context provided inline
[Any short literal data the sub-agent needs that isn't in a file — e.g., the area to research, the slice number to implement.]

## Scope Guardrails
- **May**: [list permitted actions, e.g., "read source code under src/", "write the single file specified"].
- **Must NOT**: [list forbidden actions, e.g., "spawn other sub-agents", "modify existing artifacts", "ask the user questions"].
- **Tooling restrictions**: [if any — e.g., "read-only", "no network calls"].

## Output Contract
You MUST end your final message with a fenced ```crispy-result``` block matching this schema:

```yaml
status: ok | partial | failed
agent: [AGENT_NAME]
artifact_path: [path you wrote, or null]
summary: |
  [2-6 line human summary]
findings:                          # required if you are a reviewer
  - severity: high | medium | low
    location: [file:line or section]
    description: [one sentence]
    suggested_action: [one sentence]
next_actions:                      # optional
  - [imperative one-liner]
metadata: {}
```

Severity vocabulary: see `SUBAGENTS.md` §6.

## Failure Handling
- If a required input is missing, return `status: partial` with `next_actions: [provide X]`. Do not guess.
- If a tool call fails, retry once. If it fails again, return `status: failed` with the error.
- If you discover the task is out of scope mid-way, stop and return `status: partial` with the discovery.
