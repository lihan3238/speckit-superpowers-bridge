$ErrorActionPreference = "Stop"

# Tests for scripts/release/validate-release-readiness.ps1.
# These use synthetic repository roots so release-readiness regressions fail
# before a broken package reaches the Spec Kit community catalog.

function New-FakeRepo {
    param(
        [string]$Version = "9.9.9",
        [string]$ExtensionVersion = "9.9.9",
        [string]$CatalogVersion = "9.9.9",
        [string]$DownloadUrlVersion = "9.9.9",
        [string]$ExtensionId = "speckit-superpowers-bridge",
        [string]$CatalogId = "speckit-superpowers-bridge",
        [string]$CommandNamespace = "speckit.speckit-superpowers-bridge",
        [string]$HookNamespace = "speckit.speckit-superpowers-bridge",
        [bool]$ChangelogHasSection = $true,
        [int]$PowerShellCount = 6,
        [int]$BashCount = 6,
        [string]$GitAttributesContent = "*.sh text eol=lf`n*.ps1 text eol=crlf`n",
        [string]$WorkflowContent = "name: Release`nsteps:`n  - run: bash tests/run-all.sh`n",
        [bool]$IncludeVerifiedVersions = $true,
        [bool]$IncludeCodexRow = $true,
        [bool]$IncludeClaudeRow = $true,
        [bool]$IncludeArtifactSha = $true,
        [bool]$IncludePlatformRows = $true,
        [bool]$IncludeWorkflowEvidence = $true,
        [bool]$MarketplaceBodyHasVersion = $true,
        [bool]$CatalogHasCapabilityCounts = $true,
        [bool]$CatalogHasOfficialFields = $true,
        [bool]$MarketplaceRowHasVersion = $true,
        [bool]$MarketplaceBodyHasSupportMatrix = $true,
        [bool]$MarketplaceBodyHasValidationSummary = $true,
        [bool]$MarketplaceBodyHasOfficialSections = $true,
        [bool]$ReleaseRunbookUsesOfficialSubmission = $true
    )

    $root = Join-Path ([System.IO.Path]::GetTempPath()) "validate-release-test-$([Guid]::NewGuid().ToString('N').Substring(0,8))"
    $bridgeDir = Join-Path $root ".specify/extensions/speckit-superpowers-bridge"
    $cmdDir = Join-Path $bridgeDir "commands"
    $psDir = Join-Path $bridgeDir "scripts/powershell"
    $bashDir = Join-Path $bridgeDir "scripts/bash"
    $marketDir = Join-Path $root "marketplace"
    $workflowDir = Join-Path $root ".github/workflows"
    $docsDir = Join-Path $root "docs"
    New-Item -ItemType Directory -Force -Path $cmdDir, $psDir, $bashDir, $marketDir, $workflowDir, $docsDir | Out-Null

    @"
schema_version: "1.0"
extension:
  id: $ExtensionId
  name: "Superpowers Implementation Bridge"
  version: "$ExtensionVersion"
provides:
  commands:
    - name: $CommandNamespace.handoff
      file: commands/speckit.speckit-superpowers-bridge.handoff.md
    - name: $CommandNamespace.guard
      file: commands/speckit.speckit-superpowers-bridge.guard.md
    - name: $CommandNamespace.execute
      file: commands/speckit.speckit-superpowers-bridge.execute.md
hooks:
  before_plan:
    command: $HookNamespace.guard
  before_tasks:
    command: $HookNamespace.guard
  before_implement:
    command: $HookNamespace.guard
  after_tasks:
    command: $HookNamespace.handoff
"@ | Set-Content -LiteralPath (Join-Path $bridgeDir "extension.yml") -Encoding UTF8

    foreach ($cmd in @("handoff", "guard", "execute")) {
        Set-Content -LiteralPath (Join-Path $cmdDir "speckit.speckit-superpowers-bridge.$cmd.md") -Value "# $cmd" -Encoding UTF8
    }

    $stems = @("auto-archive-handoff", "bridge-state", "bridge-status", "common-actor-resolution", "guard-command", "update-handoff")
    foreach ($stem in ($stems | Select-Object -First $PowerShellCount)) {
        Set-Content -LiteralPath (Join-Path $psDir "$stem.ps1") -Value "# fake ps" -Encoding UTF8
    }
    foreach ($stem in ($stems | Select-Object -First $BashCount)) {
        Set-Content -LiteralPath (Join-Path $bashDir "$stem.sh") -Value "#!/usr/bin/env bash`n" -Encoding UTF8
    }

    $url = "https://github.com/lihan3238/speckit-superpowers-bridge/releases/download/v$DownloadUrlVersion/speckit-superpowers-bridge-v$DownloadUrlVersion.zip"
    $catalogProvides = if ($CatalogHasCapabilityCounts) {
        '  "provides": { "commands": 3, "hooks": 5 }'
    } else {
        '  "provides": { "commands": 2, "hooks": 5 }'
    }
    $catalogOfficialFields = if ($CatalogHasOfficialFields) {
        @"
,
  "verified": false,
  "downloads": 0,
  "stars": 0,
  "created_at": "2026-05-15T00:00:00Z",
  "updated_at": "2026-06-04T00:00:00Z"
"@
    } else {
        ""
    }
    @"
{
  "id": "$CatalogId",
  "description": "Thin orchestrator between Spec Kit and Superpowers.",
  "version": "$CatalogVersion",
  "download_url": "$url",
$catalogProvides,
  "tags": ["bridge", "superpowers", "cross-agent", "tdd", "workflow"]$catalogOfficialFields
}
"@ | Set-Content -LiteralPath (Join-Path $marketDir "catalog-entry.json") -Encoding UTF8
    $rowDescription = if ($MarketplaceRowHasVersion) {
        "Thin $Version bridge from Spec Kit to Superpowers; verified on Linux bash, Windows PowerShell, Codex, and Claude Code."
    } else {
        "Thin orchestrator between Spec Kit and Superpowers."
    }
    Set-Content -LiteralPath (Join-Path $marketDir "extensions-readme-row.md") -Value "| Superpowers Implementation Bridge | $rowDescription | `process` | Read+Write | [speckit-superpowers-bridge](https://github.com/lihan3238/speckit-superpowers-bridge) |" -Encoding UTF8
    $bodyVersion = if ($MarketplaceBodyHasVersion) { $Version } else { "0.0.1" }
    $supportMatrix = if ($MarketplaceBodyHasSupportMatrix) {
        @"

### Support Matrix

| Target | Result |
|---|---|
| Linux bash | PASS |
| Windows PowerShell 5.1+ | PASS |
| Codex | PASS |
| Claude Code | PASS |
"@
    } else {
        ""
    }
    $validationSummary = if ($MarketplaceBodyHasValidationSummary) {
        @"

### Release Validation Summary

- validate-release-readiness.ps1 -Version $Version passes.
- bash tests/run-all.sh passes.
- tests/test-release-powershell.ps1 passes.
"@
    } else {
        ""
    }
    $officialSections = if ($MarketplaceBodyHasOfficialSections) {
        @"

### Testing Checklist

- [x] Extension installs successfully via download URL.

### Submission Requirements

- [x] Valid extension.yml manifest included.

### Testing Details

Synthetic fixture passed.

### Example Usage

`$speckit-superpowers-bridge`

### Proposed Catalog Entry

{
  "speckit-superpowers-bridge": {
    "version": "$Version",
    "verified": false,
    "created_at": "2026-05-15T00:00:00Z",
    "updated_at": "2026-06-04T00:00:00Z"
  }
}
"@
    } else {
        ""
    }
    @"
# Extension Submission: Superpowers Implementation Bridge

### Version

$bodyVersion

### Download URL

https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip

### Number of Commands

3

### Number of Hooks

5
$supportMatrix
$validationSummary
$officialSections
"@ | Set-Content -LiteralPath (Join-Path $marketDir "extension-submission-body.md") -Encoding UTF8

    $changelog = if ($ChangelogHasSection) { "# Changelog`n`n## [$Version] - 2026-06-04`n`n- placeholder" } else { "# Changelog`n`n## [0.0.1] - 2026-01-01`n`n- nothing relevant" }
    Set-Content -LiteralPath (Join-Path $root "CHANGELOG.md") -Value $changelog -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root ".gitattributes") -Value $GitAttributesContent -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $workflowDir "release.yml") -Value $WorkflowContent -Encoding UTF8
    $runbookText = if ($ReleaseRunbookUsesOfficialSubmission) {
        "# Release Runbook`n`n## Step 16 - Submit upstream catalog update`n`nUse the official Extension Submission issue template. Do not open a direct pull request that edits extensions/catalog.community.json.`n"
    } else {
        "# Release Runbook`n`n## Step 16 - Submit upstream PR`n`nPaste into extensions/catalog.community.json and open a PR.`n"
    }
    Set-Content -LiteralPath (Join-Path $docsDir "release-runbook.md") -Value $runbookText -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root "README.md") -Value "# README`n" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root "README.zh-CN.md") -Value "# README zh`n" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root "LICENSE") -Value "MIT`n" -Encoding UTF8
    $verificationDir = Join-Path $root "specs/013-v1-0-release-hardening"
    New-Item -ItemType Directory -Force -Path $verificationDir | Out-Null
    $agentRows = @()
    if ($IncludeCodexRow) { $agentRows += "| Codex | 0.137.0 | Linux bash | sandbox only | status, guard, handoff | PASS | evidence | synthetic |" }
    if ($IncludeClaudeRow) { $agentRows += "| Claude Code | 2.1.162 | Linux bash | sandbox only | status, guard, handoff | PASS | evidence | synthetic |" }
    $artifactSha = if ($IncludeArtifactSha) { "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef" } else { "Pending" }
    $platformRows = @()
    if ($IncludePlatformRows) {
        $platformRows += "| Linux bash | synthetic | sh | ZIP | PASS | PASS | PASS | PASS | synthetic |"
        $platformRows += "| Windows PowerShell | synthetic | ps | ZIP | PASS | PASS | PASS | PASS | synthetic |"
    }
    $workflowEvidence = if ($IncludeWorkflowEvidence) { "| Release workflow inventory | release.yml | PASS | synthetic |" } else { "" }
    @"
