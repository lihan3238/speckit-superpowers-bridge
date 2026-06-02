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
$stageDir = $stageRoot
$distDir = Join-Path $repoRoot "dist"
$outZip = Join-Path $distDir "speckit-superpowers-bridge-v$Version.zip"
$latestZip = Join-Path $distDir "speckit-superpowers-bridge.zip"
if (-not (Test-Path -LiteralPath $distDir)) { New-Item -ItemType Directory -Force -Path $distDir | Out-Null }

# Clean stage
if (Test-Path -LiteralPath $stageRoot) { Remove-Item -Recurse -Force -LiteralPath $stageRoot }
New-Item -ItemType Directory -Force -Path $stageDir | Out-Null

# Bridge content: extension.yml, optional package metadata, commands/, scripts/
Copy-Item -LiteralPath (Join-Path $bridgeDir "extension.yml") -Destination $stageDir
if (Test-Path -LiteralPath (Join-Path $bridgeDir "verified-versions.json")) {
    Copy-Item -LiteralPath (Join-Path $bridgeDir "verified-versions.json") -Destination $stageDir
}
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

# Build ZIP. Use ZipArchive directly so entry names always use '/' separators
# even when this script runs on Windows; Linux/macOS installers require real
# directory entries, not filenames containing backslashes.
if (Test-Path -LiteralPath $outZip) { Remove-Item -Force -LiteralPath $outZip }
if (Test-Path -LiteralPath $latestZip) { Remove-Item -Force -LiteralPath $latestZip }
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::Open($outZip, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    $files = Get-ChildItem -LiteralPath $stageRoot -Recurse -File
    $stageRootFull = (Resolve-Path -LiteralPath $stageRoot).Path.TrimEnd('\', '/')
    foreach ($file in $files) {
        $fileFull = (Resolve-Path -LiteralPath $file.FullName).Path
        if (-not $fileFull.StartsWith($stageRootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Staged file is outside stage root: $fileFull"
        }
        $relative = $fileFull.Substring($stageRootFull.Length).TrimStart('\', '/')
        $entryName = $relative.Replace([System.IO.Path]::DirectorySeparatorChar, '/').Replace([System.IO.Path]::AltDirectorySeparatorChar, '/')
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
            $zip,
            $file.FullName,
            $entryName,
            [System.IO.Compression.CompressionLevel]::Optimal
        ) | Out-Null
    }
} finally {
    $zip.Dispose()
}

# Spec Kit extension install expects extension.yml at ZIP root and portable '/'
# path separators for nested command/script files.
$zip = [System.IO.Compression.ZipFile]::OpenRead($outZip)
try {
    $hasRootManifest = $false
    $badBackslashEntries = New-Object System.Collections.Generic.List[string]
    foreach ($entry in $zip.Entries) {
        if ($entry.FullName -eq "extension.yml") {
            $hasRootManifest = $true
        }
        if ($entry.FullName.Contains("\")) {
            $badBackslashEntries.Add($entry.FullName)
        }
    }
    if (-not $hasRootManifest) {
        throw "Built ZIP does not contain extension.yml at archive root."
    }
    if ($badBackslashEntries.Count -gt 0) {
        throw "Built ZIP contains non-portable backslash entry names: $($badBackslashEntries -join ', ')"
    }
} finally {
    $zip.Dispose()
}

# Report
$sha = (Get-FileHash -LiteralPath $outZip -Algorithm SHA256).Hash.ToLower()
$size = [Math]::Round((Get-Item -LiteralPath $outZip).Length / 1KB, 1)
Copy-Item -LiteralPath $outZip -Destination $latestZip
Write-Output "Built: $outZip"
Write-Output "Alias: $latestZip"
Write-Output "Size:  $size KB"
Write-Output "SHA256: $sha"

# Cleanup stage
Remove-Item -Recurse -Force -LiteralPath $stageRoot
