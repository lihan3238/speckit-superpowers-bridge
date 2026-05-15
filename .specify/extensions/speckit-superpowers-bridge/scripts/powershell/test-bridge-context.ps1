param()

$ErrorActionPreference = "Stop"

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

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

    return (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
}

function Read-Text {
    param([string]$Path)

    Assert-True (Test-Path -LiteralPath $Path) "Missing required file: $Path"
    return Get-Content -LiteralPath $Path -Raw
}

$repoRoot = Get-RepoRoot

$agentsPath = Join-Path $repoRoot "AGENTS.md"
$claudePath = Join-Path $repoRoot "CLAUDE.md"
$codexBridgeSkillPath = Join-Path $repoRoot ".agents\skills\speckit-superpowers-bridge\SKILL.md"
$claudeBridgeSkillPath = Join-Path $repoRoot ".claude\skills\speckit-superpowers-bridge\SKILL.md"
$workflowPath = Join-Path $repoRoot ".specify\workflows\speckit-superpowers\workflow.yml"
$integrationPath = Join-Path $repoRoot ".specify\integration.json"

$agents = Read-Text -Path $agentsPath
$claude = Read-Text -Path $claudePath
$codexBridgeSkill = Read-Text -Path $codexBridgeSkillPath
$claudeBridgeSkill = Read-Text -Path $claudeBridgeSkillPath
$workflow = Read-Text -Path $workflowPath
$integration = Read-Text -Path $integrationPath | ConvertFrom-Json

Assert-True ($agents -match "master bridge protocol") "AGENTS.md must identify itself as the master bridge protocol."
Assert-True ($agents -match "\$speckit-plan") "AGENTS.md must document Codex command syntax."
Assert-True ($agents -match "/speckit-plan") "AGENTS.md must document Claude Code command syntax."
Assert-True ($agents -match "speckit\.plan") "AGENTS.md must document internal dotted command ids."
Assert-True ($agents -match "Do not hand-edit official generated") "AGENTS.md must protect official generated skills."
Assert-True ($agents -match "Only one agent may own writes") "AGENTS.md must document single-writer ownership."
Assert-True ($agents -match "-Actor codex") "AGENTS.md must document Codex actor usage."
Assert-True ($agents -match "-Actor claude") "AGENTS.md must document Claude actor usage."

Assert-True ($claude -match "AGENTS\.md") "CLAUDE.md must instruct Claude Code to read AGENTS.md."
Assert-True ($claude -match "/speckit-speckit-superpowers-bridge-execute") "CLAUDE.md must document the Claude bridge execute command."
Assert-True ($claude -match "\.claude/skills/speckit-superpowers-bridge") "CLAUDE.md must point to the Claude bridge skill."
Assert-True ($claude -match "vendor-managed") "CLAUDE.md must keep official Claude Spec Kit skills vendor-managed."
Assert-True ($claude -match "-Actor claude") "CLAUDE.md must document Claude actor usage."

Assert-True ($codexBridgeSkill -match "\.agents/skills/speckit-superpowers-bridge") "Codex bridge skill must mention its agent-specific path."
Assert-True ($codexBridgeSkill -match "\.claude/skills/speckit-superpowers-bridge") "Codex bridge skill must mention the Claude bridge skill path."
Assert-True ($claudeBridgeSkill -match "/speckit-speckit-superpowers-bridge-execute") "Claude bridge skill must use Claude slash-hyphen examples."
Assert-True ($claudeBridgeSkill -match "\.claude/skills/speckit-superpowers-bridge") "Claude bridge skill must mention its agent-specific path."
Assert-True ($claudeBridgeSkill -match 'Do not call `speckit\.implement`') "Claude bridge skill must preserve the speckit.implement deny rule."

Assert-True ($workflow -match 'any:\s*\["codex",\s*"claude"\]') "speckit-superpowers workflow must allow codex or claude."
Assert-True ($workflow -notmatch "command:\s*speckit\.implement") "speckit-superpowers workflow must not include speckit.implement as a workflow step."

Assert-True ($integration.installed_integrations -contains "codex") "Codex integration must be installed."
Assert-True ($integration.installed_integrations -contains "claude") "Claude integration must be installed."

Write-Output "bridge-context-tests-ok"
