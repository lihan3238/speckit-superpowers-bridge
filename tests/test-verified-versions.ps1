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
function Assert-Equals { param([object]$e, [object]$a, [string]$m); if ($e -ne $a) { throw "$m Expected '$e', got '$a'." } }

$repoRoot = Get-RepoRoot
$verifiedPath = Join-Path $repoRoot ".specify\extensions\speckit-superpowers-bridge\verified-versions.json"
$initPath = Join-Path $repoRoot ".specify\init-options.json"

Assert-True (Test-Path -LiteralPath $verifiedPath) "verified-versions.json missing"
$verified = Get-Content -LiteralPath $verifiedPath -Raw | ConvertFrom-Json
Assert-Equals 1 $verified.schema_version "verified-versions.json schema_version must be 1"
Assert-True (-not [string]::IsNullOrWhiteSpace([string]$verified.spec_kit_version)) "verified-versions.json missing spec_kit_version"
Assert-True ($verified.PSObject.Properties.Name -contains "superpowers_skills") "verified-versions.json missing superpowers_skills array"
Assert-True (@($verified.superpowers_skills).Count -gt 0) "verified-versions.json superpowers_skills must be non-empty"
foreach ($sk in @($verified.superpowers_skills)) {
    Assert-True (-not [string]::IsNullOrWhiteSpace([string]$sk.name)) "skill entry missing name"
    Assert-True (-not [string]::IsNullOrWhiteSpace([string]$sk.version)) "skill '$($sk.name)' missing version"
}
Assert-True (-not [string]::IsNullOrWhiteSpace([string]$verified.verified_at)) "verified-versions.json missing verified_at"
Assert-True (-not [string]::IsNullOrWhiteSpace([string]$verified.verified_by)) "verified-versions.json missing verified_by"

# Match installed Spec Kit version from init-options.json (if present)
if (Test-Path -LiteralPath $initPath) {
    $init = Get-Content -LiteralPath $initPath -Raw | ConvertFrom-Json
    $installed = [string]$init.speckit_version
    if (-not [string]::IsNullOrWhiteSpace($installed)) {
        Assert-Equals $installed ([string]$verified.spec_kit_version) "verified-versions.spec_kit_version must match init-options.speckit_version"
    }
}

Write-Output "verified-versions-tests-ok"
