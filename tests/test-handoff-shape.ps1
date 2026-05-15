$ErrorActionPreference = "Stop"

# Smoke test for the v1 handoff schema (FR-006 + FR-009).
# Covers:
#   (a) update-handoff.ps1 writes a JSON document matching the v1 shape
#   (b) reading a fabricated v3-shape handoff does not error
#   (c) new writes do not echo back v3-only fields (autonomous_mode, resume_context, archive_history)

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

function Get-AvailableFlavors {
    param([string]$BridgeRoot)
    $flavors = @()
    if (Test-Path -LiteralPath (Join-Path $BridgeRoot "scripts/powershell/update-handoff.ps1")) { $flavors += "ps" }
    if (Test-Path -LiteralPath (Join-Path $BridgeRoot "scripts/bash/update-handoff.sh")) { $flavors += "bash" }
    return $flavors
}

function Convert-ToBashPath {
    param([string]$Path)

    # Normalize backslashes to forward slashes first
    $normalized = $Path.Replace('\', '/')

    # Strategy 1: ask bash to translate via cygpath (MSYS/Cygwin/git-bash)
    if (Get-Command bash -ErrorAction SilentlyContinue) {
        $prev = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try {
            $cygpathOut = & bash -c "command -v cygpath >/dev/null 2>&1 && cygpath -u '$normalized' 2>/dev/null" 2>$null
        } finally {
            $ErrorActionPreference = $prev
        }
        if ($LASTEXITCODE -eq 0 -and $cygpathOut) {
            return $cygpathOut.Trim()
        }
    }

    # Strategy 2: input already in WSL form
    if ($normalized -match '^/mnt/[a-z]/') { return $normalized }

    # Strategy 3: Windows drive path → MSYS shorthand /<drive>/...
    if ($normalized -match '^([A-Za-z]):/(.*)$') {
        return "/$($Matches[1].ToLowerInvariant())/$($Matches[2])"
    }

    # Strategy 4: Linux/macOS native — path is already correct
    return $normalized
}

function Test-BashPathReachable {
    param([string]$BashPath)
    if (-not (Get-Command bash -ErrorAction SilentlyContinue)) { return $false }
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $check = & bash -c "[ -f '$BashPath' ] && echo OK" 2>$null
    } finally {
        $ErrorActionPreference = $prev
    }
    return ($check -eq 'OK')
}

function Invoke-UpdateHandoff {
    param([string]$Flavor, [string[]]$Arguments)

    $parsed = @{}
    for ($i = 0; $i -lt $Arguments.Count; $i++) {
        switch ($Arguments[$i]) {
            "-Status" { $parsed.Status = $Arguments[++$i]; continue }
            "-FeatureDirectory" { $parsed.FeatureDirectory = $Arguments[++$i]; continue }
            "-Reason" { $parsed.Reason = $Arguments[++$i]; continue }
            "-ArtifactOwner" { $parsed.ArtifactOwner = $Arguments[++$i]; continue }
            "-Actor" { $parsed.Actor = $Arguments[++$i]; continue }
            default { throw "Unsupported update-handoff test argument: $($Arguments[$i])" }
        }
    }

    if ($Flavor -eq "ps") {
        & $updatePsScript @parsed | Out-Null
        return $true
    }

    if (-not (Get-Command bash -ErrorAction SilentlyContinue)) {
        Write-Host "  (bash flavor not exercised: bash not on PATH)"
        return $false
    }

    $bashPath = Convert-ToBashPath -Path $updateBashScript
    if (-not (Test-BashPathReachable -BashPath $bashPath)) {
        Write-Host "  (bash flavor not exercised: path-translation produced unreachable path '$bashPath')"
        return $false
    }

    $bashArgs = @()
    if ($parsed.ContainsKey("Status")) { $bashArgs += "--status"; $bashArgs += $parsed.Status }
    if ($parsed.ContainsKey("FeatureDirectory")) { $bashArgs += "--feature-directory"; $bashArgs += $parsed.FeatureDirectory }
    if ($parsed.ContainsKey("Reason")) { $bashArgs += "--reason"; $bashArgs += $parsed.Reason }
    if ($parsed.ContainsKey("ArtifactOwner")) { $bashArgs += "--artifact-owner"; $bashArgs += $parsed.ArtifactOwner }
    if ($parsed.ContainsKey("Actor")) { $bashArgs += "--actor"; $bashArgs += $parsed.Actor }

    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $bashOutput = & bash $bashPath @bashArgs 2>&1
    } finally {
        $ErrorActionPreference = $prev
    }
    if ($LASTEXITCODE -ne 0) {
        $reason = (($bashOutput | Select-Object -First 1) -as [string])
        Write-Host "  (bash flavor not exercised: bash exited $LASTEXITCODE - $reason)"
        return $false
    }
    return $true
}

$repoRoot = Get-RepoRoot
$bridgeRoot = Join-Path $repoRoot ".specify/extensions/speckit-superpowers-bridge"
$updatePsScript = Join-Path $bridgeRoot "scripts/powershell/update-handoff.ps1"
$updateBashScript = Join-Path $bridgeRoot "scripts/bash/update-handoff.sh"
$handoffPath = Join-Path $repoRoot ".specify/superpowers-handoff.json"
$flavors = @(Get-AvailableFlavors -BridgeRoot $bridgeRoot)
Assert-True ($flavors.Count -gt 0) "no update-handoff flavors available"

# Snapshot current handoff so we can restore it after the test
$backupContent = if (Test-Path -LiteralPath $handoffPath) { Get-Content -LiteralPath $handoffPath -Raw } else { $null }

