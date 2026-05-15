# Quickstart: Bridge Cross-Platform Scripts — Cleanup Tail (v0.4.2)

**Feature**: 003-bridge-cross-platform-scripts (v0.4.2 cycle)
**Audience**: the executor implementing v0.4.2 and a reviewer validating the result.

This quickstart is the verification gate for everything except US4 sandbox runs (those have their own procedure documented in the constitution and in `contracts/verification-record.md`). The 8 steps below establish that the in-repo work landed correctly. US4 sandbox verification then runs against the **published** v0.4.2 artifact per the constitution v1.2.0 procedure.

---

## Prerequisites

- Branch `003-cross-platform-cleanup` (already created by `before_specify` hook).
- v0.4.1 is the current production release (verified by `gh release list`).
- Local clone clean (`git status` empty).
- `pwsh` 7.x available; `bash` available (git-bash, WSL, or native).
- `..\test_specify_superpower` directory exists OR can be created on demand for US4.

---

## Step 1 — Verify the B1 fix landed (FR-001, SC-001)

```powershell
# Round-trip test: write with --actor codex (no --artifact-owner) against a state where prior owner is claude
$tmp = New-TemporaryFile; Remove-Item $tmp; New-Item -Type Directory $tmp | Out-Null
$origHandoff = Get-Content .specify/superpowers-handoff.json -Raw
try {
    # Set prior state
    @'{"schema_version":1,"feature_directory":"specs/006-trim-to-thin-bridge","source_of_truth":{"constitution":".specify/memory/constitution.md","spec":"specs/006-trim-to-thin-bridge/spec.md","plan":"specs/006-trim-to-thin-bridge/plan.md","tasks":"specs/006-trim-to-thin-bridge/tasks.md"},"executor":"superpowers","status":"complete","artifact_owner":"claude","updated_at":"2026-05-15T12:00:00Z"}'@ |
        Set-Content .specify/superpowers-handoff.json
    # Invoke without --artifact-owner; new actor is codex
    pwsh .specify/extensions/speckit-superpowers-bridge/scripts/powershell/update-handoff.ps1 -Status complete -Actor codex
    $after = Get-Content .specify/superpowers-handoff.json -Raw | ConvertFrom-Json
    if ($after.artifact_owner -ne 'claude') {
        throw "B1 FIX MISSING: artifact_owner became '$($after.artifact_owner)', expected 'claude'"
    }
    "B1 (ps) OK: artifact_owner preserved"
} finally {
    Set-Content .specify/superpowers-handoff.json -Value $origHandoff -NoNewline
}

# Same test for bash flavor (if bash on PATH)
if (Get-Command bash -ErrorAction SilentlyContinue) {
    # ... analogous bash invocation via Convert-ToBashPath ...
}
```

Expected: both flavors print `B1 (<flavor>) OK: artifact_owner preserved`.

Per spec FR-002, the maintainer ALSO must run the one-shot correction on the live handoff after the fix lands:

```powershell
pwsh .specify/extensions/speckit-superpowers-bridge/scripts/powershell/update-handoff.ps1 -Status complete -ArtifactOwner claude -Actor claude
```

This fixes the currently-poisoned `artifact_owner: codex` state. Verify:

```powershell
(Get-Content .specify/superpowers-handoff.json -Raw | ConvertFrom-Json).artifact_owner
# Expected: claude
```

---

## Step 2 — Verify the B2 fix landed (FR-003, FR-004, SC-002)

On a Windows dev box with MSYS git-bash on PATH:

```powershell
foreach ($t in @('tests/test-handoff-shape.ps1', 'tests/test-guard-hardcoded-rules.ps1')) {
    Write-Output "--- $t ---"
    pwsh -NoProfile -File $t
    if ($LASTEXITCODE -ne 0) { throw "$t failed; B2 fix did not land cleanly" }
}
"B2 OK: both tests pass with bash exercised (or gracefully skipped with a reason)"
```

Expected output includes one of:

- `handoff-shape-tests-ok (ps, bash)` — both flavors exercised
- `handoff-shape-tests-ok (ps)` + a one-line note about why bash was skipped (with an actionable reason, not a `No such file or directory` opaque failure)

