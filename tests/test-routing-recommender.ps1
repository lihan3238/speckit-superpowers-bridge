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

function Assert-Equals { param([object]$Expected, [object]$Actual, [string]$Message); if ($Expected -ne $Actual) { throw "$Message Expected '$Expected', got '$Actual'." } }
function Assert-True { param([bool]$Condition, [string]$Message); if (-not $Condition) { throw $Message } }

$repoRoot = Get-RepoRoot
$script = Join-Path $repoRoot ".specify\extensions\speckit-superpowers-bridge\scripts\powershell\recommend-route.ps1"
Assert-True (Test-Path -LiteralPath $script) "Missing recommend-route.ps1."

$cases = @(
    @{ description = "fix the typo in README"; expected = "direct-superpowers" },
    @{ description = "rename a variable"; expected = "direct-superpowers" },
    @{ description = "design a new auth module with OAuth2"; expected = "full-pipeline" },
    @{ description = "rewrite the routing architecture"; expected = "full-pipeline" },
    @{ description = ""; expected = "no-recommendation" }
)

foreach ($case in $cases) {
    $result = & $script -Description $case.description -Json | ConvertFrom-Json
    Assert-Equals $case.expected $result.recommendation "Unexpected recommendation for '$($case.description)'."
}

$noDescription = & $script -Json | ConvertFrom-Json
Assert-Equals "no-recommendation" $noDescription.recommendation "Hook execution without a provided description must fail open."

$previousDescription = $env:SPECKIT_FEATURE_DESCRIPTION
try {
    $env:SPECKIT_FEATURE_DESCRIPTION = "fix README typo"
    $fromEnv = & $script -Json | ConvertFrom-Json
    Assert-Equals "direct-superpowers" $fromEnv.recommendation "Hook execution should use SPECKIT_FEATURE_DESCRIPTION when available."
}
finally {
    $env:SPECKIT_FEATURE_DESCRIPTION = $previousDescription
}

$extensions = Get-Content -LiteralPath (Join-Path $repoRoot ".specify\extensions.yml") -Raw
Assert-True ($extensions -match "before_specify") "extensions.yml should include before_specify hook."
Assert-True ($extensions -match "speckit.speckit-superpowers-bridge.recommend-route") "before_specify should surface recommend-route."

Write-Output "routing-recommender-tests-ok"
