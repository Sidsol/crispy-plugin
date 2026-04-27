# _crispy-metrics-common.ps1 — Shared helpers for crispy-metrics-{start,record}.ps1
# This file is dot-sourced, not executed.

function Test-CrispyMetricsDisabled {
  return ($env:CRISPY_METRICS_DISABLED -eq '1')
}

function Get-CrispyMetricsPendingDir {
  $base = $env:TEMP
  if (-not $base) { $base = [System.IO.Path]::GetTempPath() }
  return (Join-Path $base 'crispy-metrics-pending')
}

function Get-CrispyMetricsHash {
  param([string]$Text)
  $sha = [System.Security.Cryptography.SHA256]::Create()
  try {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    $hash  = $sha.ComputeHash($bytes)
    $hex   = -join ($hash | ForEach-Object { $_.ToString('x2') })
    return $hex.Substring(0, 32)
  } finally { $sha.Dispose() }
}

# Returns @{ Workstream='feature'|'project'|'both'; Phase='Research'; Order=2 } or $null.
function Get-CrispyMetricsClassification {
  param([string]$Agent)
  switch -Regex ($Agent) {
    '^(crispy|crispy-project)$'                    { return @{ Workstream='both';    Phase='Orchestration'; Order=0 } }
    '^crispy-clarify$'                             { return @{ Workstream='feature'; Phase='Clarify';       Order=1 } }
    '^(crispy-research|aggregate-research|explore)$' { return @{ Workstream='feature'; Phase='Research';      Order=2 } }
    '^crispy-intent$'                              { return @{ Workstream='feature'; Phase='Intention';     Order=3 } }
    '^crispy-structure$'                           { return @{ Workstream='feature'; Phase='Structure';     Order=4 } }
    '^crispy-plan$'                                { return @{ Workstream='feature'; Phase='Plan';          Order=5 } }
    '^crispy-yield$'                               { return @{ Workstream='feature'; Phase='Yield';         Order=6 } }
    '^(crispy-implement|test-author|implementer|spec-review|code-review|rubber-duck)$' {
      return @{ Workstream='feature'; Phase='Implementation'; Order=7 }
    }
    '^crispy-vision$'                              { return @{ Workstream='project'; Phase='Vision';        Order=1 } }
    '^crispy-domain-research$'                     { return @{ Workstream='project'; Phase='Domain Research'; Order=2 } }
    '^(crispy-architecture|crispy-scaffold)$'      { return @{ Workstream='project'; Phase='Architecture';  Order=3 } }
    '^crispy-feature-map$'                         { return @{ Workstream='project'; Phase='Feature Map';   Order=4 } }
    '^crispy-roadmap$'                             { return @{ Workstream='project'; Phase='Roadmap';       Order=5 } }
    '^crispy-project-yield$'                       { return @{ Workstream='project'; Phase='Yield';         Order=6 } }
    '^(crispy-scan|crispy-branch)$'                { return @{ Workstream='both';    Phase='Utility';       Order=8 } }
    default                                        { return $null }
  }
}

function ConvertTo-CrispyMetricsAgentName {
  param([string]$Raw)
  if (-not $Raw) { return '' }
  $n = $Raw -replace '^crispy-workflow:', ''
  return $n.ToLowerInvariant()
}

# Returns @{ Feature='crispy-docs/...'; Project='crispy-docs/projects/...' } (either may be '').
function Get-CrispyMetricsPaths {
  param([string]$Blob)
  $feature = ''
  $project = ''
  $m = [regex]::Match($Blob, 'crispy-docs/projects/([0-9A-Za-z._-]+)/features/([0-9A-Za-z._-]+)')
  if ($m.Success) {
    $project = "crispy-docs/projects/$($m.Groups[1].Value)"
    $feature = "$project/features/$($m.Groups[2].Value)"
  } else {
    $m = [regex]::Match($Blob, 'crispy-docs/projects/([0-9A-Za-z._-]+)')
    if ($m.Success) {
      $project = "crispy-docs/projects/$($m.Groups[1].Value)"
    } else {
      $m = [regex]::Match($Blob, 'crispy-docs/specs/([0-9A-Za-z._-]+)')
      if ($m.Success) {
        $feature = "crispy-docs/specs/$($m.Groups[1].Value)"
      }
    }
  }
  return @{ Feature = $feature; Project = $project }
}

function Find-CrispyMetricsRoot {
  param([string]$StartDir)
  $d = $StartDir
  while ($d -and (Test-Path $d)) {
    if (Test-Path (Join-Path $d 'crispy-docs')) { return $d }
    $parent = Split-Path -Parent $d
    if (-not $parent -or $parent -eq $d) { return '' }
    $d = $parent
  }
  return ''
}

function Get-CrispyMetricsApproxTokens {
  param([int]$Chars)
  if ($Chars -lt 0) { $Chars = 0 }
  return [int][math]::Ceiling($Chars / 4.0)
}

function Invoke-CrispyMetricsGC {
  $dir = Get-CrispyMetricsPendingDir
  if (-not (Test-Path $dir)) { return }
  $cutoff = (Get-Date).AddHours(-24)
  Get-ChildItem -Path $dir -Filter '*.json' -File -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt $cutoff } |
    Remove-Item -Force -ErrorAction SilentlyContinue
}
