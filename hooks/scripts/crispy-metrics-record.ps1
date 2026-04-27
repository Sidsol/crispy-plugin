# crispy-metrics-record.ps1 — postToolUse hook
$ErrorActionPreference = 'SilentlyContinue'
. "$PSScriptRoot/_crispy-metrics-common.ps1"

try {
  if (Test-CrispyMetricsDisabled) { exit 0 }

  $raw = [Console]::In.ReadToEnd()
  if (-not $raw) { exit 0 }
  $payload = $raw | ConvertFrom-Json -ErrorAction Stop

  $toolName = $payload.toolName; if (-not $toolName) { $toolName = $payload.tool_name }
  if ($toolName -ne 'task') { exit 0 }

  $toolArgsRaw = $payload.toolArgs; if (-not $toolArgsRaw) { $toolArgsRaw = $payload.tool_args }
  if (-not $toolArgsRaw) { exit 0 }
  if ($toolArgsRaw -isnot [string]) { $toolArgsRaw = ($toolArgsRaw | ConvertTo-Json -Depth 20 -Compress) }

  $agentRaw = ''
  $promptText = ''
  $modelHint = ''
  try {
    $argsObj = $toolArgsRaw | ConvertFrom-Json -ErrorAction Stop
    $agentRaw   = $argsObj.agent_type; if (-not $agentRaw) { $agentRaw = $argsObj.name }
    $promptText = [string]($argsObj.prompt)
    $modelHint  = [string]($argsObj.model)
  } catch { }

  $agent = ConvertTo-CrispyMetricsAgentName -Raw $agentRaw
  if (-not $agent) { exit 0 }
  $cls = Get-CrispyMetricsClassification -Agent $agent
  if (-not $cls) { exit 0 }

  $tsEnd = $payload.timestamp
  if (-not $tsEnd) { $tsEnd = [int64]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()) }
  $cwd = $payload.cwd; if (-not $cwd) { $cwd = '' }

  $hash = Get-CrispyMetricsHash -Text "$toolName|$toolArgsRaw"
  $pendingFile = Join-Path (Get-CrispyMetricsPendingDir) "$hash.json"
  $tsStart = $tsEnd
  if (Test-Path $pendingFile) {
    try {
      $pending = Get-Content $pendingFile -Raw -Encoding utf8 | ConvertFrom-Json
      if ($pending.ts_start_ms) { $tsStart = [int64]$pending.ts_start_ms }
      if (-not $modelHint -and $pending.model) { $modelHint = [string]$pending.model }
    } catch { }
    Remove-Item $pendingFile -Force -ErrorAction SilentlyContinue
  }

  $inputChars  = if ($promptText) { $promptText.Length } else { 0 }
  $resultType  = 'unknown'
  $outputChars = 0
  try {
    $r = $payload.toolResult
    if ($r) {
      if ($r.resultType) { $resultType = [string]$r.resultType }
      if ($r.textResultForLlm) { $outputChars = ([string]$r.textResultForLlm).Length }
    }
  } catch { }

  $paths = Get-CrispyMetricsPaths -Blob $toolArgsRaw
  $root  = Find-CrispyMetricsRoot -StartDir $cwd
  if (-not $root) { $root = $cwd }

  $targetDir = $null
  if ($paths.Feature) { $targetDir = Join-Path $root $paths.Feature }
  elseif ($paths.Project) { $targetDir = Join-Path $root $paths.Project }
  else { $targetDir = Join-Path $root 'crispy-docs' }
  if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Force -Path $targetDir | Out-Null }

  $elapsedMs = [int64]$tsEnd - [int64]$tsStart
  if ($elapsedMs -lt 0) { $elapsedMs = 0 }

  $featureOut = if ($paths.Feature) { $paths.Feature } else { $null }
  $projectOut = if ($paths.Project) { $paths.Project } else { $null }

  $rec = [ordered]@{
    ts_start_ms          = [int64]$tsStart
    ts_end_ms            = [int64]$tsEnd
    elapsed_s            = [math]::Round($elapsedMs / 1000.0, 3)
    agent                = $agent
    model                = $modelHint
    workstream           = $cls.Workstream
    phase                = $cls.Phase
    phase_order          = $cls.Order
    result               = $resultType
    invocations          = 1
    input_chars          = $inputChars
    output_chars         = $outputChars
    approx_input_tokens  = [int][math]::Ceiling($inputChars / 4.0)
    approx_output_tokens = [int][math]::Ceiling($outputChars / 4.0)
    feature_path         = $featureOut
    project_path         = $projectOut
    cwd                  = $cwd
  }
  $line = ($rec | ConvertTo-Json -Depth 10 -Compress)
  Add-Content -Path (Join-Path $targetDir '.metrics.jsonl') -Value $line -Encoding utf8
} catch {
} finally {
  '{}'
}
exit 0
