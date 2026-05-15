$ErrorActionPreference = "Stop"

function Get-RepoRoot {
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

function Assert-True { param([bool]$Condition, [string]$Message); if (-not $Condition) { throw $Message } }

$repoRoot = Get-RepoRoot
$script = Join-Path $repoRoot ".specify\extensions\speckit-superpowers-bridge\scripts\powershell\check-readme-bilingual-parity.ps1"
Assert-True (Test-Path -LiteralPath $script) "Missing check-readme-bilingual-parity.ps1."

& $script | Out-Null
$report = & $script -Json | ConvertFrom-Json
Assert-True $report.passed "README parity should pass for repository files."

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("readme-parity-" + [guid]::NewGuid().ToString("N"))
try {
    New-Item -ItemType Directory -Force -Path $tmp | Out-Null
    Copy-Item -LiteralPath (Join-Path $repoRoot "README.md") -Destination (Join-Path $tmp "README.md")
    Copy-Item -LiteralPath (Join-Path $repoRoot "README.zh-CN.md") -Destination (Join-Path $tmp "README.zh-CN.md")
    Add-Content -LiteralPath (Join-Path $tmp "README.md") -Encoding UTF8 -Value "`n## temporary-extra-section`n"
    Push-Location $tmp
    & $script | Out-Null
    $failed = ($LASTEXITCODE -ne 0)
    Pop-Location
    Assert-True $failed "Heading mismatch should fail parity."
}
finally {
    if ((Get-Location).Path -eq $tmp) { Pop-Location }
    if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Recurse -Force }
}

Write-Output "readme-bilingual-parity-tests-ok"
