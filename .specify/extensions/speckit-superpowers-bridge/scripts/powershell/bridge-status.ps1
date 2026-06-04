# bridge-status.ps1 — read-only bridge state introspection (v0.7.0+).
# Spec:     specs/012-bridge-status-and-hash/spec.md (FR-001..FR-007)
# Contract: specs/012-bridge-status-and-hash/contracts/{bridge-status-output,next-command-decision-table}.md
# Parity with bridge-status.sh. Read-only.

[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$Readiness,
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

if ($Readiness) {
    $BridgeDir = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '..\..')).Path

    $toolsStatus = 'ready'
    $toolsItems = @(
        [ordered]@{ name = 'powershell'; status = 'ready'; version = $PSVersionTable.PSVersion.ToString() }
    )
    $toolsDetail = "powershell: $($PSVersionTable.PSVersion)"

    $namespaceStatus = 'ready'
    $namespaceDetail = 'speckit.speckit-superpowers-bridge.*'
    $extensionId = ''
    $manifestPath = Join-Path $BridgeDir 'extension.yml'
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        $namespaceStatus = 'failed'
        $namespaceDetail = 'missing extension.yml'
    } else {
        $manifest = Get-Content -LiteralPath $manifestPath -Raw
        $m = [regex]::Match($manifest, '(?m)^\s{2,}id:\s*["'']?([^"''\s#]+)')
        if ($m.Success) { $extensionId = $m.Groups[1].Value }
        $expectedPrefix = "speckit.$extensionId."
        $commandMatches = [regex]::Matches($manifest, '(?m)^\s*-\s+name:\s*["'']?([^"''\s#]+)')
        $hookMatches = [regex]::Matches($manifest, '(?m)^\s*command:\s*["'']?([^"''\s#]+)')
        foreach ($match in $commandMatches) {
            $name = $match.Groups[1].Value
            if ($name.StartsWith('speckit.', [System.StringComparison]::Ordinal) -and -not $name.StartsWith($expectedPrefix, [System.StringComparison]::Ordinal)) {
                $namespaceStatus = 'failed'
            }
        }
        foreach ($match in $hookMatches) {
            $name = $match.Groups[1].Value
            if ($name.StartsWith('speckit.', [System.StringComparison]::Ordinal) -and -not $name.StartsWith($expectedPrefix, [System.StringComparison]::Ordinal)) {
                $namespaceStatus = 'failed'
            }
        }
        if ($extensionId -ne 'speckit-superpowers-bridge') {
            $namespaceStatus = 'failed'
        }
        if ($namespaceStatus -eq 'failed') {
            $namespaceDetail = 'expected prefix speckit.speckit-superpowers-bridge.*'
        }
    }

    $requiredFiles = @(
        'extension.yml',
        'verified-versions.json',
        'commands/speckit.speckit-superpowers-bridge.execute.md',
        'commands/speckit.speckit-superpowers-bridge.guard.md',
        'commands/speckit.speckit-superpowers-bridge.handoff.md',
        'scripts/bash/bridge-status.sh',
        'scripts/bash/guard-command.sh',
        'scripts/bash/update-handoff.sh',
        'scripts/powershell/bridge-status.ps1',
        'scripts/powershell/guard-command.ps1',
        'scripts/powershell/update-handoff.ps1'
    )
    $missing = @()
    foreach ($rel in $requiredFiles) {
        if (-not (Test-Path -LiteralPath (Join-Path $BridgeDir ($rel -replace '/', [System.IO.Path]::DirectorySeparatorChar)))) {
            $missing += $rel
        }
    }
    $packageStatus = if ($missing.Count -gt 0) { 'failed' } else { 'ready' }
    $packageDetail = if ($missing.Count -gt 0) { "missing: $($missing -join ', ')" } else { 'required bridge files present' }

    $bridgeStateStatus = 'ready'
    $bridgeStateDetail = "status: $Status; pending tasks: $PendingLabel"
    if ($State -eq 'corrupted') {
        $bridgeStateStatus = 'failed'
        $bridgeStateDetail = 'corrupted handoff'
    } elseif ($State -eq 'no-handoff') {
        $bridgeStateStatus = 'warning'
        $bridgeStateDetail = 'no handoff file'
    }

    $agentsStatus = 'not checked'
    $agentsDetail = 'verified-versions.json has no agent rows'
    $agentsItems = @()
    $verifiedPath = Join-Path $BridgeDir 'verified-versions.json'
    if (Test-Path -LiteralPath $verifiedPath -PathType Leaf) {
        try {
            $verified = Get-Content -LiteralPath $verifiedPath -Raw | ConvertFrom-Json
            if ($verified.agents) {
                $agentsItems = @($verified.agents)
                $allPassed = $true
                foreach ($item in $agentsItems) {
                    if ($item.status -ne 'passed') { $allPassed = $false }
                }
                $agentsStatus = if ($allPassed -and $agentsItems.Count -gt 0) { 'ready' } else { 'warning' }
                $agentsDetail = (($agentsItems | ForEach-Object { "$($_.name): $($_.status)" }) -join '; ')
            }
        } catch {
            $agentsStatus = 'warning'
            $agentsDetail = 'verified-versions.json could not be parsed'
        }
    }

    $overallStatus = 'ready'
    if ($toolsStatus -eq 'failed' -or $namespaceStatus -eq 'failed' -or $packageStatus -eq 'failed' -or $bridgeStateStatus -eq 'failed') {
        $overallStatus = 'failed'
    } elseif ($toolsStatus -eq 'warning' -or $bridgeStateStatus -eq 'warning' -or $agentsStatus -eq 'warning' -or $agentsStatus -eq 'not checked') {
        $overallStatus = 'warning'
    }

    if ($Json) {
        $payload = [ordered]@{
            script_flavor  = 'ps'
            required_tools = [ordered]@{ status = $toolsStatus; items = @($toolsItems) }
            namespace      = [ordered]@{ status = $namespaceStatus; extension_id = $extensionId; command_prefix = 'speckit.speckit-superpowers-bridge.' }
            package_files  = [ordered]@{ status = $packageStatus; missing = @($missing) }
            bridge_state   = [ordered]@{ status = $bridgeStateStatus; feature_directory = $(if ($FeatureDir -eq '(none)') { $null } else { $FeatureDir }); next = $NextRec }
            agents         = [ordered]@{ status = $agentsStatus; items = @($agentsItems) }
            overall_status = $overallStatus
            next           = $NextRec
        }
        Write-Output ($payload | ConvertTo-Json -Compress -Depth 8)
    } else {
        Write-Output '[bridge readiness]'
        Write-Output '  Script flavor: ps'
        Write-Output "  Required tools: $toolsStatus ($toolsDetail)"
        Write-Output "  Namespace: $namespaceStatus ($namespaceDetail)"
        Write-Output "  Package files: $packageStatus ($packageDetail)"
        Write-Output "  Bridge state: $bridgeStateStatus ($bridgeStateDetail)"
        Write-Output "  Agents: $agentsStatus ($agentsDetail)"
        Write-Output "  Next: $NextRec"
    }
    if ($overallStatus -eq 'failed') { exit 1 }
    exit 0
}

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
