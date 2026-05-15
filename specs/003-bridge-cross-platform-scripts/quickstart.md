# Quickstart: Bridge Cross-Platform Scripts

**Feature**: 003-bridge-cross-platform-scripts
**Audience**: the executor implementing v0.4.0 and a reviewer validating the result.

This quickstart is the verification gate. Invoke each step after `/speckit-tasks` finishes and the implementation lands.

---

## Prerequisites

- Working tree clean.
- Branch `003-bridge-cross-platform-scripts`.
- v0.3.1 is the current tip of `main` before this feature lands.
- `pwsh` available on the developer's machine.
- For full SC validation, ALSO need a Linux container (e.g., `docker run --rm -it ubuntu:24.04 bash`) and ideally a macOS box.

---

## Step 1 — Verify the 4 new bash scripts exist (FR-001, SC-004)

```powershell
$bridgeDir = ".specify/extensions/speckit-superpowers-bridge"
Get-ChildItem (Join-Path $bridgeDir "scripts/bash/") -Filter *.sh | Select-Object -ExpandProperty Name
```

Expected output (4 lines):

```text
auto-archive-handoff.sh
common-actor-resolution.sh
guard-command.sh
update-handoff.sh
```

```powershell
# File-count parity:
$psCount = (Get-ChildItem (Join-Path $bridgeDir "scripts/powershell/") -Filter *.ps1).Count
$shCount = (Get-ChildItem (Join-Path $bridgeDir "scripts/bash/") -Filter *.sh).Count
if ($psCount -ne $shCount) { throw "FR-001/SC-004 violation: $psCount PS != $shCount bash" }
"file-count parity: $psCount each"
```

Expected: `file-count parity: 4 each`.

---

## Step 2 — Verify `.gitattributes` (FR-020)

```powershell
(Get-Content .gitattributes -Raw) -match '\*\.sh\s+text\s+eol=lf'
```

Expected: `True`.

```powershell
# Sanity: clone a fresh copy on Windows + check actual line endings in .sh files
git clone . /tmp/repo-clone-test
(Get-Content /tmp/repo-clone-test/.specify/extensions/speckit-superpowers-bridge/scripts/bash/update-handoff.sh -Raw) `
  -notmatch "`r`n"
Remove-Item -Recurse -Force /tmp/repo-clone-test
```

Expected: `True` (no CRLF in the cloned .sh file).

---

## Step 3 — Verify extension.yml requires.tools (FR-010, R12)

```powershell
$ext = Get-Content (Join-Path $bridgeDir "extension.yml") -Raw
foreach ($tool in @("powershell","bash","jq","git")) {
    if ($ext -notmatch "name:\s*[`"']?$tool[`"']?") {
        throw "extension.yml missing tool: $tool"
    }
}
"tools list OK"
```

---

## Step 4 — Run the validator (FR-012)

```powershell
pwsh scripts/release/validate-release-readiness.ps1 -Version 0.4.0
```

Expected exit 0. The validator now checks:

- extension.yml version = 0.4.0
- catalog-entry.json version = 0.4.0
- catalog-entry.json download_url contains `v0.4.0`
- CHANGELOG has `## [0.4.0]` section
- bash/ ↔ powershell/ file-count parity (NEW)
- `.gitattributes` has `*.sh text eol=lf` line (NEW)

---

## Step 5 — Run the 3 smoke tests; verify both flavors exercised (FR-014, FR-015, SC-005)

```powershell
foreach ($t in (Get-ChildItem tests/*.ps1)) {
    Write-Output "--- $($t.Name) ---"
    pwsh -NoProfile -File $t.FullName
    if ($LASTEXITCODE -ne 0) { throw "$($t.Name) failed" }
}
```

Expected output includes per-flavor summary lines, e.g.:

```text
handoff-shape-tests-ok (ps, bash)
guard-hardcoded-rules-tests-ok (ps, bash)
claude-codex-skill-parity-tests-ok
```

(On Windows without WSL, expect `(ps)` only. On Linux/macOS, expect `(ps, bash)`.)

---

## Step 6 — Linux container end-to-end (SC-001)

In a clean Ubuntu 24.04 container with bash + jq + Spec Kit installed (no pwsh):

```bash
# Install Spec Kit prereqs
apt update && apt install -y git bash jq python3
pip install specify-cli

# Init a project and add the bridge from the v0.4.0 release URL
mkdir /tmp/test-project && cd /tmp/test-project
specify init . --integration codex --script sh --here
specify extension add speckit-superpowers-bridge \
    --from https://github.com/lihan3238/speckit-superpowers-bridge/releases/download/v0.4.0/speckit-superpowers-bridge-v0.4.0.zip
specify extension list  # should show speckit-superpowers-bridge v0.4.0

# Walk through Spec Kit → bridge for a trivial feature
# (Manual: in Codex CLI, invoke $speckit-specify "Add TEST marker to README"
#  through to $speckit-tasks. Then $speckit-superpowers-bridge.)
# The bridge MUST complete the handoff cycle without invoking pwsh.

# Verify by inspecting handoff JSON
cat .specify/superpowers-handoff.json | jq .schema_version
# Expected: 1
```

