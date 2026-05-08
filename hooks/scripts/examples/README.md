# Hook Script Examples

This directory contains **example hook scripts** that are NOT registered in `hooks.json`. They demonstrate hook patterns plugin authors may want to copy or adapt.

## `pre-branch-check.{sh,ps1}` — `permissionDecision` JSON convention

The `pre-branch-check.{sh,ps1}` example demonstrates the **canonical `permissionDecision` JSON shape** that a Copilot CLI hook script may emit on stdout to instruct the runtime how to dispatch a tool call. The shape is:

```json
{
  "permissionDecision": "allow" | "deny" | "ask",
  "reason": "<one-line explanation>"
}
```

The runtime parses this JSON from the hook's stdout when the hook exits 0. Hooks that exit non-zero (e.g., `dangerous-command-guard.{sh,ps1}` which uses `exit 1`) are treated by the runtime as a hard deny without parsing stdout — both mechanisms are valid, but `permissionDecision` is more expressive (it carries `reason` and supports the `ask` interactive form).

The `pre-branch-check` example shows how a plugin author might gate `git checkout` and `git switch` operations against an allowlist of branch-name prefixes. It is preserved here for reference; the active CRISPY guard surface intentionally uses the simpler `exit 1` mechanism in `hooks/scripts/dangerous-command-guard.{sh,ps1}` for backward-compat (NFR-001 / NFR-005).

## Using these examples

1. Copy the script of interest to `hooks/scripts/`.
2. Add a corresponding entry in `hooks.json` under the appropriate lifecycle event (e.g., `preToolUse`).
3. Optionally add a `matcher` regex on the entry to scope it (see `hooks.json` for an example on `dangerous-command-guard`).
4. Test against fixtures under `hooks/fixtures/` before relying on the hook in production.

See the [README §Loading model](../../../README.md#loading-model) and the canonical `permissionDecision` JSON section for the runtime contract details.
