$ErrorActionPreference = "Stop"

# Smoke test for the v0.5.0 bridge drift hardening (US1 / FR-001..FR-005, SC-001..SC-003).
#
# Covers:
#   (SC-001) Pending tasks count visible in [bridge state] block within first 20 lines.
#   (SC-002) WARNING line emitted to stderr on complete-with-unchecked; NO warning when all
#            unchecked tasks are under deferred-exemption sections (false-positive prevention).
#   (SC-003) bridge-events.jsonl handoff entry contains prior_actor and the reason notes the
#            actor change when applicable.
#
# Pattern follows tests/test-handoff-shape.ps1 (path translation, flavor skip-on-failure).

function Get-RepoRoot {
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $prev = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        try {
            $root = (& git rev-parse --show-toplevel 2>$null)
            if ($LASTEXITCODE -eq 0 -and $root) { return $root.Trim() }
        }
        finally { $ErrorActionPreference = $prev }
    }
    return (Get-Location).Path
}

function Assert-True { param([bool]$c, [string]$m); if (-not $c) { throw $m } }

function Convert-ToBashPath {
    param([string]$Path)
    $normalized = $Path.Replace('\', '/')
    if (Get-Command bash -ErrorAction SilentlyContinue) {
        $prev = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try {
            $cygpathOut = & bash -c "command -v cygpath >/dev/null 2>&1 && cygpath -u '$normalized' 2>/dev/null" 2>$null
        } finally { $ErrorActionPreference = $prev }
        if ($LASTEXITCODE -eq 0 -and $cygpathOut) { return $cygpathOut.Trim() }
    }
    if ($normalized -match '^/mnt/[a-z]/') { return $normalized }
    if ($normalized -match '^([A-Za-z]):/(.*)$') {
        return "/$($Matches[1].ToLowerInvariant())/$($Matches[2])"
    }
    return $normalized
}

function Test-BashPathReachable {
    param([string]$BashPath)
    if (-not (Get-Command bash -ErrorAction SilentlyContinue)) { return $false }
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try { $check = & bash -c "[ -f '$BashPath' ] && echo OK" 2>$null }
    finally { $ErrorActionPreference = $prev }
    return ($check -eq 'OK')
}

function Get-PsExecutable {
    # Prefer pwsh (cross-platform PS 7+); fall back to Windows-only powershell.exe.
    if (Get-Command pwsh -ErrorAction SilentlyContinue) { return 'pwsh' }
    if (Get-Command powershell.exe -ErrorAction SilentlyContinue) { return 'powershell.exe' }
    if (Get-Command powershell -ErrorAction SilentlyContinue) { return 'powershell' }
    throw "No PowerShell executable found (looked for pwsh, powershell.exe, powershell)."
}

function Invoke-CapturedPs {
    param([string]$ScriptPath, [hashtable]$Params)
    $outFile = [System.IO.Path]::GetTempFileName()
    $errFile = [System.IO.Path]::GetTempFileName()
    try {
        $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $ScriptPath)
        foreach ($k in $Params.Keys) {
            $argList += "-$k"
            $argList += [string]$Params[$k]
        }
        $exe = Get-PsExecutable
        $proc = Start-Process -FilePath $exe -ArgumentList $argList -RedirectStandardOutput $outFile -RedirectStandardError $errFile -NoNewWindow -Wait -PassThru
        return [pscustomobject]@{
            ExitCode = $proc.ExitCode
            Stdout = (Get-Content -LiteralPath $outFile -Raw -ErrorAction SilentlyContinue)
            Stderr = (Get-Content -LiteralPath $errFile -Raw -ErrorAction SilentlyContinue)
        }
    }
    finally {
        Remove-Item -LiteralPath $outFile, $errFile -ErrorAction SilentlyContinue
    }
}

