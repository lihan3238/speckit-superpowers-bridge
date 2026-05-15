param(
    [switch]$Json,
    [switch]$Strict,
    [string]$Actor = ""
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "common-actor-resolution.ps1")

function New-Finding {
    param(
        [string]$Code,
        [string]$Severity,
        [string]$Target,
        [string]$Agent = "n/a",
        [string]$Message,
        [string]$SuggestedFix
    )
    return [pscustomobject]@{
        code = $Code
        severity = $Severity
        target = $Target
        agent = $Agent
        message = $Message
        suggested_fix = $SuggestedFix
    }
}

function Get-SkillIds {
    param([string]$RepoRoot, [string]$RelativeDir)
    $dir = Join-Path $RepoRoot $RelativeDir
    if (-not (Test-Path -LiteralPath $dir)) { return @() }
    return @(Get-ChildItem -LiteralPath $dir -Directory | ForEach-Object { $_.Name })
}

function Get-Headings {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return @() }
    return @(Get-Content -LiteralPath $Path | Where-Object { $_ -match '^\s*#{1,6}\s+' } | ForEach-Object { ($_ -replace '^\s*#{1,6}\s+', '').Trim().ToLowerInvariant() })
}

function Get-FileSha {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function Read-SimpleYamlValue {
    param([string]$Path, [string]$Key)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    foreach ($line in (Get-Content -LiteralPath $Path)) {
        if ($line -match "^\s*$([regex]::Escape($Key))\s*:\s*['""]?([^'""]+)['""]?\s*$") {
            return $Matches[1].Trim()
        }
    }
    return $null
}

$repoRoot = Get-BridgeRepoRoot
$Actor = Resolve-BridgeActor -Argument $Actor -RepoRoot $repoRoot
$findings = New-Object System.Collections.Generic.List[object]

$integrationPath = Join-Path $repoRoot ".specify\integration.json"
if (-not (Test-Path -LiteralPath $integrationPath)) {
    throw "Missing .specify/integration.json"
}

$integration = Get-Content -LiteralPath $integrationPath -Raw | ConvertFrom-Json
$specVersion = if ($integration.version) { [string]$integration.version } else { $null }
$defaultIntegration = if ($integration.default_integration) { [string]$integration.default_integration } elseif ($integration.integration) { [string]$integration.integration } else { $null }
$installedIntegrations = @($integration.installed_integrations | ForEach-Object { [string]$_ })

if ($defaultIntegration -notin @("codex", "claude")) {
    $findings.Add((New-Finding -Code "ambiguous_default_integration" -Severity "P2" -Target ".specify/integration.json" -Message "default_integration is empty or unsupported." -SuggestedFix "Run specify integration use codex or specify integration use claude."))
}

$verifiedPath = Join-Path $repoRoot ".specify\extensions\speckit-superpowers-bridge\verified-versions.json"
if (Test-Path -LiteralPath $verifiedPath) {
    $verified = Get-Content -LiteralPath $verifiedPath -Raw | ConvertFrom-Json
    if ($verified.spec_kit_version -and $specVersion -and [string]$verified.spec_kit_version -ne $specVersion) {
        $findings.Add((New-Finding -Code "spec_kit_version_drift" -Severity "P1" -Target "spec_kit_version" -Message "Installed Spec Kit '$specVersion' differs from verified '$($verified.spec_kit_version)'." -SuggestedFix "Re-run bridge validation, then update verified-versions.json if compatible."))
    }
}

$integrationReports = @()
foreach ($name in $installedIntegrations) {
    $manifestPath = Join-Path $repoRoot ".specify\integrations\$name.manifest.json"
    $present = Test-Path -LiteralPath $manifestPath
    $integrationReports += [pscustomobject]@{ name = $name; manifest_present = $present }
    if (-not $present) {
        $findings.Add((New-Finding -Code "missing_integration_manifest" -Severity "P1" -Target $manifestPath -Agent $name -Message "Installed integration '$name' has no manifest file." -SuggestedFix "Run specify integration upgrade $name."))
    }
}

$gitExtensionPath = Join-Path $repoRoot ".specify\extensions\git\extension.yml"
$gitCommandsDir = Join-Path $repoRoot ".specify\extensions\git\commands"
$gitCommands = @()
if (Test-Path -LiteralPath $gitCommandsDir) {
    $gitCommands = @(Get-ChildItem -LiteralPath $gitCommandsDir -Filter "*.md" -File | ForEach-Object { $_.BaseName })
}
$gitExtension = [pscustomobject]@{
    installed = (Test-Path -LiteralPath $gitExtensionPath)
    version = (Read-SimpleYamlValue -Path $gitExtensionPath -Key "version")
    commands = @($gitCommands)
}

$codexSkills = Get-SkillIds -RepoRoot $repoRoot -RelativeDir ".agents\skills"
$claudeSkills = Get-SkillIds -RepoRoot $repoRoot -RelativeDir ".claude\skills"
$missingOnClaude = @()
$missingOnCodex = @()
$diverged = @()

foreach ($id in $codexSkills) {
    if (-not ($claudeSkills -contains $id)) {
        $missingOnClaude += $id
        $findings.Add((New-Finding -Code "missing_per_agent_skill" -Severity "P1" -Target $id -Agent "claude" -Message "Codex skill '$id' has no Claude peer." -SuggestedFix "Run specify integration upgrade claude; if upstream cannot mirror extension skills, manually copy .agents/skills/$id/SKILL.md to .claude/skills/$id/SKILL.md and adapt invocation syntax."))
    }
}
foreach ($id in $claudeSkills) {
    if (-not ($codexSkills -contains $id)) {
        $missingOnCodex += $id
        $findings.Add((New-Finding -Code "missing_per_agent_skill" -Severity "P1" -Target $id -Agent "codex" -Message "Claude skill '$id' has no Codex peer." -SuggestedFix "Run specify integration upgrade codex; if upstream cannot mirror extension skills, manually copy .claude/skills/$id/SKILL.md to .agents/skills/$id/SKILL.md and adapt invocation syntax."))
    }
}

foreach ($id in @($codexSkills | Where-Object { $claudeSkills -contains $_ })) {
    $codexPath = Join-Path $repoRoot ".agents\skills\$id\SKILL.md"
    $claudePath = Join-Path $repoRoot ".claude\skills\$id\SKILL.md"
    $codexSha = Get-FileSha -Path $codexPath
    $claudeSha = Get-FileSha -Path $claudePath
    if ($codexSha -ne $claudeSha) {
        if ($id -eq "speckit-superpowers-bridge") {
            $codexHeadings = Get-Headings -Path $codexPath
            $claudeHeadings = Get-Headings -Path $claudePath
            if (($codexHeadings -join "|") -ne ($claudeHeadings -join "|")) {
                $diverged += [pscustomobject]@{ name = $id; agents_sha = $codexSha; claude_sha = $claudeSha; structural = "mismatch" }
                $findings.Add((New-Finding -Code "skill_content_diverged" -Severity "P2" -Target $id -Message "Bridge skill headings differ between Codex and Claude." -SuggestedFix "Re-sync bridge SKILL.md structure while preserving agent-specific syntax."))
            }
        }
        else {
            $diverged += [pscustomobject]@{ name = $id; agents_sha = $codexSha; claude_sha = $claudeSha; structural = "not_checked" }
            $findings.Add((New-Finding -Code "skill_content_diverged" -Severity "P2" -Target $id -Message "Skill '$id' differs between Codex and Claude copies." -SuggestedFix "Run specify integration upgrade codex and specify integration upgrade claude; if still divergent, compare the two generated files before editing."))
        }
    }
}

$initOptionsPath = Join-Path $repoRoot ".specify\init-options.json"
$scriptFlavour = $null
if (Test-Path -LiteralPath $initOptionsPath) {
    try {
        $init = Get-Content -LiteralPath $initOptionsPath -Raw | ConvertFrom-Json
        $scriptFlavour = if ($init.script) { [string]$init.script } else { $null }
    }
    catch { }
}

$counts = [ordered]@{ P0 = 0; P1 = 0; P2 = 0; P3 = 0 }
foreach ($finding in $findings) {
    if ($counts.Contains([string]$finding.severity)) {
        $counts[[string]$finding.severity] = [int]$counts[[string]$finding.severity] + 1
    }
}

if ([int]$counts.P0 -gt 0) { $exitCode = 1 }
elseif ([int]$counts.P1 -gt 0) { $exitCode = 2 }
elseif ($Strict -and [int]$counts.P2 -gt 0) { $exitCode = 3 }
else { $exitCode = 0 }

$report = [ordered]@{
    schema_version = 1
    generated_at = (Get-Date).ToUniversalTime().ToString("o")
    spec_kit = [ordered]@{ version = $specVersion; default_integration = $defaultIntegration }
    integrations = @($integrationReports)
    git_extension = $gitExtension
    skills_parity = [ordered]@{
        missing_on_claude = @($missingOnClaude)
        missing_on_codex = @($missingOnCodex)
        diverged = @($diverged)
    }
    script_flavour = $scriptFlavour
    findings = @($findings.ToArray())
    summary = [ordered]@{ total = $findings.Count; by_severity = $counts }
    exit_code = $exitCode
}

$handoffPath = Join-Path $repoRoot ".specify\superpowers-handoff.json"
$handoff = $null
if (Test-Path -LiteralPath $handoffPath) { $handoff = Get-Content -LiteralPath $handoffPath -Raw | ConvertFrom-Json }
$event = [ordered]@{
    timestamp = (Get-Date).ToUniversalTime().ToString("o")
    action = "install_state_audit"
    status = if ($handoff -and $handoff.status) { [string]$handoff.status } else { "" }
    feature_directory = if ($handoff -and $handoff.feature_directory) { [string]$handoff.feature_directory } else { "" }
    decision = if ($exitCode -eq 0) { "allow" } else { "deny" }
    reason = "install-state audit completed: P0=$($counts.P0) P1=$($counts.P1) P2=$($counts.P2) P3=$($counts.P3)"
    actor = $Actor
    snapshot_id = $null
}
($event | ConvertTo-Json -Compress -Depth 6) + [Environment]::NewLine | Add-Content -LiteralPath (Join-Path $repoRoot ".specify\bridge-events.jsonl") -Encoding UTF8

if ($Json) {
    $report | ConvertTo-Json -Depth 10
}
else {
    Write-Output "Install-state audit: spec_kit $specVersion / default_integration $defaultIntegration"
    Write-Output "  Integrations: $($installedIntegrations -join ', ')"
    Write-Output "  Git extension: $($gitExtension.installed) ($($gitExtension.commands.Count) commands)"
    Write-Output "  Skill parity: $($missingOnClaude.Count + $missingOnCodex.Count) missing, $($diverged.Count) diverged"
    Write-Output "  Findings: P0=$($counts.P0) P1=$($counts.P1) P2=$($counts.P2) P3=$($counts.P3)"
    foreach ($finding in $findings) {
        [Console]::Error.WriteLine("[$($finding.severity)] $($finding.code) $($finding.target) - $($finding.message) Fix: $($finding.suggested_fix)")
    }
}

exit $exitCode
