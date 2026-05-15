param(
    [Parameter(Mandatory = $true)]
    [string]$SnapshotId,

    [string]$Actor = ""
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

function Write-BridgeEvent {
    param(
        [string]$RepoRoot,
        [string]$Status,
        [string]$FeatureDirectory,
        [string]$Decision,
        [string]$Reason,
        [string]$SnapshotId,
        [string[]]$RestoredPaths = @(),
        [string]$Actor = ""
    )

    $event = [ordered]@{
        timestamp = (Get-Date).ToUniversalTime().ToString("o")
        action = "rollback"
        status = $Status
        feature_directory = $FeatureDirectory
        decision = $Decision
        reason = $Reason
        actor = $Actor
        snapshot_id = $SnapshotId
        restored_paths = @($RestoredPaths)
    }

    $eventPath = Join-Path $RepoRoot ".specify\bridge-events.jsonl"
    ($event | ConvertTo-Json -Compress -Depth 6) + [Environment]::NewLine | Add-Content -LiteralPath $eventPath -Encoding UTF8
}

$repoRoot = Get-RepoRoot
$Actor = Resolve-BridgeActor -Argument $Actor -RepoRoot $repoRoot
$snapshotRoot = Join-Path $repoRoot ".specify\bridge-snapshots\$SnapshotId"
if (-not (Test-Path -LiteralPath $snapshotRoot)) {
    throw "Snapshot '$SnapshotId' does not exist."
}

$metadataPath = Join-Path $snapshotRoot "metadata.json"
if (-not (Test-Path -LiteralPath $metadataPath)) {
    throw "Snapshot '$SnapshotId' is missing metadata.json."
}

$metadata = Get-Content -LiteralPath $metadataPath -Raw | ConvertFrom-Json
$featureDirectory = [string]$metadata.feature_directory
if ([string]::IsNullOrWhiteSpace($featureDirectory)) {
    throw "Snapshot '$SnapshotId' does not record a feature_directory."
}

$featurePath = if ([System.IO.Path]::IsPathRooted($featureDirectory)) {
    $featureDirectory
}
else {
    Join-Path $repoRoot $featureDirectory
}

New-Item -ItemType Directory -Force -Path $featurePath | Out-Null

$restoredPaths = New-Object System.Collections.Generic.List[string]
foreach ($artifact in @("spec.md", "plan.md", "tasks.md")) {
    $snapshotArtifact = Join-Path $snapshotRoot $artifact
    if (Test-Path -LiteralPath $snapshotArtifact) {
        $destination = Join-Path $featurePath $artifact
        Copy-Item -LiteralPath $snapshotArtifact -Destination $destination -Force
        $restoredPaths.Add($destination.Replace($repoRoot, "").TrimStart("\", "/").Replace("\", "/"))
    }
}

$snapshotHandoff = Join-Path $snapshotRoot "superpowers-handoff.json"
if (Test-Path -LiteralPath $snapshotHandoff) {
    $handoffDestination = Join-Path $repoRoot ".specify\superpowers-handoff.json"
    Copy-Item -LiteralPath $snapshotHandoff -Destination $handoffDestination -Force
    $restoredPaths.Add(".specify/superpowers-handoff.json")
}

Write-BridgeEvent -RepoRoot $repoRoot -Status "restored" -FeatureDirectory $featureDirectory -Decision "restored" -Reason "Restored Spec Kit control artifacts from snapshot." -SnapshotId $SnapshotId -RestoredPaths $restoredPaths.ToArray() -Actor $Actor
Write-Output "Restored snapshot '$SnapshotId'."
