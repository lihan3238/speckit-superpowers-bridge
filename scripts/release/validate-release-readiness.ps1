param(
    [Parameter(Mandatory = $true)]
    [string]$Version,

    [string]$RepoRoot = ""
)

$ErrorActionPreference = "Stop"

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
if (-not (Test-Path -LiteralPath $extYml)) {
    $problems.Add("extension.yml not found at $extYml")
} else {
    $manifest = Get-Content -LiteralPath $extYml -Raw
    $pattern = "version:\s*[`"']?$([regex]::Escape($Version))[`"']?\b"
    if ($manifest -notmatch $pattern) {
        $problems.Add("extension.yml: extension.version does not match '$Version'")
    }
}

# 2 + 3. catalog-entry.json version + download_url
$catalog = Join-Path $RepoRoot "marketplace/catalog-entry.json"
if (-not (Test-Path -LiteralPath $catalog)) {
    $problems.Add("catalog-entry.json not found at $catalog")
} else {
    $entry = Get-Content -LiteralPath $catalog -Raw | ConvertFrom-Json
    if ($entry.version -ne $Version) {
        $problems.Add("catalog-entry.json: version field is '$($entry.version)', expected '$Version'")
    }
    $expectedFragment = "v$Version"
    if ($entry.download_url -notmatch [regex]::Escape($expectedFragment)) {
        $problems.Add("catalog-entry.json: download_url does not contain '$expectedFragment' (got '$($entry.download_url)')")
    }
}

# 4. CHANGELOG has [Version] section
$changelog = Join-Path $RepoRoot "CHANGELOG.md"
if (-not (Test-Path -LiteralPath $changelog)) {
    $problems.Add("CHANGELOG.md not found at $changelog")
} else {
    $body = Get-Content -LiteralPath $changelog -Raw
    $headerPattern = "(?m)^##\s*\[$([regex]::Escape($Version))\]"
    if ($body -notmatch $headerPattern) {
        $problems.Add("CHANGELOG.md: no '## [$Version]' section found")
    }
}

if ($problems.Count -gt 0) {
    Write-Output "Release readiness FAILED for version $Version :"
    foreach ($p in $problems) { Write-Output "  - $p" }
    exit 1
}

Write-Output "Release readiness OK for version $Version."
exit 0
