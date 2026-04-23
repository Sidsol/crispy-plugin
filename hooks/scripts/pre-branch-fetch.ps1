# pre-branch-fetch.ps1 — preToolUse hook, advisory only.
$ErrorActionPreference = 'SilentlyContinue'
$payload = [Console]::In.ReadToEnd()
try { $j = $payload | ConvertFrom-Json } catch { '{}' ; exit 0 }
$tool = $j.toolName; if (-not $tool) { $tool = $j.tool_name }
$argsStr = ''
if ($j.toolArgs) { $argsStr = ($j.toolArgs | ConvertTo-Json -Depth 10 -Compress) }
elseif ($j.tool_args) { $argsStr = ($j.tool_args | ConvertTo-Json -Depth 10 -Compress) }
if ($tool -notin @('bash','powershell','execute','shell','run')) { '{}'; exit 0 }
if ($argsStr -notmatch 'git\s+(checkout\s+-b|switch\s+-c)') { '{}'; exit 0 }
if (Get-Command git -ErrorAction SilentlyContinue) { git fetch origin develop 2>$null | Out-Null }
'{}'