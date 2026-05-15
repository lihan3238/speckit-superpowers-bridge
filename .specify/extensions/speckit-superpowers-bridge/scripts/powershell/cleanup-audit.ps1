param(
    [switch]$Json,
    [switch]$Strict,
    [switch]$Fix,
    [ValidateSet("codex", "claude", "unknown")]
    [string]$Actor = ""
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "common-actor-resolution.ps1")

function Get-RepoRootCA {
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $previousErrorAction = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        try {
            $root = (& git rev-parse --show-toplevel 2>$null)
            if ($LASTEXITCODE -eq 0 -and $root) { return $root.Trim() }
        }
        finally { $ErrorActionPreference = $previousErrorAction }
    }
    return (Get-Location).Path
}

function New-CAFinding {
    param([string]$Code, [string]$Severity, [string]$Target, [string]$Message, [string]$SuggestedFix)
    return [pscustomobject]@{
        code          = $Code
        severity      = $Severity
        target        = $Target
        message       = $Message
        suggested_fix = $SuggestedFix
    }
}

$repoRoot = Get-RepoRootCA
$Actor = Resolve-BridgeActor -Argument $Actor -RepoRoot $repoRoot
$findings = New-Object System.Collections.Generic.List[object]
$fixed = New-Object System.Collections.Generic.List[string]