# Verification

## Artifact

- Version: $Version
- SHA256: $artifactSha

## Platform Matrix

| Platform | Environment | Script flavor | Install source | Smoke | Sandbox cycle | Readiness | Result | Notes |
|---|---|---|---|---|---|---|---|---|
$($platformRows -join "`n")

## Agent Matrix

| Agent | Version | Platform | Prompt boundary | Operations exercised | Result | Evidence | Notes |
|---|---|---|---|---|---|---|---|
$($agentRows -join "`n")

## Known Blockers and Deferrals

- None for synthetic fixture.

## US2 Platform Gate Evidence

| Check | Command or inspection | Result | Notes |
|---|---|---|---|
$workflowEvidence
"@ | Set-Content -LiteralPath (Join-Path $verificationDir "verification.md") -Encoding UTF8

    if ($IncludeVerifiedVersions) {
        @"
{
  "verified_at": "2026-06-04T00:00:00Z",
  "spec_kit_version": "0.9.3",
  "superpowers_version": "5.1.0",
  "codex_cli_version": "0.137.0",
  "claude_code_version": "2.1.162",
  "bridge_version": "$Version",
  "platforms": []
}
"@ | Set-Content -LiteralPath (Join-Path $bridgeDir "verified-versions.json") -Encoding UTF8
    }

    return $root
}

