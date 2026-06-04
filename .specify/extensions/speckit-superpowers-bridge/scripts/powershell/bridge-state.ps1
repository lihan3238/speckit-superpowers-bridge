# bridge-state.ps1 — shared helper for state-summary + pending-task counting.
# Sourced by update-handoff.ps1 and guard-command.ps1.
# Contract: specs/008-bridge-hardening-0-5-0/contracts/bridge-state-summary.md
# Decision basis: specs/008-bridge-hardening-0-5-0/research.md (R1-R3) + spec FR-001..FR-005.

$ErrorActionPreference = "Stop"

# Canonical task-ID regex per FR-001 + Clarifications Q4 (Option A).
$script:BridgeTaskIdRegex = '^- \[ \] T\d+'
# Deferred-exemption header regex per FR-005 + Clarifications Q6 (Option A).
$script:BridgeDeferredHeaderRegex = '^#+\s+.*\b(deferred|optional|out of scope|won.?t do|future|wontfix|backlog)\b'

function Get-PendingTaskCount {
    <#
    .SYNOPSIS
    Count `- [ ] T###` lines in tasks.md that are NOT inside a deferred-exemption section.

    .PARAMETER TasksPath
    Absolute or repo-relative path to tasks.md.

    .OUTPUTS
    Hashtable @{ Count = <int>; TasksMdExists = <bool> }
    #>
    param([Parameter(Mandatory = $true)][string]$TasksPath)

    if (-not (Test-Path -LiteralPath $TasksPath)) {
        return @{ Count = -1; TasksMdExists = $false }
    }

    $lines = Get-Content -LiteralPath $TasksPath -ErrorAction SilentlyContinue
    if (-not $lines) {
        return @{ Count = 0; TasksMdExists = $true }
    }

    $inExempt = $false
    $count = 0
    foreach ($line in $lines) {
        # Header detection: any markdown header line — sets / resets exemption state.
        if ($line -match '^#+\s+') {
            $inExempt = ($line -imatch $script:BridgeDeferredHeaderRegex)
            continue
        }
        if (-not $inExempt -and $line -match $script:BridgeTaskIdRegex) {
            $count++
        }
    }
    return @{ Count = $count; TasksMdExists = $true }
}

function Get-BridgeStateLines {
    <#
    .SYNOPSIS
    Build the [bridge state] block lines as a string array. Pure function — no I/O.

    .PARAMETER FeatureDirectory
    Repo-relative path or empty/null.

    .PARAMETER Status
    Handoff status (ready/executing/complete/blocked).

    .PARAMETER ArtifactOwner
    Resolved artifact owner string.

    .PARAMETER Actor
    Actor for THIS invocation.

    .PARAMETER PriorActor
    Actor present in handoff BEFORE the current call. Omit / null / equal-to-Actor => simple line.

    .PARAMETER PendingResult
    Output of Get-PendingTaskCount (hashtable) or $null if not applicable.
    #>
    param(
        [string]$FeatureDirectory,
        [string]$Status,
        [string]$ArtifactOwner,
        [string]$Actor,
        [string]$PriorActor,
        [hashtable]$PendingResult
    )

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('[bridge state]')

    $dirLabel = if ([string]::IsNullOrWhiteSpace($FeatureDirectory)) { '(none)' } else { $FeatureDirectory }
    $lines.Add("  Feature directory: $dirLabel")

    $statusLabel = if ([string]::IsNullOrWhiteSpace($Status)) { '(unknown)' } else { $Status }
    $lines.Add("  Status: $statusLabel")

    $ownerLabel = if ([string]::IsNullOrWhiteSpace($ArtifactOwner)) { 'unknown' } else { $ArtifactOwner }
    $lines.Add("  Artifact owner: $ownerLabel")

    $actorLabel = if ([string]::IsNullOrWhiteSpace($Actor)) { 'unknown' } else { $Actor }
    if (-not [string]::IsNullOrWhiteSpace($PriorActor) -and $PriorActor -ne $actorLabel) {
        $lines.Add("  Actor: $PriorActor → $actorLabel")
    } else {
        $lines.Add("  Actor: $actorLabel")
    }

    if ([string]::IsNullOrWhiteSpace($FeatureDirectory)) {
        $lines.Add("  Pending tasks: (no feature_directory)")
    } elseif ($null -eq $PendingResult -or -not $PendingResult.TasksMdExists) {
        $lines.Add("  Pending tasks: (no tasks.md)")
    } else {
        $lines.Add("  Pending tasks: $($PendingResult.Count)")
    }

    return $lines
}

