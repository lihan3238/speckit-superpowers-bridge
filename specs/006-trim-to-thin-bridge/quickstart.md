# Quickstart: Trim To Thin Bridge

**Feature**: 006-trim-to-thin-bridge
**Audience**: the executor (Codex or Claude Code) implementing this trim, and a reviewer validating the result.

This quickstart is a smoke walkthrough — invoke it after `/speckit-tasks` finishes and the implementation lands. It validates the cross-agent handoff flow that the spec says must survive (US2), the structural cuts (US1), the spec-history preservation (US3), and the version bump (US4).

---

## Prerequisites

- Repo clean (`git status` shows working tree clean).
- All commits from R9 (research.md §R9) are present.
- Both PowerShell 5.1+ and `git` available on PATH.
- The maintainer's local `docs/` directory may or may not exist; the test does not depend on it.

---

## Quickstart steps

### Step 1 — Verify the structural cuts (US1, FR-001..003, FR-011)

```powershell
# Count retained bridge scripts (target: ≤ 3 callable + 1 helper)
Get-ChildItem .specify/extensions/speckit-superpowers-bridge/scripts/powershell/ -Filter *.ps1 |
    Select-Object -ExpandProperty Name

# Expected output (4 lines max):
#   auto-archive-handoff.ps1
#   common-actor-resolution.ps1
#   guard-command.ps1
#   update-handoff.ps1
```

```powershell
# Count retained command md files (target: 3)
Get-ChildItem .specify/extensions/speckit-superpowers-bridge/commands/ -Filter *.md |
    Select-Object -ExpandProperty Name

# Expected output (3 lines):
#   speckit.speckit-superpowers-bridge.execute.md
#   speckit.speckit-superpowers-bridge.guard.md
#   speckit.speckit-superpowers-bridge.handoff.md
```

```powershell
# Verify the removed files are absent
$removed = @(
    'parity-check.ps1','audit-install-state.ps1','validation-pass.ps1',
    'submission-checklist.ps1','cleanup-audit.ps1','recommend-route.ps1',
    'emit-skill-invocation.ps1','emit-resume-signal.ps1','restore-snapshot.ps1',
    'check-readme-bilingual-parity.ps1','check-distribution-manifest.ps1'
)
$present = $removed | Where-Object {
    Test-Path ".specify/extensions/speckit-superpowers-bridge/scripts/powershell/$_"
}
if ($present.Count -gt 0) { throw "Trim incomplete; still present: $($present -join ', ')" }
```

```powershell
# Verify the removed data files are absent
foreach ($f in 'disposition-matrix.json','verified-versions.json','plugin-distribution-manifest.yml') {
    if (Test-Path ".specify/extensions/speckit-superpowers-bridge/$f") {
        throw "Trim incomplete; $f still present"
    }
}
```

### Step 2 — Verify line-budget compliance (SC-001..003)

```powershell
# Total lines across retained PowerShell (target: ≤ 300)
$total = (Get-ChildItem .specify/extensions/speckit-superpowers-bridge/scripts/powershell/*.ps1 |
    Get-Content | Measure-Object -Line).Lines
"Total PowerShell lines: $total (target ≤ 300)"
```

```powershell
# SKILL.md line counts (target: ≤ 100 each, hard cap 150)
(Get-Content .claude/skills/speckit-superpowers-bridge/SKILL.md).Count
(Get-Content .agents/skills/speckit-superpowers-bridge/SKILL.md).Count
```

```powershell
# Test count (target: ≤ 3)
@(Get-ChildItem tests/*.ps1).Count
```

### Step 3 — Verify backward-read of older handoff JSON (FR-009)

```powershell
# Simulate a v3 handoff document
$tempDir = New-Item -ItemType Directory -Path (Join-Path $env:TEMP "bridge-trim-test-$([Guid]::NewGuid().ToString('N').Substring(0,8))")
Copy-Item -Recurse .specify $tempDir
$handoff = Join-Path $tempDir ".specify/superpowers-handoff.json"
@'
{
  "schema_version": 3,
  "updated_at": "2026-05-15T00:00:00Z",
  "feature_directory": "specs/006-trim-to-thin-bridge",
  "source_of_truth": {
    "constitution": ".specify/memory/constitution.md",
    "spec": "specs/006-trim-to-thin-bridge/spec.md",
    "plan": "specs/006-trim-to-thin-bridge/plan.md",
    "tasks": "specs/006-trim-to-thin-bridge/tasks.md"
  },
  "executor": "superpowers",
  "status": "executing",
  "artifact_owner": "claude",
  "autonomous_mode": true,
  "resume_context": { "last_task": "T042" },
  "archive_history": [{ "feature_directory": "specs/005-marketplace-alignment", "completed_at": "2026-05-15T00:00:00Z" }]
}
'@ | Set-Content -Path $handoff -Encoding UTF8

# Have the post-trim update-handoff.ps1 read it (e.g. transition to blocked)
powershell.exe -NoProfile -File .specify/extensions/speckit-superpowers-bridge/scripts/powershell/update-handoff.ps1 `
    -Action block -BlockedReason "smoke test" -Actor claude

# Expected: no error. The v3-only fields are silently ignored.
# Verify new write does NOT include them
$post = Get-Content $handoff -Raw | ConvertFrom-Json
if ($post.PSObject.Properties.Name -contains 'autonomous_mode') {
    throw "FR-006 violation: new write contains autonomous_mode"
}
```

### Step 4 — Verify the hardcoded guard rules (R3 / FR-007)

```powershell
# Should DENY: speckit.implement during executing handoff
$result = powershell.exe -NoProfile -File .specify/extensions/speckit-superpowers-bridge/scripts/powershell/guard-command.ps1 `
    -Action speckit.implement -Actor claude
# Inspect $LASTEXITCODE; expect non-zero (deny)

# Should ALLOW: speckit.plan even during executing handoff
powershell.exe -NoProfile -File .specify/extensions/speckit-superpowers-bridge/scripts/powershell/guard-command.ps1 `
    -Action speckit.plan -Actor claude
