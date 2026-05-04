# Dangerous Command Guard Fixtures

Test cases for `hooks/scripts/dangerous-command-guard.{ps1,sh}` to verify blocking behavior across dangerous and safe operations.

## Blocked Commands (MUST reject)

### Git Destructive Operations

```bash
# Git push (force-pushes branch state to remote)
git push
git push origin main
git push --force
git push -f origin main

# Git reset --hard (discards uncommitted work)
git reset --hard
git reset --hard HEAD~1
git reset --hard origin/main

# Git clean (deletes untracked files)
git clean -f
git clean -fd
git clean -fdx
git clean --force

# Git stash drop (permanently deletes stashed changes)
git stash drop
git stash drop stash@{0}
git stash clear

# Git branch delete
git branch -d feature-branch
git branch -D feature-branch

# Git remote remove
git remote remove origin
git remote rm upstream

# Git tag delete
git tag -d v1.0.0
```

### File System Destructive Operations

```bash
# Unix/Linux/macOS recursive force delete
rm -rf /path/to/dir
rm -fr /path/to/dir
rm -f -r /path/to/dir

# Windows recursive delete (PowerShell)
Remove-Item -Recurse -Force C:\path\to\dir
Remove-Item -Force -Recurse C:\path\to\dir
Remove-Item C:\path\to\dir -Recurse -Force

# Windows recursive delete (cmd)
rd /s /q C:\path\to\dir
rmdir /s /q C:\path\to\dir
del /f /s /q C:\path\to\dir\*
```

## Allowed Commands (MUST pass)

### Safe Git Operations

```bash
# Read-only operations
git status
git log
git diff
git show
git branch
git remote -v
git tag

# Safe modifications
git add .
git commit -m "message"
git checkout main
git checkout -b new-branch
git merge feature-branch
git rebase main
git fetch
git pull

# Stash operations (except drop/clear)
git stash
git stash push
git stash list
git stash show
git stash apply
git stash pop

# Reset without --hard
git reset
git reset HEAD~1
git reset --soft HEAD~1
git reset --mixed HEAD~1
```

### Safe File Operations

```bash
# Unix/Linux/macOS safe operations
rm file.txt
rm -f file.txt
ls -la
cat file.txt
mkdir -p /path/to/dir
cp -r /src /dest
mv file.txt newfile.txt

# Windows safe operations (PowerShell)
Remove-Item file.txt
Remove-Item file.txt -Force
Get-ChildItem
Get-Content file.txt
New-Item -ItemType Directory -Path C:\path\to\dir
Copy-Item -Recurse C:\src C:\dest
Move-Item file.txt newfile.txt

# Windows safe operations (cmd)
del file.txt
dir
type file.txt
md C:\path\to\dir
copy file.txt newfile.txt
move file.txt newfile.txt
```

## Testing Instructions

### Manual Testing (PowerShell)

```powershell
cd hooks/scripts

# Test blocked command (expect exit code 1 with error message)
pwsh -NoProfile -File dangerous-command-guard.ps1 -Command "git" -Args "push origin main"

# Test allowed command (expect exit code 0)
pwsh -NoProfile -File dangerous-command-guard.ps1 -Command "git" -Args "status"
```

### Manual Testing (Bash)

```bash
cd hooks/scripts

# Test blocked command (expect exit code 1 with error message)
bash dangerous-command-guard.sh "git" "push origin main"

# Test allowed command (expect exit code 0)
bash dangerous-command-guard.sh "git" "status"
```

### Automated Testing (PowerShell)

```powershell
$blocked = @(
    @("git", "push"),
    @("git", "reset --hard"),
    @("git", "clean -f"),
    @("rm", "-rf /tmp/test")
)

$allowed = @(
    @("git", "status"),
    @("git", "add ."),
    @("ls", "-la")
)

foreach ($cmd in $blocked) {
    pwsh -NoProfile -File dangerous-command-guard.ps1 -Command $cmd[0] -Args $cmd[1]
    if ($LASTEXITCODE -ne 1) { Write-Error "FAIL: Should block $($cmd -join ' ')" }
}

foreach ($cmd in $allowed) {
    pwsh -NoProfile -File dangerous-command-guard.ps1 -Command $cmd[0] -Args $cmd[1]
    if ($LASTEXITCODE -ne 0) { Write-Error "FAIL: Should allow $($cmd -join ' ')" }
}
```

### Automated Testing (Bash)

```bash
blocked_commands=(
    "git:push"
    "git:reset --hard"
    "git:clean -f"
    "rm:-rf /tmp/test"
)

allowed_commands=(
    "git:status"
    "git:add ."
    "ls:-la"
)

for cmd in "${blocked_commands[@]}"; do
    IFS=':' read -r command args <<< "$cmd"
    bash dangerous-command-guard.sh "$command" "$args" 2>/dev/null
    if [ $? -ne 1 ]; then
        echo "FAIL: Should block $command $args"
    fi
done

for cmd in "${allowed_commands[@]}"; do
    IFS=':' read -r command args <<< "$cmd"
    bash dangerous-command-guard.sh "$command" "$args" 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "FAIL: Should allow $command $args"
    fi
done
```

## Expected Behavior

**When blocked:**
- Exit code: `1`
- Error message on stderr containing:
  - "DANGEROUS COMMAND BLOCKED"
  - Description of why the command is dangerous
  - Guidance to exit CRISPY CLI if the operation is genuinely needed
  - Timestamp

**When allowed:**
- Exit code: `0`
- Optional verbose message: "Command passed dangerous-command guard: ..."

## Notes

- **No inline override**: The guard has no `--force` or `--bypass` flag. This is intentional — requiring users to exit the CLI ensures deliberate action.
- **Pattern matching**: The guard uses regex patterns to detect dangerous operations. Adding new patterns requires updating both `.ps1` and `.sh` scripts.
- **False positives**: If a safe command is incorrectly blocked, file an issue with the command and expected behavior.
- **Cross-platform**: Both PowerShell and Bash scripts must maintain equivalent blocking logic. Test on Windows and Unix-like systems.

## Maintenance

When updating the guard scripts:
1. Add new patterns to both `.ps1` and `.sh` files
2. Add corresponding test cases to this fixture document
3. Run manual tests on both platforms
4. Update `README.md` if new command categories are added
5. Update `templates/checklist-template.md` to verify new patterns in pre-implementation checks
