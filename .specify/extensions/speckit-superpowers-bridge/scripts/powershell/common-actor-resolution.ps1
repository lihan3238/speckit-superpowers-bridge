$ErrorActionPreference = "Stop"

function Get-BridgeRepoRoot {
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

function Resolve-BridgeActor {
    param(
        [string]$Argument = "",
        [string]$RepoRoot = ""
    )

    $valid = @("codex", "claude", "unknown")

    if (-not [string]::IsNullOrWhiteSpace($Argument)) {
        $arg = $Argument.Trim().ToLowerInvariant()
        if ($valid -contains $arg) { return $arg }
        return "unknown"
    }

    if (-not [string]::IsNullOrWhiteSpace($env:SPECKIT_BRIDGE_ACTOR)) {
        $envActor = $env:SPECKIT_BRIDGE_ACTOR.Trim().ToLowerInvariant()
        if ($valid -contains $envActor) { return $envActor }
    }

    if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
        $RepoRoot = Get-BridgeRepoRoot
    }

    $integrationPath = Join-Path $RepoRoot ".specify\integration.json"
    if (Test-Path -LiteralPath $integrationPath) {
        try {
            $state = Get-Content -LiteralPath $integrationPath -Raw | ConvertFrom-Json
            $default = if ($state.default_integration) { [string]$state.default_integration } elseif ($state.integration) { [string]$state.integration } else { "" }
            $default = $default.Trim().ToLowerInvariant()
            if ($valid -contains $default) { return $default }
        }
        catch {
            return "unknown"
        }
    }

    return "unknown"
}
