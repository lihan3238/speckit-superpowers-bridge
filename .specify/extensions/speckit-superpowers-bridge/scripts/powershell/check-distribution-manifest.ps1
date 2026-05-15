param(
    [switch]$Json,
    [string]$SimulateInstall = "",
    [string]$ManifestPath = ""
)

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

function Read-Manifest {
    param([string]$Path)
    $section = ""
    $result = [ordered]@{ schema_version = 0; includes = @(); excludes = @(); notes = @() }
    $current = $null
    foreach ($line in (Get-Content -LiteralPath $Path)) {
        if ($line -match '^\s*schema_version:\s*([0-9]+)') {
            $result.schema_version = [int]$Matches[1]
            continue
        }
        if ($line -match '^\s*(includes|excludes|notes):\s*$') {
            $section = $Matches[1]
            $current = $null
            continue
        }
        if ($section -in @("includes", "excludes") -and $line -match '^\s*-\s*path:\s*(.+?)\s*$') {
            $current = [ordered]@{ path = $Matches[1].Trim().Trim('"').Trim("'") }
            $result[$section] = @($result[$section]) + @([pscustomobject]$current)
            continue
        }
        if ($section -eq "excludes" -and $null -ne $current -and $line -match '^\s*reason:\s*(.+?)\s*$') {
            $result[$section][-1] | Add-Member -NotePropertyName reason -NotePropertyValue $Matches[1].Trim().Trim('"').Trim("'") -Force
            continue
        }
        if ($section -eq "includes" -and $null -ne $current -and $line -match '^\s*condition:\s*(.+?)\s*$') {
            $result[$section][-1] | Add-Member -NotePropertyName condition -NotePropertyValue $Matches[1].Trim().Trim('"').Trim("'") -Force
            continue
        }
        if ($section -eq "notes" -and $line -match '^\s*-\s*(.+?)\s*$') {
            $result.notes = @($result.notes) + @($Matches[1].Trim().Trim('"').Trim("'"))
        }
    }
    return [pscustomobject]$result
}

function Get-ManifestShape {
    param([string]$Path)

    $rootKeys = New-Object System.Collections.Generic.List[string]
    $items = New-Object System.Collections.Generic.List[object]
    $section = ""
    $current = $null

    foreach ($line in (Get-Content -LiteralPath $Path)) {
        if ($line -match '^([A-Za-z_][A-Za-z0-9_-]*):') {
            $rootKeys.Add($Matches[1])
            $section = $Matches[1]
            $current = $null
            continue
        }
        if ($section -in @("includes", "excludes") -and $line -match '^\s*-\s*([A-Za-z_][A-Za-z0-9_-]*):') {
            $current = [pscustomobject][ordered]@{ section = $section; keys = @($Matches[1]) }
            $items.Add($current)
            continue
        }
        if ($section -in @("includes", "excludes") -and $null -ne $current -and $line -match '^\s+([A-Za-z_][A-Za-z0-9_-]*):') {
            $current.keys = @($current.keys) + @($Matches[1])
        }
    }

    return [pscustomobject]@{
        root_keys = @($rootKeys.ToArray())
        items = @($items.ToArray())
    }
}

function Get-SchemaPath {
    param([string]$RepoRoot)

    $extensionRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $candidates = @(
        (Join-Path $extensionRoot "contracts\plugin-distribution-manifest.schema.json"),
        (Join-Path $RepoRoot "specs\004-polish-and-publish\contracts\plugin-distribution-manifest.schema.json")
    )
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) { return $candidate }
    }
    return $null
}

function Add-SchemaFindings {
    param(
        [object]$Manifest,
        [object]$Shape,
        [string]$SchemaPath,
        [System.Collections.Generic.List[object]]$Findings
    )

    if ([string]::IsNullOrWhiteSpace($SchemaPath) -or -not (Test-Path -LiteralPath $SchemaPath)) {
        $Findings.Add("schema file missing: plugin-distribution-manifest.schema.json")
        return
    }

    $schema = Get-Content -LiteralPath $SchemaPath -Raw | ConvertFrom-Json
    $allowedRootKeys = @($schema.properties.PSObject.Properties.Name)
    $requiredRootKeys = @($schema.required)
    foreach ($key in $requiredRootKeys) {
        if ($Shape.root_keys -notcontains $key) { $Findings.Add("schema required root key missing: $key") }
    }
    foreach ($key in $Shape.root_keys) {
        if ($allowedRootKeys -notcontains $key) { $Findings.Add("schema disallows root key: $key") }
    }
    if ($Manifest.schema_version -ne [int]$schema.properties.schema_version.const) {
        $Findings.Add("schema_version must be $($schema.properties.schema_version.const)")
    }

    $includeItemSchema = $schema.properties.includes.items
    $includeAllowedKeys = @($includeItemSchema.properties.PSObject.Properties.Name)
    $includeRequiredKeys = @($includeItemSchema.required)
    $excludeItemSchema = $schema.properties.excludes.items
    $excludeAllowedKeys = @($excludeItemSchema.properties.PSObject.Properties.Name)
    $excludeRequiredKeys = @($excludeItemSchema.required)

    foreach ($item in @($Shape.items | Where-Object { $_.section -eq "includes" })) {
        foreach ($key in $includeRequiredKeys) {
            if ($item.keys -notcontains $key) { $Findings.Add("schema required include key missing: $key") }
        }
        foreach ($key in @($item.keys)) {
            if ($includeAllowedKeys -notcontains $key) { $Findings.Add("schema disallows include key: $key") }
        }
    }
    foreach ($item in @($Shape.items | Where-Object { $_.section -eq "excludes" })) {
        foreach ($key in $excludeRequiredKeys) {
            if ($item.keys -notcontains $key) { $Findings.Add("schema required exclude key missing: $key") }
        }
        foreach ($key in @($item.keys)) {
            if ($excludeAllowedKeys -notcontains $key) { $Findings.Add("schema disallows exclude key: $key") }
        }
    }

    foreach ($include in @($Manifest.includes)) {
        if ([string]::IsNullOrWhiteSpace([string]$include.path)) { $Findings.Add("schema include path must be a non-empty string") }
    }
    foreach ($exclude in @($Manifest.excludes)) {
        if ([string]::IsNullOrWhiteSpace([string]$exclude.path)) { $Findings.Add("schema exclude path must be a non-empty string") }
        if (-not ($exclude.PSObject.Properties.Name -contains "reason") -or [string]::IsNullOrWhiteSpace([string]$exclude.reason)) {
            $Findings.Add("schema exclude reason must be a non-empty string")
        }
    }
}

