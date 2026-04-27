#!/usr/bin/env bash
# crispy-metrics-start.sh — preToolUse hook
# Records start timestamp for CRISPY sub-agent invocations (task tool).
set +e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_crispy-metrics-common.sh
. "$SCRIPT_DIR/_crispy-metrics-common.sh"

if crispy_metrics_disabled; then echo '{}'; exit 0; fi

PAYLOAD="$(cat)"
# Always emit something so we never block the hook chain.
trap 'echo "{}"' EXIT

# Extract toolName and toolArgs (string). Use grep+sed; jq is not guaranteed.
get_field() {
  local key="$1"
  printf '%s' "$PAYLOAD" | python3 -c "import json,sys;
try:
  d=json.load(sys.stdin)
  v=d.get('$key', d.get('${key}'.replace('N','_n').lower()))
  if v is None:
    print('')
  elif isinstance(v,str):
    print(v)
  else:
    print(json.dumps(v))
except Exception:
  print('')
" 2>/dev/null
}

if ! command -v python3 >/dev/null 2>&1; then exit 0; fi

TOOL_NAME="$(printf '%s' "$PAYLOAD" | python3 -c "import json,sys
try:
  d=json.load(sys.stdin)
  print(d.get('toolName') or d.get('tool_name') or '')
except Exception:
  print('')
")"
[ "$TOOL_NAME" = "task" ] || exit 0

TOOL_ARGS_RAW="$(printf '%s' "$PAYLOAD" | python3 -c "import json,sys
try:
  d=json.load(sys.stdin)
  v=d.get('toolArgs') or d.get('tool_args') or ''
  print(v if isinstance(v,str) else json.dumps(v))
except Exception:
  print('')
")"
[ -n "$TOOL_ARGS_RAW" ] || exit 0

AGENT_RAW="$(printf '%s' "$TOOL_ARGS_RAW" | python3 -c "import json,sys
try:
  s=sys.stdin.read()
  d=json.loads(s) if s.lstrip().startswith('{') else {}
  print(d.get('agent_type') or d.get('name') or '')
except Exception:
  print('')
")"
AGENT="$(crispy_metrics_normalize_agent "$AGENT_RAW")"
[ -n "$AGENT" ] || exit 0

CLASS="$(crispy_metrics_classify "$AGENT")"
[ -n "$CLASS" ] || exit 0

MODEL="$(printf '%s' "$TOOL_ARGS_RAW" | python3 -c "import json,sys
try:
  s=sys.stdin.read(); d=json.loads(s) if s.lstrip().startswith('{') else {}
  print(d.get('model') or '')
except Exception: print('')
")"

TS_MS="$(printf '%s' "$PAYLOAD" | python3 -c "import json,sys,time
try:
  d=json.load(sys.stdin)
  v=d.get('timestamp')
  print(int(v) if v else int(time.time()*1000))
except Exception:
  print(int(time.time()*1000))
")"

PENDING_DIR="$(crispy_metrics_pending_dir)"
mkdir -p "$PENDING_DIR" 2>/dev/null
crispy_metrics_gc

HASH="$(crispy_metrics_hash "$TOOL_NAME|$TOOL_ARGS_RAW")"
OUT="$PENDING_DIR/$HASH.json"

CWD="$(printf '%s' "$PAYLOAD" | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); print(d.get('cwd') or '')
except Exception: print('')
")"

# Use python to write JSON safely.
python3 - "$OUT" "$TS_MS" "$AGENT" "$CWD" "$TOOL_ARGS_RAW" "$MODEL" <<'PY'
import json,sys,os
out, ts, agent, cwd, args_raw, model = sys.argv[1:7]
data = {
  "ts_start_ms": int(ts),
  "agent": agent,
  "model": model or "",
  "cwd": cwd,
  "tool_args": args_raw,
}
tmp = out + ".tmp"
with open(tmp, "w", encoding="utf-8") as f:
  json.dump(data, f)
os.replace(tmp, out)
PY

exit 0
