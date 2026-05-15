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

function Assert-True { param([bool]$Condition, [string]$Message); if (-not $Condition) { throw $Message } }

$repoRoot = Get-RepoRoot
$script = Join-Path $repoRoot ".specify\extensions\speckit-superpowers-bridge\scripts\powershell\check-distribution-manifest.ps1"
Assert-True (Test-Path -LiteralPath $script) "Missing check-distribution-manifest.ps1."

$report = & $script -Json | ConvertFrom-Json
Assert-True $report.passed "Distribution manifest should validate."
Assert-True (-not [string]::IsNullOrWhiteSpace($report.schema_path)) "Distribution manifest check should load the JSON Schema."

$invalidManifest = Join-Path ([System.IO.Path]::GetTempPath()) ("bridge-invalid-manifest-" + [guid]::NewGuid().ToString("N") + ".yml")
try {
    @"
schema_version: 1
includes:
  - path: README.md
excludes:
  - path: specs/**
"@ | Set-Content -LiteralPath $invalidManifest -Encoding UTF8
    $invalid = & $script -Json -ManifestPath $invalidManifest | ConvertFrom-Json
    Assert-True (-not $invalid.passed) "Manifest missing required exclude.reason should fail schema validation."
    Assert-True ((@($invalid.findings) -match "schema required exclude key missing: reason").Count -gt 0) "Schema finding should name the missing reason key."
}
finally {
    if (Test-Path -LiteralPath $invalidManifest) { Remove-Item -LiteralPath $invalidManifest -Force }
}

$installRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("bridge-install-target-" + [guid]::NewGuid().ToString("N"))
try {
    $sim = & $script -Json -SimulateInstall $installRoot | ConvertFrom-Json
    Assert-True $sim.passed "Simulated clean install should pass."
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $installRoot "specs"))) "Simulated install must not copy specs."
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $installRoot ".specify\bridge-events.jsonl"))) "Simulated install must not copy event log."

    New-Item -ItemType Directory -Force -Path (Join-Path $installRoot ".specify\extensions\speckit-superpowers-bridge") | Out-Null
    Set-Content -LiteralPath (Join-Path $installRoot ".specify\extensions\speckit-superpowers-bridge\extension.yml") -Encoding UTF8 -Value "user modified"
    & $script -SimulateInstall $installRoot | Out-Null
    $failed = ($LASTEXITCODE -ne 0)
    Assert-True $failed "Simulated reinstall must fail on user-modified target file."
}
finally {
    if (Test-Path -LiteralPath $installRoot) { Remove-Item -LiteralPath $installRoot -Recurse -Force }
}

Write-Output "distribution-manifest-tests-ok"
