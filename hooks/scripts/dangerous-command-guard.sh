#!/usr/bin/env bash
# Dangerous Command Guard (Bash)
# Blocks destructive git and file operations in CRISPY CLI pre-tool hooks

set -euo pipefail

COMMAND="${1:-}"
ARGS="${2:-}"

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
