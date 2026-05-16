param(
    [Parameter(Mandatory = $true)]
    [string]$Action,

    [string]$Reason = "",
    [string]$Actor = "",
    [string]$TargetFeatureDirectory = ""
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "common-actor-resolution.ps1")
. (Join-Path $PSScriptRoot "bridge-state.ps1")

function Get-RepoRoot {
    if (Get-Command Get-BridgeRepoRoot -ErrorAction SilentlyContinue) { return Get-BridgeRepoRoot }
    return (Get-Location).Path
}

function Write-GuardEvent {
    param([string]$RepoRoot, [string]$ActionName, [string]$Decision, [string]$ReasonText, [string]$Actor, [string]$FeatureDirectory)
    $event = [ordered]@{
        timestamp = (Get-Date).ToUniversalTime().ToString("o")
        action = "guard"
        status = $Decision
        feature_directory = $FeatureDirectory
        decision = $Decision
        reason = $ReasonText
        actor = $Actor
        checked_action = $ActionName
    }
    $path = Join-Path $RepoRoot ".specify\bridge-events.jsonl"
    ($event | ConvertTo-Json -Compress -Depth 4) + [Environment]::NewLine | Add-Content -LiteralPath $path -Encoding UTF8
}

# --- Main ---

$repoRoot = Get-RepoRoot
$Actor = Resolve-BridgeActor -Argument $Actor

# Read handoff state (tolerant of v2/v3 unknown fields per FR-009)
$handoffPath = Join-Path $repoRoot ".specify\superpowers-handoff.json"
$handoffStatus = $null
$handoffFeatureDir = $null
if (Test-Path -LiteralPath $handoffPath) {
    $h = Get-Content -LiteralPath $handoffPath -Raw | ConvertFrom-Json
    if ($h.status) { $handoffStatus = [string]$h.status }
    if ($h.feature_directory) { $handoffFeatureDir = [string]$h.feature_directory }
}

# --- 5 hardcoded rules (research.md R3) ---

$decision = $null
$denyReason = $null

# Rule 1: deny speckit.implement when handoff is executing
if ($Action -eq "speckit.implement" -and $handoffStatus -eq "executing") {
    $decision = "deny"
    $denyReason = "speckit.implement blocked while superpowers handoff is executing"
}
# Rule 2: deny superpowers writing-plans / brainstorming when active feature has spec.md + plan.md
elseif (($Action -eq "superpowers:writing-plans" -or $Action -eq "superpowers:brainstorming") -and $handoffFeatureDir) {
    $specPath = Join-Path $repoRoot (Join-Path $handoffFeatureDir "spec.md")
    $planPath = Join-Path $repoRoot (Join-Path $handoffFeatureDir "plan.md")
    if ((Test-Path -LiteralPath $specPath) -and (Test-Path -LiteralPath $planPath)) {
        $decision = "deny"
        $denyReason = "native superpowers planning is forbidden while spec kit owns design artifacts"
    }
}
# Rule 3: deny speckit.constitution while handoff is executing
elseif ($Action -eq "speckit.constitution" -and $handoffStatus -eq "executing") {
    $decision = "deny"
    $denyReason = "constitution edits blocked during active handoff; mark blocked first"
}
# Rule 4: allow any other speckit.*
elseif ($Action -like "speckit.*") {
    $decision = "allow"
}
# Rule 5 (default): allow
else {
    $decision = "allow"
}

Write-GuardEvent -RepoRoot $repoRoot -ActionName $Action -Decision $decision -ReasonText $denyReason -Actor $Actor -FeatureDirectory $handoffFeatureDir

# FR-002: emit [bridge state] block on every allow/deny decision. The guard never mutates,
# so we do NOT pass -EmitCompleteWarning. PriorActor is omitted (guard doesn't change actors).
Write-BridgeStateSummaryFull -HandoffPath $handoffPath -RepoRoot $repoRoot -Actor $Actor

if ($decision -eq "deny") {
    Write-Output "Guard denied $Action."
    if ($denyReason) { Write-Output "Reason: $denyReason" }
    exit 1
}

Write-Output "Guard allowed $Action."
exit 0
