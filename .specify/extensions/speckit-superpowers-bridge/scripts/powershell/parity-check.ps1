param(
    [switch]$Json,
    [switch]$Strict,
    [ValidateSet("codex", "claude", "unknown")]
    [string]$Actor = "unknown"
)

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
        code          = $Code
        severity      = $Severity
        target        = $Target
        agent         = $Agent
        message       = $Message
        suggested_fix = $SuggestedFix
    }
}

function Get-AgentSkillIds {
    param([string]$RepoRoot, [string]$AgentDir)
    $base = Join-Path $RepoRoot $AgentDir
    if (-not (Test-Path -LiteralPath $base)) { return @() }
    return @(Get-ChildItem -LiteralPath $base -Directory | ForEach-Object { $_.Name })
}

function Get-ExtensionCommandIds {
    param([string]$RepoRoot)
    $base = Join-Path $RepoRoot ".specify\extensions"
    if (-not (Test-Path -LiteralPath $base)) { return @() }
    $commands = @()
    foreach ($extDir in (Get-ChildItem -LiteralPath $base -Directory)) {
        $cmdDir = Join-Path $extDir.FullName "commands"
        if (Test-Path -LiteralPath $cmdDir) {
            foreach ($cmdFile in (Get-ChildItem -LiteralPath $cmdDir -File -Filter "*.md")) {
                $commands += $cmdFile.BaseName
            }
        }
    }
    return $commands
}

function Read-HookCommands {
    param([string]$RepoRoot)
    $extYamlPath = Join-Path $RepoRoot ".specify\extensions.yml"
    if (-not (Test-Path -LiteralPath $extYamlPath)) { return @() }
    # Minimal YAML extraction: look for lines `    command: <value>` under a `hooks:` block.
    $commands = @()
    $inHooks = $false
    foreach ($line in (Get-Content -LiteralPath $extYamlPath)) {
        if ($line -match '^\s*hooks:\s*$') { $inHooks = $true; continue }
        if ($inHooks -and $line -match '^\S') { $inHooks = $false }
        if ($inHooks -and $line -match '^\s*command:\s*(\S+)\s*$') {
            $commands += $Matches[1]
        }
    }
    return @($commands | Select-Object -Unique)
}

function Test-DocReferencesMatrix {
    param([string]$RepoRoot, [string]$DocRelativePath)
    $p = Join-Path $RepoRoot $DocRelativePath
    if (-not (Test-Path -LiteralPath $p)) { return $false }
    $content = Get-Content -LiteralPath $p -Raw
    return ($content -match 'disposition[-_ ]matrix')
}

$repoRoot = Get-RepoRoot
$bridgeRoot = Join-Path $repoRoot ".specify\extensions\speckit-superpowers-bridge"
$matrixPath = Join-Path $bridgeRoot "disposition-matrix.json"
$verifiedPath = Join-Path $bridgeRoot "verified-versions.json"
$initOptionsPath = Join-Path $repoRoot ".specify\init-options.json"

$findings = New-Object System.Collections.Generic.List[object]

