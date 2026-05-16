# Quickstart: Bridge Hardening & 0.5.0 Cleanup

**Phase 1 output for** [plan.md](./plan.md). The two practical playbooks for this release: (1) local verification of US1's drift-hardening, (2) constitution v1.2.0 sandbox run for v0.5.0.

## Prerequisites

- Repo cloned, on branch `008-bridge-hardening-0-5-0`.
- PowerShell 5.1+ available (Windows native or `powershell.exe` from WSL).
- Bash 4.0+ + `jq >= 1.6` (Linux/macOS/WSL).
- `..\test_specify_superpower` sibling directory exists (canonical end-user sandbox per constitution v1.2.0).
- Spec Kit CLI `specify` installed and on PATH (`>= 0.8.10`).

## Playbook 1 — Local verification of US1 drift hardening (in-repo)

Use this after Phase A implementation to confirm the drift-hardening helper works against synthetic fixtures, BEFORE running the published-artifact sandbox.

### Step 1 — Run the new regression test (PS + bash)

```powershell
# Windows or WSL
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests/test-bridge-state-summary.ps1
```

Expected: `(ps, bash)` or `(ps)` summary line + exit 0. The bash flavor may be skipped-with-reason if `jq` or `awk` is missing; that is acceptable per the v0.4.2 B2 strategy chain.

### Step 2 — Manual fixture walkthrough

Create a synthetic fixture in a temp directory and observe the state-summary block:

```powershell
# PowerShell
$tmp = New-Item -ItemType Directory -Path "$env:TEMP/bridge-state-fixture-$(Get-Random)" -Force
Set-Location $tmp
New-Item -ItemType Directory -Path "specs/fake-feature" -Force | Out-Null
@"
- [x] T001 done task
- [ ] T002 in progress
- [ ] T003 in progress

## Deferred (later cycle)

- [ ] T100 deferred task
- [ ] T101 deferred task
"@ | Out-File specs/fake-feature/tasks.md -Encoding UTF8

# Initialize a minimal handoff (use the real script for the synthetic feature)
New-Item -ItemType Directory -Path .specify -Force | Out-Null
@'{"schema_version":1,"feature_directory":"specs/fake-feature","status":"executing","actor":"claude","artifact_owner":"claude"}'@ | Out-File .specify/superpowers-handoff.json -Encoding UTF8

# Invoke the new helper (or update-handoff which sources it)
& "$REPO/.specify/extensions/speckit-superpowers-bridge/scripts/powershell/bridge-state.ps1"
```

Expected output (representative — exact form per [contracts/bridge-state-summary.md](./contracts/bridge-state-summary.md)):

```text
[bridge state]
  Feature directory: specs/fake-feature
  Status: executing
  Artifact owner: claude
  Actor: claude
  Pending tasks: 2
```

(T100 + T101 excluded because they live under the `## Deferred (later cycle)` header.)

### Step 3 — Deliberate-mismatch test (FR-019 prep)

Transition the fixture handoff to `complete` and observe the warning:

```powershell
& "$REPO/.specify/extensions/speckit-superpowers-bridge/scripts/powershell/update-handoff.ps1" -Status complete -Actor claude
```

Expected:
- stdout: state-summary block showing `Status: complete`, `Pending tasks: 2`.
- stderr: `[bridge] WARNING: handoff is 'complete' but tasks.md has 2 unchecked tasks; review or move under a deferred section.`
- Exit code: 0.

### Step 4 — Actor change verification (SC-003)

```powershell
& "$REPO/.specify/extensions/speckit-superpowers-bridge/scripts/powershell/update-handoff.ps1" -Status executing -Actor codex
Get-Content .specify/bridge-events.jsonl | Select-Object -Last 1 | ConvertFrom-Json | Select-Object actor, prior_actor, reason
```

Expected: `actor: codex`, `prior_actor: claude`, `reason` contains `actor change claude → codex`.

### Step 5 — Clean up

```powershell
Set-Location $REPO
Remove-Item $tmp -Recurse -Force
```

## Playbook 2 — Sandbox verification for v0.5.0 release (constitution v1.2.0 gate)

Use this AFTER tagging `v0.5.0` and the GH Actions release workflow completes. Records the FR-018 + FR-019 PASS rows in `specs/008-bridge-hardening-0-5-0/verification.md`.

### Step 1 — Confirm release artifact

```bash
gh release view v0.5.0 --json tagName,assets --jq '{tag, assets: [.assets[] | {name, size, state, digest}]}'
```

Expected: two `state: "uploaded"` assets — `speckit-superpowers-bridge-v0.5.0.zip` AND `speckit-superpowers-bridge.zip`, identical digest.

Capture the SHA256 from the GH Actions Step Summary or via:

```bash
curl -fsSL https://github.com/lihan3238/speckit-superpowers-bridge/releases/download/v0.5.0/speckit-superpowers-bridge-v0.5.0.zip | sha256sum
```

