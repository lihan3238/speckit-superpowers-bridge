# bridge-status.ps1 — read-only bridge state introspection (v0.7.0+).
# Spec:     specs/012-bridge-status-and-hash/spec.md (FR-001..FR-007)
# Contract: specs/012-bridge-status-and-hash/contracts/{bridge-status-output,next-command-decision-table}.md
# Parity with bridge-status.sh. Read-only.

[CmdletBinding()]
param(
    [switch]$Json,
    [string]$Actor = "",
    [switch]$NoDriftCheck
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptDir 'common-actor-resolution.ps1')
. (Join-Path $ScriptDir 'bridge-state.ps1')

# Locate repo root + .specify dir
$RepoRoot = Get-BridgeRepoRoot
$SpecifyDir = Join-Path $RepoRoot '.specify'
if (-not (Test-Path -LiteralPath $SpecifyDir -PathType Container)) {
    [Console]::Error.WriteLine('[bridge] not inside a Spec Kit repository')
    exit 2
}
$HandoffPath = Join-Path $SpecifyDir 'superpowers-handoff.json'
$ResolvedActor = Resolve-BridgeActor $Actor

# ---------------------------------------------------------------------------
# Classify handoff state: no-handoff | corrupted | parseable
# ---------------------------------------------------------------------------

$State = 'parseable'
$Handoff = $null
if (-not (Test-Path -LiteralPath $HandoffPath -PathType Leaf)) {
    $State = 'no-handoff'
} else {
    try {
        $Handoff = Get-Content -LiteralPath $HandoffPath -Raw | ConvertFrom-Json
    } catch {
        $State = 'corrupted'
        $ParseError = $_.Exception.Message
    }
}

# ---------------------------------------------------------------------------
# Field extraction based on state
# ---------------------------------------------------------------------------

$FeatureDir = ''
$Status = ''
$Owner = ''

switch ($State) {
    'no-handoff' {
        $FeatureDir = '(none)'
        $Status = '(no handoff)'
        $Owner = 'unknown'
    }
    'corrupted' {
        $FeatureDir = '(unknown)'
        $Status = '(corrupted handoff)'
        $Owner = '(unknown)'
    }
    'parseable' {
        $FeatureDir = if ($Handoff.feature_directory) { [string]$Handoff.feature_directory } else { '' }
        $Status = if ($Handoff.status) { [string]$Handoff.status } else { '' }
        $Owner = if ($Handoff.artifact_owner) { [string]$Handoff.artifact_owner } else { '' }
        if ([string]::IsNullOrWhiteSpace($FeatureDir)) { $FeatureDir = '(none)' }
        if ([string]::IsNullOrWhiteSpace($Status))     { $Status = '(unknown)' }
        if ([string]::IsNullOrWhiteSpace($Owner))      { $Owner = 'unknown' }
    }
}

# ---------------------------------------------------------------------------
# Pending tasks
# ---------------------------------------------------------------------------

$PendingLabel = ''
$PendingInt = $null
$FeatureFull = ''
if ($State -eq 'corrupted') {
    $PendingLabel = '(unknown)'
} elseif ($FeatureDir -eq '(none)' -or [string]::IsNullOrWhiteSpace($FeatureDir)) {
    $PendingLabel = '(no feature_directory)'
} else {
    $FeatureFull = if ([System.IO.Path]::IsPathRooted($FeatureDir)) { $FeatureDir } else { Join-Path $RepoRoot $FeatureDir }
    if (-not (Test-Path -LiteralPath $FeatureFull -PathType Container)) {
        $PendingLabel = '(no feature_directory)'
    } else {
        $pendingResult = Get-PendingTaskCount -TasksPath (Join-Path $FeatureFull 'tasks.md')
        if (-not $pendingResult.TasksMdExists) {
            $PendingLabel = '(no tasks.md)'
        } else {
            $PendingLabel = [string]$pendingResult.Count
            $PendingInt = [int]$pendingResult.Count
        }
    }
}

# ---------------------------------------------------------------------------
# Drift detection
# ---------------------------------------------------------------------------

$DriftPresent = $false
$DriftList = ''
if ($State -eq 'parseable' -and -not $NoDriftCheck -and $FeatureDir -ne '(none)') {
    if ($Handoff.PSObject.Properties.Name -contains 'artifacts_sha256' -and $Handoff.artifacts_sha256) {
        $DriftPresent = $true
        if (-not [string]::IsNullOrWhiteSpace($FeatureFull) -and (Test-Path -LiteralPath $FeatureFull -PathType Container)) {
            $DriftList = Get-DriftList -HandoffPath $HandoffPath -FeatureFull $FeatureFull
        }
    }
}

# ---------------------------------------------------------------------------
# Next recommendation
# ---------------------------------------------------------------------------

$NextRec = Get-NextCommandRecommendation -RepoRoot $RepoRoot -HandoffPath $HandoffPath

# ---------------------------------------------------------------------------
# Emit
# ---------------------------------------------------------------------------

if ($Json) {
    $jsonFeatureDir = if ($FeatureDir -eq '(none)' -or [string]::IsNullOrWhiteSpace($FeatureDir)) { $null } else { $FeatureDir }
    $jsonStatus = switch ($State) {
        'no-handoff' { 'no_handoff' }
        'corrupted'  { 'corrupted_handoff' }
        'parseable'  { if ($Handoff.status) { [string]$Handoff.status } else { $null } }
    }
    $jsonOwner = switch ($State) {
        'no-handoff' { 'unknown' }
        'corrupted'  { $null }
        'parseable'  { if ($Handoff.artifact_owner) { [string]$Handoff.artifact_owner } else { $null } }
    }
    $jsonPending = if ($null -ne $PendingInt) { $PendingInt } else { $null }
    $jsonDrift = $null
    if ($DriftPresent) {
        if ([string]::IsNullOrWhiteSpace($DriftList)) {
            $jsonDrift = [ordered]@{ detected = $false; artifacts = @() }
        } else {
            $artifacts = $DriftList -split ',\s*' | Where-Object { $_ -ne '' }
            $jsonDrift = [ordered]@{ detected = $true; artifacts = @($artifacts) }
        }
    }
    $jsonNext = if ([string]::IsNullOrWhiteSpace($NextRec)) { '(none)' } else { $NextRec }
    $rc = if ($State -eq 'corrupted') { 3 } else { 0 }

    $payload = [ordered]@{
        feature_directory = $jsonFeatureDir
        status            = $jsonStatus
        artifact_owner    = $jsonOwner
        actor             = $ResolvedActor
        pending_tasks     = $jsonPending
        drift             = $jsonDrift
        next              = $jsonNext
        exit_code         = $rc
    }
    # Emit as single-line JSON
    Write-Output ($payload | ConvertTo-Json -Compress -Depth 6)

    if ($State -eq 'corrupted') {
        [Console]::Error.WriteLine($ParseError)
        exit 3
    }
    exit 0
}

# Human-mode output
Write-Output '[bridge state]'
Write-Output "  Feature directory: $FeatureDir"
Write-Output "  Status: $Status"
Write-Output "  Artifact owner: $Owner"
Write-Output "  Actor: $ResolvedActor"
Write-Output "  Pending tasks: $PendingLabel"
if ($DriftPresent) {
    if ([string]::IsNullOrWhiteSpace($DriftList)) {
        Write-Output '  Drift: (none)'
    } else {
        Write-Output "  Drift: $DriftList"
    }
}
Write-Output "  Next: $NextRec"

if ($State -eq 'corrupted') {
    [Console]::Error.WriteLine($ParseError)
    exit 3
}
exit 0
