param(
    [ValidateSet("ready", "executing", "blocked", "complete")]
    [string]$Status = "ready",

    [string]$FeatureDirectory = "",

    [string]$Reason = "",

    [ValidateSet("codex", "claude", "unknown")]
    [string]$ArtifactOwner = "",

    [ValidateSet("codex", "claude", "unknown")]
    [string[]]$ReviewOnlyAgents = @(),

    [string]$Actor = "",

    [object]$AutonomousMode = $null,

    [object]$ResumeContext = $null,

    [switch]$ClearFeatureDirectory,

    [psobject]$AppendArchiveEntry = $null
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "common-actor-resolution.ps1")

function Write-BridgeEvent {
    param(
        [string]$RepoRoot,
        [string]$Action,
        [string]$Status,
        [string]$FeatureDirectory,
        [string]$Decision,
        [string]$Reason,
        [string]$SnapshotId,
        [string]$ArtifactOwner = "",
        [string[]]$ReviewOnlyAgents = @(),
        [string]$Actor = "speckit-superpowers-bridge"
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
        artifact_owner = if ([string]::IsNullOrWhiteSpace($ArtifactOwner)) { $null } else { $ArtifactOwner }
        review_only_agents = @($ReviewOnlyAgents)
    }

    $eventPath = Join-Path $RepoRoot ".specify\bridge-events.jsonl"
    ($event | ConvertTo-Json -Compress -Depth 6) + [Environment]::NewLine | Add-Content -LiteralPath $eventPath -Encoding UTF8
}

function New-BridgeSnapshot {
    param(
        [string]$RepoRoot,
        [string]$Status,
        [string]$FeatureDirectoryFullPath,
        [string]$FeatureDirectoryProjectPath
    )

    if ([string]::IsNullOrWhiteSpace($FeatureDirectoryFullPath) -or -not (Test-Path -LiteralPath $FeatureDirectoryFullPath)) {
        return $null
    }

    $timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssfffffffZ")
    $snapshotId = "$timestamp-$Status"
    $snapshotRoot = Join-Path $RepoRoot ".specify\bridge-snapshots\$snapshotId"
    New-Item -ItemType Directory -Force -Path $snapshotRoot | Out-Null

    $metadata = [ordered]@{
        snapshot_id = $snapshotId
        created_at = (Get-Date).ToUniversalTime().ToString("o")
        status = $Status
        feature_directory = $FeatureDirectoryProjectPath
    }
    $metadata | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $snapshotRoot "metadata.json") -Encoding UTF8

    foreach ($artifact in @("spec.md", "plan.md", "tasks.md")) {
        $artifactPath = Join-Path $FeatureDirectoryFullPath $artifact
        if (Test-Path -LiteralPath $artifactPath) {
            Copy-Item -LiteralPath $artifactPath -Destination (Join-Path $snapshotRoot $artifact) -Force
        }
    }

    $handoffPath = Join-Path $RepoRoot ".specify\superpowers-handoff.json"
    if (Test-Path -LiteralPath $handoffPath) {
        Copy-Item -LiteralPath $handoffPath -Destination (Join-Path $snapshotRoot "superpowers-handoff.json") -Force
    }

    return $snapshotId
}

function Get-RepoRoot {
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $previousErrorAction = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        try {
            $root = (& git rev-parse --show-toplevel 2>$null)
            if ($LASTEXITCODE -eq 0 -and $root) {
                return $root.Trim()
            }
        }
        finally {
            $ErrorActionPreference = $previousErrorAction
        }
    }

    return (Get-Location).Path
}

