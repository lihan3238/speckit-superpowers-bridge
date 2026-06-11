param(
    [Parameter(Mandatory = $true)]
    [string]$Version,

    [string]$RepoRoot = "",

    [string]$PackageZip = ""
)

$ErrorActionPreference = "Stop"

function Add-Problem {
    param(
        [System.Collections.Generic.List[string]]$Problems,
        [string]$Message
    )
    $Problems.Add($Message)
}

function Get-RequiredText {
    param(
        [string]$Path,
        [System.Collections.Generic.List[string]]$Problems,
        [string]$Label
    )
    if (-not (Test-Path -LiteralPath $Path)) {
        Add-Problem $Problems "$Label not found at $Path"
        return $null
    }
    return Get-Content -LiteralPath $Path -Raw
}

function Get-ExtensionId {
    param(
        [string]$Manifest,
        [System.Collections.Generic.List[string]]$Problems
    )
    if ([string]::IsNullOrWhiteSpace($Manifest)) {
        return $null
    }
    $match = [regex]::Match($Manifest, '(?m)^\s{2,}id:\s*["'']?([^"''\s#]+)["'']?\s*$')
    if (-not $match.Success) {
        Add-Problem $Problems "extension.yml: extension.id could not be found"
        return $null
    }
    return $match.Groups[1].Value
}

function Test-IsoUtcTimestamp {
    param([object]$Value)

    if ($null -eq $Value) {
        return $false
    }
    if ($Value -is [datetime]) {
        return $Value.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ") -match '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$'
    }
    return ([string]$Value) -match '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$'
}

function Assert-ZipContents {
    param(
        [string]$ZipPath,
        [System.Collections.Generic.List[string]]$Problems
    )

    if ([string]::IsNullOrWhiteSpace($ZipPath)) {
        return
    }
    if (-not (Test-Path -LiteralPath $ZipPath -PathType Leaf)) {
        Add-Problem $Problems "Package ZIP not found at $ZipPath"
        return
    }

    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $zip = $null
    try {
        $zip = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
        $names = @($zip.Entries | ForEach-Object { $_.FullName })
        $requiredFiles = @(
            "extension.yml",
            "verified-versions.json",
            "README.md",
            "README.zh-CN.md",
            "CHANGELOG.md",
            "LICENSE",
            ".gitattributes"
        )
        foreach ($name in $requiredFiles) {
            if (-not ($names -contains $name)) {
                Add-Problem $Problems "Package ZIP: missing required root entry '$name'"
            }
        }
        foreach ($prefix in @("commands/", "scripts/bash/", "scripts/powershell/")) {
            if (-not (@($names | Where-Object { $_.StartsWith($prefix, [System.StringComparison]::Ordinal) }).Count -gt 0)) {
                Add-Problem $Problems "Package ZIP: missing required '$prefix' entries"
            }
        }
        $badBackslashEntries = @($names | Where-Object { $_ -match '\\' })
        if ($badBackslashEntries.Count -gt 0) {
            Add-Problem $Problems "Package ZIP: contains non-portable backslash entries: $($badBackslashEntries -join ', ')"
        }
        $topLevelDirEntries = @($names | Where-Object { $_ -match '^[^/]+/extension\.yml$' })
        if ($topLevelDirEntries.Count -gt 0 -and -not ($names -contains "extension.yml")) {
            Add-Problem $Problems "Package ZIP: extension.yml must be at archive root, not under a top-level folder"
        }
    } catch {
        Add-Problem $Problems "Package ZIP could not be inspected: $($_.Exception.Message)"
    } finally {
        if ($zip -ne $null) {
            $zip.Dispose()
        }
    }
}

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = (& git rev-parse --show-toplevel).Trim()
}
if (-not (Test-Path -LiteralPath $RepoRoot)) {
    Write-Output "RepoRoot not found: $RepoRoot"
    exit 2
}

$problems = New-Object System.Collections.Generic.List[string]

