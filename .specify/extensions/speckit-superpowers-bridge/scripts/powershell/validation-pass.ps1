param(
    [switch]$Json,
    [switch]$Strict,
    [string]$Actor = "",
    [string]$FeatureDirectory = ""
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "common-actor-resolution.ps1")

function New-Finding {
    param([string]$Code, [string]$Severity, [string]$Target, [string]$Message, [string]$SuggestedFix)
    return [pscustomobject]@{
        code = $Code
        severity = $Severity
        target = $Target
        message = $Message
        suggested_fix = $SuggestedFix
    }
}

function Add-Step {
    param([System.Collections.Generic.List[object]]$Steps, [string]$Name, [bool]$Passed, [string]$Details)
    $Steps.Add([pscustomobject]@{ step = $Name; passed = $Passed; details = $Details })
}

function Invoke-BridgeScriptJson {
    param([string]$Path, [string[]]$Arguments)
    $psExe = (Get-Process -Id $PID).Path
    $args = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $Path) + $Arguments
    $output = & $psExe @args
    return [pscustomobject]@{ output = ($output -join [Environment]::NewLine); exit_code = $LASTEXITCODE }
}

function Get-CurrentFeatureDirectory {
    param([string]$RepoRoot, [object]$Handoff, [string]$Argument)
    if (-not [string]::IsNullOrWhiteSpace($Argument)) { return $Argument }
    if ($Handoff -and $Handoff.feature_directory) { return [string]$Handoff.feature_directory }
    $featureJson = Join-Path $RepoRoot ".specify\feature.json"
    if (Test-Path -LiteralPath $featureJson) {
        $state = Get-Content -LiteralPath $featureJson -Raw | ConvertFrom-Json
        if ($state.feature_directory) { return [string]$state.feature_directory }
    }
    return ""
}

function Append-CompatibilityGap {
    param([string]$FeaturePath, [object]$Finding)
    $gapPath = Join-Path $FeaturePath "compat-gaps.md"
    if (-not (Test-Path -LiteralPath $gapPath)) {
        Set-Content -LiteralPath $gapPath -Encoding UTF8 -Value "# Compatibility Gaps`n"
    }
    $content = Get-Content -LiteralPath $gapPath -Raw
    $signature = "$($Finding.code)|$($Finding.target)"
    if ($content -match [regex]::Escape($signature)) { return }
    $next = 1
    $ids = [regex]::Matches($content, 'CG-(\d{3})') | ForEach-Object { [int]$_.Groups[1].Value }
    if ($ids) { $next = ($ids | Measure-Object -Maximum).Maximum + 1 }
    $id = "CG-" + ([string]$next).PadLeft(3, '0')
    $row = "`n## $id - $($Finding.code)`n`n- Status: OPEN`n- Severity: $($Finding.severity)`n- Target: $($Finding.target)`n- Signature: $signature`n- Observed: $($Finding.message)`n- Proposed fix: $($Finding.suggested_fix)`n"
    Add-Content -LiteralPath $gapPath -Encoding UTF8 -Value $row
}

$repoRoot = Get-BridgeRepoRoot
$Actor = Resolve-BridgeActor -Argument $Actor -RepoRoot $repoRoot
$steps = New-Object System.Collections.Generic.List[object]
$findings = New-Object System.Collections.Generic.List[object]

$handoffPath = Join-Path $repoRoot ".specify\superpowers-handoff.json"
$handoff = $null
try {
    if (-not (Test-Path -LiteralPath $handoffPath)) { throw "missing handoff" }
    $handoff = Get-Content -LiteralPath $handoffPath -Raw | ConvertFrom-Json
    if ([int]$handoff.schema_version -notin @(2, 3)) { throw "unsupported schema_version $($handoff.schema_version)" }
    Add-Step -Steps $steps -Name "handoff-state" -Passed $true -Details "schema_version=$($handoff.schema_version)"
}
catch {
    Add-Step -Steps $steps -Name "handoff-state" -Passed $false -Details $_.Exception.Message
    $findings.Add((New-Finding -Code "handoff_invalid" -Severity "P0" -Target ".specify/superpowers-handoff.json" -Message $_.Exception.Message -SuggestedFix "Regenerate handoff with update-handoff.ps1."))
}