function New-FakePackageZip {
    param(
        [string]$RepoRoot,
        [bool]$IncludePowerShell = $true,
        [bool]$IncludeBash = $true
    )

    $stage = Join-Path ([System.IO.Path]::GetTempPath()) "validate-release-zip-$([Guid]::NewGuid().ToString('N').Substring(0,8))"
    New-Item -ItemType Directory -Force -Path $stage | Out-Null
    Copy-Item -LiteralPath (Join-Path $RepoRoot ".specify/extensions/speckit-superpowers-bridge/extension.yml") -Destination $stage
    Copy-Item -LiteralPath (Join-Path $RepoRoot ".specify/extensions/speckit-superpowers-bridge/verified-versions.json") -Destination $stage
    Copy-Item -Recurse -LiteralPath (Join-Path $RepoRoot ".specify/extensions/speckit-superpowers-bridge/commands") -Destination (Join-Path $stage "commands")
    New-Item -ItemType Directory -Force -Path (Join-Path $stage "scripts") | Out-Null
    if ($IncludeBash) {
        Copy-Item -Recurse -LiteralPath (Join-Path $RepoRoot ".specify/extensions/speckit-superpowers-bridge/scripts/bash") -Destination (Join-Path $stage "scripts/bash")
    }
    if ($IncludePowerShell) {
        Copy-Item -Recurse -LiteralPath (Join-Path $RepoRoot ".specify/extensions/speckit-superpowers-bridge/scripts/powershell") -Destination (Join-Path $stage "scripts/powershell")
    }
    foreach ($name in @("README.md", "README.zh-CN.md", "LICENSE", "CHANGELOG.md", ".gitattributes")) {
        Copy-Item -LiteralPath (Join-Path $RepoRoot $name) -Destination $stage
    }

    $zip = Join-Path ([System.IO.Path]::GetTempPath()) "speckit-superpowers-bridge-test-$([Guid]::NewGuid().ToString('N').Substring(0,8)).zip"
    Compress-Archive -Path (Join-Path $stage "*") -DestinationPath $zip -Force
    Remove-Item -Recurse -Force -LiteralPath $stage
    return $zip
}