# 1. extension.yml version matches
$extYml = Join-Path $RepoRoot ".specify/extensions/speckit-superpowers-bridge/extension.yml"
$manifest = Get-RequiredText -Path $extYml -Problems $problems -Label "extension.yml"
$extensionId = $null
if ($manifest -ne $null) {
    $pattern = "version:\s*[`"']?$([regex]::Escape($Version))[`"']?\b"
    if ($manifest -notmatch $pattern) {
        Add-Problem $problems "extension.yml: extension.version does not match '$Version'"
    }
    if ($Version -notmatch '^\d+\.\d+\.\d+$') {
        Add-Problem $problems "release version '$Version' is not semantic version X.Y.Z"
    }
    $extensionId = Get-ExtensionId -Manifest $manifest -Problems $problems
    if ($extensionId -ne $null -and $extensionId -ne "speckit-superpowers-bridge") {
        Add-Problem $problems "extension.yml: extension.id is '$extensionId', expected 'speckit-superpowers-bridge'"
    }
    if ($extensionId -ne $null -and $extensionId -notmatch '^[a-z0-9]+(-[a-z0-9]+)*$') {
        Add-Problem $problems "extension.yml: extension.id must be lowercase alphanumeric with hyphens only"
    }

    if ($extensionId -ne $null) {
        $expectedNamespace = "speckit.$extensionId."
        $commandMatches = [regex]::Matches($manifest, '(?m)^\s*-\s+name:\s*["'']?([^"''\s#]+)["'']?')
        foreach ($match in $commandMatches) {
            $commandName = $match.Groups[1].Value
            if ($commandName.StartsWith("speckit.", [System.StringComparison]::Ordinal) -and
                -not $commandName.StartsWith($expectedNamespace, [System.StringComparison]::Ordinal)) {
                Add-Problem $problems "extension.yml: command namespace mismatch for '$commandName', expected prefix '$expectedNamespace'"
            }
        }

        $hookMatches = [regex]::Matches($manifest, '(?m)^\s*command:\s*["'']?([^"''\s#]+)["'']?')
        foreach ($match in $hookMatches) {
            $hookCommand = $match.Groups[1].Value
            if ($hookCommand.StartsWith("speckit.", [System.StringComparison]::Ordinal) -and
                -not $hookCommand.StartsWith($expectedNamespace, [System.StringComparison]::Ordinal)) {
                Add-Problem $problems "extension.yml: hook namespace mismatch for '$hookCommand', expected prefix '$expectedNamespace'"
            }
        }
    }
}

# 1b. verified-versions.json bridge version matches
$verifiedVersions = Join-Path $RepoRoot ".specify/extensions/speckit-superpowers-bridge/verified-versions.json"
if (-not (Test-Path -LiteralPath $verifiedVersions)) {
    Add-Problem $problems "verified-versions.json not found at $verifiedVersions"
} else {
    try {
        $verified = Get-Content -LiteralPath $verifiedVersions -Raw | ConvertFrom-Json
        if ($verified.bridge_version -ne $Version) {
            Add-Problem $problems "verified-versions.json: bridge_version is '$($verified.bridge_version)', expected '$Version'"
        }
    } catch {
        Add-Problem $problems "verified-versions.json could not be parsed as JSON: $($_.Exception.Message)"
    }
}

# 2 + 3. catalog-entry.json version + download_url
$catalog = Join-Path $RepoRoot "marketplace/catalog-entry.json"
if (-not (Test-Path -LiteralPath $catalog)) {
    Add-Problem $problems "catalog-entry.json not found at $catalog"
} else {
    $entry = Get-Content -LiteralPath $catalog -Raw | ConvertFrom-Json
    if ($extensionId -ne $null -and $entry.id -ne $extensionId) {
        Add-Problem $problems "catalog-entry.json: id is '$($entry.id)', expected extension id '$extensionId'"
    }
    if ($entry.version -ne $Version) {
        Add-Problem $problems "catalog-entry.json: version field is '$($entry.version)', expected '$Version'"
    }
    if ($entry.provides.commands -ne 3 -or $entry.provides.hooks -ne 5) {
        Add-Problem $problems "catalog-entry.json: provides counts must be commands=3 and hooks=5"
    }
    if ($entry.description -and $entry.description.Length -gt 200) {
        Add-Problem $problems "catalog-entry.json: description must stay under 200 characters for the official submission template"
    }
    $tagCount = @($entry.tags).Count
    if ($tagCount -lt 2 -or $tagCount -gt 5) {
        Add-Problem $problems "catalog-entry.json: tags must contain 2-5 entries for the official submission template"
    }
    foreach ($tag in @($entry.tags)) {
        if ($tag -notmatch '^[a-z0-9-]+$') {
            Add-Problem $problems "catalog-entry.json: tag '$tag' must be lowercase alphanumeric with hyphens only"
        }
    }
    foreach ($fieldName in @("verified", "downloads", "stars", "created_at", "updated_at")) {
        if ($null -eq $entry.$fieldName) {
            Add-Problem $problems "catalog-entry.json: missing official catalog field '$fieldName'"
        }
    }
    if ($null -ne $entry.created_at -and -not (Test-IsoUtcTimestamp -Value $entry.created_at)) {
        Add-Problem $problems "catalog-entry.json: created_at must be an ISO-8601 UTC timestamp"
    }
    if ($null -ne $entry.updated_at -and -not (Test-IsoUtcTimestamp -Value $entry.updated_at)) {
        Add-Problem $problems "catalog-entry.json: updated_at must be an ISO-8601 UTC timestamp"
    }
    # download_url: as of v0.6.0 (feature 011), this is PERMANENTLY decoupled
    # from the per-release version pin and aliased to the GitHub stable-alias URL
    # `releases/latest/download/speckit-superpowers-bridge.zip` (which GitHub
    # auto-resolves to the latest release's asset). Accept that canonical form.
    # For pre-0.6.0 historical compatibility, also accept versioned forms.
    $stableAlias = 'releases/latest/download/speckit-superpowers-bridge.zip'
    $versionedFragment = "v$Version"
    if (($entry.download_url -notmatch [regex]::Escape($stableAlias)) -and
        ($entry.download_url -notmatch [regex]::Escape($versionedFragment))) {
        Add-Problem $problems "catalog-entry.json: download_url is neither the v0.6.0+ stable-alias form ('$stableAlias') nor a versioned form containing 'v$Version' (got '$($entry.download_url)')"
    }
}

