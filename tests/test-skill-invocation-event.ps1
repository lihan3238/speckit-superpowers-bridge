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
$script = Join-Path $repoRoot ".specify\extensions\speckit-superpowers-bridge\scripts\powershell\emit-skill-invocation.ps1"
Assert-True (Test-Path -LiteralPath $script) "Missing emit-skill-invocation.ps1."

$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("bridge-skill-event-" + [guid]::NewGuid().ToString("N"))
try {
    New-Item -ItemType Directory -Force -Path (Join-Path $testRoot ".specify") | Out-Null
    Set-Content -LiteralPath (Join-Path $testRoot ".specify\superpowers-handoff.json") -Encoding UTF8 -Value (@{
        schema_version = 3
        status = "executing"
        feature_directory = "specs/001-event"
        last_snapshot_id = "snap-1"
    } | ConvertTo-Json -Depth 5)

    Push-Location $testRoot
    & $script -SkillId "superpowers:test-driven-development" -Phase "before-implementation-task" -TaskId "T024" -Actor codex -Decision invoked -Reason "red step" | Out-Null
    $event = Get-Content -LiteralPath ".specify\bridge-events.jsonl" -Raw | ConvertFrom-Json
    Assert-Equals "skill_invocation" $event.action "Skill invocation action mismatch."
    Assert-Equals "superpowers:test-driven-development" $event.skill_id "Skill id mismatch."
    Assert-Equals "before-implementation-task" $event.phase "Phase mismatch."
    Assert-Equals "T024" $event.task_id "Task id mismatch."
    Assert-Equals "codex" $event.actor "Actor mismatch."
    Assert-Equals "executing" $event.status "Status mismatch."
    Pop-Location

    Push-Location $testRoot
    $failed = $false
    try {
        & $script -SkillId "bad:test" -Phase "before-implementation-task" -Actor codex -Decision invoked | Out-Null
    }
    catch {
        $failed = $true
    }
    Assert-True $failed "Invalid skill id should fail."
    Pop-Location
}
finally {
    if ((Get-Location).Path -eq $testRoot) { Pop-Location }
    if (Test-Path -LiteralPath $testRoot) { Remove-Item -LiteralPath $testRoot -Recurse -Force }
}

Write-Output "skill-invocation-event-tests-ok"