$featureDirectory = Get-CurrentFeatureDirectory -RepoRoot $repoRoot -Handoff $handoff -Argument $FeatureDirectory
$featurePath = ""
if ([string]::IsNullOrWhiteSpace($featureDirectory)) {
    Add-Step -Steps $steps -Name "feature-directory" -Passed $false -Details "missing"
    $findings.Add((New-Finding -Code "feature_directory_missing" -Severity "P0" -Target ".specify/superpowers-handoff.json" -Message "No active feature_directory was found in arguments, handoff, or .specify/feature.json." -SuggestedFix "Regenerate handoff with update-handoff.ps1 -FeatureDirectory <specs/...> or pass -FeatureDirectory explicitly."))
}
else {
    $featurePath = if ([System.IO.Path]::IsPathRooted($featureDirectory)) { $featureDirectory } else { Join-Path $repoRoot $featureDirectory }
    Add-Step -Steps $steps -Name "feature-directory" -Passed $true -Details $featureDirectory
}

$matrixPath = Join-Path $repoRoot ".specify\extensions\speckit-superpowers-bridge\disposition-matrix.json"
$verifiedPath = Join-Path $repoRoot ".specify\extensions\speckit-superpowers-bridge\verified-versions.json"
try {
    Get-Content -LiteralPath $matrixPath -Raw | ConvertFrom-Json | Out-Null
    Get-Content -LiteralPath $verifiedPath -Raw | ConvertFrom-Json | Out-Null
    Add-Step -Steps $steps -Name "matrix-and-versions" -Passed $true -Details "matrix and verified versions parse"
}
catch {
    Add-Step -Steps $steps -Name "matrix-and-versions" -Passed $false -Details $_.Exception.Message
    $findings.Add((New-Finding -Code "matrix_or_versions_invalid" -Severity "P0" -Target ".specify/extensions/speckit-superpowers-bridge" -Message $_.Exception.Message -SuggestedFix "Repair matrix or verified-versions JSON."))
}

$parity = Invoke-BridgeScriptJson -Path (Join-Path $PSScriptRoot "parity-check.ps1") -Arguments @("-Json", "-Actor", $Actor)
if ($parity.exit_code -eq 0) {
    Add-Step -Steps $steps -Name "parity-check" -Passed $true -Details "exit 0"
}
else {
    Add-Step -Steps $steps -Name "parity-check" -Passed $false -Details "exit $($parity.exit_code)"
    $findings.Add((New-Finding -Code "parity_check_failed" -Severity "P1" -Target "parity-check.ps1" -Message "Parity check exited $($parity.exit_code)." -SuggestedFix "Run parity-check.ps1 -Json and address findings."))
}

$audit = Invoke-BridgeScriptJson -Path (Join-Path $PSScriptRoot "audit-install-state.ps1") -Arguments @("-Json", "-Actor", $Actor)
if ($audit.exit_code -eq 0) {
    Add-Step -Steps $steps -Name "install-state-audit" -Passed $true -Details "exit 0"
}
else {
    Add-Step -Steps $steps -Name "install-state-audit" -Passed $false -Details "exit $($audit.exit_code)"
    $findings.Add((New-Finding -Code "install_state_audit_failed" -Severity "P1" -Target "audit-install-state.ps1" -Message "Install-state audit exited $($audit.exit_code)." -SuggestedFix "Run audit-install-state.ps1 -Json and address findings."))
}

$requiredArtifacts = @(".specify\memory\constitution.md")
if (-not [string]::IsNullOrWhiteSpace($featureDirectory)) {
    $requiredArtifacts += @(
        (Join-Path $featureDirectory "spec.md"),
        (Join-Path $featureDirectory "plan.md"),
        (Join-Path $featureDirectory "tasks.md")
    )
}
$missingArtifacts = @($requiredArtifacts | Where-Object { -not (Test-Path -LiteralPath (Join-Path $repoRoot $_)) })
if ($missingArtifacts.Count -eq 0) {
    Add-Step -Steps $steps -Name "feature-artifacts" -Passed $true -Details $(if ([string]::IsNullOrWhiteSpace($featureDirectory)) { "constitution only" } else { $featureDirectory })
}
else {
    Add-Step -Steps $steps -Name "feature-artifacts" -Passed $false -Details ($missingArtifacts -join ", ")
    $findings.Add((New-Finding -Code "feature_artifacts_missing" -Severity "P0" -Target $featureDirectory -Message "Missing required artifacts: $($missingArtifacts -join ', ')." -SuggestedFix "Return to Spec Kit and regenerate missing artifacts."))
}

