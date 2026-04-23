#!/usr/bin/env bash
# inject-crispy-protocol.sh — userPromptSubmit hook (telemetry only).
# Per docs, userPromptSubmit hook output is IGNORED — the hook cannot mutate
# the prompt. The CRISPY sub-agent protocol reminder lives in
# templates/subagent-prompt.template.md and SUBAGENTS.md, which are loaded
# by agent prompts directly. This hook exists only to log when a CRISPY
# sub-agent invocation passes through the session, for observability.
set -euo pipefail
PAYLOAD="$(cat || true)"
PROMPT="$(printf "%s" "$PAYLOAD" | jq -r '.userPrompt // .user_prompt // ""' 2>/dev/null || echo "")"
case "$PROMPT" in
  *crispy-result*|*"## Output contract"*)
    LOG_DIR="${CRISPY_LOG_DIR:-${TMPDIR:-/tmp}/crispy}"
    mkdir -p "$LOG_DIR" 2>/dev/null || true
    printf '[%s] CRISPY subagent prompt detected\n' "$(date -u +%FT%TZ)" >> "$LOG_DIR/subagent-prompts.log" 2>/dev/null || true
    ;;
esac
echo '{}'