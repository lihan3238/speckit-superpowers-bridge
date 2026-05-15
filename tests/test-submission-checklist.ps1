$ErrorActionPreference = "Stop"

function Get-RepoRootSCT {
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $previousErrorAction = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        try {
            $root = (& git rev-parse --show-toplevel 2>$null)
            if ($LASTEXITCODE -eq 0 -and $root) { return $root.Trim() }
        }
        finally { $ErrorActionPreference = $previousErrorAction }
    }
    return (Get-Location).Path
}

function Assert-True { param([bool]$c, [string]$m); if (-not $c) { throw $m } }

function Invoke-Script {
    param([string]$ScriptPath, [string[]]$ArgList)
    # Capture both stdout and stderr but suppress PowerShell's stderr-as-error promotion.
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $out = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @ArgList 2>&1
        $exit = $LASTEXITCODE
    }
    finally { $ErrorActionPreference = $prev }
    return [pscustomobject]@{ Output = ($out -join [Environment]::NewLine); ExitCode = $exit }
}

$repoRoot = Get-RepoRootSCT
$script = Join-Path $repoRoot ".specify\extensions\speckit-superpowers-bridge\scripts\powershell\submission-checklist.ps1"
Assert-True (Test-Path -LiteralPath $script) "submission-checklist.ps1 missing"

# (a) Happy path: -OfflineOnly should pass since all required files exist
$result = Invoke-Script -ScriptPath $script -ArgList @("-OfflineOnly", "-Json")
Assert-True ($result.ExitCode -eq 0) "happy-path offline run should exit 0; got $($result.ExitCode)"
Assert-True ($result.Output -match '"exit_code":\s*0') "JSON report missing exit_code 0"
Assert-True ($result.Output -match '"target_version":\s*"\d+\.\d+\.\d+"') "JSON report missing target_version"

# (b) Synthetic missing LICENSE
$licensePath = Join-Path $repoRoot "LICENSE"
$bak = "$licensePath.bak-sctest"
Copy-Item -LiteralPath $licensePath -Destination $bak -Force
Remove-Item -LiteralPath $licensePath -Force
try {
    $result = Invoke-Script -ScriptPath $script -ArgList @("-OfflineOnly")
    Assert-True ($result.ExitCode -eq 1) "missing LICENSE should exit 1 (P0); got $($result.ExitCode)"
    Assert-True ($result.Output -match 'license_missing') "expected license_missing finding code"
}
finally {
    Move-Item -LiteralPath $bak -Destination $licensePath -Force
}

# (c) Synthetic broken catalog-entry (non-semver version)
$catalogPath = Join-Path $repoRoot "marketplace\catalog-entry.json"
$catalogBak = "$catalogPath.bak-sctest"
Copy-Item -LiteralPath $catalogPath -Destination $catalogBak -Force
try {
    $catalog = Get-Content -LiteralPath $catalogPath -Raw | ConvertFrom-Json
    $catalog.version = "not-semver"
    $catalog | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $catalogPath -Encoding UTF8
    $result = Invoke-Script -ScriptPath $script -ArgList @("-OfflineOnly")
    Assert-True ($result.ExitCode -eq 1) "broken catalog version should exit 1 (P0); got $($result.ExitCode)"
    Assert-True ($result.Output -match 'catalog_entry_invalid') "expected catalog_entry_invalid finding"
}
finally {
    Copy-Item -LiteralPath $catalogBak -Destination $catalogPath -Force
    Remove-Item -LiteralPath $catalogBak -Force
}

# (d) Synthetic missing AI-disclosure paragraph
$prBodyPath = Join-Path $repoRoot "marketplace\upstream-pr-body.md"
$prBak = "$prBodyPath.bak-sctest"
Copy-Item -LiteralPath $prBodyPath -Destination $prBak -Force
try {
    Set-Content -LiteralPath $prBodyPath -Value "# PR body without the canonical disclosure" -Encoding UTF8
    $result = Invoke-Script -ScriptPath $script -ArgList @("-OfflineOnly")
    Assert-True ($result.ExitCode -eq 2) "missing AI disclosure should exit 2 (P1); got $($result.ExitCode)"
    Assert-True ($result.Output -match 'ai_disclosure_missing') "expected ai_disclosure_missing finding"
}
finally {
    Copy-Item -LiteralPath $prBak -Destination $prBodyPath -Force
    Remove-Item -LiteralPath $prBak -Force
}

# (e) -OfflineOnly should yield a 'download_url_skipped' info finding without failing
$result = Invoke-Script -ScriptPath $script -ArgList @("-OfflineOnly", "-Json")
Assert-True ($result.ExitCode -eq 0) "-OfflineOnly happy path should exit 0; got $($result.ExitCode)"
Assert-True ($result.Output -match 'download_url_skipped') "expected download_url_skipped marker"

Write-Output "submission-checklist-tests-ok"