# 4. CHANGELOG has [Version] section
$changelog = Join-Path $RepoRoot "CHANGELOG.md"
if (-not (Test-Path -LiteralPath $changelog)) {
    Add-Problem $problems "CHANGELOG.md not found at $changelog"
} else {
    $body = Get-Content -LiteralPath $changelog -Raw
    $headerPattern = "(?m)^##\s*\[$([regex]::Escape($Version))\]"
    if ($body -notmatch $headerPattern) {
        Add-Problem $problems "CHANGELOG.md: no '## [$Version]' section found"
    }
}

# 5. Bash / PowerShell script parity when bash flavor exists
$bridgeScripts = Join-Path $RepoRoot ".specify/extensions/speckit-superpowers-bridge/scripts"
$psDir = Join-Path $bridgeScripts "powershell"
$bashDir = Join-Path $bridgeScripts "bash"
if (Test-Path -LiteralPath $bashDir) {
    if (-not (Test-Path -LiteralPath $psDir)) {
        Add-Problem $problems "scripts/powershell missing while scripts/bash exists; file-count parity cannot be checked"
    } else {
        $psFiles = @(Get-ChildItem -LiteralPath $psDir -Filter "*.ps1" -File | Sort-Object Name)
        $bashFiles = @(Get-ChildItem -LiteralPath $bashDir -Filter "*.sh" -File | Sort-Object Name)
        if ($psFiles.Count -ne $bashFiles.Count) {
            Add-Problem $problems "scripts file-count parity failed: $($psFiles.Count) .ps1 file(s) vs $($bashFiles.Count) .sh file(s)"
        }
        $psStems = @($psFiles | ForEach-Object { $_.BaseName })
        $bashStems = @($bashFiles | ForEach-Object { $_.BaseName })
        $missingBash = @($psStems | Where-Object { -not ($bashStems -contains $_) })
        $missingPs = @($bashStems | Where-Object { -not ($psStems -contains $_) })
        if ($missingBash.Count -gt 0 -or $missingPs.Count -gt 0) {
            $detail = @()
            if ($missingBash.Count -gt 0) { $detail += "missing .sh for: $($missingBash -join ', ')" }
            if ($missingPs.Count -gt 0) { $detail += "missing .ps1 for: $($missingPs -join ', ')" }
            Add-Problem $problems "scripts filename parity failed: $($detail -join '; ')"
        }
    }
}

# 6. .gitattributes pins shell scripts to portable line endings
$gitAttributes = Join-Path $RepoRoot ".gitattributes"
if (-not (Test-Path -LiteralPath $gitAttributes)) {
    Add-Problem $problems ".gitattributes not found at $gitAttributes"
} else {
    $gitAttributesBody = Get-Content -LiteralPath $gitAttributes -Raw
    if ($gitAttributesBody -notmatch '(?m)^\*\.sh\s+text\s+eol=lf\b') {
        Add-Problem $problems ".gitattributes: missing '*.sh text eol=lf' rule"
    }
    if ($gitAttributesBody -notmatch '(?m)^\*\.ps1\s+text\s+eol=crlf\b') {
        Add-Problem $problems ".gitattributes: missing '*.ps1 text eol=crlf' rule"
    }
}

