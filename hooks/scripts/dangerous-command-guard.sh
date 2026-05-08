#!/usr/bin/env bash
# Dangerous Command Guard (Bash)
# Blocks destructive git and file operations in CRISPY CLI pre-tool hooks
#
# Two-layer guard (per feature 002, AMD-003):
#   Layer 1 (optimization): preToolUse.matcher in hooks.json filters by tool name
#                            before this script is invoked.
#   Layer 2 (correctness floor, this script): in-script allowlist short-circuits
#                            to "allow" for any tool name not in the mutating-tool
#                            allowlist, ensuring guarantees on runtimes that do
#                            not honor the matcher field.

set -euo pipefail

COMMAND="${1:-}"
ARGS="${2:-}"

# --- Layer 2: in-script mutating-tool allowlist ---
# 12 tool tokens that may invoke shell or filesystem mutation.
# If the runtime-passed tool name is not in this list, decline to decide (exit 0).
# This list MUST stay in lockstep with the matcher regex in hooks.json
# (per feature 002 R-008 lockstep guard).
ALLOWLIST=("Bash" "bash" "Edit" "edit" "Write" "Create" "MultiEdit" "execute" "powershell" "shell" "run" "task")
TOOL_IN_ALLOWLIST=0
for allowed in "${ALLOWLIST[@]}"; do
    if [[ "$COMMAND" == "$allowed" ]]; then
        TOOL_IN_ALLOWLIST=1
        break
    fi
done
if [[ $TOOL_IN_ALLOWLIST -eq 0 ]]; then
    # Tool is not a mutating tool — allow without inspecting payload.
    exit 0
fi

# Combine command and args for pattern matching
FULL_COMMAND="$COMMAND $ARGS"

# Function to block dangerous command
block_command() {
    local description="$1"
    cat >&2 <<EOF
DANGEROUS COMMAND BLOCKED: $description

Command: $FULL_COMMAND

This operation is blocked by CRISPY dangerous-command guard because it can:
- Permanently delete work
- Modify remote repository state
- Affect other team members

If you genuinely need this operation:
1. Review the necessity with your team
2. Exit CRISPY CLI and run the command directly in a standard shell
3. Document the reason in your commit message or feature notes

To disable this guard (NOT RECOMMENDED):
- Remove or modify hooks/scripts/dangerous-command-guard.sh
- Update hooks.json preToolUse configuration

Blocked at: $(date +'%Y-%m-%d %H:%M:%S')
EOF
    exit 1
}

# Check for dangerous git operations
if [[ "$FULL_COMMAND" =~ git.*[[:space:]]push($|[[:space:]]) ]]; then
    block_command "git push (force-pushes branch state to remote)"
elif [[ "$FULL_COMMAND" =~ git.*[[:space:]]reset[[:space:]].*--hard ]]; then
    block_command "git reset --hard (discards uncommitted work)"
elif [[ "$FULL_COMMAND" =~ git.*[[:space:]]clean($|[[:space:]]) ]]; then
    block_command "git clean (deletes untracked files)"
elif [[ "$FULL_COMMAND" =~ git.*[[:space:]]stash[[:space:]].*[[:space:]]drop($|[[:space:]]) ]]; then
    block_command "git stash drop (permanently deletes stashed changes)"
elif [[ "$FULL_COMMAND" =~ git.*[[:space:]]stash[[:space:]].*[[:space:]]clear($|[[:space:]]) ]]; then
    block_command "git stash clear (deletes all stashes)"
elif [[ "$FULL_COMMAND" =~ git.*[[:space:]]branch[[:space:]].*-[Dd]($|[[:space:]]) ]]; then
    block_command "git branch -D/-d (deletes branches)"
elif [[ "$FULL_COMMAND" =~ git.*[[:space:]]remote[[:space:]].*[[:space:]]remove($|[[:space:]]) ]]; then
    block_command "git remote remove (removes remote configuration)"
elif [[ "$FULL_COMMAND" =~ git.*[[:space:]]tag[[:space:]].*-[Dd]($|[[:space:]]) ]]; then
    block_command "git tag -d (deletes tags)"
# Check for dangerous file operations
elif [[ "$FULL_COMMAND" =~ rm[[:space:]]+-[^[:space:]]*r[^[:space:]]*f ]]; then
    block_command "rm -rf (recursive force delete)"
elif [[ "$FULL_COMMAND" =~ rm[[:space:]]+-[^[:space:]]*f[^[:space:]]*r ]]; then
    block_command "rm -fr (recursive force delete)"
fi

# Command is safe - allow it
echo "Command passed dangerous-command guard: $FULL_COMMAND" >&2
exit 0