# $LASTEXITCODE expected: 0 (allow)

# Should DENY: superpowers:writing-plans when an active feature has spec.md + plan.md
powershell.exe -NoProfile -File .specify/extensions/speckit-superpowers-bridge/scripts/powershell/guard-command.ps1 `
    -Action "superpowers:writing-plans" -Actor claude
# $LASTEXITCODE expected: non-zero (deny)
```

### Step 5 — Verify spec history is byte-identical (US3, FR-017, SC-006)

```powershell
git diff --stat HEAD~10..HEAD -- specs/001-spec-superpowers-bridge specs/002-complete-bridge-protocol specs/003-bridge-cross-platform-scripts specs/004-polish-and-publish specs/005-marketplace-alignment
# Expected: no output (no changes in those directories across the trim's commits)
```

### Step 6 — Verify cross-agent task handoff (US2, SC-005)

This is the load-bearing happy path. Two-agent walkthrough:

1. In **Claude Code**, on a fresh small test feature (e.g., a no-op markdown edit), run:
   ```
   /speckit-specify Add a TEST marker line to README — quickstart smoke test
   /speckit-clarify
   /speckit-plan
   /speckit-tasks
   ```
2. After `/speckit-tasks` finishes, inspect `.specify/superpowers-handoff.json`:
   - `schema_version == 1`
   - `feature_directory == specs/NNN-add-test-marker-line-to-readme` (or similar)
   - `status == "ready"` or `"executing"` (depending on which auto-transition runs)
   - `artifact_owner == "claude"`
3. Switch to **Codex** (close Claude Code session; open Codex on the same repo). In Codex:
   ```
   $speckit-superpowers-bridge
   ```
4. Confirm Codex:
   - Reads `superpowers-handoff.json` and finds the active feature.
   - Reads `tasks.md`.
   - Invokes Superpowers `executing-plans`.
   - Transitions status to `executing` with `artifact_owner` unchanged.
5. Let Codex run through one task end-to-end (TDD → verification → review → finishing).
6. Confirm post-completion:
   - `status == "complete"` in `superpowers-handoff.json`.
   - The new feature's `tasks.md` checkboxes are filled.

### Step 7 — Verify version + CHANGELOG (US4, FR-013..014, SC-007..008)

```powershell
# extension.yml version
(Get-Content .specify/extensions/speckit-superpowers-bridge/extension.yml | Select-String 'version').Line
# Expected: contains "0.3.0"

# catalog-entry.json version
(Get-Content marketplace/catalog-entry.json -Raw | ConvertFrom-Json).version
# Expected: "0.3.0"

# CHANGELOG has [0.3.0] section naming ≥ 5 removed items
Select-String -Path CHANGELOG.md -Pattern '^\[0\.3\.0\]|^## \[?0\.3\.0\]?' -SimpleMatch:$false | Format-List
```

### Step 8 — Verify docs/ is untracked (FR-020)

```powershell
git ls-files docs/
# Expected: no output (no tracked files under docs/)

(Get-Content .gitignore) -match '^/?docs/?$'
# Expected: at least one matching line
```

### Step 9 — Verify the "When to Skip Spec Kit" README section exists (FR-021, R8)

```powershell
Select-String -Path README.md -Pattern '^## When to Skip Spec Kit' -SimpleMatch
Select-String -Path README.zh-CN.md -Pattern '^## When to Skip Spec Kit' -SimpleMatch
# Expected: one hit in each file (English anchor preserved across both per bilingual convention)
```

### Step 10 — Verify bilingual README structural parity (FR-015, SC-010)

```powershell
# H2 anchors should match between the two READMEs (count + names)
$en = (Select-String -Path README.md -Pattern '^## ' | ForEach-Object { $_.Line }).Count
$zh = (Select-String -Path README.zh-CN.md -Pattern '^## ' | ForEach-Object { $_.Line }).Count
if ($en -ne $zh) { Write-Warning "H2 count mismatch: README.md=$en  README.zh-CN.md=$zh" }
```

---

## Cleanup

```powershell
Remove-Item -Recurse -Force $tempDir
```

---

## Pass criteria

| Check | Pass if |
|-------|---------|
| Step 1 | All 11 removed scripts absent; all 3 retained commands present. |
| Step 2 | PS line total ≤ 300; each SKILL.md ≤ 100; tests count ≤ 3. |
| Step 3 | v3 handoff JSON reads without error; new write does not echo v3 fields. |
| Step 4 | Guard denies `speckit.implement` (exit non-zero); allows `speckit.plan` (exit 0); denies `superpowers:writing-plans` when artifacts exist. |
| Step 5 | `git diff` shows zero changes in `specs/001..005/`. |
| Step 6 | Cross-agent handoff completes one feature end-to-end. |
| Step 7 | Version `0.3.0` everywhere; CHANGELOG section names ≥ 5 removed items. |
| Step 8 | `docs/` has zero tracked files; `.gitignore` has the entry. |
| Step 9 | Both READMEs contain the "When to Skip Spec Kit" H2. |
| Step 10 | H2 counts match between English and Chinese READMEs. |

If any step fails, the trim is not complete. Reopen `tasks.md`, identify the failing requirement, and patch.