Expected: end-to-end success with zero `pwsh` invocations.

---

## Step 7 — macOS end-to-end (SC-002)

Same as Step 6 but on macOS 13+ with `brew install bash jq python3 spec-kit` first. The system bash 3.2 is NOT used; the Homebrew bash 5.x is.

---

## Step 8 — Windows regression (US2, SC-003)

On Windows with v0.3.1 installed and a feature in progress:

```powershell
# Snapshot pre-upgrade state
Copy-Item .specify/superpowers-handoff.json $env:TEMP/pre-upgrade.json

# Upgrade to v0.4.0 (manual: download v0.4.0 ZIP, replace extension dir)
specify extension upgrade speckit-superpowers-bridge

# Diff: handoff JSON must be byte-identical until next bridge operation
fc .specify/superpowers-handoff.json $env:TEMP/pre-upgrade.json
```

Expected: "FC: no differences encountered" — byte-identical.

```powershell
# Run all 3 tests on Windows; same output as v0.3.1
foreach ($t in (Get-ChildItem tests/*.ps1)) { pwsh -NoProfile -File $t.FullName }
```

Expected: 3 × `*-ok` lines, all exit 0.

---

## Step 9 — Verify single ZIP contains both flavors (SC-004)

```powershell
pwsh scripts/release/build-extension-zip.ps1 -Version 0.4.0

$zip = "dist/speckit-superpowers-bridge-v0.4.0.zip"
Expand-Archive -LiteralPath $zip -DestinationPath $env:TEMP/zip-verify -Force

$inside = "$env:TEMP/zip-verify/speckit-superpowers-bridge-0.4.0"
@(Get-ChildItem "$inside/scripts/powershell/*.ps1").Count
@(Get-ChildItem "$inside/scripts/bash/*.sh").Count
Remove-Item -Recurse -Force $env:TEMP/zip-verify
```

Expected: 4 and 4.

---

## Step 10 — Spec history byte-identical (SC-006)

```powershell
# Recompute checksum from feature 006 baseline (1f09423e...)
$current = git ls-tree -r HEAD --name-only specs/001-* specs/002-* specs/003-* specs/004-* specs/005-* specs/006-* | sort | git hash-object --stdin
# Compare to the new baseline captured during T003 of this feature.
"current: $current"
```

Spec dirs 001–006 (excluding 003 itself which we're authoring) must remain byte-identical. 003 changes are expected — they're this feature.

---

## Step 11 — Release tooling regression (SC-009)

```powershell
pwsh scripts/release/test-validate-release-readiness.ps1
```

Expected: `validate-release-readiness-tests-ok` (all original 5 cases + the 2 new cases for FR-012's added checks).

---

## Step 12 — End-to-end release via workflow (SC-009)

Push tag `v0.4.0` to `origin`. The workflow at `.github/workflows/release.yml` (unchanged from v0.3.1) runs:

1. Validate release readiness (validator pass, including the 2 new checks)
2. Run bridge smoke tests (3 tests, both flavors exercised on ubuntu runner)
3. Run release-tooling self-tests (validator's own test suite passes)
4. Build extension ZIP (now contains scripts/bash/)
5. Extract CHANGELOG [0.4.0] section as release notes
6. `gh release create` + attach ZIP
7. Print SHA256 + URL in workflow Step Summary

Expected: workflow run green in ≤ 60 seconds.

---

## Pass criteria summary

| Step | Pass if | Maps to |
|------|---------|---------|
| 1 | 4 .sh files; parity with 4 .ps1 | FR-001, SC-004 |
| 2 | .gitattributes correct + clone preserves LF | FR-020 |
| 3 | extension.yml has 4 tools entries | FR-010 |
| 4 | validator exit 0 | FR-012 |
| 5 | 3 smoke tests pass; both flavors covered when available | FR-014, FR-015, SC-005 |
| 6 | Linux end-to-end, no pwsh | SC-001 |
| 7 | macOS end-to-end, no pwsh | SC-002 |
| 8 | Windows upgrade byte-identical until next op | SC-003 |
| 9 | ZIP contains 4 ps + 4 bash | SC-004 |
| 10 | specs/001..006 unchanged | SC-006 |
| 11 | Release-tooling tests pass | FR-012, SC-009 |
| 12 | Workflow green; release published | SC-007, SC-009 |

Steps 6 and 7 (Linux + macOS) are the hard ones — they require real infrastructure access. The implementation considers this feature **NOT complete** until at least Step 6 has been run by a human. Step 7 may be deferred to a follow-up smoke if macOS hardware isn't immediately available.
