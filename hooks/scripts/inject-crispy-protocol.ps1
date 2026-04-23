# inject-crispy-protocol.ps1 — userPromptSubmit hook (telemetry only)
$ErrorActionPreference = 'SilentlyContinue'
$payload = [Console]::In.ReadToEnd()
try { $j = $payload | ConvertFrom-Json } catch { '{}' ; exit 0 }
$prompt = $j.userPrompt; if (-not $prompt) { $prompt = $j.user_prompt }
if ($prompt -match 'crispy-result' -or $prompt -match '## Output contract') {
  $logDir = $env:CRISPY_LOG_DIR; if (-not $logDir) { $logDir = Join-Path $env:TEMP 'crispy' }
  if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Force -Path $logDir | Out-Null }
  Add-Content -Path (Join-Path $logDir 'subagent-prompts.log') -Value ("[{0}] CRISPY subagent prompt detected" -f (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'))
}
'{}'