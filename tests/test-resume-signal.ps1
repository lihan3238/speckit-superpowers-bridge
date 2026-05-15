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

function Assert-True { param([bool]$Condition, [string]$Message); if (-not $Condition) { throw $Message } }

$repoRoot = Get-RepoRoot
$script = Join-Path $repoRoot ".specify\extensions\speckit-superpowers-bridge\scripts\powershell\emit-resume-signal.ps1"
Assert-True (Test-Path -LiteralPath $script) "Missing emit-resume-signal.ps1."

$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("bridge-resume-signal-" + [guid]::NewGuid().ToString("N"))
try {
    New-Item -ItemType Directory -Force -Path (Join-Path $testRoot ".specify") | Out-Null
    $handoff = [ordered]@{
        schema_version = 3
        status = "executing"
        autonomous_mode = $true
        resume_context = [ordered]@{
            current_task_id = "T042"
            current_skill = "superpowers:test-driven-development"
            current_phase = "before-implementation-task"
            next_expected_action = "write failing test for T042"
        }
    }
    $handoff | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $testRoot ".specify\superpowers-handoff.json") -Encoding UTF8

    Push-Location $testRoot
    $line = (& $script | Select-Object -First 1)
    Pop-Location

    Assert-True ($line -match "T042") "Resume signal should contain active task id."
    Assert-True ($line -match "superpowers:test-driven-development") "Resume signal should contain active skill id."
    Assert-True ($line.Length -le 200) "Resume signal must stay within 200 characters."

    $codexSkill = Get-Content -LiteralPath (Join-Path $repoRoot ".agents\skills\speckit-superpowers-bridge\SKILL.md") -Raw
    $claudeSkill = Get-Content -LiteralPath (Join-Path $repoRoot ".claude\skills\speckit-superpowers-bridge\SKILL.md") -Raw
    foreach ($content in @($codexSkill, $claudeSkill)) {
        Assert-True ($content -match "Resume Signal") "Bridge skill should document resume signal."
        Assert-True ($content -match "Autonomous Mode") "Bridge skill should document autonomous mode."
        Assert-True ($content -match "task boundaries") "Bridge skill should define autonomous task-boundary behavior."
        Assert-True ($content -match "verification-before-completion") "Bridge skill should preserve review checkpoint wording."
        Assert-True ($content -match "update-handoff.ps1" -and $content -match "-ResumeContext") "Bridge skill should persist resume_context before Superpowers invocations."
    }
}
finally {
    if ((Get-Location).Path -eq $testRoot) { Pop-Location }
    if (Test-Path -LiteralPath $testRoot) { Remove-Item -LiteralPath $testRoot -Recurse -Force }
}

Write-Output "resume-signal-tests-ok"
