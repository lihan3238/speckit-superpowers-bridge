param(
    [Parameter(Mandatory = $true)]
    [string]$Action,

    [switch]$AllowDiscardSpecArtifacts,

    [string]$Reason = "",

    [ValidateSet("codex", "claude", "unknown")]
    [string]$Actor = "unknown",

    [string]$TargetFeatureDirectory = ""
)

$ErrorActionPreference = "Stop"

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

function Write-BridgeEvent {
    param(
        [string]$RepoRoot,
        [string]$ActionName,
        [string]$Status,
        [string]$FeatureDirectory,
        [string]$Decision,
        [string]$ReasonText,
        [string]$Actor,
        [string]$SnapshotId,
        [string]$PolicyRef = ""
    )

    $event = [ordered]@{
        timestamp = (Get-Date).ToUniversalTime().ToString("o")
        action = "guard"
        status = $Status
        feature_directory = $FeatureDirectory
        decision = $Decision
        reason = $ReasonText
        actor = $Actor
        snapshot_id = $SnapshotId
        checked_action = $ActionName
    }
    if (-not [string]::IsNullOrWhiteSpace($PolicyRef)) {
        $event["policy_ref"] = $PolicyRef
    }

    $eventPath = Join-Path $RepoRoot ".specify\bridge-events.jsonl"
    ($event | ConvertTo-Json -Compress -Depth 6) + [Environment]::NewLine | Add-Content -LiteralPath $eventPath -Encoding UTF8
}

function Get-FeatureDirectory {
    param(
        [string]$RepoRoot,
        [object]$Handoff
    )

    if ($Handoff -and $Handoff.feature_directory) {
        return [string]$Handoff.feature_directory
    }

    $featureJson = Join-Path $RepoRoot ".specify\feature.json"
    if (Test-Path -LiteralPath $featureJson) {
        $featureState = Get-Content -LiteralPath $featureJson -Raw | ConvertFrom-Json
        if ($featureState.feature_directory) {
            return [string]$featureState.feature_directory
        }
    }

    return $null
}

function Test-FeatureArtifacts {
    param(
        [string]$RepoRoot,
        [string]$FeatureDirectory
    )

    if ([string]::IsNullOrWhiteSpace($FeatureDirectory)) {
        return $false
    }

    $featurePath = if ([System.IO.Path]::IsPathRooted($FeatureDirectory)) {
        $FeatureDirectory
    }
    else {
        Join-Path $RepoRoot $FeatureDirectory
    }

    foreach ($artifact in @("spec.md", "plan.md", "tasks.md")) {
        if (-not (Test-Path -LiteralPath (Join-Path $featurePath $artifact))) {
            return $false
        }
    }

    return $true
}

function Get-DispositionMatrix {
    param([string]$RepoRoot)

    $path = Join-Path $RepoRoot ".specify\extensions\speckit-superpowers-bridge\disposition-matrix.json"
    if (-not (Test-Path -LiteralPath $path)) {
        return $null
    }

    try {
        return Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
    }
    catch {
        return $null
    }
}

function Find-DispositionEntry {
    param(
        [object]$Matrix,
        [string]$NormalizedAction
    )

    if ($null -eq $Matrix -or $null -eq $Matrix.entries) {
        return $null
    }

    foreach ($entry in $Matrix.entries) {
        if (-not $entry.id) { continue }
        # Normalize the entry id the same way as the requested action so namespace separators
        # (colon for Superpowers, dot for Spec Kit) compare as equivalent.
        $entryId = ([string]$entry.id).Trim().ToLowerInvariant().Replace(":", ".")
        if ($entryId -eq $NormalizedAction) {
            return $entry
        }
    }

    return $null
}

$repoRoot = Get-RepoRoot
$handoffPath = Join-Path $repoRoot ".specify\superpowers-handoff.json"
$handoff = $null
if (Test-Path -LiteralPath $handoffPath) {
    $handoff = Get-Content -LiteralPath $handoffPath -Raw | ConvertFrom-Json
}

$normalizedAction = $Action.Trim().ToLowerInvariant().Replace(":", ".")
$status = if ($handoff -and $handoff.status) { [string]$handoff.status } else { "none" }
$executor = if ($handoff -and $handoff.executor) { [string]$handoff.executor } else { "" }
$featureDirectory = Get-FeatureDirectory -RepoRoot $repoRoot -Handoff $handoff
$hasSpecArtifacts = Test-FeatureArtifacts -RepoRoot $repoRoot -FeatureDirectory $featureDirectory
$artifactOwner = if ($handoff -and $handoff.PSObject.Properties.Name -contains "artifact_owner" -and $handoff.artifact_owner) { [string]$handoff.artifact_owner } else { "" }
$snapshotId = if ($handoff -and $handoff.PSObject.Properties.Name -contains "last_snapshot_id") { [string]$handoff.last_snapshot_id } else { $null }
$specKitMutatingActions = @("speckit.clarify", "speckit.plan", "speckit.tasks")