function Invoke-Validator {
    param([string]$RepoRoot, [string]$Version, [string]$PackageZip = "")
    $validator = Join-Path $PSScriptRoot "validate-release-readiness.ps1"
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        if ([string]::IsNullOrWhiteSpace($PackageZip)) {
            $output = & $validator -Version $Version -RepoRoot $RepoRoot 2>&1 | Out-String
        } else {
            $output = & $validator -Version $Version -RepoRoot $RepoRoot -PackageZip $PackageZip 2>&1 | Out-String
        }
        return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = $output }
    } finally {
        $ErrorActionPreference = $prev
    }
}

$targetVersion = "9.9.9"
$cases = @(
    @{
        Name = "all aligned -> exit 0"
        Repo = { New-FakeRepo -Version $targetVersion }
        ExpectFail = $false
        ExpectsInOutput = @()
    },
    @{
        Name = "extension.yml version mismatch -> fail naming extension.yml"
        Repo = { New-FakeRepo -Version $targetVersion -ExtensionVersion "1.0.0" }
        ExpectFail = $true
        ExpectsInOutput = @("extension.yml")
    },
    @{
        Name = "catalog-entry version mismatch -> fail naming catalog-entry"
        Repo = { New-FakeRepo -Version $targetVersion -CatalogVersion "1.0.0" }
        ExpectFail = $true
        ExpectsInOutput = @("catalog-entry.json")
    },
    @{
        Name = "download_url version mismatch -> fail naming download_url"
        Repo = { New-FakeRepo -Version $targetVersion -DownloadUrlVersion "1.0.0" }
        ExpectFail = $true
        ExpectsInOutput = @("download_url")
    },
    @{
        Name = "missing CHANGELOG section -> fail naming CHANGELOG"
        Repo = { New-FakeRepo -Version $targetVersion -ChangelogHasSection $false }
        ExpectFail = $true
        ExpectsInOutput = @("CHANGELOG")
    },
    @{
        Name = "bash/ps file-count mismatch -> fail naming file-count parity"
        Repo = { New-FakeRepo -Version $targetVersion -BashCount 5 -PowerShellCount 6 }
        ExpectFail = $true
        ExpectsInOutput = @("file-count parity")
    },
    @{
        Name = "missing .gitattributes rules -> fail naming .gitattributes"
        Repo = { New-FakeRepo -Version $targetVersion -GitAttributesContent "*.md text`n" }
        ExpectFail = $true
        ExpectsInOutput = @(".gitattributes")
    },
    @{
        Name = "catalog id mismatch -> fail naming catalog id"
        Repo = { New-FakeRepo -Version $targetVersion -CatalogId "wrong-bridge" }
        ExpectFail = $true
        ExpectsInOutput = @("catalog-entry.json", "id")
    },
    @{
        Name = "command namespace mismatch -> fail naming command namespace"
        Repo = { New-FakeRepo -Version $targetVersion -CommandNamespace "speckit.wrong-bridge" }
        ExpectFail = $true
        ExpectsInOutput = @("command namespace")
    },
    @{
        Name = "hook namespace mismatch -> fail naming hook namespace"
        Repo = { New-FakeRepo -Version $targetVersion -HookNamespace "speckit.wrong-bridge" }
        ExpectFail = $true
        ExpectsInOutput = @("hook namespace")
    },
    @{
        Name = "release workflow references nonexistent ps tests -> fail naming workflow"
        Repo = { New-FakeRepo -Version $targetVersion -WorkflowContent "name: Release`nsteps:`n  - shell: pwsh`n    run: Get-ChildItem tests/*.ps1`n" }
        ExpectFail = $true
        ExpectsInOutput = @("release.yml", "tests/*.ps1")
    },
    @{
        Name = "release runbook direct catalog PR -> fail naming official template"
        Repo = { New-FakeRepo -Version $targetVersion -ReleaseRunbookUsesOfficialSubmission $false }
        ExpectFail = $true
        ExpectsInOutput = @("docs/release-runbook.md", "Extension Submission")
    },
    @{
        Name = "missing package PowerShell flavor -> fail naming package scripts/powershell"
        Repo = { New-FakeRepo -Version $targetVersion }
        Package = { param($repo) New-FakePackageZip -RepoRoot $repo -IncludePowerShell $false -IncludeBash $true }
        ExpectFail = $true
        ExpectsInOutput = @("Package ZIP", "scripts/powershell")
    },
    @{
        Name = "missing Codex verification row -> fail naming Codex"
        Repo = { New-FakeRepo -Version $targetVersion -IncludeCodexRow $false }
        ExpectFail = $true
        ExpectsInOutput = @("verification.md", "Codex")
    },
    @{
        Name = "missing Claude verification row -> fail naming Claude"
        Repo = { New-FakeRepo -Version $targetVersion -IncludeClaudeRow $false }
        ExpectFail = $true
        ExpectsInOutput = @("verification.md", "Claude")
    },
    @{
        Name = "marketplace submission body stale version -> fail naming marketplace"
        Repo = { New-FakeRepo -Version $targetVersion -MarketplaceBodyHasVersion $false }
        ExpectFail = $true
        ExpectsInOutput = @("extension-submission-body.md", $targetVersion)
    },
    @{
        Name = "catalog capability counts mismatch -> fail naming provides"
        Repo = { New-FakeRepo -Version $targetVersion -CatalogHasCapabilityCounts $false }
        ExpectFail = $true
        ExpectsInOutput = @("catalog-entry.json", "provides")
    },
    @{
        Name = "catalog missing official fields -> fail naming official catalog field"
        Repo = { New-FakeRepo -Version $targetVersion -CatalogHasOfficialFields $false }
        ExpectFail = $true
        ExpectsInOutput = @("catalog-entry.json", "official catalog field")
    },
    @{
        Name = "marketplace row lacks support summary -> fail naming extensions row"
        Repo = { New-FakeRepo -Version $targetVersion -MarketplaceRowHasVersion $false }
        ExpectFail = $true
        ExpectsInOutput = @("extensions-readme-row.md", $targetVersion)
    },
    @{
        Name = "marketplace body lacks support matrix -> fail naming support matrix"
        Repo = { New-FakeRepo -Version $targetVersion -MarketplaceBodyHasSupportMatrix $false }
        ExpectFail = $true
        ExpectsInOutput = @("extension-submission-body.md", "Support Matrix")
    },
    @{
        Name = "marketplace body lacks validation summary -> fail naming validation summary"
        Repo = { New-FakeRepo -Version $targetVersion -MarketplaceBodyHasValidationSummary $false }
        ExpectFail = $true
        ExpectsInOutput = @("extension-submission-body.md", "Release Validation Summary")
    },
    @{
        Name = "marketplace body lacks official sections -> fail naming official section"
        Repo = { New-FakeRepo -Version $targetVersion -MarketplaceBodyHasOfficialSections $false }
        ExpectFail = $true
        ExpectsInOutput = @("extension-submission-body.md", "Testing Checklist")
    },
    @{
        Name = "missing artifact SHA -> fail naming SHA256"
        Repo = { New-FakeRepo -Version $targetVersion -IncludeArtifactSha $false }
        ExpectFail = $true
        ExpectsInOutput = @("verification.md", "SHA256")
    },
    @{
        Name = "missing platform rows -> fail naming platform"
        Repo = { New-FakeRepo -Version $targetVersion -IncludePlatformRows $false }
        ExpectFail = $true
        ExpectsInOutput = @("verification.md", "platform")
    },
    @{
        Name = "missing workflow evidence -> fail naming workflow evidence"
        Repo = { New-FakeRepo -Version $targetVersion -IncludeWorkflowEvidence $false }
        ExpectFail = $true
        ExpectsInOutput = @("verification.md", "Release workflow")
    }
)

$failed = 0
foreach ($c in $cases) {
    $repo = & $c.Repo
    $zip = ""
    try {
        if ($c.ContainsKey("Package")) {
            $zip = & $c.Package $repo
        }
        $r = Invoke-Validator -RepoRoot $repo -Version $targetVersion -PackageZip $zip
        $passedExit = if ($c.ExpectFail) { $r.ExitCode -ne 0 } else { $r.ExitCode -eq 0 }
        $passedOutput = $true
        foreach ($needle in $c.ExpectsInOutput) {
            if ($r.Output -notmatch [regex]::Escape($needle)) {
                $passedOutput = $false
                break
            }
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
        if (-not [string]::IsNullOrWhiteSpace($zip)) {
            Remove-Item -Force -LiteralPath $zip -ErrorAction SilentlyContinue
        }
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
