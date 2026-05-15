param(
    [Parameter(Mandatory = $true)]
    [string]$SkillId,

    [Parameter(Mandatory = $true)]
    [ValidateSet("before-implementation-task", "on-failure", "before-phase-completion", "before-feature-completion", "other")]
    [string]$Phase,

    [string]$TaskId = "",

    [string]$Actor = "",

    [ValidateSet("invoked", "failed")]
    [string]$Decision = "invoked",

    [string]$Reason = ""
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "common-actor-resolution.ps1")

function Get-RepoRoot {
    return Get-BridgeRepoRoot
}

if ($SkillId -notmatch '^superpowers:[a-z][a-z0-9-]*$') {
    throw "Invalid SkillId '$SkillId'. Expected superpowers:<name>."
}

if (-not [string]::IsNullOrWhiteSpace($TaskId) -and $TaskId -notmatch '^T[0-9]{3,}$') {
    throw "Invalid TaskId '$TaskId'. Expected T###."
}

$repoRoot = Get-RepoRoot
$resolvedActor = Resolve-BridgeActor -Argument $Actor -RepoRoot $repoRoot
$handoffPath = Join-Path $repoRoot ".specify\superpowers-handoff.json"
$handoff = $null
if (Test-Path -LiteralPath $handoffPath) {
    $handoff = Get-Content -LiteralPath $handoffPath -Raw | ConvertFrom-Json
}

$status = if ($handoff -and $handoff.status) { [string]$handoff.status } else { "none" }
$featureDirectory = if ($handoff -and $handoff.feature_directory) { [string]$handoff.feature_directory } else { $null }
$snapshotId = if ($handoff -and ($handoff.PSObject.Properties.Name -contains "last_snapshot_id")) { [string]$handoff.last_snapshot_id } else { $null }

$event = [ordered]@{
    timestamp = (Get-Date).ToUniversalTime().ToString("o")
    action = "skill_invocation"
    status = $status
    feature_directory = $featureDirectory
    decision = $Decision
    reason = if ([string]::IsNullOrWhiteSpace($Reason)) { $Phase } else { $Reason }
    actor = $resolvedActor
    snapshot_id = $snapshotId
    skill_id = $SkillId
    phase = $Phase
    task_id = if ([string]::IsNullOrWhiteSpace($TaskId)) { $null } else { $TaskId }
}

$eventPath = Join-Path $repoRoot ".specify\bridge-events.jsonl"
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $eventPath) | Out-Null
($event | ConvertTo-Json -Compress -Depth 6) + [Environment]::NewLine | Add-Content -LiteralPath $eventPath -Encoding UTF8
Write-Output "Recorded skill invocation $SkillId ($Phase)."
