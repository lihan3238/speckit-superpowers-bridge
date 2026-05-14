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
$verifiedPath = Join-Path $repoRoot ".specify\extensions\speckit-superpowers-bridge\verified-versions.json"
$parityScript = Join-Path $repoRoot ".specify\extensions\speckit-superpowers-bridge\scripts\powershell\parity-check.ps1"
$backupPath = "$verifiedPath.bak-parity-drift"

Assert-True (Test-Path -LiteralPath $verifiedPath) "verified-versions.json must exist for the drift test"
Assert-True (Test-Path -LiteralPath $parityScript) "parity-check.ps1 must exist for the drift test"

try {
    # Backup the live verified-versions.json
    Copy-Item -LiteralPath $verifiedPath -Destination $backupPath -Force

    # Mutate the pin
    $obj = Get-Content -LiteralPath $verifiedPath -Raw | ConvertFrom-Json
    $obj.spec_kit_version = "0.0.0-drift-synthetic"
    $obj | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $verifiedPath -Encoding UTF8

    # Run parity-check; expect a version_drift finding
    $output = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $parityScript -Json -Actor claude 2>&1
    $exit = $LASTEXITCODE
    Assert-True ($exit -eq 2) "expected parity-check to exit 2 (P1) after drift; got $exit"

    $combined = ($output -join [Environment]::NewLine)
    Assert-True ($combined -match "version_drift") "parity-check did not emit a version_drift finding"
    Assert-True ($combined -match "0\.0\.0-drift-synthetic") "parity-check output did not mention the synthetic drift value"
}
finally {
    # Always restore the original
    if (Test-Path -LiteralPath $backupPath) {
        Copy-Item -LiteralPath $backupPath -Destination $verifiedPath -Force
        Remove-Item -LiteralPath $backupPath -Force
    }
}

Write-Output "parity-drift-tests-ok"