# 7. Release workflow references only tests that exist in the checkout.
$releaseWorkflow = Join-Path $RepoRoot ".github/workflows/release.yml"
if (Test-Path -LiteralPath $releaseWorkflow) {
    $workflowBody = Get-Content -LiteralPath $releaseWorkflow -Raw
    $bashBuilder = Join-Path $RepoRoot "scripts/release/build-extension-zip.sh"
    if (-not (Test-Path -LiteralPath $bashBuilder -PathType Leaf)) {
        Add-Problem $problems "release.yml: bash package builder scripts/release/build-extension-zip.sh is missing"
    }
    if ($workflowBody -notmatch 'scripts/release/build-extension-zip\.sh') {
        Add-Problem $problems "release.yml: release package build must use scripts/release/build-extension-zip.sh"
    }
    if ($workflowBody -match 'scripts/release/build-extension-zip\.ps1') {
        Add-Problem $problems "release.yml: release package build must not use scripts/release/build-extension-zip.ps1; use scripts/release/build-extension-zip.sh"
    }

    if ($workflowBody -match 'tests/\*\.ps1') {
        $testsDir = Join-Path $RepoRoot "tests"
        $psTests = @()
        if (Test-Path -LiteralPath $testsDir -PathType Container) {
            $psTests = @(Get-ChildItem -LiteralPath $testsDir -Filter "*.ps1" -File)
        }
        if ($psTests.Count -eq 0) {
            Add-Problem $problems "release.yml: references tests/*.ps1 but no matching PowerShell tests exist"
        }
    }

    $specificPsRefs = @([regex]::Matches($workflowBody, 'tests/[A-Za-z0-9._/-]+\.ps1') | ForEach-Object { $_.Value } | Sort-Object -Unique)
    foreach ($ref in $specificPsRefs) {
        $refPath = Join-Path $RepoRoot ($ref.Replace('/', [System.IO.Path]::DirectorySeparatorChar))
        if (-not (Test-Path -LiteralPath $refPath -PathType Leaf)) {
            Add-Problem $problems "release.yml: references missing PowerShell test '$ref'"
        }
    }
}

$releaseRunbook = Join-Path $RepoRoot "docs/release-runbook.md"
if (-not (Test-Path -LiteralPath $releaseRunbook -PathType Leaf)) {
    Add-Problem $problems "docs/release-runbook.md not found at $releaseRunbook"
} else {
    $runbookBody = Get-Content -LiteralPath $releaseRunbook -Raw
    if ($runbookBody -notmatch 'Extension Submission') {
        Add-Problem $problems "docs/release-runbook.md: upstream catalog step must use the official Extension Submission issue template"
    }
    if ($runbookBody -match '## Step 16.*Submit upstream PR' -or
        $runbookBody -match 'direct pull request that edits `?extensions/catalog\.community\.json`?\s+is allowed') {
        Add-Problem $problems "docs/release-runbook.md: must not instruct maintainers to directly PR-edit the official catalog"
    }
}

# 8. Optional release package inspection.
Assert-ZipContents -ZipPath $PackageZip -Problems $problems

# 9. Marketplace submission material is aligned.
$marketplaceRow = Join-Path $RepoRoot "marketplace/extensions-readme-row.md"
if (-not (Test-Path -LiteralPath $marketplaceRow -PathType Leaf)) {
    Add-Problem $problems "extensions-readme-row.md not found at $marketplaceRow"
} else {
    $marketplaceRowBody = Get-Content -LiteralPath $marketplaceRow -Raw
    if ($marketplaceRowBody -notmatch 'speckit-superpowers-bridge' -or $marketplaceRowBody -notmatch 'Superpowers Implementation Bridge') {
        Add-Problem $problems "extensions-readme-row.md: missing bridge name or repository id"
    }
    foreach ($needle in @($Version, "Linux bash", "Windows PowerShell", "Codex", "Claude Code")) {
        if ($marketplaceRowBody -notmatch [regex]::Escape($needle)) {
            Add-Problem $problems "extensions-readme-row.md: missing support summary term '$needle'"
        }
    }
}

