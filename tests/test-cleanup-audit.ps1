$ErrorActionPreference = "Stop"

function Get-RepoRootCAT {
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

function Invoke-CAScript {
    param([string]$ScriptPath, [string[]]$ArgList)
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $out = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @ArgList 2>&1
        $exit = $LASTEXITCODE
    }
    finally { $ErrorActionPreference = $prev }
    return [pscustomobject]@{ Output = ($out -join [Environment]::NewLine); ExitCode = $exit }
}

$repoRoot = Get-RepoRootCAT
$script = Join-Path $repoRoot ".specify\extensions\speckit-superpowers-bridge\scripts\powershell\cleanup-audit.ps1"
Assert-True (Test-Path -LiteralPath $script) "cleanup-audit.ps1 missing"

# (a) Happy path: 0 P0/P1 findings on this repo
$result = Invoke-CAScript -ScriptPath $script -ArgList @("-Json")
Assert-True ($result.ExitCode -eq 0) "happy path should exit 0; got $($result.ExitCode)"
Assert-True ($result.Output -match '"exit_code":\s*0') "JSON report missing exit_code 0"

# (b) Synthetic backup file → P2 finding
$bakFile = Join-Path $repoRoot "ca-test-synthetic.bak"
Set-Content -LiteralPath $bakFile -Value "synthetic backup for test" -Encoding UTF8
try {
    $result = Invoke-CAScript -ScriptPath $script -ArgList @("-Json")
    Assert-True ($result.Output -match 'backup_file_present') "expected backup_file_present finding for ca-test-synthetic.bak"
}
finally {
    if (Test-Path -LiteralPath $bakFile) { Remove-Item -LiteralPath $bakFile -Force }
}

# (c) Synthetic unreferenced doc → P2 finding
$extDocsDir = Join-Path $repoRoot ".specify\extensions\speckit-superpowers-bridge\docs"
$synthDoc = Join-Path $extDocsDir "synth-unreferenced-$(Get-Random).md"
Set-Content -LiteralPath $synthDoc -Value "# Synthetic" -Encoding UTF8
try {
    $result = Invoke-CAScript -ScriptPath $script -ArgList @("-Json")
    Assert-True ($result.Output -match 'unreferenced_doc') "expected unreferenced_doc finding"
}
finally {
    if (Test-Path -LiteralPath $synthDoc) { Remove-Item -LiteralPath $synthDoc -Force }
}

# (d) Synthetic manifest path inconsistency → P0 finding
$manifestPath = Join-Path $repoRoot ".specify\extensions\speckit-superpowers-bridge\plugin-distribution-manifest.yml"
$manifestBak = "$manifestPath.bak-catest"
Copy-Item -LiteralPath $manifestPath -Destination $manifestBak -Force
try {
    $content = Get-Content -LiteralPath $manifestPath -Raw
    # Inject a nonexistent path into includes
    $content = $content -replace '(?m)^includes:\s*$', "includes:`r`n  - path: nonexistent/synthetic/path.md"
    Set-Content -LiteralPath $manifestPath -Value $content -Encoding UTF8
    $result = Invoke-CAScript -ScriptPath $script -ArgList @("-Json")
    Assert-True ($result.ExitCode -eq 1) "manifest path inconsistency should exit 1 (P0); got $($result.ExitCode)"
    Assert-True ($result.Output -match 'manifest_path_inconsistency') "expected manifest_path_inconsistency finding"
}
finally {
    Copy-Item -LiteralPath $manifestBak -Destination $manifestPath -Force
    Remove-Item -LiteralPath $manifestBak -Force
}

# (e) -Fix mode: synthesize a backup file, run with -Fix, assert it's deleted
$bakFile2 = Join-Path $repoRoot "ca-test-fix-$(Get-Random).bak"
Set-Content -LiteralPath $bakFile2 -Value "fix-test" -Encoding UTF8
try {
    $result = Invoke-CAScript -ScriptPath $script -ArgList @("-Fix")
    Assert-True (-not (Test-Path -LiteralPath $bakFile2)) "-Fix should have deleted the backup file at $bakFile2"
}
finally {
    if (Test-Path -LiteralPath $bakFile2) { Remove-Item -LiteralPath $bakFile2 -Force }
}

Write-Output "cleanup-audit-tests-ok"