### Step 2 — Windows PowerShell sandbox run

```powershell
# In a fresh PS session
cd ..\test_specify_superpower
Remove-Item -Recurse -Force .specify, specs, .claude, .agents -ErrorAction SilentlyContinue
specify init . --integration claude --script ps --here --force
specify extension add speckit-superpowers-bridge --from https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip
specify extension list
# expected: 3 commands + 5 hooks, version 0.5.0
```

Drive one bridge cycle:

```powershell
# Inside Claude Code in the sandbox project
/speckit-specify "throwaway feature for v0.5.0 sandbox verification"
/speckit-clarify   # skip if no clarifications surface
/speckit-plan
/speckit-tasks
/speckit-superpowers-bridge
# verify handoff goes ready → executing → complete cleanly
```

**Observe US1 drift output**: At each script invocation note the `[bridge state]` block is printed; capture into the verification.md Notes column.

### Step 3 — Deliberate-mismatch test (FR-019)

In the sandbox project, after the throwaway feature reaches `complete`:

```powershell
# Add an unchecked line to the sandbox feature's tasks.md
Add-Content -Path specs/<sandbox-feature>/tasks.md -Value "- [ ] T999 deliberately unchecked for FR-019"
# Trigger any bridge invocation
& .specify\extensions\speckit-superpowers-bridge\scripts\powershell\guard-command.ps1 -Action speckit.plan -Actor claude
# Expected: [bridge state] block shows Pending tasks: 1 even though Status: complete
# Re-transitioning forward to complete should fire the warning:
& .specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status complete -Actor claude
# Expected stderr: [bridge] WARNING: handoff is 'complete' but tasks.md has 1 unchecked tasks; ...
```

Record this in the verification.md row's Notes column.

### Step 4 — WSL Linux bash sandbox run

```bash
cd ../test_specify_superpower
rm -rf .specify specs .claude .agents
specify init . --integration claude --script sh --here --force
specify extension add speckit-superpowers-bridge --from https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip
specify extension list
```

Drive the same one-cycle sequence as Step 2 but with bash flavor scripts under `scripts/bash/`. Confirm bash scripts are invoked (visible in `bridge-events.jsonl` entries that have `scripts/bash/` paths if logged, or via `which awk` and absence of `pwsh`).

Repeat Step 3 (deliberate-mismatch test) with the bash flavor of `update-handoff.sh`.

### Step 5 — macOS row

```text
| macos-bash | — | — | — | PENDING | no host available; deferred per Clarifications Q1 (008) inheriting v0.4.2 / v0.4.3 |
```

### Step 6 — Append to `verification.md`

Open `specs/008-bridge-hardening-0-5-0/verification.md` (create if not present) and append the `## v0.5.0` section with three rows per the schema in `../003-bridge-cross-platform-scripts/contracts/verification-record.md`. Notes column MUST mention the US1 drift output was observed AND the deliberate-mismatch warning fired.

### Step 7 — Commit + transition handoff

```bash
git add specs/008-bridge-hardening-0-5-0/verification.md
git commit -m "verify(bridge): record v0.5.0 sandbox run (Windows PS + WSL Linux PASS; macOS pending)"
git push

# Transition 008 handoff to complete
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .specify/extensions/speckit-superpowers-bridge/scripts/powershell/update-handoff.ps1 -Status complete -Actor claude
```

Now US1's hardening should report `Pending tasks: 0` (all 008 tasks checked or under `## Deferred`) and NO warning. If it does fire a warning, that itself is a defect — return to US2 alignment and fix the offending tasks.md.

## Failure recovery

- **Sandbox install fails** (e.g., wrong SHA, asset not found): the release is not shippable. Mark handoff `blocked` with a reason; re-tag a v0.5.1 once fixed; do NOT delete the v0.5.0 tag (audit trail).
- **Sandbox PASS on one platform, FAIL on another**: record the FAIL row honestly; mark handoff `blocked`; open a follow-up spec (likely 009) addressing the regression.
- **macOS host becomes available mid-cycle**: opportunistically run Step 4 on macOS and append a fourth row replacing PENDING with PASS/FAIL.

## Cross-references

- US1 acceptance scenarios → [spec.md § User Story 1](./spec.md)
- US5 verification inheritance → [spec.md § User Story 5](./spec.md)
- Constitution v1.2.0 sandbox gate → [`.specify/memory/constitution.md` § End-User Verification Sandbox](../../.specify/memory/constitution.md)
- Verification record schema → [`../003-bridge-cross-platform-scripts/contracts/verification-record.md`](../003-bridge-cross-platform-scripts/contracts/verification-record.md)
- v0.4.2 verification (precedent) → [`../003-bridge-cross-platform-scripts/verification.md`](../003-bridge-cross-platform-scripts/verification.md)
- v0.4.3 verification (precedent) → [`../007-catalog-distribution-polish/verification.md`](../007-catalog-distribution-polish/verification.md)