$eventsPath = Join-Path $repoRoot ".specify\bridge-events.jsonl"
$skillEvents = @()
if (Test-Path -LiteralPath $eventsPath) {
    $cutoff = (Get-Date).ToUniversalTime().AddHours(-24)
    foreach ($line in (Get-Content -LiteralPath $eventsPath)) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        try {
            $event = $line | ConvertFrom-Json
            if ($event.action -eq "skill_invocation" -and ([datetime]$event.timestamp).ToUniversalTime() -ge $cutoff) {
                $skillEvents += $event
            }
        }
        catch { }
    }
}
if ($skillEvents.Count -gt 0) {
    Add-Step -Steps $steps -Name "skill-invocation-events" -Passed $true -Details "$($skillEvents.Count) recent event(s)"
}
else {
    Add-Step -Steps $steps -Name "skill-invocation-events" -Passed $false -Details "none in last 24h"
    $findings.Add((New-Finding -Code "skill_invocations_absent" -Severity "P1" -Target ".specify/bridge-events.jsonl" -Message "No recent skill_invocation events found." -SuggestedFix "Ensure bridge skill emits skill_invocation events before Superpowers skill calls."))
}

$requiredPhases = @("before-implementation-task", "before-phase-completion", "before-feature-completion")
$missingPhases = @($requiredPhases | Where-Object { $phase = $_; -not (@($skillEvents | Where-Object { $_.phase -eq $phase }).Count -gt 0) })
if ($missingPhases.Count -eq 0) {
    Add-Step -Steps $steps -Name "skill-phase-coverage" -Passed $true -Details "all required phases covered"
}
else {
    Add-Step -Steps $steps -Name "skill-phase-coverage" -Passed $false -Details ($missingPhases -join ", ")
    $findings.Add((New-Finding -Code "skill_phase_uncovered" -Severity "P1" -Target ".specify/bridge-events.jsonl" -Message "Missing invocation phase(s): $($missingPhases -join ', ')." -SuggestedFix "Emit events for each required lifecycle phase."))
}

$skillFiles = @(
    ".agents\skills\speckit-superpowers-bridge\SKILL.md",
    ".claude\skills\speckit-superpowers-bridge\SKILL.md"
)
$skillIds = @(
    "superpowers:test-driven-development",
    "superpowers:systematic-debugging",
    "superpowers:verification-before-completion",
    "superpowers:requesting-code-review",
    "superpowers:finishing-a-development-branch"
)
$missingSkillPhrases = @()
foreach ($skillFile in $skillFiles) {
    $content = if (Test-Path -LiteralPath (Join-Path $repoRoot $skillFile)) { Get-Content -LiteralPath (Join-Path $repoRoot $skillFile) -Raw } else { "" }
    foreach ($skillId in $skillIds) {
        if ($content -notmatch [regex]::Escape($skillId)) {
            $missingSkillPhrases += "$skillFile::$skillId"
        }
    }
    if ($content -notmatch "emit-skill-invocation.ps1") {
        $missingSkillPhrases += "$skillFile::emit-skill-invocation.ps1"
    }
    if ($content -notmatch "update-handoff.ps1" -or $content -notmatch "-ResumeContext") {
        $missingSkillPhrases += "$skillFile::resume_context persistence"
    }
}
if ($missingSkillPhrases.Count -eq 0) {
    Add-Step -Steps $steps -Name "bridge-skill-explicit-invocation" -Passed $true -Details "all phrases found"
}
else {
    Add-Step -Steps $steps -Name "bridge-skill-explicit-invocation" -Passed $false -Details ($missingSkillPhrases -join ", ")
    $findings.Add((New-Finding -Code "bridge_skill_missing_explicit_invocation" -Severity "P1" -Target "bridge SKILL.md" -Message "Missing explicit invocation phrase(s): $($missingSkillPhrases -join ', ')." -SuggestedFix "Update both bridge SKILL.md files with explicit Superpowers invocation rules."))
}

