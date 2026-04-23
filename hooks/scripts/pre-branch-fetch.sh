#!/usr/bin/env bash
# pre-branch-fetch.sh — preToolUse hook, advisory only.
# Pre-fetches origin/develop before any git checkout -b so the new branch
# starts from up-to-date refs. Never denies.
set -euo pipefail
PAYLOAD="$(cat || true)"
TOOL_NAME="$(printf "%s" "$PAYLOAD" | jq -r '.toolName // .tool_name // ""' 2>/dev/null || echo "")"
TOOL_ARGS="$(printf "%s" "$PAYLOAD" | jq -r '.toolArgs // .tool_args // {} | tostring' 2>/dev/null || echo "")"
case "$TOOL_NAME" in bash|powershell|execute|shell|run) ;; *) echo '{}'; exit 0 ;; esac
if ! printf "%s" "$TOOL_ARGS" | grep -Eq 'git[[:space:]]+(checkout[[:space:]]+-b|switch[[:space:]]+-c)'; then
  echo '{}'; exit 0
fi
command -v git >/dev/null 2>&1 && git fetch origin develop >/dev/null 2>&1 || true
echo '{}'