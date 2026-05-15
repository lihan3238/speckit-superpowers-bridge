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

function Assert-Equals {
    param([object]$Expected, [object]$Actual, [string]$Message)
    if ($Expected -ne $Actual) {
        throw "$Message Expected '$Expected', got '$Actual'."
    }
}

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

$repoRoot = Get-RepoRoot
$resolverPath = Join-Path $repoRoot ".specify\extensions\speckit-superpowers-bridge\scripts\powershell\common-actor-resolution.ps1"
Assert-True (Test-Path -LiteralPath $resolverPath) "Missing common-actor-resolution.ps1."
. $resolverPath

$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("bridge-actor-resolution-" + [guid]::NewGuid().ToString("N"))
$oldEnvActor = $env:SPECKIT_BRIDGE_ACTOR

try {
    New-Item -ItemType Directory -Force -Path (Join-Path $testRoot ".specify") | Out-Null
    Set-Content -LiteralPath (Join-Path $testRoot ".specify\integration.json") -Encoding UTF8 -Value (@{
        default_integration = "claude"
        installed_integrations = @("codex", "claude")
    } | ConvertTo-Json -Depth 5)

    $env:SPECKIT_BRIDGE_ACTOR = "codex"
    Assert-Equals "claude" (Resolve-BridgeActor -Argument "claude" -RepoRoot $testRoot) "Explicit actor should win over environment."
    Assert-Equals "codex" (Resolve-BridgeActor -Argument "" -RepoRoot $testRoot) "Environment actor should win over default integration."

    $env:SPECKIT_BRIDGE_ACTOR = ""
    Assert-Equals "claude" (Resolve-BridgeActor -Argument "" -RepoRoot $testRoot) "Default integration should be used when no arg/env is present."

    Remove-Item -LiteralPath (Join-Path $testRoot ".specify\integration.json") -Force
    Assert-Equals "unknown" (Resolve-BridgeActor -Argument "" -RepoRoot $testRoot) "Resolver should return deterministic fallback when no source is available."

    $featureDir = Join-Path $testRoot "specs\001-actor"
    New-Item -ItemType Directory -Force -Path (Join-Path $testRoot ".specify\memory") | Out-Null
    New-Item -ItemType Directory -Force -Path $featureDir | Out-Null
    Set-Content -LiteralPath (Join-Path $testRoot ".specify\memory\constitution.md") -Encoding UTF8 -Value "# Constitution"
    Set-Content -LiteralPath (Join-Path $testRoot ".specify\feature.json") -Encoding UTF8 -Value '{ "feature_directory": "specs/001-actor" }'
    Set-Content -LiteralPath (Join-Path $testRoot ".specify\integration.json") -Encoding UTF8 -Value '{ "default_integration": "claude", "installed_integrations": ["codex", "claude"] }'
    Set-Content -LiteralPath (Join-Path $featureDir "spec.md") -Encoding UTF8 -Value "# Spec"
    Set-Content -LiteralPath (Join-Path $featureDir "plan.md") -Encoding UTF8 -Value "# Plan"
    Set-Content -LiteralPath (Join-Path $featureDir "tasks.md") -Encoding UTF8 -Value "# Tasks"

    Push-Location $testRoot
    $env:SPECKIT_BRIDGE_ACTOR = "codex"
    & (Join-Path $repoRoot ".specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1") -Status ready | Out-Null
    $handoff = Get-Content -LiteralPath ".specify\superpowers-handoff.json" -Raw | ConvertFrom-Json
    Assert-Equals "codex" $handoff.artifact_owner "update-handoff.ps1 should record the resolved environment actor when -Actor is omitted."
    Pop-Location
}
finally {
    $env:SPECKIT_BRIDGE_ACTOR = $oldEnvActor
    if ((Get-Location).Path -eq $testRoot) { Pop-Location }
    if (Test-Path -LiteralPath $testRoot) { Remove-Item -LiteralPath $testRoot -Recurse -Force }
}

Write-Output "actor-resolution-tests-ok"
