$ErrorActionPreference = "Stop"

# Tests for scripts/release/validate-release-readiness.ps1
#
# Seven assertions over a synthetic repo dir:
#  1. All four cross-references aligned -> exit 0
#  2. extension.yml version mismatch     -> non-zero + names the file
#  3. catalog-entry.json version mismatch -> non-zero + names the file
#  4. catalog-entry.json download_url missing version -> non-zero + names download_url
#  5. CHANGELOG missing the version section -> non-zero + names CHANGELOG
#  6. Bash / PowerShell file-count mismatch -> non-zero + names file-count parity
#  7. Missing .gitattributes sh LF rule -> non-zero + names .gitattributes

function New-FakeRepo {
    param(
        [string]$Version,
        [string]$CatalogVersion,
        [string]$DownloadUrlVersion,
        [bool]$ChangelogHasSection,
        [int]$PowerShellCount = 4,
        [int]$BashCount = 4,
        [string]$GitAttributesContent = "*.sh text eol=lf`n"
    )

    $root = Join-Path ([System.IO.Path]::GetTempPath()) "validate-release-test-$([Guid]::NewGuid().ToString('N').Substring(0,8))"
    $bridgeDir = Join-Path $root ".specify/extensions/speckit-superpowers-bridge"
    $psDir = Join-Path $bridgeDir "scripts/powershell"
    $bashDir = Join-Path $bridgeDir "scripts/bash"
    $marketDir = Join-Path $root "marketplace"
    New-Item -ItemType Directory -Force -Path $bridgeDir | Out-Null
    New-Item -ItemType Directory -Force -Path $psDir | Out-Null
    New-Item -ItemType Directory -Force -Path $bashDir | Out-Null
    New-Item -ItemType Directory -Force -Path $marketDir | Out-Null

    @"
schema_version: "1.0"
extension:
  id: speckit-superpowers-bridge
  name: "Superpowers Implementation Bridge"
  version: "$Version"
"@ | Set-Content -LiteralPath (Join-Path $bridgeDir "extension.yml") -Encoding UTF8

    $stems = @("auto-archive-handoff", "common-actor-resolution", "guard-command", "update-handoff")
    foreach ($stem in ($stems | Select-Object -First $PowerShellCount)) {
        Set-Content -LiteralPath (Join-Path $psDir "$stem.ps1") -Value "# fake ps" -Encoding UTF8
    }
    foreach ($stem in ($stems | Select-Object -First $BashCount)) {
        Set-Content -LiteralPath (Join-Path $bashDir "$stem.sh") -Value "#!/usr/bin/env bash`n" -Encoding UTF8
    }

    $url = "https://github.com/lihan3238/speckit-superpowers-bridge/releases/download/v$DownloadUrlVersion/speckit-superpowers-bridge-v$DownloadUrlVersion.zip"
    @"
{
  "id": "speckit-superpowers-bridge",
  "version": "$CatalogVersion",
  "download_url": "$url"
}
"@ | Set-Content -LiteralPath (Join-Path $marketDir "catalog-entry.json") -Encoding UTF8

    $changelog = if ($ChangelogHasSection) { "# Changelog`n`n## [$Version] - 2026-05-15`n`n- placeholder" } else { "# Changelog`n`n## [0.0.1] - 2026-01-01`n`n- nothing relevant" }
    Set-Content -LiteralPath (Join-Path $root "CHANGELOG.md") -Value $changelog -Encoding UTF8

    Set-Content -LiteralPath (Join-Path $root ".gitattributes") -Value $GitAttributesContent -Encoding UTF8

    return $root
}

function Invoke-Validator {
    param([string]$RepoRoot, [string]$Version)
    $validator = Join-Path $PSScriptRoot "validate-release-readiness.ps1"
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = & $validator -Version $Version -RepoRoot $RepoRoot 2>&1 | Out-String
        return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = $output }
    } finally {
        $ErrorActionPreference = $prev
    }
}

function Assert-True { param([bool]$c, [string]$m); if (-not $c) { throw $m } }

