param(
    [string]$Actor = "",

    [string]$Reason = "Auto-archive complete handoff before new feature."
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "common-actor-resolution.ps1")

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

$repoRoot = Get-RepoRoot
$Actor = Resolve-BridgeActor -Argument $Actor -RepoRoot $repoRoot
$handoffPath = Join-Path $repoRoot ".specify\superpowers-handoff.json"
if (-not (Test-Path -LiteralPath $handoffPath)) {
    Write-Output "No handoff file at $handoffPath; nothing to archive."
    return
}

$state = Get-Content -LiteralPath $handoffPath -Raw | ConvertFrom-Json
$currentStatus = if ($state.PSObject.Properties.Name -contains "status") { [string]$state.status } else { "" }

if ($currentStatus -ne "complete") {
    Write-Output "No complete handoff to archive (current status: '$currentStatus')."
    return
}

$priorFeatureDirectory = if ($state.PSObject.Properties.Name -contains "feature_directory") { [string]$state.feature_directory } else { "" }
$priorStatus = $currentStatus

$archiveEntry = [pscustomobject]@{
    feature_directory = $priorFeatureDirectory
    status_at_archive = $priorStatus
    archived_at = (Get-Date).ToUniversalTime().ToString("o")
    archived_by = $Actor
}

# Delegate to update-handoff.ps1 with -ClearFeatureDirectory so the snapshot captures the prior state
# and the new state has feature_directory cleared. The script returns the snapshot ID via the handoff file's
# last_snapshot_id, which we then patch into the archive entry below for traceability.
# Use $PSScriptRoot (this script's own location) rather than $repoRoot so the helper still works in
# test environments where the repo root may be temporarily relocated.
$updateScript = Join-Path $PSScriptRoot "update-handoff.ps1"
& $updateScript `
    -Status ready `
    -ClearFeatureDirectory `
    -ArtifactOwner unknown `
    -Reason $Reason `
    -AppendArchiveEntry $archiveEntry `
    -Actor $Actor | Out-Null

# Re-read the updated handoff to find the snapshot ID; patch the archive entry's snapshot_id so future
# audits can correlate the archive record with the snapshot directory under .specify/bridge-snapshots/.
$updatedState = Get-Content -LiteralPath $handoffPath -Raw | ConvertFrom-Json
$snapshotId = if ($updatedState.PSObject.Properties.Name -contains "last_snapshot_id") { [string]$updatedState.last_snapshot_id } else { $null }
if ($snapshotId -and $updatedState.archive_history -and $updatedState.archive_history.Count -gt 0) {
    $lastIndex = $updatedState.archive_history.Count - 1
    $lastEntry = $updatedState.archive_history[$lastIndex]
    if (-not ($lastEntry.PSObject.Properties.Name -contains "snapshot_id") -or [string]::IsNullOrWhiteSpace([string]$lastEntry.snapshot_id)) {
        $lastEntry | Add-Member -NotePropertyName snapshot_id -NotePropertyValue $snapshotId -Force
        $updatedState | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $handoffPath -Encoding UTF8
    }
}

# Append a dedicated bridge event so consumers can recognize this as an auto_archive rather than a generic handoff update.
$eventPath = Join-Path $repoRoot ".specify\bridge-events.jsonl"
$event = [ordered]@{
    timestamp = (Get-Date).ToUniversalTime().ToString("o")
    action = "auto_archive"
    status = "ready"
    feature_directory = $priorFeatureDirectory
    decision = "archive"
    reason = $Reason
    actor = $Actor
    snapshot_id = $snapshotId
    prior_status = $priorStatus
}
($event | ConvertTo-Json -Compress -Depth 6) + [Environment]::NewLine | Add-Content -LiteralPath $eventPath -Encoding UTF8

Write-Output "Auto-archived handoff for '$priorFeatureDirectory' (snapshot: $snapshotId)."
