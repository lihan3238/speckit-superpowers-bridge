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
        [string]$RepoRoot = ""  # accepted for backward call-site compat; ignored in v0.3.0 (3-step chain)
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

    return "unknown"
}