$submissionBody = Join-Path $RepoRoot "marketplace/extension-submission-body.md"
if (-not (Test-Path -LiteralPath $submissionBody -PathType Leaf)) {
    Add-Problem $problems "extension-submission-body.md not found at $submissionBody"
} else {
    $submissionText = Get-Content -LiteralPath $submissionBody -Raw
    if ($submissionText -notmatch "(?ms)^###\s+Version\s*\r?\n\s*$([regex]::Escape($Version))\b") {
        Add-Problem $problems "extension-submission-body.md: expected version '$Version'"
    }
    if ($submissionText -notmatch 'releases/latest/download/speckit-superpowers-bridge\.zip') {
        Add-Problem $problems "extension-submission-body.md: missing stable latest-release download URL"
    }
    if ($submissionText -notmatch '(?ms)Number of Commands.*?\b3\b') {
        Add-Problem $problems "extension-submission-body.md: missing command count 3"
    }
    if ($submissionText -notmatch '(?ms)Number of Hooks.*?\b5\b') {
        Add-Problem $problems "extension-submission-body.md: missing hook count 5"
    }
    if ($submissionText -notmatch '(?ms)Support Matrix.*Linux bash.*PASS.*Windows PowerShell.*PASS.*Codex.*PASS.*Claude Code.*PASS') {
        Add-Problem $problems "extension-submission-body.md: missing Support Matrix with passing Linux, Windows, Codex, and Claude rows"
    }
    if ($submissionText -notmatch '(?ms)Release Validation Summary.*validate-release-readiness.*tests/run-all\.sh.*test-release-powershell\.ps1') {
        Add-Problem $problems "extension-submission-body.md: missing Release Validation Summary with readiness, Linux, and Windows gates"
    }
    foreach ($requiredSection in @("Testing Checklist", "Submission Requirements", "Testing Details", "Example Usage", "Proposed Catalog Entry")) {
        if ($submissionText -notmatch "(?m)^###\s+$([regex]::Escape($requiredSection))\s*$") {
            Add-Problem $problems "extension-submission-body.md: missing official submission section '$requiredSection'"
        }
    }
    if ($submissionText -notmatch "(?ms)Proposed Catalog Entry.*`"speckit-superpowers-bridge`".*`"version`":\s*`"$([regex]::Escape($Version))`".*`"verified`":\s*false.*`"created_at`":\s*`"2026-05-15T00:00:00Z`".*`"updated_at`":\s*`"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z`"") {
        Add-Problem $problems "extension-submission-body.md: Proposed Catalog Entry is missing official catalog fields for the 1.0.0 update"
    }
}

# 10. v1.0.0 verification evidence has required release rows.
$verificationEvidence = Join-Path $RepoRoot "specs/013-v1-0-release-hardening/verification.md"
if (-not (Test-Path -LiteralPath $verificationEvidence -PathType Leaf)) {
    Add-Problem $problems "verification.md not found at $verificationEvidence"
} else {
    $verificationBody = Get-Content -LiteralPath $verificationEvidence -Raw
    if ($verificationBody -notmatch '(?m)^-\s+SHA256:\s+`?[0-9a-fA-F]{64}`?') {
        Add-Problem $problems "verification.md: missing final artifact SHA256"
    }
    if ($verificationBody -notmatch '(?m)^\|\s*Linux bash\s*\|.*\|\s*PASS\s*\|' -or
        $verificationBody -notmatch '(?m)^\|\s*Windows PowerShell\s*\|.*\|\s*PASS\s*\|') {
        Add-Problem $problems "verification.md: missing passing Linux bash or Windows PowerShell platform row"
    }
    if ($verificationBody -notmatch '(?m)^\|\s*Codex\s*\|') {
        Add-Problem $problems "verification.md: missing Codex verification row"
    }
    if ($verificationBody -notmatch '(?m)^\|\s*Claude Code\s*\|') {
        Add-Problem $problems "verification.md: missing Claude Code verification row"
    }
    if ($verificationBody -notmatch '(?m)^\|\s*Codex\s*\|.*\|\s*PASS\s*\|' -or
        $verificationBody -notmatch '(?m)^\|\s*Claude Code\s*\|.*\|\s*PASS\s*\|') {
        Add-Problem $problems "verification.md: Codex and Claude rows must be passing before release readiness"
    }
    if ($verificationBody -notmatch 'Release workflow inventory.*PASS') {
        Add-Problem $problems "verification.md: missing passing Release workflow evidence"
    }
    if ($verificationBody -notmatch '(?m)^##\s+Known Blockers and Deferrals') {
        Add-Problem $problems "verification.md: missing Known Blockers and Deferrals section"
    }
}

if ($problems.Count -gt 0) {
    Write-Output "Release readiness FAILED for version $Version :"
    foreach ($p in $problems) { Write-Output "  - $p" }
    exit 1
}

Write-Output "Release readiness OK for version $Version."
exit 0
