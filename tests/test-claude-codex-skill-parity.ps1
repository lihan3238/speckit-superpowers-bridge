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

# T021: every .agents/skills/<id> must have a peer .claude/skills/<id> (and vice versa)
$codex = @(Get-ChildItem -LiteralPath (Join-Path $repoRoot ".agents/skills") -Directory | ForEach-Object { $_.Name })
$claude = @(Get-ChildItem -LiteralPath (Join-Path $repoRoot ".claude/skills") -Directory | ForEach-Object { $_.Name })

$missingOnClaude = @($codex | Where-Object { -not ($claude -contains $_) })
$missingOnCodex  = @($claude | Where-Object { -not ($codex -contains $_) })

if ($missingOnClaude.Count -gt 0) {
    foreach ($s in $missingOnClaude) {
        Write-Output ("  cp -r .agents/skills/" + $s + " .claude/skills/" + $s)
    }
    throw "Missing Claude peers: " + ($missingOnClaude -join ", ")
}
if ($missingOnCodex.Count -gt 0) {
    foreach ($s in $missingOnCodex) {
        Write-Output ("  cp -r .claude/skills/" + $s + " .agents/skills/" + $s)
    }
    throw "Missing Codex peers: " + ($missingOnCodex -join ", ")
}

Write-Output "claude-codex-skill-parity-tests-ok"