Same for `guard-hardcoded-rules-tests-ok`.

For Linux/macOS contributors: same test run; expected output `(ps, bash)`.

---

## Step 3 — Verify install-time registries are untracked (FR-006, SC-003)

```powershell
git ls-files .specify/workflows/workflow-registry.json
git ls-files .specify/workflows/speckit/workflow.yml
git ls-files .specify/workflows/speckit-superpowers/workflow.yml
git ls-files .specify/extensions/.registry
```

Expected: all 4 commands return empty (no tracked entries).

```powershell
specify extension list  # or equivalent CLI command; should regenerate the files locally
git status --porcelain  # should NOT mention the 4 paths
```

Expected: `git status --porcelain` reports zero changes to the registry paths.

---

## Step 4 — Verify tasks.md sweep landed (FR-005, SC-004)

```powershell
$tasks = Get-Content specs/003-bridge-cross-platform-scripts/tasks.md
$checked = ($tasks | Select-String '^- \[x\]').Count
$absorbed = ($tasks | Select-String 'absorbed into US4').Count
Write-Output "checked: $checked   absorbed: $absorbed"
```

Expected: `checked ≥ 50` and `absorbed ≥ 15` (matches the rough counts in spec FR-005).

The closing paragraph of `tasks.md` MUST contain the phrase "Tasks closed by v0.4.1 release" — verifies the summary note landed.

---

## Step 5 — Verify version + release prep (FR-010, FR-011, FR-014, SC-006, SC-007)

```powershell
# extension.yml version
(Get-Content .specify/extensions/speckit-superpowers-bridge/extension.yml -Raw) -match 'version:\s*"0\.4\.2"'
# Expected: True

# catalog-entry.json
(Get-Content marketplace/catalog-entry.json -Raw | ConvertFrom-Json).version
# Expected: 0.4.2

# download_url contains v0.4.2
(Get-Content marketplace/catalog-entry.json -Raw | ConvertFrom-Json).download_url -match 'v0\.4\.2'
# Expected: True

# CHANGELOG section
Select-String -Path CHANGELOG.md -Pattern '^## \[0\.4\.2\] -' -SimpleMatch:$false
# Expected: at least one hit

# CHANGELOG names B1, B2, C1, C4, US4
$cl = Get-Content CHANGELOG.md -Raw
@('B1', 'B2', 'C1', 'C4', 'US4') | ForEach-Object {
    if ($cl -notmatch [regex]::Escape($_)) { throw "CHANGELOG [0.4.2] missing reference: $_" }
}
"Step 5 OK: version + CHANGELOG aligned for v0.4.2"
```

---

## Step 6 — Run the release-readiness validator locally

```powershell
pwsh scripts/release/validate-release-readiness.ps1 -Version 0.4.2
# Expected: "Release readiness OK for version 0.4.2." exit 0
```

If this fails, fix whichever check it names BEFORE committing the v0.4.2 release commit.

---

## Step 7 — Run all 3 smoke tests + release-tooling self-test

```powershell
foreach ($t in (Get-ChildItem tests/*.ps1)) {
    pwsh -NoProfile -File $t.FullName
    if ($LASTEXITCODE -ne 0) { throw "$($t.Name) failed" }
}
pwsh scripts/release/test-validate-release-readiness.ps1
if ($LASTEXITCODE -ne 0) { throw "validate-release-readiness self-test failed" }
"Step 7 OK: all 3 smoke tests + release-tooling self-test green"
```

Expected: 3× `*-ok` lines from the bridge tests, 1× `validate-release-readiness-tests-ok` from the tooling self-test.

---

## Step 8 — Spec history byte-identical (SC-009)

```powershell
$baselineSha = '<baseline SHA from tasks.md T002>'
git diff --stat ${baselineSha}..HEAD -- specs/001-* specs/002-* specs/004-* specs/005-* specs/006-*
# Expected: empty output (specs/003 itself IS this feature's work — exempt)
```

Spec dirs 001, 002, 004, 005, 006 MUST be byte-identical between feature start and end.

