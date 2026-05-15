$ErrorActionPreference = "Stop"

# Smoke test for the v1 handoff schema (FR-006 + FR-009).
# Covers:
#   (a) update-handoff.ps1 writes a JSON document matching the v1 shape
#   (b) reading a fabricated v3-shape handoff does not error
#   (c) new writes do not echo back v3-only fields (autonomous_mode, resume_context, archive_history)

function Get-RepoRoot {
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $prev = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        try {
            $root = (& git rev-parse --show-toplevel 2>$null)
            if ($LASTEXITCODE -eq 0 -and $root) { return $root.Trim() }
        }
        finally { $ErrorActionPreference = $prev }
    }
    return (Get-Location).Path
}

function Assert-True { param([bool]$c, [string]$m); if (-not $c) { throw $m } }

$repoRoot = Get-RepoRoot
$updateScript = Join-Path $repoRoot ".specify/extensions/speckit-superpowers-bridge/scripts/powershell/update-handoff.ps1"
$handoffPath = Join-Path $repoRoot ".specify/superpowers-handoff.json"

# Snapshot current handoff so we can restore it after the test
$backupContent = if (Test-Path -LiteralPath $handoffPath) { Get-Content -LiteralPath $handoffPath -Raw } else { $null }

try {
    # --- (a) v1 write shape ---
    & $updateScript -Status executing -FeatureDirectory "specs/006-trim-to-thin-bridge" -ArtifactOwner claude -Actor claude -Reason "smoke test (a)" | Out-Null
    $h = Get-Content -LiteralPath $handoffPath -Raw | ConvertFrom-Json

    Assert-True ($h.schema_version -eq 1) "schema_version should be 1, got $($h.schema_version)"
    Assert-True ($h.status -in @("ready","executing","blocked","complete")) "status not in v1 enum"
    Assert-True ($null -ne $h.source_of_truth) "source_of_truth missing"
    Assert-True ($h.source_of_truth.constitution -eq ".specify/memory/constitution.md") "constitution path wrong"
    Assert-True ($h.artifact_owner -in @("codex","claude","unknown")) "artifact_owner not in v1 enum"
    Assert-True ($null -ne $h.updated_at) "updated_at missing"

    # v3-only fields must NOT appear in new writes
    $names = $h.PSObject.Properties.Name
    foreach ($dropped in @("autonomous_mode","resume_context","archive_history")) {
        Assert-True (-not ($names -contains $dropped)) "v1 write should not contain v3 field: $dropped"
    }

    # --- (b) backward-read of v3 JSON ---
    $v3 = @{
        schema_version = 3
        updated_at = "2026-05-15T00:00:00Z"
        feature_directory = "specs/006-trim-to-thin-bridge"
        source_of_truth = @{
            constitution = ".specify/memory/constitution.md"
            spec = "specs/006-trim-to-thin-bridge/spec.md"
            plan = "specs/006-trim-to-thin-bridge/plan.md"
            tasks = "specs/006-trim-to-thin-bridge/tasks.md"
        }
        executor = "superpowers"
        status = "executing"
        artifact_owner = "claude"
        autonomous_mode = $true
        resume_context = @{ last_task = "Tsmoke" }
        archive_history = @(@{ feature_directory = "specs/005-marketplace-alignment" })
    } | ConvertTo-Json -Depth 5
    Set-Content -LiteralPath $handoffPath -Value $v3 -Encoding UTF8

    # Reading via update-handoff should NOT throw on v3-only fields
    & $updateScript -Status executing -Actor claude -Reason "smoke test (b)" | Out-Null
    $post = Get-Content -LiteralPath $handoffPath -Raw | ConvertFrom-Json
    Assert-True ($post.schema_version -eq 1) "post-write schema_version should be 1"
    $postNames = $post.PSObject.Properties.Name
    foreach ($dropped in @("autonomous_mode","resume_context","archive_history")) {
        Assert-True (-not ($postNames -contains $dropped)) "after reading v3, new write echoed back: $dropped"
    }

    Write-Output "handoff-shape-tests-ok"
}
finally {
    if ($backupContent) {
        Set-Content -LiteralPath $handoffPath -Value $backupContent -Encoding UTF8 -NoNewline
    }
}
