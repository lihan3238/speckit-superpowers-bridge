param(
    [Parameter(Mandatory = $true)]
    [string]$Version
)

$ErrorActionPreference = "Stop"

if ($Version -notmatch '^\d+\.\d+\.\d+(-[a-zA-Z0-9.]+)?$') {
    throw "Version '$Version' is not semver. Expected: X.Y.Z or X.Y.Z-prerelease"
}

$repoRoot = (& git rev-parse --show-toplevel).Trim()
$bridgeDir = Join-Path $repoRoot ".specify/extensions/speckit-superpowers-bridge"
$stageRoot = Join-Path ([System.IO.Path]::GetTempPath()) "speckit-superpowers-bridge-build-$Version"
$archiveTopDir = "speckit-superpowers-bridge-$Version"
$stageDir = Join-Path $stageRoot $archiveTopDir
$distDir = Join-Path $repoRoot "dist"
$outZip = Join-Path $distDir "speckit-superpowers-bridge-v$Version.zip"
if (-not (Test-Path -LiteralPath $distDir)) { New-Item -ItemType Directory -Force -Path $distDir | Out-Null }

# Clean stage
if (Test-Path -LiteralPath $stageRoot) { Remove-Item -Recurse -Force -LiteralPath $stageRoot }
New-Item -ItemType Directory -Force -Path $stageDir | Out-Null

# Bridge content: extension.yml, commands/, scripts/powershell/
Copy-Item -LiteralPath (Join-Path $bridgeDir "extension.yml") -Destination $stageDir
Copy-Item -Recurse -LiteralPath (Join-Path $bridgeDir "commands") -Destination $stageDir
New-Item -ItemType Directory -Force -Path (Join-Path $stageDir "scripts") | Out-Null
Copy-Item -Recurse -LiteralPath (Join-Path $bridgeDir "scripts/powershell") -Destination (Join-Path $stageDir "scripts/powershell")
Copy-Item -Recurse -LiteralPath (Join-Path $bridgeDir "scripts/bash") -Destination (Join-Path $stageDir "scripts/bash") -ErrorAction SilentlyContinue

# Repo-root marketplace docs: README, README.zh-CN, LICENSE, CHANGELOG, .gitignore, .gitattributes
foreach ($name in @("README.md", "README.zh-CN.md", "LICENSE", "CHANGELOG.md", ".gitignore", ".gitattributes")) {
    $src = Join-Path $repoRoot $name
    if (Test-Path -LiteralPath $src) {
        Copy-Item -LiteralPath $src -Destination $stageDir
    }
}

# Sanity: verify extension.yml version matches the requested Version arg
$manifest = Get-Content -LiteralPath (Join-Path $stageDir "extension.yml") -Raw
if ($manifest -notmatch "version:\s*[`"']?$([regex]::Escape($Version))[`"']?\b") {
    throw "extension.yml does not declare version '$Version'. Bump it first."
}

# Build ZIP
if (Test-Path -LiteralPath $outZip) { Remove-Item -Force -LiteralPath $outZip }
Compress-Archive -Path (Join-Path $stageRoot "*") -DestinationPath $outZip -CompressionLevel Optimal

# Report
$sha = (Get-FileHash -LiteralPath $outZip -Algorithm SHA256).Hash.ToLower()
$size = [Math]::Round((Get-Item -LiteralPath $outZip).Length / 1KB, 1)
Write-Output "Built: $outZip"
Write-Output "Size:  $size KB"
Write-Output "SHA256: $sha"

# Cleanup stage
Remove-Item -Recurse -Force -LiteralPath $stageRoot
