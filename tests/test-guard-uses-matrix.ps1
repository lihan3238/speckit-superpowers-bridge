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

function Assert-True { param([bool]$c, [string]$m); if (-not $c) { throw $m } }

$repoRoot = Get-RepoRoot
$scriptRoot = Join-Path $repoRoot ".specify\extensions\speckit-superpowers-bridge\scripts\powershell"
$updateScript = Join-Path $scriptRoot "update-handoff.ps1"
$guardScript = Join-Path $scriptRoot "guard-command.ps1"

# Isolated workspace so we don't mutate the live handoff
$testRoot = Join-Path "C:\tmp" ("speckit-guard-matrix-test-" + [guid]::NewGuid().ToString("N"))
$featureDir = Join-Path $testRoot "specs\002-matrix-driven"

try {
    New-Item -ItemType Directory -Force -Path (Join-Path $testRoot ".specify\memory") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $testRoot ".specify\extensions\speckit-superpowers-bridge") | Out-Null
    New-Item -ItemType Directory -Force -Path $featureDir | Out-Null

    Set-Content -LiteralPath (Join-Path $testRoot ".specify\memory\constitution.md") -Value "# C" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $testRoot ".specify\feature.json") -Value '{ "feature_directory": "specs/002-matrix-driven" }' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $featureDir "spec.md") -Value "# S" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $featureDir "plan.md") -Value "# P" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $featureDir "tasks.md") -Value "# T" -Encoding UTF8

    # Copy the live matrix into the isolated workspace so the guard finds it via test-root path
    Copy-Item -LiteralPath (Join-Path $repoRoot ".specify\extensions\speckit-superpowers-bridge\disposition-matrix.json") `
        -Destination (Join-Path $testRoot ".specify\extensions\speckit-superpowers-bridge\disposition-matrix.json") -Force

    Push-Location $testRoot

    # Seed executing handoff
    & $updateScript -Status executing -ArtifactOwner claude | Out-Null

    # superpowers.brainstorming is FORBID-UNDER-HANDOFF[executing,complete] — must deny when status=executing
    $denied = $false
    try { & $guardScript -Action superpowers.brainstorming -Actor claude | Out-Null } catch { $denied = $true }
    Assert-True $denied "guard must deny superpowers.brainstorming when status=executing per matrix."

    # Read events; latest guard event should carry policy_ref=superpowers:brainstorming
    $events = Get-Content -LiteralPath ".specify\bridge-events.jsonl"
    $lastGuard = $null
    for ($i = $events.Count - 1; $i -ge 0; $i--) {
        $line = $events[$i]
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $e = $line | ConvertFrom-Json
        if ($e.action -eq "guard") { $lastGuard = $e; break }
    }
    Assert-True ($null -ne $lastGuard) "no guard event found"
    Assert-True ($lastGuard.PSObject.Properties.Name -contains "policy_ref") "guard event missing policy_ref field"
    # policy_ref echoes the matrix entry id (which uses colon for Superpowers namespace); the guard's
    # decision matched the matrix entry, so policy_ref must be the matrix id verbatim.
    Assert-True ([string]$lastGuard.policy_ref -eq "superpowers:brainstorming") "policy_ref mismatch; got '$([string]$lastGuard.policy_ref)'"

    Pop-Location
}
finally {
    if ((Get-Location).Path -eq $testRoot) { Pop-Location }
    if (Test-Path -LiteralPath $testRoot) { Remove-Item -LiteralPath $testRoot -Recurse -Force }
}

Write-Output "guard-uses-matrix-tests-ok"
