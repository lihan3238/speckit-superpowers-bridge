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
$script = Join-Path $repoRoot ".specify\extensions\speckit-superpowers-bridge\scripts\powershell\validation-pass.ps1"
$emit = Join-Path $repoRoot ".specify\extensions\speckit-superpowers-bridge\scripts\powershell\emit-skill-invocation.ps1"
$eventsPath = Join-Path $repoRoot ".specify\bridge-events.jsonl"
Assert-True (Test-Path -LiteralPath $script) "Missing validation-pass.ps1."
Assert-True (Test-Path -LiteralPath $emit) "Missing emit-skill-invocation.ps1."

$originalEvents = if (Test-Path -LiteralPath $eventsPath) { Get-Content -LiteralPath $eventsPath -Raw } else { $null }
try {
    & $emit -SkillId "superpowers:test-driven-development" -Phase "before-implementation-task" -TaskId "T001" -Actor codex -Decision invoked -Reason "validation test seed" | Out-Null
    & $emit -SkillId "superpowers:verification-before-completion" -Phase "before-phase-completion" -Actor codex -Decision invoked -Reason "validation test seed" | Out-Null
    & $emit -SkillId "superpowers:finishing-a-development-branch" -Phase "before-feature-completion" -Actor codex -Decision invoked -Reason "validation test seed" | Out-Null

    $report = & $script -Json -Actor codex | ConvertFrom-Json
    Assert-True ($report.schema_version -eq 1) "Validation report schema mismatch."
    Assert-True ($report.steps.Count -ge 10) "Validation should report ordered steps."

    $second = & $script -Json -Actor codex | ConvertFrom-Json
    Assert-True ($second.findings.Count -eq $report.findings.Count) "Repeated validation should be stable."

    $codexSkill = Get-Content -LiteralPath (Join-Path $repoRoot ".agents\skills\speckit-superpowers-bridge\SKILL.md") -Raw
    $claudeSkill = Get-Content -LiteralPath (Join-Path $repoRoot ".claude\skills\speckit-superpowers-bridge\SKILL.md") -Raw
    foreach ($skillId in @(
        "superpowers:test-driven-development",
        "superpowers:systematic-debugging",
        "superpowers:verification-before-completion",
        "superpowers:requesting-code-review",
        "superpowers:finishing-a-development-branch"
    )) {
        Assert-True ($codexSkill -match [regex]::Escape($skillId)) "Codex bridge skill missing $skillId."
        Assert-True ($claudeSkill -match [regex]::Escape($skillId)) "Claude bridge skill missing $skillId."
    }
    foreach ($content in @($codexSkill, $claudeSkill)) {
        Assert-True ($content -match "update-handoff.ps1" -and $content -match "-ResumeContext") "Bridge skill missing resume_context persistence before Superpowers invocation."
    }
}
finally {
    if ($null -eq $originalEvents) {
        if (Test-Path -LiteralPath $eventsPath) { Remove-Item -LiteralPath $eventsPath -Force }
    }
    else {
        Set-Content -LiteralPath $eventsPath -Value $originalEvents -Encoding UTF8 -NoNewline
    }
}

Write-Output "validation-pass-tests-ok"
