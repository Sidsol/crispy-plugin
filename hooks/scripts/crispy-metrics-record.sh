#!/usr/bin/env bash
# crispy-metrics-record.sh — postToolUse hook
# Pairs with the start record, computes elapsed + token approximations,
# and appends a JSONL line to <feature-or-project>/.metrics.jsonl.
set +e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_crispy-metrics-common.sh
. "$SCRIPT_DIR/_crispy-metrics-common.sh"

trap 'echo "{}"' EXIT
if crispy_metrics_disabled; then exit 0; fi
if ! command -v python3 >/dev/null 2>&1; then exit 0; fi

PAYLOAD="$(cat)"

TOOL_NAME="$(printf '%s' "$PAYLOAD" | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); print(d.get('toolName') or d.get('tool_name') or '')
except Exception: print('')
")"
[ "$TOOL_NAME" = "task" ] || exit 0

TOOL_ARGS_RAW="$(printf '%s' "$PAYLOAD" | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); v=d.get('toolArgs') or d.get('tool_args') or ''
  print(v if isinstance(v,str) else json.dumps(v))
except Exception: print('')
")"
[ -n "$TOOL_ARGS_RAW" ] || exit 0

AGENT_RAW="$(printf '%s' "$TOOL_ARGS_RAW" | python3 -c "import json,sys
try:
  s=sys.stdin.read(); d=json.loads(s) if s.lstrip().startswith('{') else {}
  print(d.get('agent_type') or d.get('name') or '')
except Exception: print('')
")"
AGENT="$(crispy_metrics_normalize_agent "$AGENT_RAW")"
[ -n "$AGENT" ] || exit 0

MODEL="$(printf '%s' "$TOOL_ARGS_RAW" | python3 -c "import json,sys
try:
  s=sys.stdin.read(); d=json.loads(s) if s.lstrip().startswith('{') else {}
  print(d.get('model') or '')
except Exception: print('')
")"

CLASS="$(crispy_metrics_classify "$AGENT")"
[ -n "$CLASS" ] || exit 0
WORKSTREAM="$(printf '%s' "$CLASS" | cut -d'|' -f1)"
PHASE="$(printf '%s' "$CLASS" | cut -d'|' -f2)"
PHASE_ORDER="$(printf '%s' "$CLASS" | cut -d'|' -f3)"

TS_END_MS="$(printf '%s' "$PAYLOAD" | python3 -c "import json,sys,time
try:
  d=json.load(sys.stdin); v=d.get('timestamp')
  print(int(v) if v else int(time.time()*1000))
except Exception: print(int(time.time()*1000))
")"

CWD="$(printf '%s' "$PAYLOAD" | python3 -c "import json,sys
try: d=json.load(sys.stdin); print(d.get('cwd') or '')
except Exception: print('')
")"

PENDING_DIR="$(crispy_metrics_pending_dir)"
HASH="$(crispy_metrics_hash "$TOOL_NAME|$TOOL_ARGS_RAW")"
PENDING_FILE="$PENDING_DIR/$HASH.json"
TS_START_MS=""
PENDING_MODEL=""
if [ -f "$PENDING_FILE" ]; then
  TS_START_MS="$(python3 -c "import json
try: print(json.load(open('$PENDING_FILE','r',encoding='utf-8')).get('ts_start_ms') or '')
except Exception: print('')
")"
  PENDING_MODEL="$(python3 -c "import json
try: print(json.load(open('$PENDING_FILE','r',encoding='utf-8')).get('model') or '')
except Exception: print('')
")"
  rm -f "$PENDING_FILE" 2>/dev/null
fi
if [ -z "$TS_START_MS" ]; then TS_START_MS="$TS_END_MS"; fi
if [ -z "$MODEL" ] && [ -n "$PENDING_MODEL" ]; then MODEL="$PENDING_MODEL"; fi

# Pull the prompt out of toolArgs (input chars) and result text (output chars).
INPUT_CHARS="$(printf '%s' "$TOOL_ARGS_RAW" | python3 -c "import json,sys
try:
  d=json.loads(sys.stdin.read()); p=d.get('prompt') or ''
  print(len(p))
except Exception: print(0)
")"
OUTPUT_CHARS="$(printf '%s' "$PAYLOAD" | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); r=d.get('toolResult') or {}
  t=r.get('textResultForLlm') or ''
  print(len(t))
except Exception: print(0)
")"
RESULT_TYPE="$(printf '%s' "$PAYLOAD" | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); r=d.get('toolResult') or {}
  print(r.get('resultType') or 'unknown')
except Exception: print('unknown')
")"

PATHS="$(crispy_metrics_locate_paths "$TOOL_ARGS_RAW")"
FEATURE_REL="$(printf '%s' "$PATHS" | cut -d'|' -f1)"
PROJECT_REL="$(printf '%s' "$PATHS" | cut -d'|' -f2)"

ROOT="$(crispy_metrics_find_root "$CWD")"
[ -n "$ROOT" ] || ROOT="$CWD"

# Decide where the JSONL goes.
TARGET_DIR=""
if [ -n "$FEATURE_REL" ]; then
  TARGET_DIR="$ROOT/$FEATURE_REL"
elif [ -n "$PROJECT_REL" ]; then
  TARGET_DIR="$ROOT/$PROJECT_REL"
else
  TARGET_DIR="$ROOT/crispy-docs"
fi
mkdir -p "$TARGET_DIR" 2>/dev/null

ELAPSED_MS=$(( TS_END_MS - TS_START_MS ))
[ "$ELAPSED_MS" -ge 0 ] 2>/dev/null || ELAPSED_MS=0

# Emit one JSON line. Use python for safe encoding.
python3 - "$TARGET_DIR" "$TS_START_MS" "$TS_END_MS" "$ELAPSED_MS" "$AGENT" "$WORKSTREAM" "$PHASE" "$PHASE_ORDER" "$RESULT_TYPE" "$INPUT_CHARS" "$OUTPUT_CHARS" "$FEATURE_REL" "$PROJECT_REL" "$CWD" "$MODEL" <<'PY'
import json,os,sys,math
(target, ts0, ts1, elapsed_ms, agent, ws, phase, order, result, in_chars, out_chars, feat, proj, cwd, model) = sys.argv[1:16]
in_chars = int(in_chars or 0); out_chars = int(out_chars or 0)
rec = {
  "ts_start_ms": int(ts0 or 0),
  "ts_end_ms":   int(ts1 or 0),
  "elapsed_s":   round(int(elapsed_ms or 0) / 1000.0, 3),
  "agent":       agent,
  "model":       model or "",
  "workstream":  ws,
  "phase":       phase,
  "phase_order": int(order or 0),
  "result":      result,
  "invocations": 1,
  "input_chars":          in_chars,
  "output_chars":         out_chars,
  "approx_input_tokens":  math.ceil(in_chars / 4),
  "approx_output_tokens": math.ceil(out_chars / 4),
  "feature_path": feat or None,
  "project_path": proj or None,
  "cwd":          cwd,
}
os.makedirs(target, exist_ok=True)
path = os.path.join(target, ".metrics.jsonl")
with open(path, "a", encoding="utf-8") as f:
  f.write(json.dumps(rec, ensure_ascii=False) + "\n")
PY

exit 0
