param(
    [ValidateSet("ready", "executing", "blocked", "complete")]
    [string]$Status = "ready",

    [string]$FeatureDirectory = "",

    [string]$Reason = "",

    [ValidateSet("codex", "claude", "unknown", "")]
    [string]$ArtifactOwner = "",

    [ValidateSet("codex", "claude", "unknown")]
    [string[]]$ReviewOnlyAgents = @(),

    [string]$Actor = "",

    [switch]$ClearFeatureDirectory,

    [psobject]$AppendArchiveEntry = $null
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "common-actor-resolution.ps1")

function Convert-ToProjectPath {
    param([string]$RepoRoot, [string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $null }
    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $rootPath = [System.IO.Path]::GetFullPath($RepoRoot).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    if ($fullPath.StartsWith($rootPath, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $fullPath.Substring($rootPath.Length).TrimStart([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar).Replace("\", "/")
    }
    return $fullPath.Replace("\", "/")
}

function Write-BridgeEvent {
    param(
        [string]$RepoRoot, [string]$Action, [string]$Status,
        [string]$FeatureDirectory, [string]$Decision, [string]$Reason,
        [string]$SnapshotId, [string]$Actor
    )
    $event = [ordered]@{
        timestamp = (Get-Date).ToUniversalTime().ToString("o")
        action = $Action
        status = $Status
        feature_directory = $FeatureDirectory
        decision = $Decision
        reason = $Reason
        actor = $Actor
        snapshot_id = $SnapshotId
    }
    $eventPath = Join-Path $RepoRoot ".specify\bridge-events.jsonl"
    ($event | ConvertTo-Json -Compress -Depth 4) + [Environment]::NewLine | Add-Content -LiteralPath $eventPath -Encoding UTF8
}

function New-BridgeSnapshot {
    param([string]$RepoRoot, [string]$Status, [string]$FeatureDirectoryFullPath, [string]$FeatureDirectoryProjectPath)
    if ([string]::IsNullOrWhiteSpace($FeatureDirectoryFullPath) -or -not (Test-Path -LiteralPath $FeatureDirectoryFullPath)) { return $null }
    $timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssfffffffZ")
    $snapshotId = "$timestamp-$Status"
    $snapshotRoot = Join-Path $RepoRoot ".specify\bridge-snapshots\$snapshotId"
    New-Item -ItemType Directory -Force -Path $snapshotRoot | Out-Null
    foreach ($artifact in @("spec.md", "plan.md", "tasks.md")) {
        $p = Join-Path $FeatureDirectoryFullPath $artifact
        if (Test-Path -LiteralPath $p) { Copy-Item -LiteralPath $p -Destination (Join-Path $snapshotRoot $artifact) -Force }
    }
    $constitutionSrc = Join-Path $RepoRoot ".specify\memory\constitution.md"
    if (Test-Path -LiteralPath $constitutionSrc) { Copy-Item -LiteralPath $constitutionSrc -Destination (Join-Path $snapshotRoot "constitution.md") -Force }
    return $snapshotId
}

# --- Main ---

$repoRoot = if (Get-Command Get-BridgeRepoRoot -ErrorAction SilentlyContinue) { Get-BridgeRepoRoot } else { (Get-Location).Path }
$Actor = Resolve-BridgeActor -Argument $Actor

$specifyDir = Join-Path $repoRoot ".specify"
if (-not (Test-Path -LiteralPath $specifyDir)) { throw "Missing .specify directory. Run this from a Spec Kit project." }

# Read existing handoff (tolerantly — ignore unknown v2/v3 fields per FR-009)
$existingHandoffPath = Join-Path $specifyDir "superpowers-handoff.json"
$priorFeatureDirectory = $null
$priorArtifactOwner = $null
if (Test-Path -LiteralPath $existingHandoffPath) {
    $existingHandoff = Get-Content -LiteralPath $existingHandoffPath -Raw | ConvertFrom-Json
    if ($existingHandoff.feature_directory) { $priorFeatureDirectory = [string]$existingHandoff.feature_directory }
    if ($existingHandoff.artifact_owner) { $priorArtifactOwner = [string]$existingHandoff.artifact_owner }
}

# Resolve feature_directory: explicit > current handoff > .specify/feature.json
# When -ClearFeatureDirectory is set, capture the prior dir BEFORE clearing so we can still snapshot it.
$featureJsonPath = Join-Path $specifyDir "feature.json"
$snapshotSourceDirectory = $null
if ($ClearFeatureDirectory) {
    $snapshotSourceDirectory = $priorFeatureDirectory
    $FeatureDirectory = ""
}
elseif ([string]::IsNullOrWhiteSpace($FeatureDirectory)) {
    if ($priorFeatureDirectory) {
        $FeatureDirectory = $priorFeatureDirectory
    }
    elseif (Test-Path -LiteralPath $featureJsonPath) {
        $featureState = Get-Content -LiteralPath $featureJsonPath -Raw | ConvertFrom-Json
        if ($featureState.feature_directory) { $FeatureDirectory = [string]$featureState.feature_directory }
    }
}

$featureDirectoryFullPath = $null
$featureDirectoryProjectPath = $null
if (-not [string]::IsNullOrWhiteSpace($FeatureDirectory)) {
    if ([System.IO.Path]::IsPathRooted($FeatureDirectory)) {
        $featureDirectoryFullPath = [System.IO.Path]::GetFullPath($FeatureDirectory)
    }
    else {
        $featureDirectoryFullPath = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $FeatureDirectory))
    }
    $featureDirectoryProjectPath = Convert-ToProjectPath -RepoRoot $repoRoot -Path $featureDirectoryFullPath
}

$constitutionPath = Join-Path $specifyDir "memory\constitution.md"
$sourceOfTruth = [ordered]@{
    constitution = ".specify/memory/constitution.md"
    spec = $null
    plan = $null
    tasks = $null
}
$missing = New-Object System.Collections.Generic.List[string]
if ($featureDirectoryFullPath) {
    foreach ($pair in @(@{ k = "spec"; f = "spec.md" }, @{ k = "plan"; f = "plan.md" }, @{ k = "tasks"; f = "tasks.md" })) {
        $artifactFull = Join-Path $featureDirectoryFullPath $pair.f
        $sourceOfTruth[$pair.k] = Convert-ToProjectPath -RepoRoot $repoRoot -Path $artifactFull
        if (-not (Test-Path -LiteralPath $artifactFull)) { $missing.Add($sourceOfTruth[$pair.k]) }
    }
}

$resolvedStatus = $Status
$blockedReason = $null
if ($missing.Count -gt 0 -and $Status -ne "complete" -and $Status -ne "ready") {
    $resolvedStatus = "blocked"
    $blockedReason = if ([string]::IsNullOrWhiteSpace($Reason)) { "Missing required Spec Kit artifacts: " + (($missing.ToArray()) -join ", ") } else { $Reason }
}
elseif ($Status -eq "blocked") {
    $blockedReason = if ([string]::IsNullOrWhiteSpace($Reason)) { "(no reason provided)" } else { $Reason }
}
$eventReason = if ([string]::IsNullOrWhiteSpace($Reason)) { $blockedReason } else { $Reason }

# Artifact owner: explicit > prior > actor > "unknown"
$owner = if ($ArtifactOwner) { $ArtifactOwner } elseif ($priorArtifactOwner) { $priorArtifactOwner } elseif ($Actor -in @("codex", "claude")) { $Actor } else { "unknown" }
$reviewOnly = @($ReviewOnlyAgents | Where-Object { $_ -and $_ -ne $owner } | Select-Object -Unique)

# Snapshot before writing (constitution Principle IV).
# For auto-archive (ClearFeatureDirectory), snapshot the prior feature_directory we captured above.
$snapshotId = $null
$snapshotPath = $null
if ($snapshotSourceDirectory) {
    $snapshotPath = if ([System.IO.Path]::IsPathRooted($snapshotSourceDirectory)) { [System.IO.Path]::GetFullPath($snapshotSourceDirectory) } else { [System.IO.Path]::GetFullPath((Join-Path $repoRoot $snapshotSourceDirectory)) }
}
elseif ($featureDirectoryFullPath) {
    $snapshotPath = $featureDirectoryFullPath
}
if ($snapshotPath) {
    $snapshotId = New-BridgeSnapshot -RepoRoot $repoRoot -Status $resolvedStatus -FeatureDirectoryFullPath $snapshotPath -FeatureDirectoryProjectPath $null
}

$handoff = [ordered]@{
    schema_version = 1
    updated_at = (Get-Date).ToUniversalTime().ToString("o")
    feature_directory = $featureDirectoryProjectPath
    source_of_truth = $sourceOfTruth
    supersedes = @("speckit.implement")
    executor = if ($resolvedStatus -eq "ready") { "speckit" } else { "superpowers" }
    capabilities = @("executing-plans", "test-driven-development", "verification-before-completion", "requesting-code-review", "finishing-a-development-branch")
    status = $resolvedStatus
    blocked_reason = $blockedReason
    artifact_owner = $owner
    review_only_agents = @($reviewOnly)
    notes = $null
    last_snapshot_id = $snapshotId
    instructions = "Use /speckit-superpowers-bridge (Claude Code) or `$speckit-superpowers-bridge (Codex). The bridge orchestrates native Superpowers skills against tasks.md; do not run speckit.implement and do not invoke superpowers:writing-plans / :brainstorming for an active Spec Kit feature."
}

$handoffPath = Join-Path $specifyDir "superpowers-handoff.json"
$handoff | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $handoffPath -Encoding UTF8

Write-BridgeEvent -RepoRoot $repoRoot -Action "handoff" -Status $resolvedStatus -FeatureDirectory $featureDirectoryProjectPath -Decision "updated" -Reason $eventReason -SnapshotId $snapshotId -Actor $Actor

Write-Output "Wrote .specify/superpowers-handoff.json with status '$resolvedStatus'."
if ($blockedReason) { Write-Output "Reason: $blockedReason" }