# ---- Check 1: backup files (*.bak, *.bak-*, *.orig, *.tmp) ----
$backupPatterns = @("*.bak", "*.bak-*", "*.orig", "*.tmp")
$backupFiles = @(Get-ChildItem -Path $repoRoot -Recurse -File -Force -Include $backupPatterns -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch '\\\.git\\' })
foreach ($f in $backupFiles) {
    $rel = $f.FullName.Substring($repoRoot.Length).TrimStart('\','/').Replace('\','/')
    $finding = New-CAFinding -Code "backup_file_present" -Severity "P2" -Target $rel -Message "Backup file present" -SuggestedFix "Delete $rel"
    $findings.Add($finding)
    if ($Fix) {
        try { Remove-Item -LiteralPath $f.FullName -Force; $fixed.Add($rel) } catch {}
    }
}

# ---- Check 2: unreferenced docs in .specify/extensions/speckit-superpowers-bridge/docs/ ----
$extDocsDir = Join-Path $repoRoot ".specify\extensions\speckit-superpowers-bridge\docs"
if (Test-Path -LiteralPath $extDocsDir) {
    $readmePath = Join-Path $repoRoot "README.md"
    $extensionYmlPath = Join-Path $repoRoot ".specify\extensions\speckit-superpowers-bridge\extension.yml"
    $readmeContent = if (Test-Path -LiteralPath $readmePath) { Get-Content -LiteralPath $readmePath -Raw } else { "" }
    $extContent = if (Test-Path -LiteralPath $extensionYmlPath) { Get-Content -LiteralPath $extensionYmlPath -Raw } else { "" }
    foreach ($f in (Get-ChildItem -LiteralPath $extDocsDir -File)) {
        $referenced = ($readmeContent -match [regex]::Escape($f.Name)) -or ($extContent -match [regex]::Escape($f.Name))
        if (-not $referenced) {
            $rel = $f.FullName.Substring($repoRoot.Length).TrimStart('\','/').Replace('\','/')
            $findings.Add((New-CAFinding -Code "unreferenced_doc" -Severity "P2" -Target $rel -Message "Extension doc not referenced from README.md or extension.yml" -SuggestedFix "Reference $rel or delete it"))
        }
    }
}

# ---- Check 3: abandoned one-shot scripts at repo root ----
$abandonedPatterns = @("bump-*.ps1", "migrate-*.ps1", "fix-*.ps1", "patch-*.ps1")
$abandonedScripts = @(Get-ChildItem -Path $repoRoot -File -Force -Include $abandonedPatterns -ErrorAction SilentlyContinue |
    Where-Object { $_.DirectoryName -eq $repoRoot })
foreach ($f in $abandonedScripts) {
    $rel = $f.Name
    $finding = New-CAFinding -Code "abandoned_script" -Severity "P2" -Target $rel -Message "Root-level one-shot script appears abandoned" -SuggestedFix "Delete $rel or move into .specify/extensions/.../scripts/ with rationale"
    $findings.Add($finding)
    if ($Fix) {
        try { Remove-Item -LiteralPath $f.FullName -Force; $fixed.Add($rel) } catch {}
    }
}

# ---- Check 4: .gitignore covers 5 categories ----
$gitignorePath = Join-Path $repoRoot ".gitignore"
$missingCategories = @()
if (-not (Test-Path -LiteralPath $gitignorePath)) {
    $missingCategories += "per-developer state"
    $missingCategories += "OS junk"
    $missingCategories += "backup patterns"
    $missingCategories += "editor scratch"
    $missingCategories += "build artifacts"
}
else {
    $giContent = Get-Content -LiteralPath $gitignorePath -Raw
    if ($giContent -notmatch '(?i)superpowers-handoff|bridge-events\.jsonl|bridge-snapshots|feature\.json') { $missingCategories += "per-developer state" }
    if ($giContent -notmatch '(?i)\.DS_Store|Thumbs\.db|desktop\.ini') { $missingCategories += "OS junk" }
    if ($giContent -notmatch '(?i)\*\.bak|\*\.orig|\*\.tmp') { $missingCategories += "backup patterns" }
    if ($giContent -notmatch '(?i)\*\.swp|\.idea|\.vscode|editor') { $missingCategories += "editor scratch" }
    if ($giContent -notmatch '(?i)build|dist|out|target|node_modules') { $missingCategories += "build artifacts" }
}
if ($missingCategories.Count -gt 0) {
    foreach ($cat in $missingCategories) {
        $findings.Add((New-CAFinding -Code "gitignore_gap" -Severity "P1" -Target ".gitignore" -Message ".gitignore missing category: $cat" -SuggestedFix "Add a commented section covering '$cat' patterns"))
    }
}

# ---- Check 5: plugin-distribution-manifest.yml consistency ----
$manifestPath = Join-Path $repoRoot ".specify\extensions\speckit-superpowers-bridge\plugin-distribution-manifest.yml"
if (Test-Path -LiteralPath $manifestPath) {
    $manifestLines = Get-Content -LiteralPath $manifestPath
    $includes = @()
    $excludes = @()
    $section = $null
    foreach ($line in $manifestLines) {
        if ($line -match '^\s*includes:\s*$') { $section = "includes"; continue }
        if ($line -match '^\s*excludes:\s*$') { $section = "excludes"; continue }
        if ($line -match '^\s*notes:\s*$' -or $line -match '^\s*#') { continue }
        if ($line -match '^\S' -and $line -notmatch '^\s*-\s') { $section = $null }
        if ($section -and $line -match '^\s*-\s*path:\s*(.+?)(?:\s|$)') {
            $path = $Matches[1].Trim().Trim('"').Trim("'")
            if ($section -eq "includes") { $includes += $path } else { $excludes += $path }
        }
    }

    # Validate every include path resolves (allowing glob patterns; only literal paths checked)
    foreach ($p in $includes) {
        if ($p -notmatch '[\*\?\[]') {
            $abs = Join-Path $repoRoot $p
            if (-not (Test-Path -LiteralPath $abs)) {
                $findings.Add((New-CAFinding -Code "manifest_path_inconsistency" -Severity "P0" -Target $p -Message "includes path does not exist on disk" -SuggestedFix "Create the file or remove from includes"))
            }
        }
    }

    # No path appears in both lists
    $overlap = $includes | Where-Object { $_ -in $excludes }
    foreach ($p in $overlap) {
        $findings.Add((New-CAFinding -Code "manifest_path_inconsistency" -Severity "P0" -Target $p -Message "path appears in both includes and excludes" -SuggestedFix "Move to only one list"))
    }
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

$report = [ordered]@{
    schema_version = 1
    generated_at   = (Get-Date).ToUniversalTime().ToString("o")
    findings       = @($findings.ToArray())
    summary        = [ordered]@{ total = $findings.Count; by_severity = $counts }
    fixed          = @($fixed.ToArray())
    exit_code      = $exitCode
}

if ($Json) {
    $report | ConvertTo-Json -Depth 10
}
else {
    Write-Output "Cleanup audit: $($findings.Count) finding(s) (P0=$([int]$counts['P0']) P1=$([int]$counts['P1']) P2=$([int]$counts['P2']) P3=$([int]$counts['P3']))."
    foreach ($f in $findings) {
        [Console]::Error.WriteLine("[$($f.severity)] $($f.code)  $($f.target) - $($f.message). Fix: $($f.suggested_fix)")
    }
    if ($Fix -and $fixed.Count -gt 0) {
        Write-Output "Fixed $($fixed.Count) item(s): $($fixed -join ', ')"
    }
}

exit $exitCode