function Resolve-IncludeFiles {
    param([string]$RepoRoot, [string]$Pattern)
    $normalized = $Pattern.Replace("/", "\")
    if ($normalized.EndsWith("\**")) {
        $root = Join-Path $RepoRoot $normalized.Substring(0, $normalized.Length - 3)
        if (-not (Test-Path -LiteralPath $root)) { return @() }
        return @(Get-ChildItem -LiteralPath $root -Recurse -File | ForEach-Object { $_.FullName })
    }
    $path = Join-Path $RepoRoot $normalized
    if (Test-Path -LiteralPath $path -PathType Leaf) { return @((Resolve-Path -LiteralPath $path).Path) }
    if (Test-Path -LiteralPath $path -PathType Container) { return @(Get-ChildItem -LiteralPath $path -Recurse -File | ForEach-Object { $_.FullName }) }
    return @()
}

$repoRoot = Get-RepoRoot
$manifestPath = if ([string]::IsNullOrWhiteSpace($ManifestPath)) {
    Join-Path $repoRoot ".specify\extensions\speckit-superpowers-bridge\plugin-distribution-manifest.yml"
}
else {
    $ManifestPath
}
if (-not (Test-Path -LiteralPath $manifestPath)) { throw "Missing plugin-distribution-manifest.yml" }
$manifest = Read-Manifest -Path $manifestPath
$shape = Get-ManifestShape -Path $manifestPath
$findings = New-Object System.Collections.Generic.List[object]
$schemaPath = Get-SchemaPath -RepoRoot $repoRoot
Add-SchemaFindings -Manifest $manifest -Shape $shape -SchemaPath $schemaPath -Findings $findings

if ($manifest.schema_version -ne 1) { $findings.Add("schema_version must be 1") }
if (@($manifest.includes).Count -eq 0) { $findings.Add("includes must not be empty") }

$includePaths = @($manifest.includes | ForEach-Object { $_.path })
$excludePaths = @($manifest.excludes | ForEach-Object { $_.path })
foreach ($path in $includePaths) {
    $files = Resolve-IncludeFiles -RepoRoot $repoRoot -Pattern $path
    if ($files.Count -eq 0) { $findings.Add("include path does not resolve: $path") }
}
foreach ($path in $includePaths) {
    if ($excludePaths -contains $path) { $findings.Add("path appears in both includes and excludes: $path") }
}

$copied = @()
$conflicts = @()
if (-not [string]::IsNullOrWhiteSpace($SimulateInstall)) {
    New-Item -ItemType Directory -Force -Path $SimulateInstall | Out-Null
    foreach ($include in $manifest.includes) {
        foreach ($source in (Resolve-IncludeFiles -RepoRoot $repoRoot -Pattern $include.path)) {
            $relative = $source.Substring($repoRoot.Length).TrimStart("\", "/")
            $target = Join-Path $SimulateInstall $relative
            if (Test-Path -LiteralPath $target) {
                $srcHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
                $dstHash = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
                if ($srcHash -ne $dstHash) {
                    $conflicts += $relative.Replace("\", "/")
                    continue
                }
            }
            else {
                New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
                Copy-Item -LiteralPath $source -Destination $target
                $copied += $relative.Replace("\", "/")
            }
        }
    }
    if ($conflicts.Count -gt 0) {
        foreach ($conflict in $conflicts) { $findings.Add("no-clobber conflict: $conflict") }
    }
}

$passed = ($findings.Count -eq 0)
$report = [ordered]@{
    passed = $passed
    findings = @($findings.ToArray())
    copied = @($copied)
    conflicts = @($conflicts)
    schema_path = $schemaPath
    manifest_path = $manifestPath
}

if ($Json) {
    $report | ConvertTo-Json -Depth 8
}
elseif ($passed) {
    Write-Output "distribution-manifest: passed"
}
else {
    foreach ($finding in $findings) { [Console]::Error.WriteLine($finding) }
}

if ($passed) { exit 0 } else { exit 2 }
