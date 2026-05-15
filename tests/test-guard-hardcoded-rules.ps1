$ErrorActionPreference = "Stop"

# Smoke test for the 5 hardcoded guard rules (FR-007 + research.md R3):
#   Rule 1: deny speckit.implement during executing handoff
#   Rule 2: deny superpowers:writing-plans / :brainstorming when active feature has spec.md + plan.md
#   Rule 3: deny speckit.constitution during executing handoff
#   Rule 4: allow any other speckit.*
#   Rule 5: default allow

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

function Get-AvailableFlavors {
    param([string]$BridgeRoot)
    $flavors = @()
    if (Test-Path -LiteralPath (Join-Path $BridgeRoot "scripts/powershell/guard-command.ps1")) { $flavors += "ps" }
    if (Test-Path -LiteralPath (Join-Path $BridgeRoot "scripts/bash/guard-command.sh")) { $flavors += "bash" }
    return $flavors
}

function Convert-ToBashPath {
    param([string]$Path)
    $normalized = $Path.Replace("\", "/")
    if ($normalized -match "^([A-Za-z]):/(.*)$") {
        return "/mnt/$($Matches[1].ToLowerInvariant())/$($Matches[2])"
    }
    return $normalized
}

function Invoke-Guard {
    param([string]$Flavor, [string]$Action)
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        if ($Flavor -eq "ps") {
            & $guardPsScript -Action $Action -Actor claude *> $null
        } else {
            if (-not (Get-Command bash -ErrorAction SilentlyContinue)) {
                Write-Output "  (bash flavor not exercised: bash not on PATH)"
                return 0
            }
            $bashPath = Convert-ToBashPath -Path $guardBashScript
            & bash $bashPath --action $Action --actor claude *> $null
        }
        return $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $prev
    }
}

$repoRoot = Get-RepoRoot
$bridgeRoot = Join-Path $repoRoot ".specify/extensions/speckit-superpowers-bridge"
$guardPsScript = Join-Path $bridgeRoot "scripts/powershell/guard-command.ps1"
$guardBashScript = Join-Path $bridgeRoot "scripts/bash/guard-command.sh"
$handoffPath = Join-Path $repoRoot ".specify/superpowers-handoff.json"
$flavors = @(Get-AvailableFlavors -BridgeRoot $bridgeRoot)
Assert-True ($flavors.Count -gt 0) "no guard-command flavors available"

# Snapshot current handoff
$backupContent = if (Test-Path -LiteralPath $handoffPath) { Get-Content -LiteralPath $handoffPath -Raw } else { $null }

try {
    foreach ($flavor in $flavors) {
        if ($flavor -eq "bash" -and -not (Get-Command bash -ErrorAction SilentlyContinue)) { continue }

        # Set handoff to executing on feature 006 (which has spec.md + plan.md present)
        $executingHandoff = @{
            schema_version = 1
            updated_at = (Get-Date).ToUniversalTime().ToString("o")
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
        } | ConvertTo-Json -Depth 5
        Set-Content -LiteralPath $handoffPath -Value $executingHandoff -Encoding UTF8

        # Rule 1: deny speckit.implement
        Assert-True ((Invoke-Guard $flavor "speckit.implement") -ne 0) "[$flavor] Rule 1: speckit.implement should be denied during executing"

        # Rule 2: deny superpowers:writing-plans (artifacts exist)
        Assert-True ((Invoke-Guard $flavor "superpowers:writing-plans") -ne 0) "[$flavor] Rule 2: superpowers:writing-plans should be denied with artifacts"
        Assert-True ((Invoke-Guard $flavor "superpowers:brainstorming") -ne 0) "[$flavor] Rule 2: superpowers:brainstorming should be denied with artifacts"

        # Rule 3: deny speckit.constitution
        Assert-True ((Invoke-Guard $flavor "speckit.constitution") -ne 0) "[$flavor] Rule 3: speckit.constitution should be denied during executing"

        # Rule 4: allow other speckit.*
        Assert-True ((Invoke-Guard $flavor "speckit.plan") -eq 0) "[$flavor] Rule 4: speckit.plan should be allowed"
        Assert-True ((Invoke-Guard $flavor "speckit.tasks") -eq 0) "[$flavor] Rule 4: speckit.tasks should be allowed"
        Assert-True ((Invoke-Guard $flavor "speckit.clarify") -eq 0) "[$flavor] Rule 4: speckit.clarify should be allowed"

        # Rule 5: default allow (unknown action)
        Assert-True ((Invoke-Guard $flavor "some.random.action") -eq 0) "[$flavor] Rule 5: unknown action should default-allow"
        Assert-True ((Invoke-Guard $flavor "superpowers:test-driven-development") -eq 0) "[$flavor] Rule 5: non-planning superpowers skills should be allowed"
    }

    Write-Output "guard-hardcoded-rules-tests-ok ($($flavors -join ', '))"
}
finally {
    if ($backupContent) {
        Set-Content -LiteralPath $handoffPath -Value $backupContent -Encoding UTF8 -NoNewline
    }
}
