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

function Assert-True { param([bool]$c, [string]$m); if (-not $c) { throw $m } }

$repoRoot = Get-RepoRoot
$uvToolDir = (& uv tool dir).Trim()
$python = Join-Path $uvToolDir "specify-cli\Scripts\python.exe"
Assert-True (Test-Path -LiteralPath $python) "specify-cli Python runtime not found at $python"

$script = @"
from pathlib import Path
from tempfile import TemporaryDirectory
from specify_cli.extensions import ExtensionManager

repo = Path(r"$repoRoot")
src = repo / ".specify" / "extensions" / "speckit-superpowers-bridge"

with TemporaryDirectory() as tmp:
    manifest = ExtensionManager(Path(tmp)).install_from_directory(
        src,
        "0.8.10",
        register_commands=False,
    )
    assert manifest.id == "speckit-superpowers-bridge", manifest.id
    assert manifest.version == "0.1.1", manifest.version
    commands = [cmd["name"] for cmd in manifest.commands]
    assert len(commands) == 7, commands
    assert all(name.startswith("speckit.speckit-superpowers-bridge.") for name in commands), commands
"@

$output = $script | & $python -
if ($LASTEXITCODE -ne 0) {
    throw "extension manifest install compatibility failed: $output"
}

Write-Output "extension-manifest-install-tests-ok"
