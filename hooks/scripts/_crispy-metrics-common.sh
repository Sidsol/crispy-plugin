#!/usr/bin/env bash
# Shared helpers for crispy-metrics-{start,record}.sh
# This file is sourced, not executed.

# Disable on demand
crispy_metrics_disabled() {
  [ "${CRISPY_METRICS_DISABLED:-0}" = "1" ]
}

crispy_metrics_pending_dir() {
  local base="${TMPDIR:-/tmp}"
  printf '%s/crispy-metrics-pending' "$base"
}

# Hash a string with sha256 (first 32 hex chars). Falls back to md5 / cksum.
crispy_metrics_hash() {
  local s="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    printf '%s' "$s" | sha256sum | awk '{print substr($1,1,32)}'
  elif command -v shasum >/dev/null 2>&1; then
    printf '%s' "$s" | shasum -a 256 | awk '{print substr($1,1,32)}'
  elif command -v md5sum >/dev/null 2>&1; then
    printf '%s' "$s" | md5sum | awk '{print $1}'
  else
    printf '%s' "$s" | cksum | awk '{print $1}'
  fi
}

# Phase classification.
# Echoes:  "<workstream>|<phase_label>|<phase_order>"
# Workstream is "feature", "project", or "both".
crispy_metrics_classify() {
  local agent="$1"
  case "$agent" in
    crispy|crispy-project)                 echo "both|Orchestration|0" ;;
    crispy-clarify)                        echo "feature|Clarify|1" ;;
    crispy-research|aggregate-research)    echo "feature|Research|2" ;;
    crispy-intent)                         echo "feature|Intention|3" ;;
    crispy-structure)                      echo "feature|Structure|4" ;;
    crispy-plan)                           echo "feature|Plan|5" ;;
    crispy-yield)                          echo "feature|Yield|6" ;;
    crispy-implement|test-author|implementer|spec-review|code-review|rubber-duck)
                                           echo "feature|Implementation|7" ;;
    crispy-vision)                         echo "project|Vision|1" ;;
    crispy-domain-research)                echo "project|Domain Research|2" ;;
    crispy-architecture|crispy-scaffold)   echo "project|Architecture|3" ;;
    crispy-feature-map)                    echo "project|Feature Map|4" ;;
    crispy-roadmap)                        echo "project|Roadmap|5" ;;
    crispy-project-yield)                  echo "project|Yield|6" ;;
    crispy-scan|crispy-branch)             echo "both|Utility|8" ;;
    explore)                               echo "feature|Research|2" ;;
    *)                                     echo "" ;;
  esac
}

# Extract agent name from a Copilot Task tool agent_type/name field.
# Strips the "crispy-workflow:" prefix (custom agents) and lower-cases.
crispy_metrics_normalize_agent() {
  local raw="$1"
  raw="${raw#crispy-workflow:}"
  printf '%s' "$raw" | tr '[:upper:]' '[:lower:]'
}

# Locate the owning crispy-docs feature/project from a search string (toolArgs blob).
# Echoes: "<feature_path>|<project_path>"  (either may be empty)
# Paths are relative (start with "crispy-docs/").
crispy_metrics_locate_paths() {
  local blob="$1"
  local feature=""
  local project=""

  # Project-feature: crispy-docs/projects/NNN-foo/features/MMM-bar
  if [[ "$blob" =~ (crispy-docs/projects/[0-9A-Za-z._-]+)/features/([0-9A-Za-z._-]+) ]]; then
    project="${BASH_REMATCH[1]}"
    feature="${project}/features/${BASH_REMATCH[2]}"
  # Project (no feature)
  elif [[ "$blob" =~ (crispy-docs/projects/[0-9A-Za-z._-]+) ]]; then
    project="${BASH_REMATCH[1]}"
  # Standalone feature
  elif [[ "$blob" =~ (crispy-docs/specs/[0-9A-Za-z._-]+) ]]; then
    feature="${BASH_REMATCH[1]}"
  fi

  printf '%s|%s' "$feature" "$project"
}

# Walk up from cwd to find a directory containing crispy-docs/. Echoes the parent dir
# (the one that *contains* crispy-docs), or empty string if not found.
crispy_metrics_find_root() {
  local d="$1"
  while [ -n "$d" ] && [ "$d" != "/" ]; do
    if [ -d "$d/crispy-docs" ]; then
      printf '%s' "$d"
      return 0
    fi
    d="$(dirname "$d")"
  done
  printf ''
}

# Return chars / 4 (rounded up) as approx token count.
crispy_metrics_approx_tokens() {
  local n="$1"
  if [ -z "$n" ] || [ "$n" -lt 0 ] 2>/dev/null; then n=0; fi
  echo $(( (n + 3) / 4 ))
}

# Length in characters of arg $1 (handles multi-line via printf).
crispy_metrics_strlen() {
  local s="$1"
  printf '%s' "$s" | wc -c | awk '{print $1+0}'
}

# JSON-escape a string for embedding in a JSON value.
crispy_metrics_json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

# Garbage-collect pending files older than 24h.
crispy_metrics_gc() {
  local dir; dir="$(crispy_metrics_pending_dir)"
  [ -d "$dir" ] || return 0
  find "$dir" -type f -name '*.json' -mmin +1440 -delete 2>/dev/null || true
}
