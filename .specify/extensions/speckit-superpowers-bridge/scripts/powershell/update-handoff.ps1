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
. (Join-Path $PSScriptRoot "bridge-state.ps1")

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
        [string]$SnapshotId, [string]$Actor, [string]$PriorActor = $null
    )
    $event = [ordered]@{
        timestamp = (Get-Date).ToUniversalTime().ToString("o")
        action = $Action
        status = $Status
        feature_directory = $FeatureDirectory
        decision = $Decision
        reason = $Reason
        actor = $Actor
        prior_actor = $PriorActor
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
$priorActor = $null
# v0.7.0+: capture prior artifacts_sha256 snapshot for drift comparison on complete writes.
$priorArtifactsSha256 = $null
if (Test-Path -LiteralPath $existingHandoffPath) {
    $existingHandoff = Get-Content -LiteralPath $existingHandoffPath -Raw | ConvertFrom-Json
    if ($existingHandoff.feature_directory) { $priorFeatureDirectory = [string]$existingHandoff.feature_directory }
    if ($existingHandoff.artifact_owner) { $priorArtifactOwner = [string]$existingHandoff.artifact_owner }
    if ($existingHandoff.PSObject.Properties.Name -contains 'artifacts_sha256' -and $existingHandoff.artifacts_sha256) {
        $priorArtifactsSha256 = $existingHandoff.artifacts_sha256
    }
    # prior_actor is NOT stored in the handoff JSON; the last-known actor is sourced from the
    # most recent handoff event in bridge-events.jsonl. We compute it best-effort here so the
    # state-summary + event-log emission can include it (per FR-004 + Clarifications Q3=C minimum).
    $eventLogPath = Join-Path $specifyDir "bridge-events.jsonl"
    if (Test-Path -LiteralPath $eventLogPath) {
        $lastHandoffLine = Get-Content -LiteralPath $eventLogPath | Where-Object { $_ -match '"action":"handoff"' } | Select-Object -Last 1
        if ($lastHandoffLine) {
            try {
                $lastEvent = $lastHandoffLine | ConvertFrom-Json
                if ($lastEvent.actor) { $priorActor = [string]$lastEvent.actor }
            } catch { $priorActor = $null }
        }
    }
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

# v0.7.0+: compute fresh artifacts_sha256 for executing/complete writes (FR-005).
# Omitted on ready/blocked writes per spec data-model.md Entity 2 lifecycle rules.
$freshArtifactsSha256 = $null
if ($resolvedStatus -eq 'executing' -or $resolvedStatus -eq 'complete') {
    if ($featureDirectoryFullPath) {
        $freshArtifactsSha256 = Get-ArtifactsSha256Map -FeatureFull $featureDirectoryFullPath
    } else {
        $freshArtifactsSha256 = [ordered]@{ 'spec.md' = $null; 'plan.md' = $null; 'tasks.md' = $null }
    }
    $handoff['artifacts_sha256'] = $freshArtifactsSha256
}

# v0.7.0+: drift comparison (FR-006, FR-008) — compute BEFORE writing.
$driftedDetails = @()
$driftedFilenames = ''
if ($resolvedStatus -eq 'complete' -and $priorArtifactsSha256) {
    foreach ($f in @('spec.md', 'plan.md', 'tasks.md')) {
        $prior = $priorArtifactsSha256.$f
        $fresh = if ($freshArtifactsSha256) { $freshArtifactsSha256[$f] } else { $null }
        if ($prior -ne $fresh) {
            $driftedDetails += [pscustomobject]@{ path = $f; old_sha256 = $prior; new_sha256 = $fresh }
        }
    }
    if ($driftedDetails.Count -gt 0) {
        $driftedFilenames = ($driftedDetails | ForEach-Object { $_.path }) -join ', '
    }
}

$handoffPath = Join-Path $specifyDir "superpowers-handoff.json"
$handoff | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $handoffPath -Encoding UTF8

# FR-004: augment event-log reason with actor-change note when applicable.
# When prior_actor exists and differs from the new Actor, prepend the change note;
# operator-supplied -Reason is preserved (appended after the note with `; ` separator).
$eventReasonAugmented = $eventReason
if ($priorActor -and $priorActor -ne $Actor) {
    $changeNote = "actor change $priorActor → $Actor"
    if ([string]::IsNullOrWhiteSpace($eventReasonAugmented)) {
        $eventReasonAugmented = $changeNote
    } else {
        $eventReasonAugmented = "$changeNote; $eventReasonAugmented"
    }
}

Write-BridgeEvent -RepoRoot $repoRoot -Action "handoff" -Status $resolvedStatus -FeatureDirectory $featureDirectoryProjectPath -Decision "updated" -Reason $eventReasonAugmented -SnapshotId $snapshotId -Actor $Actor -PriorActor $priorActor

Write-Output "Wrote .specify/superpowers-handoff.json with status '$resolvedStatus'."
if ($blockedReason) { Write-Output "Reason: $blockedReason" }

# v0.7.0+: emit drift warning + artifact_drift_detected event on complete writes (FR-006, FR-008).
if ($driftedDetails.Count -gt 0) {
    [Console]::Error.WriteLine("[bridge] WARNING: artifact drift since executing snapshot: $driftedFilenames (sha256 mismatch)")
    $driftEvent = [ordered]@{
        event = 'artifact_drift_detected'
        timestamp = (Get-Date).ToUniversalTime().ToString("o")
        actor = $Actor
        feature_directory = $featureDirectoryProjectPath
        drifted_artifacts = @($driftedDetails)
    }
    $eventPath = Join-Path $repoRoot ".specify\bridge-events.jsonl"
    ($driftEvent | ConvertTo-Json -Compress -Depth 4) + [Environment]::NewLine | Add-Content -LiteralPath $eventPath -Encoding UTF8
}

# FR-001..FR-003: emit [bridge state] block. EmitCompleteWarning fires the FR-003 WARNING
# to stderr when this call transitioned status to 'complete' and tasks.md has unchecked
# task-ID lines outside any deferred-exemption section.
Write-BridgeStateSummaryFull -HandoffPath $handoffPath -RepoRoot $repoRoot -Actor $Actor -PriorActor ($priorActor -as [string]) -EmitCompleteWarning
