param()

$ErrorActionPreference = "Stop"

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Assert-Equals {
    param(
        [object]$Expected,
        [object]$Actual,
        [string]$Message
    )

    if ($Expected -ne $Actual) {
        throw "$Message Expected '$Expected', got '$Actual'."
    }
}

function Invoke-ExpectedDeny {
    param(
        [string]$GuardScript,
        [string]$Action,
        [string]$Actor = ""
    )

    try {
        if ([string]::IsNullOrWhiteSpace($Actor)) {
            & $GuardScript -Action $Action | Out-Null
        }
        else {
            & $GuardScript -Action $Action -Actor $Actor | Out-Null
        }
    }
    catch {
        return
    }

    throw "Expected guard to deny $Action."
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

    return (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..\..")).Path
}

$scriptRoot = $PSScriptRoot
$repoRoot = Get-RepoRoot
$updateScript = Join-Path $scriptRoot "update-handoff.ps1"
$guardScript = Join-Path $scriptRoot "guard-command.ps1"
$restoreScript = Join-Path $scriptRoot "restore-snapshot.ps1"
$autoArchiveScript = Join-Path $scriptRoot "auto-archive-handoff.ps1"

Assert-True (Test-Path -LiteralPath $updateScript) "Missing update-handoff.ps1."
Assert-True (Test-Path -LiteralPath $guardScript) "Missing guard-command.ps1."
Assert-True (Test-Path -LiteralPath $restoreScript) "Missing restore-snapshot.ps1."
Assert-True (Test-Path -LiteralPath $autoArchiveScript) "Missing auto-archive-handoff.ps1."

$testRoot = Join-Path "C:\tmp" ("speckit-bridge-guard-test-" + [guid]::NewGuid().ToString("N"))
$featureDir = Join-Path $testRoot "specs\001-guard-test"

try {
    New-Item -ItemType Directory -Force -Path (Join-Path $testRoot ".specify\memory") | Out-Null
    New-Item -ItemType Directory -Force -Path $featureDir | Out-Null

    Set-Content -LiteralPath (Join-Path $testRoot ".specify\memory\constitution.md") -Value "# Constitution" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $testRoot ".specify\feature.json") -Value '{ "feature_directory": "specs/001-guard-test" }' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $featureDir "spec.md") -Value "# Spec" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $featureDir "plan.md") -Value "# Plan" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $featureDir "tasks.md") -Value "# Tasks`n- [ ] T001 Initial task" -Encoding UTF8
    New-Item -ItemType Directory -Force -Path (Join-Path $testRoot "src") | Out-Null
    Set-Content -LiteralPath (Join-Path $testRoot "src\implementation.txt") -Value "source-before-restore" -Encoding UTF8

    Push-Location $testRoot

    $oldEnvActor = $env:SPECKIT_BRIDGE_ACTOR
    $env:SPECKIT_BRIDGE_ACTOR = "codex"
    & $updateScript -Status ready | Out-Null
    $handoff = Get-Content -LiteralPath ".specify\superpowers-handoff.json" -Raw | ConvertFrom-Json
    Assert-Equals 3 $handoff.schema_version "Handoff schema_version should be 3."
    Assert-Equals "ready" $handoff.status "Handoff ready status mismatch."
    Assert-Equals "superpowers" $handoff.executor "Handoff executor mismatch."
    Assert-Equals "specs/001-guard-test" $handoff.feature_directory "Handoff feature directory mismatch."
    Assert-Equals "specs/001-guard-test/spec.md" $handoff.source_of_truth.spec "Handoff spec source mismatch."
    Assert-Equals "specs/001-guard-test/plan.md" $handoff.source_of_truth.plan "Handoff plan source mismatch."
    Assert-Equals "specs/001-guard-test/tasks.md" $handoff.source_of_truth.tasks "Handoff tasks source mismatch."
    Assert-True ($handoff.PSObject.Properties.Name -contains "artifact_owner") "Missing handoff artifact_owner field."
    Assert-True ($handoff.PSObject.Properties.Name -contains "review_only_agents") "Missing handoff review_only_agents field."
    Assert-True ($handoff.PSObject.Properties.Name -contains "autonomous_mode") "Missing handoff autonomous_mode field."
    Assert-True ($handoff.PSObject.Properties.Name -contains "resume_context") "Missing handoff resume_context field."
    Assert-Equals "codex" $handoff.artifact_owner "Default artifact owner mismatch."
    Assert-Equals $false $handoff.autonomous_mode "autonomous_mode should default to false."
    Assert-True ($null -eq $handoff.resume_context) "resume_context should default to null."
    Assert-True (($handoff.review_only_agents -contains "claude")) "Expected claude to be review-only by default."
    Assert-True ($handoff.instructions -match "\.agents/skills/speckit-superpowers-bridge/SKILL.md") "Missing Codex bridge skill instruction."
    Assert-True ($handoff.instructions -match "\.claude/skills/speckit-superpowers-bridge/SKILL.md") "Missing Claude bridge skill instruction."
    Assert-True (Test-Path -LiteralPath ".specify\bridge-events.jsonl") "Missing bridge event log."
    Assert-True ((Get-ChildItem -LiteralPath ".specify\bridge-snapshots" -Directory).Count -ge 1) "Expected at least one snapshot."

    $schemaPath = Join-Path $repoRoot "specs\001-spec-superpowers-bridge\contracts\handoff.schema.json"
    Assert-True (Test-Path -LiteralPath $schemaPath) "Missing handoff schema contract."
    $schema = Get-Content -LiteralPath $schemaPath -Raw | ConvertFrom-Json
    foreach ($required in @("schema_version", "updated_at", "feature_directory", "source_of_truth", "supersedes", "executor", "capabilities", "autonomous_mode", "resume_context", "status", "blocked_reason", "artifact_owner", "review_only_agents", "notes", "last_snapshot_id", "instructions")) {
        Assert-True ($schema.required -contains $required) "Handoff schema missing required field '$required'."
        Assert-True ($handoff.PSObject.Properties.Name -contains $required) "Handoff missing required schema field '$required'."
    }

    Invoke-ExpectedDeny -GuardScript $guardScript -Action "speckit.implement"
    Invoke-ExpectedDeny -GuardScript $guardScript -Action "superpowers.writing-plans"
    Invoke-ExpectedDeny -GuardScript $guardScript -Action "superpowers:writing-plans"
    Invoke-ExpectedDeny -GuardScript $guardScript -Action "superpowers.brainstorming"

    & $updateScript -Status executing | Out-Null
    Invoke-ExpectedDeny -GuardScript $guardScript -Action "speckit.tasks"

    & $updateScript -Status blocked -Reason "repair needed" | Out-Null
    & $guardScript -Action "speckit.tasks" | Out-Null
    Invoke-ExpectedDeny -GuardScript $guardScript -Action "speckit.tasks" -Actor "claude"

    $snapshot = Get-ChildItem -LiteralPath ".specify\bridge-snapshots" -Directory |
        Sort-Object Name -Descending |
        Select-Object -First 1

    Assert-True ($null -ne $snapshot) "Missing snapshot for rollback."
    Set-Content -LiteralPath (Join-Path $featureDir "tasks.md") -Value "# Tasks`n- [X] broken mutation" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $testRoot "src\implementation.txt") -Value "source-after-restore-boundary" -Encoding UTF8
    & $restoreScript -SnapshotId $snapshot.Name | Out-Null
    $restoredTasks = Get-Content -LiteralPath (Join-Path $featureDir "tasks.md") -Raw
    Assert-True ($restoredTasks -match "T001 Initial task") "Rollback did not restore tasks.md."
    $sourceAfterRestore = Get-Content -LiteralPath (Join-Path $testRoot "src\implementation.txt") -Raw
    Assert-True ($sourceAfterRestore -match "source-after-restore-boundary") "Rollback changed implementation source files."

    $events = Get-Content -LiteralPath ".specify\bridge-events.jsonl"
    Assert-True (($events | Select-String -Pattern '"action":"guard"' -Quiet) -or ($events | Select-String -Pattern '"action": "guard"' -Quiet)) "Missing guard event."
    Assert-True (($events | Select-String -Pattern '"action":"rollback"' -Quiet) -or ($events | Select-String -Pattern '"action": "rollback"' -Quiet)) "Missing rollback event."
    foreach ($line in $events) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        $event = $line | ConvertFrom-Json
        foreach ($field in @("timestamp", "action", "status", "feature_directory", "decision", "reason", "actor", "snapshot_id")) {
            Assert-True ($event.PSObject.Properties.Name -contains $field) "Bridge event missing '$field'."
        }
    }

    # ===== Phase 2 (002-complete-bridge-protocol) regression tests =====

    # Schema_version is now 3 and archive_history is preserved across writes.
    $handoffStateNow = Get-Content -LiteralPath ".specify\superpowers-handoff.json" -Raw | ConvertFrom-Json
    Assert-Equals 3 $handoffStateNow.schema_version "Handoff schema_version should be 3 after update-handoff.ps1 modifications."
    Assert-True ($handoffStateNow.PSObject.Properties.Name -contains "archive_history") "Handoff must include archive_history field."

    # Move to complete state for the auto-archive scenarios.
    & $updateScript -Status complete -Reason "test seed for auto-archive" | Out-Null
    $completeState = Get-Content -LiteralPath ".specify\superpowers-handoff.json" -Raw | ConvertFrom-Json
    Assert-Equals "complete" $completeState.status "Pre-auto-archive seed should be complete."
    Assert-Equals "specs/001-guard-test" $completeState.feature_directory "Pre-auto-archive feature_directory mismatch."

    # Auto-archive happy path: complete -> ready, snapshot taken, archive_history grows.
    & $autoArchiveScript -Actor "claude" | Out-Null
    $archivedState = Get-Content -LiteralPath ".specify\superpowers-handoff.json" -Raw | ConvertFrom-Json
    Assert-Equals "ready" $archivedState.status "Auto-archive should leave status=ready."
    Assert-True ([string]::IsNullOrWhiteSpace([string]$archivedState.feature_directory)) "Auto-archive should clear feature_directory."
    Assert-True ($archivedState.archive_history.Count -ge 1) "Auto-archive should append to archive_history."
    $lastArchive = $archivedState.archive_history[$archivedState.archive_history.Count - 1]
    Assert-Equals "specs/001-guard-test" $lastArchive.feature_directory "archive_history entry feature_directory mismatch."
    Assert-Equals "complete" $lastArchive.status_at_archive "archive_history entry status_at_archive mismatch."
    Assert-Equals "claude" $lastArchive.archived_by "archive_history entry archived_by mismatch."
    Assert-True (-not [string]::IsNullOrWhiteSpace([string]$lastArchive.snapshot_id)) "archive_history entry should have snapshot_id."

    # Auto-archive no-op when status is not complete.
    $beforeNoop = Get-Content -LiteralPath ".specify\superpowers-handoff.json" -Raw | ConvertFrom-Json
    & $autoArchiveScript -Actor "claude" | Out-Null
    $afterNoop = Get-Content -LiteralPath ".specify\superpowers-handoff.json" -Raw | ConvertFrom-Json
    Assert-Equals $beforeNoop.archive_history.Count $afterNoop.archive_history.Count "Auto-archive must be no-op when status != complete."

    # auto_archive event was appended.
    $events = Get-Content -LiteralPath ".specify\bridge-events.jsonl"
    Assert-True (($events | Select-String -Pattern '"action":"auto_archive"' -Quiet) -or ($events | Select-String -Pattern '"action": "auto_archive"' -Quiet)) "Missing auto_archive event."

    # Cross-feature contract change while a prior feature is complete: allow.
    # Set up a second feature directory, point feature.json at it, seed a complete handoff for the FIRST feature,
    # then invoke guard with -TargetFeatureDirectory for the SECOND feature.
    $secondFeatureDir = Join-Path $testRoot "specs\002-second-feature"
    New-Item -ItemType Directory -Force -Path $secondFeatureDir | Out-Null
    Set-Content -LiteralPath (Join-Path $secondFeatureDir "spec.md") -Value "# Spec2" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $secondFeatureDir "plan.md") -Value "# Plan2" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $secondFeatureDir "tasks.md") -Value "# Tasks2`n- [ ] T001 do-thing" -Encoding UTF8

    & $updateScript -Status complete -FeatureDirectory "specs/001-guard-test" -Reason "seed complete on first feature" | Out-Null
    # Guard called with -TargetFeatureDirectory pointing at the SECOND feature MUST allow (cross-feature).
    & $guardScript -Action speckit.clarify -Actor claude -TargetFeatureDirectory "specs/002-second-feature" | Out-Null

    # Guard called WITHOUT -TargetFeatureDirectory (same-feature default) MUST still deny (legacy behavior).
    Invoke-ExpectedDeny -GuardScript $guardScript -Action "speckit.clarify" -Actor "claude"

    # speckit.implement must STILL be denied regardless of status (FR-012 / matrix entry).
    Invoke-ExpectedDeny -GuardScript $guardScript -Action "speckit.implement"

    Pop-Location
}
finally {
    if ($null -ne $oldEnvActor) { $env:SPECKIT_BRIDGE_ACTOR = $oldEnvActor } else { $env:SPECKIT_BRIDGE_ACTOR = "" }
    if ((Get-Location).Path -eq $testRoot) {
        Pop-Location
    }

    if (Test-Path -LiteralPath $testRoot) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
}

Write-Output "bridge-guard-tests-ok"
