# crispy-metrics-start.ps1 — preToolUse hook
# Records start timestamp for CRISPY sub-agent invocations (task tool).
$ErrorActionPreference = 'SilentlyContinue'
. "$PSScriptRoot/_crispy-metrics-common.ps1"

# Always emit '{}' at the end so we never block the hook chain.
try {
  if (Test-CrispyMetricsDisabled) { exit 0 }

  $raw = [Console]::In.ReadToEnd()
  if (-not $raw) { exit 0 }
  $payload = $raw | ConvertFrom-Json -ErrorAction Stop

  $toolName = $payload.toolName
  if (-not $toolName) { $toolName = $payload.tool_name }
  if ($toolName -ne 'task') { exit 0 }

  $toolArgsRaw = $payload.toolArgs
  if (-not $toolArgsRaw) { $toolArgsRaw = $payload.tool_args }
  if (-not $toolArgsRaw) { exit 0 }
  if ($toolArgsRaw -isnot [string]) { $toolArgsRaw = ($toolArgsRaw | ConvertTo-Json -Depth 20 -Compress) }

  $agentRaw = ''
  $modelHint = ''
  try {
    $argsObj = $toolArgsRaw | ConvertFrom-Json -ErrorAction Stop
    $agentRaw = $argsObj.agent_type
    if (-not $agentRaw) { $agentRaw = $argsObj.name }
    $modelHint = [string]$argsObj.model
  } catch { $agentRaw = '' }

  $agent = ConvertTo-CrispyMetricsAgentName -Raw $agentRaw
  if (-not $agent) { exit 0 }

  $cls = Get-CrispyMetricsClassification -Agent $agent
  if (-not $cls) { exit 0 }

  $ts = $payload.timestamp
  if (-not $ts) { $ts = [int64]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()) }

  $cwd = $payload.cwd
  if (-not $cwd) { $cwd = '' }

  Invoke-CrispyMetricsGC
  $pendingDir = Get-CrispyMetricsPendingDir
  if (-not (Test-Path $pendingDir)) { New-Item -ItemType Directory -Force -Path $pendingDir | Out-Null }

  $hash = Get-CrispyMetricsHash -Text "$toolName|$toolArgsRaw"
  $outFile = Join-Path $pendingDir "$hash.json"

  $record = [ordered]@{
    ts_start_ms = [int64]$ts
    agent       = $agent
    model       = $modelHint
    cwd         = $cwd
    tool_args   = $toolArgsRaw
  }
  $tmp = "$outFile.tmp"
  ($record | ConvertTo-Json -Depth 20 -Compress) | Set-Content -Path $tmp -Encoding utf8 -NoNewline
  Move-Item -Path $tmp -Destination $outFile -Force
} catch {
  # swallow
} finally {
  '{}'
}
exit 0