# ---- Check 1: schema validity (light-touch — required top-level fields present) ----
if (-not (Test-Path -LiteralPath $matrixPath)) {
    $findings.Add((New-Finding -Code "missing_disposition" -Severity "P0" -Target $matrixPath -Message "disposition-matrix.json is missing" -SuggestedFix "Create the matrix file per contracts/disposition-matrix.schema.json"))
    $exitCode = 66
}
else {
    try {
        $matrix = Get-Content -LiteralPath $matrixPath -Raw | ConvertFrom-Json
    }
    catch {
        $findings.Add((New-Finding -Code "missing_disposition" -Severity "P0" -Target $matrixPath -Message "disposition-matrix.json failed to parse: $($_.Exception.Message)" -SuggestedFix "Repair the JSON; validate against contracts/disposition-matrix.schema.json"))
        $matrix = $null
    }
    if ($matrix) {
        foreach ($required in @("schema_version", "entries", "last_audited_at")) {
            if (-not ($matrix.PSObject.Properties.Name -contains $required)) {
                $findings.Add((New-Finding -Code "missing_disposition" -Severity "P0" -Target "$matrixPath#/$required" -Message "Matrix missing required top-level field '$required'" -SuggestedFix "Add the field per contracts/disposition-matrix.schema.json"))
            }
        }
        # Per-entry validation (subset of the JSON Schema rules)
        foreach ($e in @($matrix.entries)) {
            foreach ($req in @("id", "kind", "disposition", "rationale", "verified_against")) {
                if (-not ($e.PSObject.Properties.Name -contains $req) -or [string]::IsNullOrWhiteSpace([string]$e.$req)) {
                    $findings.Add((New-Finding -Code "missing_disposition" -Severity "P0" -Target ("entry:" + [string]$e.id) -Message "Entry missing required field '$req'" -SuggestedFix "Populate '$req' on the entry"))
                }
            }
            if ([string]$e.disposition -eq "FORBID-UNDER-HANDOFF") {
                if (-not ($e.PSObject.Properties.Name -contains "applicability") -or -not $e.applicability -or @($e.applicability).Count -eq 0) {
                    $findings.Add((New-Finding -Code "missing_disposition" -Severity "P0" -Target ("entry:" + [string]$e.id) -Message "FORBID-UNDER-HANDOFF entry must declare applicability scope" -SuggestedFix "Add 'applicability: [executing|blocked|complete...]' to the entry"))
                }
            }
            if ([string]$e.disposition -eq "SUPERSEDED-BY") {
                if (-not ($e.PSObject.Properties.Name -contains "superseded_by") -or [string]::IsNullOrWhiteSpace([string]$e.superseded_by)) {
                    $findings.Add((New-Finding -Code "missing_replacement" -Severity "P0" -Target ("entry:" + [string]$e.id) -Message "SUPERSEDED-BY entry must declare superseded_by target" -SuggestedFix "Add 'superseded_by: <entry-id>' to the entry"))
                }
            }
        }
    }
}

# ---- Check 4: replacement validity — every SUPERSEDED-BY entry's target resolves ----
if ($matrix) {
    $idSet = @{}
    foreach ($e in @($matrix.entries)) { if ($e.id) { $idSet[[string]$e.id] = $true } }
    foreach ($e in @($matrix.entries)) {
        if ([string]$e.disposition -eq "SUPERSEDED-BY" -and ($e.PSObject.Properties.Name -contains "superseded_by")) {
            $target = [string]$e.superseded_by
            if (-not $idSet.ContainsKey($target)) {
                $findings.Add((New-Finding -Code "missing_replacement" -Severity "P0" -Target ("entry:" + [string]$e.id) -Message "SUPERSEDED-BY target '$target' is not an entry in the matrix" -SuggestedFix "Either add the missing target entry or correct the superseded_by pointer"))
            }
        }
    }
}

# ---- Check 2: verified-version drift (US4 scope; partial implementation here, full in T036) ----
$installedSpecKit = $null
if (Test-Path -LiteralPath $initOptionsPath) {
    try {
        $init = Get-Content -LiteralPath $initOptionsPath -Raw | ConvertFrom-Json
        $installedSpecKit = [string]$init.speckit_version
    } catch { }
}
$verified = $null
if (Test-Path -LiteralPath $verifiedPath) {
    try { $verified = Get-Content -LiteralPath $verifiedPath -Raw | ConvertFrom-Json } catch { }
    if ($verified -and $verified.spec_kit_version -and $installedSpecKit -and ([string]$verified.spec_kit_version -ne $installedSpecKit)) {
        $findings.Add((New-Finding -Code "version_drift" -Severity "P1" -Target "spec_kit_version" -Message "Installed Spec Kit ($installedSpecKit) differs from verified pin ($([string]$verified.spec_kit_version))" -SuggestedFix "Re-verify the disposition matrix against the new Spec Kit version, then update verified-versions.json"))
    }
}
# Note: presence of verified-versions.json is NOT required for the parity check to pass; absence is a P2 reminder.
elseif (-not (Test-Path -LiteralPath $verifiedPath)) {
    $findings.Add((New-Finding -Code "version_drift" -Severity "P2" -Target $verifiedPath -Message "verified-versions.json is absent; no drift detection is possible" -SuggestedFix "Create verified-versions.json with the current Spec Kit + Superpowers skill versions"))
}

