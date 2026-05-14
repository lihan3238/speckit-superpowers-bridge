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

$repoRoot = Get-RepoRoot
$extYaml = Join-Path $repoRoot ".specify\extensions.yml"
Assert-True (Test-Path -LiteralPath $extYaml) "extensions.yml missing"

# Parse hook commands (minimal YAML walker)
$hookCmds = @()
$inHooks = $false
foreach ($line in (Get-Content -LiteralPath $extYaml)) {
    if ($line -match '^\s*hooks:\s*$') { $inHooks = $true; continue }
    if ($inHooks -and $line -match '^\S') { $inHooks = $false }
    if ($inHooks -and $line -match '^\s*command:\s*(\S+)\s*$') {
        $hookCmds += $Matches[1]
    }
}
$hookCmds = @($hookCmds | Select-Object -Unique)
Assert-True ($hookCmds.Count -gt 0) "no hook commands parsed from extensions.yml"

$codex = @(Get-ChildItem -LiteralPath (Join-Path $repoRoot ".agents/skills") -Directory | ForEach-Object { $_.Name })
$claude = @(Get-ChildItem -LiteralPath (Join-Path $repoRoot ".claude/skills") -Directory | ForEach-Object { $_.Name })

$missing = New-Object System.Collections.Generic.List[string]
foreach ($cmd in $hookCmds) {
    $skillName = $cmd -replace '\.', '-'
    $isBridgeMeta = $cmd.StartsWith("speckit.superpowers.")
    if ($isBridgeMeta) {
        # The parent speckit-superpowers-bridge skill covers all bridge meta-commands.
        Assert-True ($codex -contains "speckit-superpowers-bridge") "Codex missing speckit-superpowers-bridge parent skill (covers $cmd)"
        Assert-True ($claude -contains "speckit-superpowers-bridge") "Claude missing speckit-superpowers-bridge parent skill (covers $cmd)"
        continue
    }
    if (-not ($codex -contains $skillName)) { $missing.Add("codex:$skillName ($cmd)") }
    if (-not ($claude -contains $skillName)) { $missing.Add("claude:$skillName ($cmd)") }
}

if ($missing.Count -gt 0) {
    foreach ($m in $missing) { Write-Output "  missing: $m" }
    throw "hook commands without a registered invocation surface on the listed agent"
}

Write-Output "hook-surface-resolution-tests-ok"
