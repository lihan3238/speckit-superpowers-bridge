# Quickstart: Complete Bridge Protocol

**Feature**: 002-complete-bridge-protocol
**Audience**: Maintainer or contributor about to validate or extend this feature
**Time**: 10 minutes

## Prerequisites

- Windows with PowerShell 5.1 or PowerShell 7.x (`powershell.exe` or `pwsh`)
- `git` ≥ 2.30
- A clone of this repository on the `002-complete-bridge-protocol` branch
- Spec Kit `0.8.9` installed (already configured in `.specify/init-options.json`)
- Either Codex or Claude Code as the active agent (this guide shows both)

## 0. Complete user workflow

Use this flow when you are using the bridge for real feature development. The later sections in this quickstart are maintainer validation checks.

1. Install both integrations if you want Codex and Claude Code available in the same repo:

   ```powershell
   specify init . --integration codex
   specify integration install claude
   specify integration use codex
   ```

2. Pick exactly one Spec Kit artifact writer for the feature. Codex uses `$speckit-*` commands; Claude Code uses `/speckit-*` commands. The other agent should review only until ownership changes.

3. Produce the Spec Kit design artifacts:

   ```text
   $speckit-specify "Describe the feature"
   $speckit-clarify
   $speckit-checklist
   $speckit-plan
   $speckit-tasks
   $speckit-analyze
   ```

   For Claude Code, replace the `$` invocations with slash invocations such as `/speckit-specify`.

4. Confirm or create the handoff. The `after_tasks` hook normally creates it; refresh manually only when needed:

   ```powershell
   .\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status ready -Actor codex
   ```

5. Execute implementation through Superpowers, not through `speckit.implement`:

   ```text
   $speckit-superpowers-bridge
   ```

   Claude Code uses `/speckit-superpowers-bridge`. The bridge reads `constitution.md`, `spec.md`, `plan.md`, and `tasks.md`, then executes `tasks.md` with TDD, debugging, review, verification, and branch finishing.

6. If implementation exposes a missing requirement or wrong design, stop implementation and return to Spec Kit:

   ```powershell
   .\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status blocked -Reason "Spec Kit artifact needs revision" -Actor codex
   ```

   Revise `spec.md`, `plan.md`, or `tasks.md`, then create a fresh ready handoff and resume.

7. Finish only after validation passes:

   ```powershell
   .\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\validation-pass.ps1 -Json -Actor codex
   ```

8. Start the next feature by letting the `before_specify` hook auto-archive a complete handoff, or run:

   ```powershell
   .\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\auto-archive-handoff.ps1 -Actor codex
   ```

Guardrails: do not run `speckit.implement` when `executor` is `superpowers`; do not use Superpowers `brainstorming` or `writing-plans` to replace existing Spec Kit artifacts; do not let two agents write the same Spec Kit files at the same time.

## 1. Verify the disposition matrix is loaded

```bash
# Confirm the matrix file exists and parses
powershell.exe -NoProfile -Command "Get-Content .specify/extensions/speckit-superpowers-bridge/disposition-matrix.json | ConvertFrom-Json | Out-Null; if (\$LASTEXITCODE -eq 0) { Write-Output 'OK' }"

# Confirm verified-versions exists
powershell.exe -NoProfile -Command "Get-Content .specify/extensions/speckit-superpowers-bridge/verified-versions.json | ConvertFrom-Json | Out-Null; if (\$LASTEXITCODE -eq 0) { Write-Output 'OK' }"
```

Both commands should print `OK`. If either file is missing, tasks for this feature have not yet been implemented — return to `tasks.md`.

## 2. Run the parity check

```bash
# On-demand parity check (works on either agent via Bash wrapper or direct invocation)
powershell.exe -NoProfile -ExecutionPolicy Bypass \
  -File .specify/extensions/speckit-superpowers-bridge/scripts/powershell/parity-check.ps1 \
  -Json -Actor claude
```

**Expected output** (after this feature ships, on a clean checkout):

```json
{
  "schema_version": 1,
  "generated_at": "2026-05-15T...",
  "installed": { "spec_kit_version": "0.8.9", "superpowers_skills": [...] },
  "verified":  { "spec_kit_version": "0.8.9", "superpowers_skills": [...] },
  "findings": [],
  "summary": { "total": 0, "by_severity": { "P0": 0, "P1": 0, "P2": 0, "P3": 0 } },
  "exit_code": 0
}
```

Exit code 0. Any non-zero exit indicates a regression — see [parity-check-contract.md](contracts/parity-check-contract.md) for codes.

## 3. Validate the Claude Code happy path (live)

This is the SC-003 acceptance test. Run from a fresh terminal in Claude Code:

