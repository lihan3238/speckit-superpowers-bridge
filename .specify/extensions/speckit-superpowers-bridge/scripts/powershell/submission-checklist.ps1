param(
    [switch]$Json,
    [switch]$Strict,
    [switch]$OfflineOnly,
    [switch]$LogEvent,
    [ValidateSet("codex", "claude", "unknown")]
    [string]$Actor = ""
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "common-actor-resolution.ps1")

function Get-RepoRootSC {
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

function New-SCFinding {
    param(
        [string]$Code,
        [string]$Severity,
        [string]$Target,
        [string]$Message,
        [string]$SuggestedFix
    )
    return [pscustomobject]@{
        code          = $Code
        severity      = $Severity
        target        = $Target
        message       = $Message
        suggested_fix = $SuggestedFix
    }
}

$repoRoot = Get-RepoRootSC
$Actor = Resolve-BridgeActor -Argument $Actor -RepoRoot $repoRoot

$findings = New-Object System.Collections.Generic.List[object]
$lockedTagSet = @("bridge", "superpowers", "cross-agent", "governance", "tdd", "workflow")

# ---- Check 1: LICENSE present + non-empty ----
$licensePath = Join-Path $repoRoot "LICENSE"
if (-not (Test-Path -LiteralPath $licensePath)) {
    $findings.Add((New-SCFinding -Code "license_missing" -Severity "P0" -Target $licensePath -Message "LICENSE not found at repo root" -SuggestedFix "Create LICENSE with MIT text matching extension.yml.extension.license"))
}
elseif ((Get-Item -LiteralPath $licensePath).Length -le 0) {
    $findings.Add((New-SCFinding -Code "license_missing" -Severity "P0" -Target $licensePath -Message "LICENSE is empty" -SuggestedFix "Populate LICENSE with MIT text"))
}

# ---- Check 2: CHANGELOG.md present with >=1 released version section ----
$changelogPath = Join-Path $repoRoot "CHANGELOG.md"
if (-not (Test-Path -LiteralPath $changelogPath)) {
    $findings.Add((New-SCFinding -Code "changelog_missing" -Severity "P0" -Target $changelogPath -Message "CHANGELOG.md not found at repo root" -SuggestedFix "Create CHANGELOG.md following Keep-a-Changelog"))
}
else {
    $content = Get-Content -LiteralPath $changelogPath -Raw
    if ($content -notmatch '##\s*\[?\d+\.\d+\.\d+\]?') {
        $findings.Add((New-SCFinding -Code "changelog_missing" -Severity "P0" -Target $changelogPath -Message "CHANGELOG.md has no released-version section (## [N.N.N])" -SuggestedFix "Add at least one version section following Keep-a-Changelog"))
    }
}

# ---- Check 3: extension.yml parses + required fields present ----
$extensionPath = Join-Path $repoRoot ".specify\extensions\speckit-superpowers-bridge\extension.yml"
$extensionContent = $null
if (-not (Test-Path -LiteralPath $extensionPath)) {
    $findings.Add((New-SCFinding -Code "manifest_invalid" -Severity "P0" -Target $extensionPath -Message "extension.yml not found" -SuggestedFix "Restore the extension manifest at $extensionPath"))
}
else {
    $extensionContent = Get-Content -LiteralPath $extensionPath -Raw
    $requiredFields = @{
        "id"          = '(?ms)extension:\s*[\r\n]+(?:.*?[\r\n]+)*?\s*id:\s*(\S+)'
        "name"        = '(?ms)extension:\s*[\r\n]+(?:.*?[\r\n]+)*?\s*name:\s*"?([^"\r\n]+)"?'
        "version"     = '(?ms)extension:\s*[\r\n]+(?:.*?[\r\n]+)*?\s*version:\s*"?(\d+\.\d+\.\d+)"?'
        "description" = '(?ms)extension:\s*[\r\n]+(?:.*?[\r\n]+)*?\s*description:\s*"?([^"\r\n]+)"?'
        "author"      = '(?ms)extension:\s*[\r\n]+(?:.*?[\r\n]+)*?\s*author:\s*"?([^"\r\n]+)"?'
        "repository"  = '(?ms)extension:\s*[\r\n]+(?:.*?[\r\n]+)*?\s*repository:\s*"?([^"\r\n]+)"?'
        "license"     = '(?ms)extension:\s*[\r\n]+(?:.*?[\r\n]+)*?\s*license:\s*"?([^"\r\n]+)"?'
        "speckit_version" = '(?ms)requires:\s*[\r\n]+(?:.*?[\r\n]+)*?\s*speckit_version:\s*"?([^"\r\n]+)"?'
    }
    foreach ($field in $requiredFields.Keys) {
        if ($extensionContent -notmatch $requiredFields[$field]) {
            $findings.Add((New-SCFinding -Code "manifest_invalid" -Severity "P0" -Target "extension.yml#$field" -Message "Required field '$field' missing from extension.yml" -SuggestedFix "Add '$field' under extension: or requires: per Spec Kit ExtensionManifest schema"))
        }
    }
}

# ---- Check 4: extension.yml.tags equals locked 6-tag set ----
if ($extensionContent) {
    $tagBlock = [regex]::Match($extensionContent, '(?ms)^tags:\s*[\r\n]+((?:\s*-\s*\S+\s*[\r\n]+)+)')
    if (-not $tagBlock.Success) {
        $findings.Add((New-SCFinding -Code "tags_mismatch" -Severity "P1" -Target "extension.yml#tags" -Message "tags: block missing or malformed" -SuggestedFix "Add 'tags:' as a YAML list with the locked 6-tag set"))
    }
    else {
        $tagLines = $tagBlock.Groups[1].Value -split "`r?`n" | Where-Object { $_ -match '^\s*-\s*(\S+)' }
        $actualTags = @($tagLines | ForEach-Object { ([regex]::Match($_, '^\s*-\s*(\S+)')).Groups[1].Value.ToLowerInvariant() })
        $missing = @($lockedTagSet | Where-Object { $_ -notin $actualTags })
        $extra = @($actualTags | Where-Object { $_ -notin $lockedTagSet })
        if ($missing.Count -gt 0 -or $extra.Count -gt 0) {
            $msg = "Tags differ from locked set. Missing: [$($missing -join ', ')]. Extra: [$($extra -join ', ')]."
            $findings.Add((New-SCFinding -Code "tags_mismatch" -Severity "P1" -Target "extension.yml#tags" -Message $msg -SuggestedFix "Set tags to exactly: $($lockedTagSet -join ', ')"))
        }
    }
}

# ---- Check 5: extension.yml.description length <=200 ----
if ($extensionContent) {
    $descMatch = [regex]::Match($extensionContent, '(?ms)extension:\s*[\r\n]+(?:.*?[\r\n]+)*?\s*description:\s*"?([^"\r\n]+)"?')
    if ($descMatch.Success) {
        $desc = $descMatch.Groups[1].Value.Trim()
        if ($desc.Length -gt 200) {
            $findings.Add((New-SCFinding -Code "description_too_long" -Severity "P1" -Target "extension.yml#description" -Message "description is $($desc.Length) chars (>200)" -SuggestedFix "Shorten description to <=200 chars"))
        }
    }
}

# ---- Check 6: marketplace/catalog-entry.json exists, parses, structural validation ----
$catalogEntryPath = Join-Path $repoRoot "marketplace\catalog-entry.json"
$catalogEntry = $null
if (-not (Test-Path -LiteralPath $catalogEntryPath)) {
    $findings.Add((New-SCFinding -Code "catalog_entry_invalid" -Severity "P0" -Target $catalogEntryPath -Message "marketplace/catalog-entry.json not found" -SuggestedFix "Create marketplace/catalog-entry.json per contracts/catalog-entry.schema.json"))
}
else {
    try {
        $catalogEntry = Get-Content -LiteralPath $catalogEntryPath -Raw | ConvertFrom-Json
    }
    catch {
        $findings.Add((New-SCFinding -Code "catalog_entry_invalid" -Severity "P0" -Target $catalogEntryPath -Message "catalog-entry.json failed to parse: $($_.Exception.Message)" -SuggestedFix "Repair JSON"))
    }
    if ($catalogEntry) {
        $catalogRequired = @("id", "name", "description", "author", "version", "license", "repository", "download_url", "requires", "tags")
        foreach ($req in $catalogRequired) {
            if (-not ($catalogEntry.PSObject.Properties.Name -contains $req)) {
                $findings.Add((New-SCFinding -Code "catalog_entry_invalid" -Severity "P0" -Target "catalog-entry.json#$req" -Message "Required field '$req' missing" -SuggestedFix "Add '$req' per contracts/catalog-entry.schema.json"))
            }
        }
        if ($catalogEntry.description -and ([string]$catalogEntry.description).Length -gt 200) {
            $findings.Add((New-SCFinding -Code "catalog_entry_invalid" -Severity "P1" -Target "catalog-entry.json#description" -Message "description is $($catalogEntry.description.Length) chars (>200)" -SuggestedFix "Shorten to <=200 chars"))
        }
        if ($catalogEntry.version -and ([string]$catalogEntry.version) -notmatch '^\d+\.\d+\.\d+(-[0-9A-Za-z-.]+)?(\+[0-9A-Za-z-.]+)?$') {
            $findings.Add((New-SCFinding -Code "catalog_entry_invalid" -Severity "P0" -Target "catalog-entry.json#version" -Message "version '$($catalogEntry.version)' is not valid semver" -SuggestedFix "Use MAJOR.MINOR.PATCH semver"))
        }
        if ($catalogEntry.tags) {
            $cTags = @($catalogEntry.tags | ForEach-Object { [string]$_ })
            if ($cTags.Count -lt 2 -or $cTags.Count -gt 10) {
                $findings.Add((New-SCFinding -Code "catalog_entry_invalid" -Severity "P1" -Target "catalog-entry.json#tags" -Message "tags count $($cTags.Count) is outside [2,10]" -SuggestedFix "Provide 2-10 tags"))
            }
        }
    }
}

# ---- Check 7: download_url HTTP 200 (skipped if -OfflineOnly) ----
if ($OfflineOnly) {
    # Recorded as skipped — emit a finding with severity P3 just for traceability; doesn't affect exit code.
    if ($catalogEntry -and $catalogEntry.download_url) {
        $findings.Add((New-SCFinding -Code "download_url_skipped" -Severity "P3" -Target $catalogEntry.download_url -Message "HTTP accessibility check skipped (-OfflineOnly)" -SuggestedFix "Re-run without -OfflineOnly to verify"))
    }
}
elseif ($catalogEntry -and $catalogEntry.download_url) {
    $url = [string]$catalogEntry.download_url
    try {
        Add-Type -AssemblyName System.Net.Http -ErrorAction SilentlyContinue
        $client = New-Object System.Net.Http.HttpClient
        $client.Timeout = [TimeSpan]::FromSeconds(10)
        $request = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::Head, $url)
        $response = $client.SendAsync($request).Result
        $statusCode = [int]$response.StatusCode
        $client.Dispose()
        if ($statusCode -ne 200) {
            $findings.Add((New-SCFinding -Code "download_url_unreachable" -Severity "P0" -Target $url -Message "HTTP HEAD returned $statusCode" -SuggestedFix "Ensure release ZIP is published at this URL"))
        }
    }
    catch {
        $findings.Add((New-SCFinding -Code "download_url_unreachable" -Severity "P0" -Target $url -Message "HTTP HEAD failed: $($_.Exception.Message)" -SuggestedFix "Verify URL is reachable; release ZIP published"))
    }
}