# Determine whether the requested action targets the SAME feature as the active handoff.
# When TargetFeatureDirectory is empty, fall back to the active feature_directory and assume same-feature.
# This permits cross-feature contract changes when the existing handoff is in a terminal-not-active state (complete).
$targetFeature = if (-not [string]::IsNullOrWhiteSpace($TargetFeatureDirectory)) { $TargetFeatureDirectory } else { $featureDirectory }
$isSameFeature = $true
if (-not [string]::IsNullOrWhiteSpace($TargetFeatureDirectory) -and -not [string]::IsNullOrWhiteSpace($featureDirectory)) {
    $normalizedTarget = $TargetFeatureDirectory.Trim().TrimEnd("/", "\").Replace("\", "/").ToLowerInvariant()
    $normalizedActive = $featureDirectory.Trim().TrimEnd("/", "\").Replace("\", "/").ToLowerInvariant()
    $isSameFeature = ($normalizedTarget -eq $normalizedActive)
}

$decision = "allow"
$denyReason = $null
$policyRef = ""

# Disposition matrix lookup (FR-003): the matrix is the source of non-overlap policy when an entry exists.
$matrix = Get-DispositionMatrix -RepoRoot $repoRoot
$entry = Find-DispositionEntry -Matrix $matrix -NormalizedAction $normalizedAction
if ($entry) {
    $policyRef = [string]$entry.id
    switch ([string]$entry.disposition) {
        "FORBID-UNDER-HANDOFF" {
            $scope = @()
            if ($entry.PSObject.Properties.Name -contains "applicability" -and $entry.applicability) {
                $scope = @($entry.applicability | ForEach-Object { [string]$_ })
            }
            if ($scope.Count -gt 0 -and $scope -contains $status -and ($isSameFeature -or $normalizedAction -eq "speckit.implement")) {
                $decision = "deny"
                $rationaleText = if ($entry.rationale) { [string]$entry.rationale } else { "FORBID-UNDER-HANDOFF disposition." }
                $denyReason = "$Action denied by disposition matrix (applicability: $(($scope -join ', '))). $rationaleText"
            }
        }
        "SUPERSEDED-BY" {
            $replacement = if ($entry.PSObject.Properties.Name -contains "superseded_by") { [string]$entry.superseded_by } else { "<unspecified>" }
            $decision = "deny"
            $denyReason = "$Action is superseded by '$replacement' per disposition matrix. $([string]$entry.rationale)"
        }
        "REVIEW-ONLY" {
            if ($Actor -ne "unknown" -and -not [string]::IsNullOrWhiteSpace($artifactOwner) -and $Actor -ne $artifactOwner) {
                $decision = "deny"
                $denyReason = "$Action is REVIEW-ONLY per disposition matrix; only artifact owner '$artifactOwner' may invoke."
            }
        }
        default { }  # COMBINE → allow (default decision)
    }
}

# Legacy / fallback rules (apply when no matrix entry, or to enforce same-feature artifact ownership
# even for COMBINE-listed mutating commands like speckit.clarify / speckit.plan / speckit.tasks).
if ($decision -ne "deny") {
    if ($normalizedAction -eq "speckit.implement" -and $executor -eq "superpowers" -and -not $entry) {
        $decision = "deny"
        $denyReason = "speckit.implement is superseded by Superpowers for bridged features."
        $policyRef = "speckit.implement"
    }
    elseif ($normalizedAction -in $specKitMutatingActions -and $status -eq "executing" -and $isSameFeature) {
        $decision = "deny"
        $denyReason = "Spec Kit contract changes are blocked while handoff status is 'executing'. Set status to blocked before repair."
    }
    elseif ($normalizedAction -in $specKitMutatingActions -and $status -eq "complete" -and $isSameFeature) {
        $decision = "deny"
        $denyReason = "Spec Kit contract changes are blocked while handoff status is 'complete' for the active feature. Run auto-archive-handoff.ps1 to start a new feature, or set status to blocked for in-place repair."
    }
    elseif ($normalizedAction -in $specKitMutatingActions -and -not [string]::IsNullOrWhiteSpace($artifactOwner) -and $artifactOwner -ne "unknown" -and $Actor -ne "unknown" -and $Actor -ne $artifactOwner -and $isSameFeature) {
        $decision = "deny"
        $denyReason = "Spec Kit artifact writes are owned by '$artifactOwner'. Actor '$Actor' is review-only for this feature."
    }
    elseif ($normalizedAction -in @("superpowers.brainstorming", "superpowers.writing-plans") -and $hasSpecArtifacts -and -not $AllowDiscardSpecArtifacts -and -not $entry) {
        $decision = "deny"
        $denyReason = "$Action is disabled for active Spec Kit features with spec.md, plan.md, and tasks.md. Revise through Spec Kit or pass -AllowDiscardSpecArtifacts only after explicit user approval."
        $policyRef = $normalizedAction
    }
    elseif ($normalizedAction -in @("superpowers.subagent-driven-development", "superpowers.executing-plans") -and (-not $hasSpecArtifacts -or $executor -ne "superpowers")) {
        $decision = "deny"
        $denyReason = "$Action must run through speckit-superpowers-bridge with active Spec Kit artifacts."
    }
}

if ($decision -eq "deny" -and -not [string]::IsNullOrWhiteSpace($Reason)) {
    $denyReason = "$denyReason Reason: $Reason"
}

Write-BridgeEvent -RepoRoot $repoRoot -ActionName $normalizedAction -Status $status -FeatureDirectory $featureDirectory -Decision $decision -ReasonText $denyReason -Actor $Actor -SnapshotId $snapshotId -PolicyRef $policyRef

if ($decision -eq "deny") {
    throw $denyReason
}

Write-Output "Guard allowed $Action."
