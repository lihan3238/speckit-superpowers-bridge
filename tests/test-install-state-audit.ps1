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
$script = Join-Path $repoRoot ".specify\extensions\speckit-superpowers-bridge\scripts\powershell\audit-install-state.ps1"
Assert-True (Test-Path -LiteralPath $script) "Missing audit-install-state.ps1."

$json = & $script -Json -Actor codex | ConvertFrom-Json
Assert-True ($json.schema_version -eq 1) "Audit schema version mismatch."
Assert-True (-not [string]::IsNullOrWhiteSpace([string]$json.spec_kit.default_integration)) "Audit should report default integration."
Assert-True ($json.integrations.Count -ge 1) "Audit should report installed integrations."

$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("bridge-install-audit-" + [guid]::NewGuid().ToString("N"))
try {
    New-Item -ItemType Directory -Force -Path (Join-Path $testRoot ".specify\integrations") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $testRoot ".specify\extensions\git\commands") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $testRoot ".agents\skills\speckit-git-feature") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $testRoot ".claude\skills\speckit-superpowers-bridge") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $testRoot ".agents\skills\speckit-superpowers-bridge") | Out-Null
    Set-Content -LiteralPath (Join-Path $testRoot ".specify\integration.json") -Encoding UTF8 -Value '{ "version": "0.8.9", "default_integration": "codex", "installed_integrations": ["codex", "claude"] }'
    Set-Content -LiteralPath (Join-Path $testRoot ".specify\init-options.json") -Encoding UTF8 -Value '{ "script": "ps", "speckit_version": "0.8.9" }'
    Set-Content -LiteralPath (Join-Path $testRoot ".specify\integrations\codex.manifest.json") -Encoding UTF8 -Value '{}'
    Set-Content -LiteralPath (Join-Path $testRoot ".specify\integrations\claude.manifest.json") -Encoding UTF8 -Value '{}'
    Set-Content -LiteralPath (Join-Path $testRoot ".specify\extensions\git\extension.yml") -Encoding UTF8 -Value "extension:`n  version: 1.0.0"
    Set-Content -LiteralPath (Join-Path $testRoot ".specify\extensions\git\commands\speckit.git.feature.md") -Encoding UTF8 -Value "# git feature"
    Set-Content -LiteralPath (Join-Path $testRoot ".agents\skills\speckit-git-feature\SKILL.md") -Encoding UTF8 -Value "# codex peer only"
    Set-Content -LiteralPath (Join-Path $testRoot ".agents\skills\speckit-superpowers-bridge\SKILL.md") -Encoding UTF8 -Value "# A`n## One"
    Set-Content -LiteralPath (Join-Path $testRoot ".claude\skills\speckit-superpowers-bridge\SKILL.md") -Encoding UTF8 -Value "# B`n## One"

    Push-Location $testRoot
    $audit = & $script -Json | ConvertFrom-Json
    Pop-Location
    $missing = @($audit.findings | Where-Object { $_.code -eq "missing_per_agent_skill" })
    Assert-True ($missing.Count -ge 1) "Synthetic missing peer should be reported."
    Assert-True ([string]$missing[0].suggested_fix -match "specify integration upgrade") "Missing peer finding should include upgrade remediation."
}
finally {
    if ((Get-Location).Path -eq $testRoot) { Pop-Location }
    if (Test-Path -LiteralPath $testRoot) { Remove-Item -LiteralPath $testRoot -Recurse -Force }
}

Write-Output "install-state-audit-tests-ok"
