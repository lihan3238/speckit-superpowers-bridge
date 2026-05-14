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

$testRoot = Join-Path "C:\tmp" ("speckit-constitution-checklist-test-" + [guid]::NewGuid().ToString("N"))
$featureDir = Join-Path $testRoot "specs\002-cc"

try {
    New-Item -ItemType Directory -Force -Path (Join-Path $testRoot ".specify\memory") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $testRoot ".specify\extensions\speckit-superpowers-bridge") | Out-Null
    New-Item -ItemType Directory -Force -Path $featureDir | Out-Null

    Set-Content -LiteralPath (Join-Path $testRoot ".specify\memory\constitution.md") -Value "# C" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $testRoot ".specify\feature.json") -Value '{ "feature_directory": "specs/002-cc" }' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $featureDir "spec.md") -Value "# S" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $featureDir "plan.md") -Value "# P" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $featureDir "tasks.md") -Value "# T" -Encoding UTF8

    Copy-Item -LiteralPath (Join-Path $repoRoot ".specify\extensions\speckit-superpowers-bridge\disposition-matrix.json") `
        -Destination (Join-Path $testRoot ".specify\extensions\speckit-superpowers-bridge\disposition-matrix.json") -Force

    Push-Location $testRoot

    # --- speckit.constitution: deny on executing; allow on ready/blocked/complete ---
    & $updateScript -Status executing -ArtifactOwner claude | Out-Null
    $denied = $false
    try { & $guardScript -Action speckit.constitution -Actor claude | Out-Null } catch { $denied = $true }
    Assert-True $denied "guard must deny speckit.constitution when status=executing"

    & $updateScript -Status blocked -ArtifactOwner claude -Reason "test transition" | Out-Null
    & $guardScript -Action speckit.constitution -Actor claude | Out-Null

    & $updateScript -Status ready -ArtifactOwner claude | Out-Null
    & $guardScript -Action speckit.constitution -Actor claude | Out-Null

    & $updateScript -Status complete -ArtifactOwner claude | Out-Null
    & $guardScript -Action speckit.constitution -Actor claude | Out-Null

    # --- speckit.checklist: COMBINE — must always be allowed regardless of status ---
    foreach ($s in @("ready", "executing", "blocked", "complete")) {
        if ($s -eq "blocked") {
            & $updateScript -Status $s -ArtifactOwner claude -Reason "test transition" | Out-Null
        } else {
            & $updateScript -Status $s -ArtifactOwner claude | Out-Null
        }
        & $guardScript -Action speckit.checklist -Actor claude | Out-Null
    }

    Pop-Location
}
finally {
    if ((Get-Location).Path -eq $testRoot) { Pop-Location }
    if (Test-Path -LiteralPath $testRoot) { Remove-Item -LiteralPath $testRoot -Recurse -Force }
}

Write-Output "constitution-checklist-guard-tests-ok"