$guard = Invoke-BridgeScriptJson -Path (Join-Path $PSScriptRoot "test-bridge-guard.ps1") -Arguments @()
if ($guard.exit_code -eq 0) {
    Add-Step -Steps $steps -Name "bridge-guard-tests" -Passed $true -Details "exit 0"
}
else {
    Add-Step -Steps $steps -Name "bridge-guard-tests" -Passed $false -Details "exit $($guard.exit_code)"
    $findings.Add((New-Finding -Code "bridge_guard_tests_failed" -Severity "P1" -Target "test-bridge-guard.ps1" -Message "Guard smoke suite failed." -SuggestedFix "Run test-bridge-guard.ps1 and fix failing guard behavior."))
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

foreach ($finding in $findings) {
    if (-not [string]::IsNullOrWhiteSpace($featurePath) -and (Test-Path -LiteralPath $featurePath)) {
        Append-CompatibilityGap -FeaturePath $featurePath -Finding $finding
    }
}

$decision = if ($exitCode -eq 0) { "pass" } else { "fail" }
$event = [ordered]@{
    timestamp = (Get-Date).ToUniversalTime().ToString("o")
    action = "validation_pass"
    status = if ($handoff -and $handoff.status) { [string]$handoff.status } else { "" }
    feature_directory = $featureDirectory
    decision = $decision
    reason = "validation-pass completed: P0=$($counts.P0) P1=$($counts.P1) P2=$($counts.P2) P3=$($counts.P3)"
    actor = $Actor
    snapshot_id = if ($handoff -and ($handoff.PSObject.Properties.Name -contains "last_snapshot_id")) { [string]$handoff.last_snapshot_id } else { $null }
}
($event | ConvertTo-Json -Compress -Depth 6) + [Environment]::NewLine | Add-Content -LiteralPath (Join-Path $repoRoot ".specify\bridge-events.jsonl") -Encoding UTF8

if ($exitCode -eq 0) {
    $headSha = ""
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $previousErrorAction = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        try {
            $headSha = (& git -C $repoRoot rev-parse HEAD 2>$null).Trim()
            if ($LASTEXITCODE -ne 0) {
                $headSha = ""
            }
        }
        finally {
            $ErrorActionPreference = $previousErrorAction
        }
    }

    $passEvent = [ordered]@{
        timestamp = (Get-Date).ToUniversalTime().ToString("o")
        action = "feature_validation_pass"
        status = if ($handoff -and $handoff.status) { [string]$handoff.status } else { "" }
        feature_directory = $featureDirectory
        decision = "pass"
        reason = if ($headSha) { "validation pass succeeded; head_sha=$headSha" } else { "validation pass succeeded; head_sha=unavailable" }
        actor = $Actor
        snapshot_id = if ($handoff -and ($handoff.PSObject.Properties.Name -contains "last_snapshot_id")) { [string]$handoff.last_snapshot_id } else { $null }
    }
    ($passEvent | ConvertTo-Json -Compress -Depth 6) + [Environment]::NewLine | Add-Content -LiteralPath (Join-Path $repoRoot ".specify\bridge-events.jsonl") -Encoding UTF8
    Add-Step -Steps $steps -Name "feature-validation-pass-event" -Passed $true -Details "emitted"
}
else {
    Add-Step -Steps $steps -Name "feature-validation-pass-event" -Passed $false -Details "skipped because validation failed"
}

$report = [ordered]@{
    schema_version = 1
    generated_at = (Get-Date).ToUniversalTime().ToString("o")
    feature_directory = $featureDirectory
    steps = @($steps.ToArray())
    findings = @($findings.ToArray())
    summary = [ordered]@{ total = $findings.Count; by_severity = $counts }
    exit_code = $exitCode
}

if ($Json) {
    $report | ConvertTo-Json -Depth 10
}
else {
    foreach ($step in $steps) {
        $prefix = if ($step.passed) { "PASS" } else { "FAIL" }
        Write-Output "$prefix $($step.step): $($step.details)"
    }
}

exit $exitCode