function Write-BridgeStateSummary {
    <#
    .SYNOPSIS
    Write the [bridge state] block to stdout. If the transition is `complete` with
    Pending > 0 and `EmitCompleteWarning` is set, also write the FR-003 WARNING to stderr.

    .PARAMETER HandoffPath
    Absolute path to .specify/superpowers-handoff.json (for reading committed state).

    .PARAMETER RepoRoot
    Absolute path to repo root (for resolving feature_directory).

    .PARAMETER PriorActor
    Actor present in handoff before the current call. Pass $null or empty if not applicable
    (e.g., from guard-command which never mutates).

    .PARAMETER EmitCompleteWarning
    Switch — when set AND the just-committed Status is `complete` AND PendingResult.Count > 0,
    emit `[bridge] WARNING: ...` to stderr. Pass this from update-handoff on completion
    transitions; do NOT pass from guard-command.

    .PARAMETER OutputPrefix
    Optional prefix prepended to the `[bridge state]` header line. Used by guard-command
    (currently the contract uses `[bridge state]` unchanged for both callers; the parameter
    exists to support future divergence without further API churn).
    #>
    param(
        [Parameter(Mandatory = $true)][string]$HandoffPath,
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        [string]$PriorActor = "",
        [switch]$EmitCompleteWarning
    )

    if (-not (Test-Path -LiteralPath $HandoffPath)) {
        # No handoff at all — nothing to summarize. Caller decides whether to print anything.
        return
    }
    $h = Get-Content -LiteralPath $HandoffPath -Raw | ConvertFrom-Json
    $featureDir = if ($h.feature_directory) { [string]$h.feature_directory } else { "" }
    $status = if ($h.status) { [string]$h.status } else { "" }
    $owner = if ($h.artifact_owner) { [string]$h.artifact_owner } else { "" }
    $actor = if ($h.artifact_owner) { [string]$h.artifact_owner } else { "" }  # placeholder; real actor passed by caller (see WriteWithActor below)

    # For now we approximate Actor with artifact_owner because the handoff JSON does not
    # store the most-recent actor distinctly. The Write-BridgeStateSummaryFull form below
    # accepts an explicit Actor argument.
    $tasksPath = $null
    $pending = $null
    if (-not [string]::IsNullOrWhiteSpace($featureDir)) {
        $tasksPath = Join-Path $RepoRoot (Join-Path $featureDir "tasks.md")
        $pending = Get-PendingTaskCount -TasksPath $tasksPath
    }

    $lines = Get-BridgeStateLines -FeatureDirectory $featureDir -Status $status -ArtifactOwner $owner -Actor $actor -PriorActor $PriorActor -PendingResult $pending
    foreach ($l in $lines) { Write-Output $l }

    if ($EmitCompleteWarning -and $status -eq 'complete' -and $pending -and $pending.TasksMdExists -and $pending.Count -gt 0) {
        $msg = "[bridge] WARNING: handoff is 'complete' but tasks.md has $($pending.Count) unchecked tasks; review or move under a deferred section."
        [Console]::Error.WriteLine($msg)
    }
}