function Convert-ToProjectPath {
    param(
        [string]$RepoRoot,
        [string]$Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $null
    }

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $rootPath = [System.IO.Path]::GetFullPath($RepoRoot).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)

    if ($fullPath.StartsWith($rootPath, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $fullPath.Substring($rootPath.Length).TrimStart([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar).Replace("\", "/")
    }

    return $fullPath.Replace("\", "/")
}

function Get-InstalledIntegrations {
    param([string]$RepoRoot)

    $integrationPath = Join-Path $RepoRoot ".specify\integration.json"
    if (-not (Test-Path -LiteralPath $integrationPath)) {
        return [pscustomobject]@{
            installed = @()
            default = $null
        }
    }

    $state = Get-Content -LiteralPath $integrationPath -Raw | ConvertFrom-Json
    return [pscustomobject]@{
        installed = @($state.installed_integrations)
        default = if ($state.default_integration) { [string]$state.default_integration } elseif ($state.integration) { [string]$state.integration } else { $null }
    }
}

function Resolve-ArtifactOwnership {
    param(
        [string]$RepoRoot,
        [string]$RequestedOwner,
        [string[]]$RequestedReviewOnlyAgents,
        [string]$ResolvedActor
    )

    $integrationState = Get-InstalledIntegrations -RepoRoot $RepoRoot
    $installed = @($integrationState.installed | Where-Object { $_ -in @("codex", "claude", "unknown") })

    $owner = $RequestedOwner
    if ([string]::IsNullOrWhiteSpace($owner)) {
        if ($ResolvedActor -in @("codex", "claude")) {
            $owner = $ResolvedActor
        }
        elseif ($integrationState.default -in @("codex", "claude")) {
            $owner = $integrationState.default
        }
        else {
            $owner = "unknown"
        }
    }

    $reviewOnly = @($RequestedReviewOnlyAgents | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and $_ -ne $owner })
    if ($reviewOnly.Count -eq 0) {
        if ($installed.Count -gt 0) {
            $reviewOnly = @($installed | Where-Object { $_ -ne $owner })
        }
        elseif ($owner -eq "codex") {
            $reviewOnly = @("claude")
        }
        elseif ($owner -eq "claude") {
            $reviewOnly = @("codex")
        }
    }

    return [pscustomobject]@{
        owner = $owner
        review_only = @($reviewOnly | Select-Object -Unique)
    }
}

$repoRoot = Get-RepoRoot
$Actor = Resolve-BridgeActor -Argument $Actor -RepoRoot $repoRoot
$ownership = Resolve-ArtifactOwnership -RepoRoot $repoRoot -RequestedOwner $ArtifactOwner -RequestedReviewOnlyAgents $ReviewOnlyAgents -ResolvedActor $Actor
$specifyDir = Join-Path $repoRoot ".specify"
if (-not (Test-Path -LiteralPath $specifyDir)) {
    throw "Missing .specify directory. Run this from a Spec Kit project."
}

# Preserve archive_history across writes by reading the existing handoff first (schema_version >= 2).
$existingHandoffPath = Join-Path $specifyDir "superpowers-handoff.json"
$existingArchiveHistory = @()
$existingAutonomousMode = $false
$existingResumeContext = $null
$priorFeatureDirectory = $null
if (Test-Path -LiteralPath $existingHandoffPath) {
    $existingHandoff = Get-Content -LiteralPath $existingHandoffPath -Raw | ConvertFrom-Json
    if ($existingHandoff.PSObject.Properties.Name -contains "archive_history" -and $existingHandoff.archive_history) {
        $existingArchiveHistory = @($existingHandoff.archive_history)
    }
    if ($existingHandoff.PSObject.Properties.Name -contains "feature_directory" -and $existingHandoff.feature_directory) {
        $priorFeatureDirectory = [string]$existingHandoff.feature_directory
    }
    if ($existingHandoff.PSObject.Properties.Name -contains "autonomous_mode") {
        $existingAutonomousMode = [bool]$existingHandoff.autonomous_mode
    }
    if ($existingHandoff.PSObject.Properties.Name -contains "resume_context") {
        $existingResumeContext = $existingHandoff.resume_context
    }
}

$featureJsonPath = Join-Path $specifyDir "feature.json"
if ($ClearFeatureDirectory) {
    # Auto-archive path: snapshot the prior feature_directory before clearing, then write the new state with feature_directory empty.
    $FeatureDirectory = ""
}
elseif ([string]::IsNullOrWhiteSpace($FeatureDirectory) -and (Test-Path -LiteralPath $featureJsonPath)) {
    $featureState = Get-Content -LiteralPath $featureJsonPath -Raw | ConvertFrom-Json
    if ($featureState.feature_directory) {
        $FeatureDirectory = [string]$featureState.feature_directory
    }
}

$featureDirectoryProjectPath = $null
$featureDirectoryFullPath = $null
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
    constitution = Convert-ToProjectPath -RepoRoot $repoRoot -Path $constitutionPath
    spec = $null
    plan = $null
    tasks = $null
}

$missing = New-Object System.Collections.Generic.List[string]
if ($featureDirectoryFullPath) {
    $requiredArtifacts = [ordered]@{
        spec = "spec.md"
        plan = "plan.md"
        tasks = "tasks.md"
    }

    foreach ($artifact in $requiredArtifacts.GetEnumerator()) {
        $artifactPath = Join-Path $featureDirectoryFullPath $artifact.Value
        $sourceOfTruth[$artifact.Key] = Convert-ToProjectPath -RepoRoot $repoRoot -Path $artifactPath
        if (-not (Test-Path -LiteralPath $artifactPath)) {
            $missing.Add($sourceOfTruth[$artifact.Key])
        }
    }
}

$resolvedStatus = $Status
$blockedReason = $Reason
$notes = $null

if ($missing.Count -gt 0 -and $Status -ne "complete") {
    $resolvedStatus = "blocked"
    if ([string]::IsNullOrWhiteSpace($blockedReason)) {
        $blockedReason = "Missing required Spec Kit artifacts: " + (($missing.ToArray()) -join ", ")
    }
}

if (-not $featureDirectoryFullPath) {
    $notes = "No active feature recorded in .specify/feature.json yet."
}

if ([string]::IsNullOrWhiteSpace($blockedReason)) {
    $blockedReason = $null
}

$snapshotFeatureDirectoryFullPath = $featureDirectoryFullPath
$snapshotFeatureDirectoryProjectPath = $featureDirectoryProjectPath
if ($ClearFeatureDirectory -and -not [string]::IsNullOrWhiteSpace($priorFeatureDirectory)) {
    # On auto-archive, snapshot the prior feature_directory (since the new state will be empty).
    if ([System.IO.Path]::IsPathRooted($priorFeatureDirectory)) {
        $snapshotFeatureDirectoryFullPath = [System.IO.Path]::GetFullPath($priorFeatureDirectory)
    }
    else {
        $snapshotFeatureDirectoryFullPath = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $priorFeatureDirectory))
    }
    $snapshotFeatureDirectoryProjectPath = Convert-ToProjectPath -RepoRoot $repoRoot -Path $snapshotFeatureDirectoryFullPath
}

