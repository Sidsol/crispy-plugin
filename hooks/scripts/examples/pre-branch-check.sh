#!/usr/bin/env bash
# pre-branch-check.sh — preToolUse hook
# Reads JSON from stdin per docs.github.com/en/copilot/reference/hooks-configuration.
# Denies a branch-creation tool call when the working tree is dirty,
# unless CRISPY_ALLOW_DIRTY=1 is set.
set -euo pipefail

PAYLOAD="$(cat || true)"

# Extract toolName and a flat string of toolArgs for matching.
TOOL_NAME="$(printf "%s" "$PAYLOAD" | jq -r '.toolName // .tool_name // ""' 2>/dev/null || echo "")"
TOOL_ARGS="$(printf "%s" "$PAYLOAD" | jq -r '.toolArgs // .tool_args // {} | tostring' 2>/dev/null || echo "")"

# Only act on shell-execution tools running git checkout/switch/branch -b.
case "$TOOL_NAME" in
  bash|powershell|execute|shell|run) ;;
  *) echo '{}' ; exit 0 ;;
esac

if ! printf "%s" "$TOOL_ARGS" | grep -Eq 'git[[:space:]]+(checkout[[:space:]]+-b|switch[[:space:]]+-c|branch[[:space:]]+(-c|-b|--create))'; then
  echo '{}'
  exit 0
fi

if [ "${CRISPY_ALLOW_DIRTY:-0}" = "1" ]; then
  echo '{}'
  exit 0
fi

if ! command -v git >/dev/null 2>&1; then
  echo '{}'
  exit 0
fi

if [ -n "$(git status --porcelain 2>/dev/null || true)" ]; then
  jq -nc '{permissionDecision:"deny", permissionDecisionReason:"CRISPY pre-branch-check: working tree has uncommitted changes. Commit or stash first, or set CRISPY_ALLOW_DIRTY=1 to override."}'
  exit 0
fi

echo '{}'