---

## Sandbox verification (US4 P1 — runs AFTER tag push)

Step 9–11 below are run AFTER `git tag v0.4.2 && git push origin v0.4.2` triggers the workflow + the release publishes. The procedure is the constitution v1.2.0 §"End-User Verification Sandbox" canonical 5-step sequence; full details in `contracts/verification-record.md`.

### Step 9 — Windows PowerShell sandbox run (mandatory)

```powershell
# In ..\test_specify_superpower
specify init . --integration claude --script ps --here --force
specify extension add speckit-superpowers-bridge --from https://github.com/lihan3238/speckit-superpowers-bridge/releases/download/v0.4.2/speckit-superpowers-bridge-v0.4.2.zip
specify extension list  # expect: v0.4.2, 3 commands, 5 hooks
# Drive a trivial feature through /speckit-specify → /speckit-tasks → /speckit-superpowers-bridge → handoff complete
```

Record PASS / FAIL in `specs/003-bridge-cross-platform-scripts/verification.md` `## v0.4.2` section, row `windows-powershell`.

### Step 10 — WSL Linux bash sandbox run (mandatory)

Inside WSL with Claude Code already installed:

```bash
cd ~/test_specify_superpower  # or equivalent path
specify init . --integration claude --script sh --here --force
specify extension add speckit-superpowers-bridge --from https://github.com/lihan3238/speckit-superpowers-bridge/releases/download/v0.4.2/speckit-superpowers-bridge-v0.4.2.zip
specify extension list  # expect: v0.4.2, 3 commands, 5 hooks
# Drive a trivial feature through the bridge; observe `bash` flavor scripts running
```

Record PASS / FAIL in the same `## v0.4.2` section, row `wsl-linux-bash`.

### Step 11 — macOS row

Add a `## v0.4.2` row for `macos-bash` with `Result: PENDING`, `Notes: no host available` per Clarifications Q3.

### Decision

- **Windows PASS + WSL Linux PASS**: commit verification.md → push → transition handoff to `complete` → update issue #2581 with v0.4.2 metadata → feature 003 closed.
- **EITHER fails**: commit verification.md with the failure record → transition handoff to `blocked` → spec gets revised → cut v0.4.3.

---

## Pass criteria summary

| Step | Pass if | Maps to |
|------|---------|---------|
| 1 | Both flavors preserve prior `artifact_owner` when not overridden; one-shot live correction succeeds | FR-001, FR-002, SC-001 |
| 2 | Both extended tests exit 0 on the dev box; no opaque `[bash] <assertion>` throws caused by path translation | FR-003, FR-004, SC-002 |
| 3 | `git ls-files` for 4 registry paths returns empty; `git status` after `specify extension list` is clean | FR-006, SC-003 |
| 4 | Tasks.md has ≥ 50 `[x]` + ≥ 15 `(absorbed)` + closing paragraph | FR-005, SC-004 |
| 5 | extension.yml + catalog-entry.json + CHANGELOG all at v0.4.2; CHANGELOG names B1/B2/C1/C4/US4 | FR-010, FR-011, FR-014, SC-006, SC-007 |
| 6 | Validator exits 0 | FR-012 (carry from feature 003 v0.4.0; still active) |
| 7 | All 4 tests (3 bridge + 1 release-tooling self-test) green | SC-008 |
| 8 | specs/001/002/004/005/006 byte-identical | SC-009 |
| 9 | Windows sandbox run PASS, recorded | FR-008, FR-009, SC-005 |
| 10 | WSL Linux sandbox run PASS, recorded | FR-008, FR-009, SC-005 |
| 11 | macOS row PENDING, recorded | FR-008, FR-009, SC-005 |
| 12 | Issue #2581 comment updated with v0.4.2 SHA256 + URL | SC-012 |
| 13 | Handoff transitions to `complete` only after Steps 9 + 10 PASS | FR-008 |

Steps 9 + 10 are the hard ones — they require manual sandbox runs. The implementation is **NOT complete** until both have been driven by a human (or by Claude/Codex remotely connecting to the sandbox dir) and recorded in verification.md.