$cases = @(
    @{ Name = "all aligned -> exit 0"; ExtVer = "9.9.9"; CatVer = "9.9.9"; UrlVer = "9.9.9"; ChangelogOk = $true; PsCount = 4; BashCount = 4; GitAttrs = "*.sh text eol=lf`n"; ExpectFail = $false; ExpectsInOutput = @() }
    @{ Name = "extension.yml version mismatch -> fail naming extension.yml"; ExtVer = "1.0.0"; CatVer = "9.9.9"; UrlVer = "9.9.9"; ChangelogOk = $true; PsCount = 4; BashCount = 4; GitAttrs = "*.sh text eol=lf`n"; ExpectFail = $true; ExpectsInOutput = @("extension.yml") }
    @{ Name = "catalog-entry version mismatch -> fail naming catalog-entry"; ExtVer = "9.9.9"; CatVer = "1.0.0"; UrlVer = "9.9.9"; ChangelogOk = $true; PsCount = 4; BashCount = 4; GitAttrs = "*.sh text eol=lf`n"; ExpectFail = $true; ExpectsInOutput = @("catalog-entry.json") }
    @{ Name = "download_url version mismatch -> fail naming download_url"; ExtVer = "9.9.9"; CatVer = "9.9.9"; UrlVer = "1.0.0"; ChangelogOk = $true; PsCount = 4; BashCount = 4; GitAttrs = "*.sh text eol=lf`n"; ExpectFail = $true; ExpectsInOutput = @("download_url") }
    @{ Name = "missing CHANGELOG section -> fail naming CHANGELOG"; ExtVer = "9.9.9"; CatVer = "9.9.9"; UrlVer = "9.9.9"; ChangelogOk = $false; PsCount = 4; BashCount = 4; GitAttrs = "*.sh text eol=lf`n"; ExpectFail = $true; ExpectsInOutput = @("CHANGELOG") }
    @{ Name = "bash/ps file-count mismatch -> fail naming file-count parity"; ExtVer = "9.9.9"; CatVer = "9.9.9"; UrlVer = "9.9.9"; ChangelogOk = $true; PsCount = 4; BashCount = 3; GitAttrs = "*.sh text eol=lf`n"; ExpectFail = $true; ExpectsInOutput = @("file-count parity") }
    @{ Name = "missing .gitattributes sh lf rule -> fail naming .gitattributes"; ExtVer = "9.9.9"; CatVer = "9.9.9"; UrlVer = "9.9.9"; ChangelogOk = $true; PsCount = 4; BashCount = 4; GitAttrs = "*.md text`n"; ExpectFail = $true; ExpectsInOutput = @(".gitattributes") }
)

$failed = 0
foreach ($c in $cases) {
    $repo = New-FakeRepo -Version $c.ExtVer -CatalogVersion $c.CatVer -DownloadUrlVersion $c.UrlVer -ChangelogHasSection $c.ChangelogOk -PowerShellCount $c.PsCount -BashCount $c.BashCount -GitAttributesContent $c.GitAttrs
    try {
        $r = Invoke-Validator -RepoRoot $repo -Version "9.9.9"
        $passedExit = if ($c.ExpectFail) { $r.ExitCode -ne 0 } else { $r.ExitCode -eq 0 }
        $passedOutput = $true
        foreach ($needle in $c.ExpectsInOutput) {
            if ($r.Output -notmatch [regex]::Escape($needle)) { $passedOutput = $false; break }
        }
        if ($passedExit -and $passedOutput) {
            Write-Output "  ok: $($c.Name)"
        } else {
            Write-Output "FAIL: $($c.Name)"
            Write-Output "      exit=$($r.ExitCode) expectFail=$($c.ExpectFail)"
            Write-Output "      output: $($r.Output.Trim())"
            $failed++
        }
    } finally {
        Remove-Item -Recurse -Force -LiteralPath $repo -ErrorAction SilentlyContinue
    }
}

if ($failed -gt 0) {
    Write-Output ""
    Write-Output "$failed case(s) failed."
    exit 1
}
Write-Output ""
Write-Output "validate-release-readiness-tests-ok"
exit 0