# ---- Check 8: marketplace/upstream-pr-body.md contains AI-disclosure paragraph ----
$prBodyPath = Join-Path $repoRoot "marketplace\upstream-pr-body.md"
if (-not (Test-Path -LiteralPath $prBodyPath)) {
    $findings.Add((New-SCFinding -Code "ai_disclosure_missing" -Severity "P1" -Target $prBodyPath -Message "marketplace/upstream-pr-body.md not found" -SuggestedFix "Create the PR body template with AI-disclosure paragraph"))
}
else {
    $prContent = Get-Content -LiteralPath $prBodyPath -Raw
    if ($prContent -notmatch '(?is)(AI|artificial intelligence).{0,200}(coding\s+assistant|assistant|disclosure)') {
        $findings.Add((New-SCFinding -Code "ai_disclosure_missing" -Severity "P1" -Target $prBodyPath -Message "AI-assistance disclosure paragraph not detected in upstream-pr-body.md" -SuggestedFix "Add the disclosure paragraph per Spec Kit CONTRIBUTING.md"))
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

$targetVersion = $null
if ($extensionContent) {
    $vMatch = [regex]::Match($extensionContent, '(?ms)extension:\s*[\r\n]+(?:.*?[\r\n]+)*?\s*version:\s*"?(\d+\.\d+\.\d+)"?')
    if ($vMatch.Success) { $targetVersion = $vMatch.Groups[1].Value }
}

$summary = [ordered]@{
    total       = $findings.Count
    by_severity = $counts
}

$report = [ordered]@{
    schema_version = 1
    generated_at   = (Get-Date).ToUniversalTime().ToString("o")
    target_version = $targetVersion
    findings       = @($findings.ToArray())
    summary        = $summary
    exit_code      = $exitCode
}

if ($LogEvent) {
    $eventPath = Join-Path $repoRoot ".specify\bridge-events.jsonl"
    if (Test-Path -LiteralPath (Split-Path $eventPath -Parent)) {
        $decision = if ($exitCode -eq 0) { "allow" } else { "deny" }
        $reason = "submission-check: $($findings.Count) finding(s); P0=$([int]$counts['P0']) P1=$([int]$counts['P1']); exit_code=$exitCode"
        $evt = [ordered]@{
            timestamp       = (Get-Date).ToUniversalTime().ToString("o")
            action          = "submission_check"
            status          = ""
            feature_directory = ""
            decision        = $decision
            reason          = $reason
            actor           = $Actor
            snapshot_id     = $null
        }
        ($evt | ConvertTo-Json -Compress -Depth 6) + [Environment]::NewLine | Add-Content -LiteralPath $eventPath -Encoding UTF8
    }
}

if ($Json) {
    $report | ConvertTo-Json -Depth 10
}
else {
    Write-Output "Submission checklist for v$($targetVersion): $($findings.Count) finding(s) (P0=$([int]$counts['P0']) P1=$([int]$counts['P1']) P2=$([int]$counts['P2']) P3=$([int]$counts['P3']))."
    foreach ($f in $findings) {
        [Console]::Error.WriteLine("[$($f.severity)] $($f.code)  $($f.target) - $($f.message). Fix: $($f.suggested_fix)")
    }
    if ($exitCode -eq 0) { Write-Output "Submission-ready." }
}

exit $exitCode