# ---- Check 3: matrix coverage vs verified pin ----
if ($matrix -and $verified) {
    $matrixIds = @{}
    foreach ($e in @($matrix.entries)) { if ($e.id) { $matrixIds[[string]$e.id] = $true } }
    if ($verified.PSObject.Properties.Name -contains "superpowers_skills") {
        foreach ($sk in @($verified.superpowers_skills)) {
            $id = "superpowers:" + [string]$sk.name
            if (-not $matrixIds.ContainsKey($id)) {
                $findings.Add((New-Finding -Code "missing_disposition" -Severity "P0" -Target $id -Message "Verified Superpowers skill '$id' has no entry in the matrix" -SuggestedFix "Add a disposition entry for '$id' (or remove from verified-versions.json)"))
            }
        }
    }
    if ($verified.PSObject.Properties.Name -contains "spec_kit_commands") {
        foreach ($cmd in @($verified.spec_kit_commands)) {
            if (-not $matrixIds.ContainsKey([string]$cmd)) {
                $findings.Add((New-Finding -Code "missing_disposition" -Severity "P0" -Target ([string]$cmd) -Message "Verified Spec Kit command '$cmd' has no entry in the matrix" -SuggestedFix "Add a disposition entry for '$cmd' (or remove from verified-versions.json)"))
            }
        }
    }
}

# ---- Check 5: per-agent surface parity ----
# Per constitution Principle III + spec FR-007, every skill that exists on one agent's skill directory
# MUST have a peer file on the other agent's skill directory (1-to-1 mirror). Additionally, every hook
# command in .specify/extensions.yml must resolve to either a per-agent skill or a bridge meta-command.
$codexSkills = Get-AgentSkillIds -RepoRoot $repoRoot -AgentDir ".agents/skills"
$claudeSkills = Get-AgentSkillIds -RepoRoot $repoRoot -AgentDir ".claude/skills"
$extensionCommands = Get-ExtensionCommandIds -RepoRoot $repoRoot
$hookCommands = Read-HookCommands -RepoRoot $repoRoot

# 5a: peer-skill parity (every skill on one side has a peer on the other)
foreach ($s in $codexSkills) {
    if (-not ($claudeSkills -contains $s)) {
        $findings.Add((New-Finding -Code "missing_invocation_surface" -Severity "P1" -Target $s -Agent "claude" -Message ".claude/skills/$s/SKILL.md is missing while .agents/skills/$s exists" -SuggestedFix "Copy .agents/skills/$s/SKILL.md to .claude/skills/$s/SKILL.md (flip invocation syntax to slash-form)"))
    }
}
foreach ($s in $claudeSkills) {
    if (-not ($codexSkills -contains $s)) {
        $findings.Add((New-Finding -Code "missing_invocation_surface" -Severity "P1" -Target $s -Agent "codex" -Message ".agents/skills/$s/SKILL.md is missing while .claude/skills/$s exists" -SuggestedFix "Copy .claude/skills/$s/SKILL.md to .agents/skills/$s/SKILL.md (flip invocation syntax to dollar-form)"))
    }
}

# 5b: hook command coverage (every hook command resolves to a skill or bridge meta-command)
foreach ($cmd in $hookCommands) {
    $skillName = $cmd -replace '\.', '-'
    $isBridgeMetaCommand = $cmd.StartsWith("speckit.speckit-superpowers-bridge.")
    if ($isBridgeMetaCommand -and ($codexSkills -contains "speckit-superpowers-bridge") -and ($claudeSkills -contains "speckit-superpowers-bridge")) {
        continue
    }
    if (-not ($codexSkills -contains $skillName)) {
        $findings.Add((New-Finding -Code "missing_invocation_surface" -Severity "P1" -Target $cmd -Agent "codex" -Message "hook command '$cmd' has no .agents/skills/$skillName/SKILL.md" -SuggestedFix "Create the missing peer skill"))
    }
    if (-not ($claudeSkills -contains $skillName)) {
        $findings.Add((New-Finding -Code "missing_invocation_surface" -Severity "P1" -Target $cmd -Agent "claude" -Message "hook command '$cmd' has no .claude/skills/$skillName/SKILL.md" -SuggestedFix "Create the missing peer skill"))
    }
}