# ---------------------------------------------------------------------------
# v0.7.0+ additions: artifact-hash + next-command helpers for bridge-status.ps1.
# Spec: specs/012-bridge-status-and-hash/spec.md
# Contracts:
#   specs/012-bridge-status-and-hash/contracts/bridge-status-output.md
#   specs/012-bridge-status-and-hash/contracts/handoff-v1.1.delta.md
#   specs/012-bridge-status-and-hash/contracts/next-command-decision-table.md
# These helpers are stateless and side-effect-free; the existing
# Write-BridgeStateSummary / Write-BridgeStateSummaryFull above stay
# byte-identical (SC-008).
# ---------------------------------------------------------------------------

# Canonical artifact set per spec Clarifications Q1.
$script:BridgeArtifacts = @('spec.md', 'plan.md', 'tasks.md')

function Get-ArtifactSha256 {
    <#
    .SYNOPSIS
    Compute SHA256 of a file, lowercase hex, or $null when file is missing.
    #>
    param([Parameter(Mandatory = $true)][string]$Path)
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        return ((Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash).ToLower()
    }
    return $null
}

function Get-ArtifactsSha256Map {
    <#
    .SYNOPSIS
    Build an ordered map of {spec.md, plan.md, tasks.md} -> hash-or-null
    suitable for ConvertTo-Json embedding into the handoff document.
    #>
    param([Parameter(Mandatory = $true)][string]$FeatureFull)
    $map = [ordered]@{}
    foreach ($f in $script:BridgeArtifacts) {
        $map[$f] = Get-ArtifactSha256 -Path (Join-Path $FeatureFull $f)
    }
    return $map
}

function Get-DriftList {
    <#
    .SYNOPSIS
    Comma-joined list of drifted filenames in canonical order, or empty string when
    no drift OR handoff lacks artifacts_sha256 (backward-compat).
    #>
    param(
        [Parameter(Mandatory = $true)][string]$HandoffPath,
        [Parameter(Mandatory = $true)][string]$FeatureFull
    )
    if (-not (Test-Path -LiteralPath $HandoffPath)) { return '' }
    if ([string]::IsNullOrWhiteSpace($FeatureFull)) { return '' }
    $h = Get-Content -LiteralPath $HandoffPath -Raw | ConvertFrom-Json
    if (-not ($h.PSObject.Properties.Name -contains 'artifacts_sha256')) { return '' }
    if (-not $h.artifacts_sha256) { return '' }
    $drifted = New-Object System.Collections.Generic.List[string]
    foreach ($f in $script:BridgeArtifacts) {
        $stored = $h.artifacts_sha256.$f
        $live = Get-ArtifactSha256 -Path (Join-Path $FeatureFull $f)
        if ($stored -ne $live) { $drifted.Add($f) }
    }
    return ($drifted -join ', ')
}

function Get-DriftDetails {
    <#
    .SYNOPSIS
    Return an array of PSCustomObjects {path, old_sha256, new_sha256} for drifted artifacts.
    Used by update-handoff to emit the artifact_drift_detected event.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$HandoffPath,
        [Parameter(Mandatory = $true)][string]$FeatureFull
    )
    if (-not (Test-Path -LiteralPath $HandoffPath)) { return @() }
    $h = Get-Content -LiteralPath $HandoffPath -Raw | ConvertFrom-Json
    if (-not ($h.PSObject.Properties.Name -contains 'artifacts_sha256')) { return @() }
    if (-not $h.artifacts_sha256) { return @() }
    $details = New-Object System.Collections.Generic.List[object]
    foreach ($f in $script:BridgeArtifacts) {
        $stored = $h.artifacts_sha256.$f
        $live = Get-ArtifactSha256 -Path (Join-Path $FeatureFull $f)
        if ($stored -eq $live) { continue }
        $details.Add([pscustomobject]@{ path = $f; old_sha256 = $stored; new_sha256 = $live })
    }
    return $details.ToArray()
}

