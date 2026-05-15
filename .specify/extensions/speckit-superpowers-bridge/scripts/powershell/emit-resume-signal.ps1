$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "common-actor-resolution.ps1")

$repoRoot = Get-BridgeRepoRoot
$handoffPath = Join-Path $repoRoot ".specify\superpowers-handoff.json"
if (-not (Test-Path -LiteralPath $handoffPath)) {
    return
}

$handoff = Get-Content -LiteralPath $handoffPath -Raw | ConvertFrom-Json
if (-not ($handoff.PSObject.Properties.Name -contains "resume_context") -or $null -eq $handoff.resume_context) {
    return
}

$ctx = $handoff.resume_context
$taskId = if ($ctx.current_task_id) { [string]$ctx.current_task_id } else { "no-task" }
$skill = if ($ctx.current_skill) { [string]$ctx.current_skill } else { "no-skill" }
$phase = if ($ctx.current_phase) { [string]$ctx.current_phase } else { "other" }
$next = if ($ctx.next_expected_action) { [string]$ctx.next_expected_action } else { "continue bridge execution" }

$line = "Resuming $taskId via $skill (phase: $phase) - next: $next"
if ($line.Length -gt 200) {
    $prefix = "Resuming $taskId via $skill - next: "
    $remaining = [Math]::Max(0, 197 - $prefix.Length)
    $line = $prefix + $next.Substring(0, [Math]::Min($next.Length, $remaining)) + "..."
}

Write-Output $line
