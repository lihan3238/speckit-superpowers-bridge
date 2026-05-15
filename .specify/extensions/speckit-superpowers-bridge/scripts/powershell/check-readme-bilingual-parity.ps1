param([switch]$Json, [switch]$Strict)

$ErrorActionPreference = "Stop"

function Get-RepoRoot {
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

function Get-Headings {
    param([string]$Path)
    return @(Get-Content -LiteralPath $Path | Where-Object { $_ -match '^\s*#{1,3}\s+' } | ForEach-Object {
        ($_ -replace '^\s*#{1,3}\s+', '').Trim().ToLowerInvariant()
    })
}

function Count-CodeFences {
    param([string]$Path)
    return @((Get-Content -LiteralPath $Path) | Where-Object { $_ -match '^\s*```' }).Count
}

function Count-Images {
    param([string]$Path)
    return ([regex]::Matches((Get-Content -LiteralPath $Path -Raw), '!\[.*?\]\(')).Count
}

$repoRoot = Get-RepoRoot
$enPath = Join-Path $repoRoot "README.md"
$zhPath = Join-Path $repoRoot "README.zh-CN.md"
$checks = New-Object System.Collections.Generic.List[object]

if (-not (Test-Path -LiteralPath $enPath)) { throw "Missing README.md" }
if (-not (Test-Path -LiteralPath $zhPath)) { throw "Missing README.zh-CN.md" }

$enHeadings = Get-Headings -Path $enPath
$zhHeadings = Get-Headings -Path $zhPath
$headingPassed = (($enHeadings -join "|") -eq ($zhHeadings -join "|"))
$checks.Add([pscustomobject]@{ name = "heading_sequence"; passed = $headingPassed; severity = "P1"; details = "EN=$($enHeadings.Count) zh-CN=$($zhHeadings.Count)" })

$headingCountPassed = ($enHeadings.Count -eq $zhHeadings.Count)
$checks.Add([pscustomobject]@{ name = "heading_count"; passed = $headingCountPassed; severity = "P2"; details = "EN=$($enHeadings.Count) zh-CN=$($zhHeadings.Count)" })

$enFence = Count-CodeFences -Path $enPath
$zhFence = Count-CodeFences -Path $zhPath
$checks.Add([pscustomobject]@{ name = "code_fence_count"; passed = ($enFence -eq $zhFence); severity = "P2"; details = "EN=$enFence zh-CN=$zhFence" })

$enFirst = @(Get-Content -LiteralPath $enPath | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -First 1)[0]
$zhFirst = @(Get-Content -LiteralPath $zhPath | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -First 1)[0]
$checks.Add([pscustomobject]@{ name = "language_toggle"; passed = (($enFirst -match 'README\.zh-CN\.md') -and ($zhFirst -match 'README\.md')); severity = "P1"; details = "first-line links checked" })

$enImages = Count-Images -Path $enPath
$zhImages = Count-Images -Path $zhPath
$checks.Add([pscustomobject]@{ name = "image_count"; passed = ($enImages -eq $zhImages); severity = "P3"; details = "EN=$enImages zh-CN=$zhImages" })

$failed = @($checks.ToArray() | Where-Object { -not $_.passed })
$hasP1 = @($failed | Where-Object { $_.severity -eq "P1" }).Count -gt 0
$hasP2 = @($failed | Where-Object { $_.severity -eq "P2" }).Count -gt 0
$exitCode = if ($hasP1) { 2 } elseif ($Strict -and $hasP2) { 3 } else { 0 }

$report = [ordered]@{
    passed = ($exitCode -eq 0)
    checks = @($checks.ToArray())
}

if ($Json) {
    $report | ConvertTo-Json -Depth 5
}
elseif ($exitCode -eq 0) {
    Write-Output "README parity: passed"
}
else {
    [Console]::Error.WriteLine("README parity: failed")
    foreach ($check in $failed) {
        [Console]::Error.WriteLine("  - $($check.name): $($check.details)")
    }
}

exit $exitCode