function Get-NextCommandRecommendation {
    <#
    .SYNOPSIS
    Return the recommendation string per next-command-decision-table.md.
    Rule precedence matches the bash flavor exactly.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        [Parameter(Mandatory = $true)][string]$HandoffPath
    )
    $hasHandoff = $false; $status = ''; $featureDir = ''
    $hasConstitution = Test-Path -LiteralPath (Join-Path $RepoRoot '.specify/memory/constitution.md') -PathType Leaf

    if (Test-Path -LiteralPath $HandoffPath -PathType Leaf) {
        try {
            $h = Get-Content -LiteralPath $HandoffPath -Raw | ConvertFrom-Json
            $hasHandoff = $true
            $status = if ($h.status) { [string]$h.status } else { '' }
            $featureDir = if ($h.feature_directory) { [string]$h.feature_directory } else { '' }
        } catch {
            return 'inspect .specify/superpowers-handoff.json'
        }
    }

    $hasFeatureDir = $false; $hasSpec = $false; $hasPlan = $false; $hasTasks = $false
    $featureFull = ''
    if ($featureDir) {
        $featureFull = if ([System.IO.Path]::IsPathRooted($featureDir)) { $featureDir } else { Join-Path $RepoRoot $featureDir }
        if (Test-Path -LiteralPath $featureFull -PathType Container) {
            $hasFeatureDir = $true
            $hasSpec = Test-Path -LiteralPath (Join-Path $featureFull 'spec.md') -PathType Leaf
            $hasPlan = Test-Path -LiteralPath (Join-Path $featureFull 'plan.md') -PathType Leaf
            $hasTasks = Test-Path -LiteralPath (Join-Path $featureFull 'tasks.md') -PathType Leaf
        }
    }

    if (-not $hasConstitution) { return '/speckit-constitution' }
    if (-not $hasHandoff)      { return '/speckit-specify' }
    if (-not $hasFeatureDir) {
        if ($status -eq 'ready' -or -not $status) { return '/speckit-specify' }
        return 'clear handoff or restore feature directory'
    }
    if (-not $hasSpec)  { return '/speckit-specify' }
    if (-not $hasPlan)  { return '/speckit-plan' }
    if (-not $hasTasks) { return '/speckit-tasks' }

    switch ($status) {
        'ready'     { return 'start handoff (update-handoff --status executing)' }
        'executing' { return 'continue implementation via speckit-superpowers-bridge SKILL' }
        'blocked'   { return 'resolve blocked_reason or rerun /speckit-clarify' }
        'complete'  { return '/speckit-specify' }
        default     { return '(none)' }
    }
}

function Write-BridgeStateSummaryFull {
    <#
    .SYNOPSIS
    Same as Write-BridgeStateSummary but accepts an explicit Actor argument (the new actor
    for this invocation). Use this from update-handoff.ps1 which knows the explicit Actor.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$HandoffPath,
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        [Parameter(Mandatory = $true)][string]$Actor,
        [string]$PriorActor = "",
        [switch]$EmitCompleteWarning
    )

    if (-not (Test-Path -LiteralPath $HandoffPath)) { return }
    $h = Get-Content -LiteralPath $HandoffPath -Raw | ConvertFrom-Json
    $featureDir = if ($h.feature_directory) { [string]$h.feature_directory } else { "" }
    $status = if ($h.status) { [string]$h.status } else { "" }
    $owner = if ($h.artifact_owner) { [string]$h.artifact_owner } else { "" }

    $pending = $null
    if (-not [string]::IsNullOrWhiteSpace($featureDir)) {
        $tasksPath = Join-Path $RepoRoot (Join-Path $featureDir "tasks.md")
        $pending = Get-PendingTaskCount -TasksPath $tasksPath
    }

    $lines = Get-BridgeStateLines -FeatureDirectory $featureDir -Status $status -ArtifactOwner $owner -Actor $Actor -PriorActor $PriorActor -PendingResult $pending
    foreach ($l in $lines) { Write-Output $l }

    if ($EmitCompleteWarning -and $status -eq 'complete' -and $pending -and $pending.TasksMdExists -and $pending.Count -gt 0) {
        $msg = "[bridge] WARNING: handoff is 'complete' but tasks.md has $($pending.Count) unchecked tasks; review or move under a deferred section."
        [Console]::Error.WriteLine($msg)
    }
}