try {
    $exercisedFlavors = @()
    foreach ($flavor in $flavors) {
        if ($flavor -eq "bash" -and -not (Get-Command bash -ErrorAction SilentlyContinue)) { continue }

        # --- (a) v1 write shape ---
        $ok = Invoke-UpdateHandoff -Flavor $flavor -Arguments @("-Status", "executing", "-FeatureDirectory", "specs/006-trim-to-thin-bridge", "-ArtifactOwner", "claude", "-Actor", "claude", "-Reason", "smoke test (a)")
        if (-not $ok) { continue }
        $exercisedFlavors += $flavor
        $h = Get-Content -LiteralPath $handoffPath -Raw | ConvertFrom-Json

        Assert-True ($h.schema_version -eq 1) "[$flavor] schema_version should be 1, got $($h.schema_version)"
        Assert-True ($h.status -in @("ready","executing","blocked","complete")) "[$flavor] status not in v1 enum"
        Assert-True ($null -ne $h.source_of_truth) "[$flavor] source_of_truth missing"
        Assert-True ($h.source_of_truth.constitution -eq ".specify/memory/constitution.md") "[$flavor] constitution path wrong"
        Assert-True ($h.artifact_owner -in @("codex","claude","unknown")) "[$flavor] artifact_owner not in v1 enum"
        Assert-True ($null -ne $h.updated_at) "[$flavor] updated_at missing"

        # v3-only fields must NOT appear in new writes
        $names = $h.PSObject.Properties.Name
        foreach ($dropped in @("autonomous_mode","resume_context","archive_history")) {
            Assert-True (-not ($names -contains $dropped)) "[$flavor] v1 write should not contain v3 field: $dropped"
        }

        # --- (b) backward-read of v3 JSON ---
        $v3 = @{
            schema_version = 3
            updated_at = "2026-05-15T00:00:00Z"
            feature_directory = "specs/006-trim-to-thin-bridge"
            source_of_truth = @{
                constitution = ".specify/memory/constitution.md"
                spec = "specs/006-trim-to-thin-bridge/spec.md"
                plan = "specs/006-trim-to-thin-bridge/plan.md"
                tasks = "specs/006-trim-to-thin-bridge/tasks.md"
            }
            executor = "superpowers"
            status = "executing"
            artifact_owner = "claude"
            autonomous_mode = $true
            resume_context = @{ last_task = "Tsmoke" }
            archive_history = @(@{ feature_directory = "specs/005-marketplace-alignment" })
        } | ConvertTo-Json -Depth 5
        Set-Content -LiteralPath $handoffPath -Value $v3 -Encoding UTF8

        # Reading via update-handoff should NOT throw on v3-only fields
        $ok = Invoke-UpdateHandoff -Flavor $flavor -Arguments @("-Status", "executing", "-Actor", "claude", "-Reason", "smoke test (b)")
        if (-not $ok) { continue }
        $post = Get-Content -LiteralPath $handoffPath -Raw | ConvertFrom-Json
        Assert-True ($post.schema_version -eq 1) "[$flavor] post-write schema_version should be 1"
        $postNames = $post.PSObject.Properties.Name
        foreach ($dropped in @("autonomous_mode","resume_context","archive_history")) {
            Assert-True (-not ($postNames -contains $dropped)) "[$flavor] after reading v3, new write echoed back: $dropped"
        }
        # --- (c) prior artifact_owner preserved when -ArtifactOwner is NOT passed (B1 / FR-001) ---
        # Setup: write a synthetic handoff with artifact_owner=claude
        $synthetic = @{
            schema_version = 1
            updated_at = "2026-05-15T00:00:00Z"
            feature_directory = "specs/006-trim-to-thin-bridge"
            source_of_truth = @{
                constitution = ".specify/memory/constitution.md"
                spec = "specs/006-trim-to-thin-bridge/spec.md"
                plan = "specs/006-trim-to-thin-bridge/plan.md"
                tasks = "specs/006-trim-to-thin-bridge/tasks.md"
            }
            executor = "superpowers"
            status = "executing"
            artifact_owner = "claude"
        } | ConvertTo-Json -Depth 5
        Set-Content -LiteralPath $handoffPath -Value $synthetic -Encoding UTF8

        # Invoke with -Actor codex but NO -ArtifactOwner — preservation should kick in
        $ok = Invoke-UpdateHandoff -Flavor $flavor -Arguments @("-Status", "executing", "-Actor", "codex", "-Reason", "smoke test (c) implicit preservation")
        if (-not $ok) { continue }
        $preserved = Get-Content -LiteralPath $handoffPath -Raw | ConvertFrom-Json
        Assert-True ($preserved.artifact_owner -eq "claude") "[$flavor] (c) artifact_owner should preserve prior 'claude', got '$($preserved.artifact_owner)'"

        # Inverse: invoke WITH explicit -ArtifactOwner codex — should override
        Set-Content -LiteralPath $handoffPath -Value $synthetic -Encoding UTF8
        $ok = Invoke-UpdateHandoff -Flavor $flavor -Arguments @("-Status", "executing", "-Actor", "codex", "-ArtifactOwner", "codex", "-Reason", "smoke test (c) explicit override")
        if (-not $ok) { continue }
        $overridden = Get-Content -LiteralPath $handoffPath -Raw | ConvertFrom-Json
        Assert-True ($overridden.artifact_owner -eq "codex") "[$flavor] (c) explicit -ArtifactOwner codex should override prior, got '$($overridden.artifact_owner)'"
    }

    if ($exercisedFlavors.Count -eq 0) {
        Write-Output "handoff-shape-tests-ok (no flavors exercised — see skip reasons above)"
    } else {
        Write-Output "handoff-shape-tests-ok ($($exercisedFlavors -join ', '))"
    }
}
finally {
    if ($backupContent) {
        Set-Content -LiteralPath $handoffPath -Value $backupContent -Encoding UTF8 -NoNewline
    }
}