$snapshotId = New-BridgeSnapshot -RepoRoot $repoRoot -Status $resolvedStatus -FeatureDirectoryFullPath $snapshotFeatureDirectoryFullPath -FeatureDirectoryProjectPath $snapshotFeatureDirectoryProjectPath
if ($snapshotId) {
    Write-BridgeEvent -RepoRoot $repoRoot -Action "snapshot" -Status $resolvedStatus -FeatureDirectory $snapshotFeatureDirectoryProjectPath -Decision "created" -Reason "Snapshot before handoff state update" -SnapshotId $snapshotId -ArtifactOwner $ownership.owner -ReviewOnlyAgents $ownership.review_only -Actor $Actor
}

# Compose archive_history: preserve prior entries; optionally append a new one.
$archiveHistory = @($existingArchiveHistory)
if ($AppendArchiveEntry) {
    $archiveHistory = @($archiveHistory) + @($AppendArchiveEntry)
}

function Convert-ResumeContext {
    param([object]$Value)

    if ($null -eq $Value) {
        return $null
    }

    if ($Value -is [string]) {
        if ([string]::IsNullOrWhiteSpace($Value)) {
            return $null
        }
        return ($Value | ConvertFrom-Json)
    }

    return $Value
}

$resolvedAutonomousMode = $existingAutonomousMode
if ($null -ne $AutonomousMode) {
    $resolvedAutonomousMode = [System.Convert]::ToBoolean($AutonomousMode)
}

$resolvedResumeContext = $existingResumeContext
if ($null -ne $ResumeContext) {
    $resolvedResumeContext = Convert-ResumeContext -Value $ResumeContext
}
elseif ($resolvedStatus -in @("ready", "complete") -or $ClearFeatureDirectory) {
    $resolvedResumeContext = $null
}

$handoff = [ordered]@{
    schema_version = 3
    updated_at = (Get-Date).ToUniversalTime().ToString("o")
    feature_directory = $featureDirectoryProjectPath
    source_of_truth = $sourceOfTruth
    supersedes = @("speckit.implement")
    executor = "superpowers"
    capabilities = @(
        "using-git-worktrees",
        "test-driven-development",
        "systematic-debugging",
        "subagent-driven-development",
        "executing-plans",
        "requesting-code-review",
        "verification-before-completion",
        "finishing-a-development-branch"
    )
    autonomous_mode = $resolvedAutonomousMode
    resume_context = $resolvedResumeContext
    status = $resolvedStatus
    blocked_reason = $blockedReason
    artifact_owner = $ownership.owner
    review_only_agents = @($ownership.review_only)
    notes = $notes
    last_snapshot_id = $snapshotId
    archive_history = @($archiveHistory)
    instructions = 'Use the official bridge execute command: Codex $speckit-speckit-superpowers-bridge-execute or Claude Code /speckit-speckit-superpowers-bridge-execute. In this source repo, .agents/skills/speckit-superpowers-bridge/SKILL.md and .claude/skills/speckit-superpowers-bridge/SKILL.md mirror the same protocol. Do not run speckit.implement or regenerate Spec Kit plan/tasks with Superpowers writing-plans.'
}

$handoffPath = Join-Path $specifyDir "superpowers-handoff.json"
$handoff | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $handoffPath -Encoding UTF8

Write-BridgeEvent -RepoRoot $repoRoot -Action "handoff" -Status $resolvedStatus -FeatureDirectory $featureDirectoryProjectPath -Decision "updated" -Reason $blockedReason -SnapshotId $snapshotId -ArtifactOwner $ownership.owner -ReviewOnlyAgents $ownership.review_only -Actor $Actor

Write-Output "Wrote $(Convert-ToProjectPath -RepoRoot $repoRoot -Path $handoffPath) with status '$resolvedStatus'."
if ($blockedReason) {
    Write-Output "Reason: $blockedReason"
}
if ($notes) {
    Write-Output "Note: $notes"
}
