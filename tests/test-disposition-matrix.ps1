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
function Assert-Equals { param([object]$e, [object]$a, [string]$m); if ($e -ne $a) { throw "$m Expected '$e', got '$a'." } }

$repoRoot = Get-RepoRoot
$matrixPath = Join-Path $repoRoot ".specify\extensions\speckit-superpowers-bridge\disposition-matrix.json"
Assert-True (Test-Path -LiteralPath $matrixPath) "disposition-matrix.json missing."

$matrix = Get-Content -LiteralPath $matrixPath -Raw | ConvertFrom-Json
Assert-Equals 1 $matrix.schema_version "matrix schema_version must be 1."
Assert-True ($matrix.PSObject.Properties.Name -contains "entries") "matrix.entries missing."
Assert-True ($matrix.PSObject.Properties.Name -contains "last_audited_at") "matrix.last_audited_at missing."
Assert-True (@($matrix.entries).Count -ge 25) "matrix should have >= 25 entries (Spec Kit cmds + Superpowers skills + meta-commands); got $(@($matrix.entries).Count)."

# Required fields per entry; FORBID/SUPERSEDED extras enforced
foreach ($e in @($matrix.entries)) {
    foreach ($req in @("id", "kind", "disposition", "rationale", "verified_against")) {
        Assert-True ($e.PSObject.Properties.Name -contains $req) "entry '$($e.id)' missing field '$req'."
        Assert-True (-not [string]::IsNullOrWhiteSpace([string]$e.$req)) "entry '$($e.id)' empty field '$req'."
    }
    Assert-True ([string]$e.kind -in @("spec_kit_command", "superpowers_skill", "bridge_meta_command")) "entry '$($e.id)' has invalid kind '$([string]$e.kind)'."
    Assert-True ([string]$e.disposition -in @("COMBINE", "FORBID-UNDER-HANDOFF", "SUPERSEDED-BY", "REVIEW-ONLY")) "entry '$($e.id)' has invalid disposition '$([string]$e.disposition)'."
    if ([string]$e.disposition -eq "FORBID-UNDER-HANDOFF") {
        Assert-True ($e.PSObject.Properties.Name -contains "applicability") "FORBID entry '$($e.id)' missing applicability."
        Assert-True (@($e.applicability).Count -gt 0) "FORBID entry '$($e.id)' has empty applicability."
        foreach ($a in @($e.applicability)) {
            Assert-True ([string]$a -in @("executing", "blocked", "complete", "ready")) "FORBID entry '$($e.id)' applicability '$a' is invalid."
        }
    }
    if ([string]$e.disposition -eq "SUPERSEDED-BY") {
        Assert-True ($e.PSObject.Properties.Name -contains "superseded_by") "SUPERSEDED entry '$($e.id)' missing superseded_by."
        Assert-True (-not [string]::IsNullOrWhiteSpace([string]$e.superseded_by)) "SUPERSEDED entry '$($e.id)' empty superseded_by."
    }
}

# Per US2: explicit assertions for constitution + checklist entries (T017)
$constitution = @($matrix.entries | Where-Object { [string]$_.id -eq "speckit.constitution" })
Assert-Equals 1 $constitution.Count "Matrix must have exactly one speckit.constitution entry."
Assert-Equals "FORBID-UNDER-HANDOFF" ([string]$constitution[0].disposition) "speckit.constitution must be FORBID-UNDER-HANDOFF."
Assert-True (@($constitution[0].applicability) -contains "executing") "speckit.constitution must forbid during 'executing'."
Assert-True (-not (@($constitution[0].applicability) -contains "ready")) "speckit.constitution must NOT forbid during 'ready'."
Assert-True (-not (@($constitution[0].applicability) -contains "blocked")) "speckit.constitution must NOT forbid during 'blocked' (repair state)."
Assert-True (-not (@($constitution[0].applicability) -contains "complete")) "speckit.constitution must NOT forbid during 'complete'."

$checklist = @($matrix.entries | Where-Object { [string]$_.id -eq "speckit.checklist" })
Assert-Equals 1 $checklist.Count "Matrix must have exactly one speckit.checklist entry."
Assert-Equals "COMBINE" ([string]$checklist[0].disposition) "speckit.checklist must be COMBINE (always allowed)."

# IDs must be unique
$ids = @($matrix.entries | ForEach-Object { [string]$_.id })
$dupes = @($ids | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })
Assert-Equals 0 $dupes.Count "Duplicate entry ids: $(($dupes -join ', '))."

Write-Output "disposition-matrix-tests-ok"
