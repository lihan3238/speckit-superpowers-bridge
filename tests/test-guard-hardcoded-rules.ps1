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

function Invoke-Guard {
    param([string]$Action)
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & $guardScript -Action $Action -Actor claude *> $null
        return $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $prev
    }
}

$repoRoot = Get-RepoRoot
$guardScript = Join-Path $repoRoot ".specify/extensions/speckit-superpowers-bridge/scripts/powershell/guard-command.ps1"
$handoffPath = Join-Path $repoRoot ".specify/superpowers-handoff.json"

# Snapshot current handoff
$backupContent = if (Test-Path -LiteralPath $handoffPath) { Get-Content -LiteralPath $handoffPath -Raw } else { $null }

try {
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
    Assert-True ((Invoke-Guard "speckit.implement") -ne 0) "Rule 1: speckit.implement should be denied during executing"

    # Rule 2: deny superpowers:writing-plans (artifacts exist)
    Assert-True ((Invoke-Guard "superpowers:writing-plans") -ne 0) "Rule 2: superpowers:writing-plans should be denied with artifacts"
    Assert-True ((Invoke-Guard "superpowers:brainstorming") -ne 0) "Rule 2: superpowers:brainstorming should be denied with artifacts"

    # Rule 3: deny speckit.constitution
    Assert-True ((Invoke-Guard "speckit.constitution") -ne 0) "Rule 3: speckit.constitution should be denied during executing"

    # Rule 4: allow other speckit.*
    Assert-True ((Invoke-Guard "speckit.plan") -eq 0) "Rule 4: speckit.plan should be allowed"
    Assert-True ((Invoke-Guard "speckit.tasks") -eq 0) "Rule 4: speckit.tasks should be allowed"
    Assert-True ((Invoke-Guard "speckit.clarify") -eq 0) "Rule 4: speckit.clarify should be allowed"

    # Rule 5: default allow (unknown action)
    Assert-True ((Invoke-Guard "some.random.action") -eq 0) "Rule 5: unknown action should default-allow"
    Assert-True ((Invoke-Guard "superpowers:test-driven-development") -eq 0) "Rule 5: non-planning superpowers skills should be allowed"

    Write-Output "guard-hardcoded-rules-tests-ok"
}
finally {
    if ($backupContent) {
        Set-Content -LiteralPath $handoffPath -Value $backupContent -Encoding UTF8 -NoNewline
    }
}