function Invoke-CapturedBash {
    param([string]$BashScript, [string[]]$BashArgs)
    if (-not (Get-Command bash -ErrorAction SilentlyContinue)) { return $null }
    $bashPath = Convert-ToBashPath -Path $BashScript
    if (-not (Test-BashPathReachable -BashPath $bashPath)) { return $null }
    $outFile = [System.IO.Path]::GetTempFileName()
    $errFile = [System.IO.Path]::GetTempFileName()
    try {
        $proc = Start-Process -FilePath 'bash' -ArgumentList (@($bashPath) + $BashArgs) -RedirectStandardOutput $outFile -RedirectStandardError $errFile -NoNewWindow -Wait -PassThru
        return [pscustomobject]@{
            ExitCode = $proc.ExitCode
            Stdout = (Get-Content -LiteralPath $outFile -Raw -ErrorAction SilentlyContinue)
            Stderr = (Get-Content -LiteralPath $errFile -Raw -ErrorAction SilentlyContinue)
        }
    }
    finally {
        Remove-Item -LiteralPath $outFile, $errFile -ErrorAction SilentlyContinue
    }
}

function Test-BashPrerequisites {
    # Probe bash for required tools (jq, awk). Returns @{ Ok = $bool; Reason = $string }.
    if (-not (Get-Command bash -ErrorAction SilentlyContinue)) {
        return @{ Ok = $false; Reason = "bash not on PATH" }
    }
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $missing = & bash -c 'for t in jq awk; do command -v $t >/dev/null 2>&1 || echo $t; done' 2>$null
    }
    finally {
        $ErrorActionPreference = $prev
    }
    if ($missing) {
        return @{ Ok = $false; Reason = "missing in bash: $($missing -join ', ')" }
    }
    return @{ Ok = $true; Reason = "" }
}

function New-TempFeatureDir {
    param([string]$RepoRoot, [string]$Slug, [string]$FixtureFile)
    $dir = Join-Path $RepoRoot "tests/fixtures/.temp-$Slug"
    if (Test-Path -LiteralPath $dir) { Remove-Item -LiteralPath $dir -Recurse -Force }
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $RepoRoot "tests/fixtures/$FixtureFile") -Destination (Join-Path $dir "tasks.md")
    # update-handoff requires spec.md + plan.md to exist for non-blocked transitions; provide stubs.
    Set-Content -LiteralPath (Join-Path $dir "spec.md") -Value "# Stub spec (test fixture)`n" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $dir "plan.md") -Value "# Stub plan (test fixture)`n" -Encoding UTF8
    return $dir
}

