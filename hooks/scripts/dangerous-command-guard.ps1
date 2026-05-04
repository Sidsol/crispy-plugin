# Dangerous Command Guard (PowerShell)
# Blocks destructive git and file operations in CRISPY CLI pre-tool hooks

param(
    [Parameter(Mandatory=$true)]
    [string]$Command,
    
    [Parameter(Mandatory=$false)]
    [string]$Args
)

$ErrorActionPreference = "Stop"

# Combine command and args for pattern matching
$fullCommand = "$Command $Args".Trim()

# Define dangerous command patterns
$dangerousPatterns = @(
    # Git destructive operations
    @{ Pattern = '(?i)\bgit\b.*\bpush\b'; Description = 'git push (force-pushes branch state to remote)' },
    @{ Pattern = '(?i)\bgit\b.*\breset\b.*--hard'; Description = 'git reset --hard (discards uncommitted work)' },
    @{ Pattern = '(?i)\bgit\b.*\bclean\b'; Description = 'git clean (deletes untracked files)' },
    @{ Pattern = '(?i)\bgit\b.*\bstash\b.*\bdrop\b'; Description = 'git stash drop (permanently deletes stashed changes)' },
    @{ Pattern = '(?i)\bgit\b.*\bstash\b.*\bclear\b'; Description = 'git stash clear (deletes all stashes)' },
    @{ Pattern = '(?i)\bgit\b.*\bbranch\b.*\s-[Dd]\b'; Description = 'git branch -D/-d (deletes branches)' },
    @{ Pattern = '(?i)\bgit\b.*\bremote\b.*\bremove\b'; Description = 'git remote remove (removes remote configuration)' },
    @{ Pattern = '(?i)\bgit\b.*\btag\b.*\s-[Dd]\b'; Description = 'git tag -d (deletes tags)' },
    
    # File system destructive operations (cross-platform patterns)
    @{ Pattern = '(?i)\brm\s+-[^ \t\r\n]*r[^ \t\r\n]*f|(?i)\brm\s+-[^ \t\r\n]*f[^ \t\r\n]*r'; Description = 'rm -rf/rm -fr (recursive force delete)' },
    @{ Pattern = '(?i)\bRemove-Item\b.*-Recurse.*-Force'; Description = 'Remove-Item -Recurse -Force (recursive force delete)' },
    @{ Pattern = '(?i)\bRemove-Item\b.*-Force.*-Recurse'; Description = 'Remove-Item -Force -Recurse (recursive force delete)' },
    @{ Pattern = '(?i)\brd\s+/s\s+/q'; Description = 'rd /s /q (Windows recursive delete)' },
    @{ Pattern = '(?i)\brmdir\s+/s\s+/q'; Description = 'rmdir /s /q (Windows recursive delete)' },
    @{ Pattern = '(?i)\bdel\s+/f\s+/s\s+/q'; Description = 'del /f /s /q (Windows forced recursive delete)' }
)

# Check if command matches any dangerous pattern
foreach ($danger in $dangerousPatterns) {
    if ($fullCommand -match $danger.Pattern) {
        Write-Error @"
DANGEROUS COMMAND BLOCKED: $($danger.Description)

Command: $fullCommand

This operation is blocked by CRISPY dangerous-command guard because it can:
- Permanently delete work
- Modify remote repository state
- Affect other team members

If you genuinely need this operation:
1. Review the necessity with your team
2. Exit CRISPY CLI and run the command directly in a standard shell
3. Document the reason in your commit message or feature notes

To disable this guard (NOT RECOMMENDED):
- Remove or modify hooks/scripts/dangerous-command-guard.ps1
- Update hooks.json preToolUse configuration

Blocked at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@
        exit 1
    }
}

# Command is safe - allow it
Write-Verbose "Command passed dangerous-command guard: $fullCommand"
exit 0
