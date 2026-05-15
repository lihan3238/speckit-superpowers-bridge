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

# 5. Bash / PowerShell script parity when bash flavor exists
$bridgeScripts = Join-Path $RepoRoot ".specify/extensions/speckit-superpowers-bridge/scripts"
$psDir = Join-Path $bridgeScripts "powershell"
$bashDir = Join-Path $bridgeScripts "bash"
if (Test-Path -LiteralPath $bashDir) {
    if (-not (Test-Path -LiteralPath $psDir)) {
        $problems.Add("scripts/powershell missing while scripts/bash exists; file-count parity cannot be checked")
    } else {
        $psFiles = @(Get-ChildItem -LiteralPath $psDir -Filter "*.ps1" -File | Sort-Object Name)
        $bashFiles = @(Get-ChildItem -LiteralPath $bashDir -Filter "*.sh" -File | Sort-Object Name)
        if ($psFiles.Count -ne $bashFiles.Count) {
            $problems.Add("scripts file-count parity failed: $($psFiles.Count) .ps1 file(s) vs $($bashFiles.Count) .sh file(s)")
        }
        $psStems = @($psFiles | ForEach-Object { $_.BaseName })
        $bashStems = @($bashFiles | ForEach-Object { $_.BaseName })
        $missingBash = @($psStems | Where-Object { -not ($bashStems -contains $_) })
        $missingPs = @($bashStems | Where-Object { -not ($psStems -contains $_) })
        if ($missingBash.Count -gt 0 -or $missingPs.Count -gt 0) {
            $detail = @()
            if ($missingBash.Count -gt 0) { $detail += "missing .sh for: $($missingBash -join ', ')" }
            if ($missingPs.Count -gt 0) { $detail += "missing .ps1 for: $($missingPs -join ', ')" }
            $problems.Add("scripts filename parity failed: $($detail -join '; ')")
        }
    }
}

# 6. .gitattributes pins shell scripts to LF line endings
$gitAttributes = Join-Path $RepoRoot ".gitattributes"
if (-not (Test-Path -LiteralPath $gitAttributes)) {
    $problems.Add(".gitattributes not found at $gitAttributes")
} else {
    $gitAttributesBody = Get-Content -LiteralPath $gitAttributes -Raw
    if ($gitAttributesBody -notmatch '(?m)^\*\.sh\s+text\s+eol=lf\b') {
        $problems.Add(".gitattributes: missing '*.sh text eol=lf' rule")
    }
}

if ($problems.Count -gt 0) {
    Write-Output "Release readiness FAILED for version $Version :"
    foreach ($p in $problems) { Write-Output "  - $p" }
    exit 1
}

Write-Output "Release readiness OK for version $Version."
exit 0