function Get-FeatureDirRelative {
    param([string]$RepoRoot, [string]$AbsolutePath)
    return $AbsolutePath.Substring($RepoRoot.Length).TrimStart('\','/').Replace('\','/')
}

function Reset-HandoffToReady {
    param([string]$HandoffPath, [string]$FeatureDir, [string]$Actor, [string]$ArtifactOwner)
    $h = [ordered]@{
        schema_version = 1
        updated_at = (Get-Date).ToUniversalTime().ToString("o")
        feature_directory = $FeatureDir
        source_of_truth = @{
            constitution = ".specify/memory/constitution.md"
            spec = "$FeatureDir/spec.md"
            plan = "$FeatureDir/plan.md"
            tasks = "$FeatureDir/tasks.md"
        }
        supersedes = @("speckit.implement")
        executor = "superpowers"
        capabilities = @("executing-plans","test-driven-development","verification-before-completion","requesting-code-review","finishing-a-development-branch")
        status = "ready"
        blocked_reason = $null
        artifact_owner = $ArtifactOwner
        review_only_agents = @()
        notes = $null
        last_snapshot_id = $null
        instructions = "test fixture"
    } | ConvertTo-Json -Depth 6
    Set-Content -LiteralPath $HandoffPath -Value $h -Encoding UTF8
}

$repoRoot = Get-RepoRoot
$bridgeRoot = Join-Path $repoRoot ".specify/extensions/speckit-superpowers-bridge"
$updatePsScript = Join-Path $bridgeRoot "scripts/powershell/update-handoff.ps1"
$updateBashScript = Join-Path $bridgeRoot "scripts/bash/update-handoff.sh"
$handoffPath = Join-Path $repoRoot ".specify/superpowers-handoff.json"
$eventLogPath = Join-Path $repoRoot ".specify/bridge-events.jsonl"

# Snapshot live state so we can restore
$backupHandoff = if (Test-Path -LiteralPath $handoffPath) { Get-Content -LiteralPath $handoffPath -Raw } else { $null }
$eventLogSizeBefore = if (Test-Path -LiteralPath $eventLogPath) { (Get-Item -LiteralPath $eventLogPath).Length } else { 0 }

# Provision temp feature dirs
$pendingDir = New-TempFeatureDir -RepoRoot $repoRoot -Slug "feature-pending" -FixtureFile "tasks-with-pending.md"
$deferredDir = New-TempFeatureDir -RepoRoot $repoRoot -Slug "feature-deferred" -FixtureFile "tasks-all-deferred.md"
$pendingRel = Get-FeatureDirRelative -RepoRoot $repoRoot -AbsolutePath $pendingDir
$deferredRel = Get-FeatureDirRelative -RepoRoot $repoRoot -AbsolutePath $deferredDir

$flavors = @("ps")
if (Test-Path -LiteralPath $updateBashScript) {
    $bashPrereq = Test-BashPrerequisites
    if ($bashPrereq.Ok) {
        $flavors += "bash"
    } else {
        Write-Host "  (bash flavor not exercised: $($bashPrereq.Reason))"
    }
}

$exercisedFlavors = @()

try {
    foreach ($flavor in $flavors) {

        # ----- SC-001: pending count visible in first 20 lines -----
        Reset-HandoffToReady -HandoffPath $handoffPath -FeatureDir $pendingRel -Actor "claude" -ArtifactOwner "claude"

        if ($flavor -eq "ps") {
            $r = Invoke-CapturedPs -ScriptPath $updatePsScript -Params @{ Status = "executing"; Actor = "claude" }
        } else {
            $r = Invoke-CapturedBash -BashScript $updateBashScript -BashArgs @("--status","executing","--actor","claude")
            if ($null -eq $r) { Write-Host "  (bash flavor not exercised for SC-001: path/bash unavailable)"; continue }
        }

        Assert-True ($r.ExitCode -eq 0) "[$flavor] SC-001: update-handoff exit code = $($r.ExitCode); stderr=$($r.Stderr)"
        $stdoutText = if ($r.Stdout) { $r.Stdout } else { "" }
        $first20 = ($stdoutText -split "`n" | Select-Object -First 20) -join "`n"
        Assert-True ($first20 -match '\[bridge state\]') "[$flavor] SC-001: '[bridge state]' must appear in first 20 lines of stdout, got: $first20"
        Assert-True ($first20 -match 'Pending tasks: 3\b') "[$flavor] SC-001: 'Pending tasks: 3' missing from first 20 lines, got: $first20"

        # ----- SC-002a: WARNING fires on complete-with-unchecked (pending fixture, transitioning to complete) -----
        if ($flavor -eq "ps") {
            $r = Invoke-CapturedPs -ScriptPath $updatePsScript -Params @{ Status = "complete"; Actor = "claude" }
        } else {
            $r = Invoke-CapturedBash -BashScript $updateBashScript -BashArgs @("--status","complete","--actor","claude")
            if ($null -eq $r) { continue }
        }
        Assert-True ($r.ExitCode -eq 0) "[$flavor] SC-002a: update-handoff exit code on complete = $($r.ExitCode)"
        $stderrText = if ($r.Stderr) { $r.Stderr } else { "" }
        Assert-True ($stderrText -match '\[bridge\] WARNING:.*unchecked tasks') "[$flavor] SC-002a: WARNING line missing from stderr on complete-with-unchecked. stderr=<<$stderrText>>"

        # ----- SC-002b: NO WARNING when all unchecked tasks are deferred -----
        Reset-HandoffToReady -HandoffPath $handoffPath -FeatureDir $deferredRel -Actor "claude" -ArtifactOwner "claude"
        if ($flavor -eq "ps") {
            $r = Invoke-CapturedPs -ScriptPath $updatePsScript -Params @{ Status = "executing"; Actor = "claude" }
        } else {
            $r = Invoke-CapturedBash -BashScript $updateBashScript -BashArgs @("--status","executing","--actor","claude")
            if ($null -eq $r) { continue }
        }
        $stdoutText = if ($r.Stdout) { $r.Stdout } else { "" }
        Assert-True ($stdoutText -match 'Pending tasks: 0\b') "[$flavor] SC-002b: 'Pending tasks: 0' expected when all unchecked are deferred, got stdout=<<$stdoutText>>"

        if ($flavor -eq "ps") {
            $r = Invoke-CapturedPs -ScriptPath $updatePsScript -Params @{ Status = "complete"; Actor = "claude" }
        } else {
            $r = Invoke-CapturedBash -BashScript $updateBashScript -BashArgs @("--status","complete","--actor","claude")
            if ($null -eq $r) { continue }
        }
        $stderrText = if ($r.Stderr) { $r.Stderr } else { "" }
        Assert-True ($stderrText -notmatch '\[bridge\] WARNING:') "[$flavor] SC-002b: WARNING must NOT fire when all unchecked are deferred. stderr=<<$stderrText>>"

        # ----- SC-003: prior_actor in event log + reason mentions actor change -----
        Reset-HandoffToReady -HandoffPath $handoffPath -FeatureDir $pendingRel -Actor "claude" -ArtifactOwner "claude"
        if ($flavor -eq "ps") {
            $null = Invoke-CapturedPs -ScriptPath $updatePsScript -Params @{ Status = "executing"; Actor = "claude" }
            $null = Invoke-CapturedPs -ScriptPath $updatePsScript -Params @{ Status = "executing"; Actor = "codex" }
        } else {
            $null = Invoke-CapturedBash -BashScript $updateBashScript -BashArgs @("--status","executing","--actor","claude")
            $null = Invoke-CapturedBash -BashScript $updateBashScript -BashArgs @("--status","executing","--actor","codex")
        }

        $lastLine = Get-Content -LiteralPath $eventLogPath | Where-Object { $_ -match '"action":"handoff"' } | Select-Object -Last 1
        $parsed = $lastLine | ConvertFrom-Json
        Assert-True ($parsed.actor -eq "codex") "[$flavor] SC-003: event log actor expected 'codex', got '$($parsed.actor)'"
        $names = $parsed.PSObject.Properties.Name
        Assert-True ($names -contains "prior_actor") "[$flavor] SC-003: event log line MUST contain 'prior_actor' field"
        Assert-True ($parsed.prior_actor -eq "claude") "[$flavor] SC-003: prior_actor expected 'claude', got '$($parsed.prior_actor)'"
        Assert-True ($parsed.reason -match 'actor change claude') "[$flavor] SC-003: reason MUST contain 'actor change claude', got '$($parsed.reason)'"
        Assert-True ($parsed.reason -match 'codex') "[$flavor] SC-003: reason MUST contain 'codex' (the new actor), got '$($parsed.reason)'"

        $exercisedFlavors += $flavor
    }

    if ($exercisedFlavors.Count -eq 0) {
        Write-Output "bridge-state-summary-tests-ok (no flavors exercised — see skip reasons above)"
    } else {
        Write-Output "bridge-state-summary-tests-ok ($($exercisedFlavors -join ', '))"
    }
}
finally {
    if ($backupHandoff) {
        Set-Content -LiteralPath $handoffPath -Value $backupHandoff -Encoding UTF8 -NoNewline
    }
    # Trim event log back to its pre-test length (avoid polluting audit trail with test entries)
    if (Test-Path -LiteralPath $eventLogPath -PathType Leaf) {
        $fs = [System.IO.File]::Open($eventLogPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite)
        try { $fs.SetLength($eventLogSizeBefore) } finally { $fs.Dispose() }
    }
    # Clean temp feature dirs
    Remove-Item -LiteralPath $pendingDir, $deferredDir -Recurse -Force -ErrorAction SilentlyContinue
}
