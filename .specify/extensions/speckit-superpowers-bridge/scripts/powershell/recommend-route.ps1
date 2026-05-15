param(
    [AllowEmptyString()]
    [string]$Description = "",

    [switch]$Json
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($Description)) {
    foreach ($name in @("SPECKIT_FEATURE_DESCRIPTION", "SPECKIT_SPEC_DESCRIPTION")) {
        $candidate = [Environment]::GetEnvironmentVariable($name)
        if (-not [string]::IsNullOrWhiteSpace($candidate)) {
            $Description = $candidate
            break
        }
    }
}

$smallKeywords = @("fix", "typo", "rename", "tweak", "bug", "patch")
$bigKeywords = @("architecture", "design", "framework", "system", "rewrite", "refactor")
$length = if ($null -eq $Description) { 0 } else { $Description.Length }
$lower = if ($null -eq $Description) { "" } else { $Description.ToLowerInvariant() }
$matchedSmall = @($smallKeywords | Where-Object { $lower -match "(^|[^a-z])$([regex]::Escape($_))([^a-z]|$)" })
$matchedBig = @($bigKeywords | Where-Object { $lower -match "(^|[^a-z])$([regex]::Escape($_))([^a-z]|$)" })

if ([string]::IsNullOrWhiteSpace($Description)) {
    $recommendation = "no-recommendation"
    $reason = "No feature description was provided."
}
elseif ($length -lt 200 -and $matchedSmall.Count -gt 0 -and $matchedBig.Count -eq 0) {
    $recommendation = "direct-superpowers"
    $reason = "Description is short and matches small-scope keyword(s): $($matchedSmall -join ', '). Consider going direct to Superpowers."
}
else {
    $recommendation = "full-pipeline"
    $reason = "Description does not match the small-scope direct-Superpowers heuristic."
}

$result = [ordered]@{
    recommendation = $recommendation
    reason = $reason
    description_length = $length
    matched_keywords = @($matchedSmall)
}

if ($Json) {
    $result | ConvertTo-Json -Depth 5
}
elseif ($recommendation -eq "direct-superpowers") {
    Write-Output $reason
}
