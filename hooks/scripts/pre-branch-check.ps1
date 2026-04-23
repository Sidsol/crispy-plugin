# pre-branch-check.ps1 — preToolUse hook (PowerShell)
$ErrorActionPreference = 'SilentlyContinue'
$payload = [Console]::In.ReadToEnd()
try { $j = $payload | ConvertFrom-Json } catch { '{}' ; exit 0 }

$tool = $j.toolName
if (-not $tool) { $tool = $j.tool_name }
$argsStr = ''
if ($j.toolArgs) { $argsStr = ($j.toolArgs | ConvertTo-Json -Depth 10 -Compress) }
elseif ($j.tool_args) { $argsStr = ($j.tool_args | ConvertTo-Json -Depth 10 -Compress) }

if ($tool -notin @('bash','powershell','execute','shell','run')) { '{}' ; exit 0 }
if ($argsStr -notmatch 'git\s+(checkout\s+-b|switch\s+-c|branch\s+(-c|-b|--create))') { '{}' ; exit 0 }
if ($env:CRISPY_ALLOW_DIRTY -eq '1') { '{}' ; exit 0 }
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { '{}' ; exit 0 }

$dirty = git status --porcelain 2>$null
if ($dirty) {
  @{ permissionDecision = 'deny'; permissionDecisionReason = 'CRISPY pre-branch-check: working tree has uncommitted changes. Commit or stash first, or set CRISPY_ALLOW_DIRTY=1 to override.' } | ConvertTo-Json -Compress
  exit 0
}
'{}'