# ---- Check 6: doc/matrix consistency ----
if (-not (Test-DocReferencesMatrix -RepoRoot $repoRoot -DocRelativePath "AGENTS.md")) {
    $findings.Add((New-Finding -Code "matrix_doc_inconsistency" -Severity "P2" -Target "AGENTS.md" -Message "AGENTS.md does not reference 'disposition matrix'" -SuggestedFix "Add a section linking to .specify/extensions/speckit-superpowers-bridge/disposition-matrix.json"))
}
if (-not (Test-DocReferencesMatrix -RepoRoot $repoRoot -DocRelativePath "CLAUDE.md")) {
    $findings.Add((New-Finding -Code "matrix_doc_inconsistency" -Severity "P2" -Target "CLAUDE.md" -Message "CLAUDE.md does not reference 'disposition matrix'" -SuggestedFix "Add a one-line pointer to the matrix file"))
}

# ---- Aggregate ----
$counts = [ordered]@{ P0 = 0; P1 = 0; P2 = 0; P3 = 0 }
foreach ($f in $findings) {
    $sev = [string]$f.severity
    if ($counts.Contains($sev)) { $counts[$sev] = [int]$counts[$sev] + 1 }
}

if ([int]$counts["P0"] -gt 0) { $exitCode = 1 }
elseif ([int]$counts["P1"] -gt 0) { $exitCode = 2 }
elseif ($Strict -and [int]$counts["P2"] -gt 0) { $exitCode = 3 }
else { $exitCode = 0 }

$installed = [ordered]@{
    spec_kit_version    = $installedSpecKit
    superpowers_skills  = @()
}

if ($verified) {
    $verifiedSummary = [ordered]@{
        spec_kit_version   = [string]$verified.spec_kit_version
        superpowers_skills = @()
    }
    if ($verified.PSObject.Properties.Name -contains "superpowers_skills") {
        $verifiedSummary.superpowers_skills = @($verified.superpowers_skills)
    }
}
else {
    $verifiedSummary = [ordered]@{ spec_kit_version = $null; superpowers_skills = @() }
}

$summary = [ordered]@{
    total       = $findings.Count
    by_severity = $counts
}

$findingsArray = @($findings.ToArray())

$report = [ordered]@{
    schema_version = 1
    generated_at   = (Get-Date).ToUniversalTime().ToString("o")
    installed      = $installed
    verified       = $verifiedSummary
    findings       = $findingsArray
    summary        = $summary
    exit_code      = $exitCode
}

# Append a bridge event
$eventDecision = if ($exitCode -eq 0) { "allow" } else { "deny" }
$eventReason = "parity-check completed: $($findings.Count) finding(s); P0=$($counts.P0) P1=$($counts.P1) P2=$($counts.P2) P3=$($counts.P3); exit_code=$exitCode"
$eventPath = Join-Path $repoRoot ".specify\bridge-events.jsonl"
$evt = [ordered]@{
    timestamp       = (Get-Date).ToUniversalTime().ToString("o")
    action          = "parity_check"
    status          = ""
    feature_directory = ""
    decision        = $eventDecision
    reason          = $eventReason
    actor           = $Actor
    snapshot_id     = $null
}
($evt | ConvertTo-Json -Compress -Depth 6) + [Environment]::NewLine | Add-Content -LiteralPath $eventPath -Encoding UTF8

if ($Json) {
    $report | ConvertTo-Json -Depth 10
}
else {
    Write-Output "Parity check: $($matrix.entries.Count) entries verified, P0=$($counts.P0) P1=$($counts.P1) P2=$($counts.P2)."
    foreach ($f in $findings) {
        [Console]::Error.WriteLine("[$($f.severity)] $($f.code)  $($f.target) ($($f.agent)) - $($f.message). Fix: $($f.suggested_fix)")
    }
}

exit $exitCode