```text
/speckit-constitution     # should run without errors (status: ready)
/speckit-specify "..."    # auto-archives any complete handoff; claims claude ownership
/speckit-clarify          # passes guard automatically
/speckit-plan             # passes guard automatically
/speckit-tasks            # creates handoff, transitions to executing
/speckit-superpowers-bridge  # executes tasks.md
```

**Expected**: every command resolves to its registered Claude slash command (no `command not found`). Every hook in `.specify/extensions.yml` resolves to either a Claude slash command or a Spec Kit extension command. Zero invocations of `powershell.exe` from the user side.

If a command fails to resolve, that is a NEW Compatibility Gap Record — append a row to `specs/002-complete-bridge-protocol/compat-gaps.md`.

## 4. Validate cross-feature auto-archive

```bash
# Seed a complete handoff for a fake prior feature
powershell.exe -NoProfile -ExecutionPolicy Bypass \
  -File .specify/extensions/speckit-superpowers-bridge/scripts/powershell/update-handoff.ps1 \
  -Status complete -FeatureDirectory "specs/fake-prior" -ArtifactOwner codex -Reason "Test seed"

# Confirm the guard now allows clarify for a different feature
# (in a real flow, /speckit-specify on a new feature would invoke auto-archive automatically)
powershell.exe -NoProfile -ExecutionPolicy Bypass \
  -File .specify/extensions/speckit-superpowers-bridge/scripts/powershell/auto-archive-handoff.ps1 -Actor claude

# Inspect the handoff — status should now be ready, archive_history has one entry
type .specify/superpowers-handoff.json
```

**Expected**: status is `ready`, `feature_directory` is empty, `archive_history` has one entry referencing the fake prior feature with a snapshot ID.

## 5. Validate constitution forbid scope

```bash
# Seed an executing handoff
powershell.exe -NoProfile -ExecutionPolicy Bypass \
  -File .specify/extensions/speckit-superpowers-bridge/scripts/powershell/update-handoff.ps1 \
  -Status executing -FeatureDirectory "specs/002-complete-bridge-protocol" -ArtifactOwner claude -Reason "Test seed"

# Guard should DENY speckit.constitution
powershell.exe -NoProfile -ExecutionPolicy Bypass \
  -File .specify/extensions/speckit-superpowers-bridge/scripts/powershell/guard-command.ps1 \
  -Action speckit.constitution -Actor claude
# expected: non-zero exit, "FORBID-UNDER-HANDOFF" message

# Transition to blocked
powershell.exe -NoProfile -ExecutionPolicy Bypass \
  -File .specify/extensions/speckit-superpowers-bridge/scripts/powershell/update-handoff.ps1 \
  -Status blocked -Reason "Test transition"

# Guard should now ALLOW speckit.constitution
powershell.exe -NoProfile -ExecutionPolicy Bypass \
  -File .specify/extensions/speckit-superpowers-bridge/scripts/powershell/guard-command.ps1 \
  -Action speckit.constitution -Actor claude
# expected: "Guard allowed speckit.constitution."
```

## 6. Validate the test suite

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass \
  -File .specify/extensions/speckit-superpowers-bridge/scripts/powershell/test-bridge-guard.ps1
```

**Expected**: all cases pass (the count grew from feature 001 — new cases for auto-archive, constitution scope, checklist allow, missing-skill detection).

## 7. Compat gap log

Open `specs/002-complete-bridge-protocol/compat-gaps.md`. Confirm:

- CG-001 through CG-004 are `CLOSED-IN-FEATURE` (this feature closed them).
- CG-005 (Bash port) is `DEFERRED` with a named follow-up.
- No `OPEN` P0/P1 records remain.

If any P0/P1 record is still `OPEN`, this feature is not ready to ship per SC-007.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `powershell.exe: command not found` on Linux/macOS | CG-005 is still deferred; no Bash port yet | Use a Windows machine or wait for the Bash-port follow-up feature |
| Parity check reports `missing_invocation_surface` on a Claude `speckit-git-*` skill | The mirror wasn't applied | Copy from `.agents/skills/<id>/SKILL.md` to `.claude/skills/<id>/SKILL.md` per [research R7](research.md) |
| Guard denies `speckit.clarify` for the current feature | Handoff is `executing` or `complete` for a DIFFERENT feature | Run `auto-archive-handoff.ps1`, then retry |
| `auto_archive` event missing from `bridge-events.jsonl` | The helper's `finally` block didn't write — bug | File a P1 CG; the contract requires atomicity |

## Where to read next

- [spec.md](spec.md) — what we're building and why
- [plan.md](plan.md) — the design decisions and minimal scope
- [research.md](research.md) — alternatives considered for each design decision
- [data-model.md](data-model.md) — the precise shape of every entity
- [contracts/](contracts/) — schemas and CLI contracts the implementation must honor
- [compat-gaps.md](compat-gaps.md) — live gap log; closing condition for SC-007
- `tasks.md` (generated by `/speckit-tasks`) — the ordered work list
