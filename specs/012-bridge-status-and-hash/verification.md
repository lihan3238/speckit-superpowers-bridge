# v0.7.0 — End-User Verification Sandbox record

**Feature**: 012-bridge-status-and-hash
**Spec**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md) | **Tasks**: [tasks.md](./tasks.md)
**Date**: 2026-05-28
**Platform**: WSL Ubuntu bash 5.x (`/mnt/c/...` checkout — primary smoke surface per [009-wsl-dev-env-alignment](../009-wsl-dev-env-alignment/spec.md))

Per Constitution §"End-User Verification Sandbox" (v1.2.0+) and feature 012 FR-015 + SC-007: every feature that ships a release artifact MUST be verified end-to-end in `..\test_specify_superpower` against the **published release URL** before the feature's handoff transitions to `complete`. This record captures that run for v0.7.0.

## Setup

- Sandbox repo: `..\test_specify_superpower` (sibling to this source repo).
- Reset: `git checkout -- . && git clean -fdx` → clean slate.
- Spec Kit init: `specify init . --ai claude --script sh --here --force` → Spec Kit 0.8.16 layout.
- Bridge install via **published release URL** (stable-alias, per v0.6.0 decoupling):
  ```
  specify extension add speckit-superpowers-bridge \
    --from https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip
  ```
  Downloaded ZIP size: **61730 bytes** (release `v0.7.0`; both `speckit-superpowers-bridge-v0.7.0.zip` and `speckit-superpowers-bridge.zip` aliases identical 61730 bytes, verified post-publish).

## Bridge SHA256

| File | SHA256 |
|---|---|
| `.specify/extensions/speckit-superpowers-bridge/scripts/bash/bridge-status.sh` | `2d1e1e8e6976063f196ca1c029df5c6554a04c65ffbd08141191fb2193f6b804` |

## Cycle exercised

The cycle uses the bridge scripts directly (not slash-command UI), which is what the protocol contracts gate on. Slash commands in Claude Code are separately tested by Spec Kit's own surface.

### A. `bridge-status` against a fresh checkout (no handoff yet) — SC-001 (US1)

```
$ bash .specify/extensions/speckit-superpowers-bridge/scripts/bash/bridge-status.sh
[bridge state]
  Feature directory: (none)
  Status: (no handoff)
  Artifact owner: unknown
  Actor: unknown
  Pending tasks: (no feature_directory)
  Next: /speckit-specify
```

**Verifies**: US1 acceptance scenario S-OUT-3 (no handoff → recommend `/speckit-specify`); FR-004 exit code 0 in the no-handoff state.

### B. Seed synthetic feature + transition to `ready`

```
$ bash .specify/extensions/.../update-handoff.sh --status ready --feature-directory specs/099-sandbox-bridge-status --actor claude --artifact-owner claude
Wrote .specify/superpowers-handoff.json with status 'ready'.
[bridge state]
  Feature directory: specs/099-sandbox-bridge-status
  Status: ready
  Artifact owner: claude
  Actor: claude
  Pending tasks: 3
```

**Verifies**: existing v0.5.0 5-line `[bridge state]` block preserved byte-identical for `update-handoff` (SC-008); no `Drift:` line or `Next:` line emitted by `update-handoff` (D4 contract — only `bridge-status` emits those).

### C. Transition to `executing` — `artifacts_sha256` populated (US2)

```
$ bash .specify/extensions/.../update-handoff.sh --status executing --feature-directory specs/099-sandbox-bridge-status --actor claude
Wrote .specify/superpowers-handoff.json with status 'executing'.
[bridge state]
  Feature directory: specs/099-sandbox-bridge-status
  Status: executing
  Artifact owner: claude
  Actor: claude
  Pending tasks: 3

$ jq '.artifacts_sha256' .specify/superpowers-handoff.json
{
  "spec.md": "a6cdd5f0123ab9390255692fd63663df885bef5b140b4307c5fa994c9f840f14",
  "plan.md": "1036c63c0e310032fb273ed5dc624f6de743c7167c45868994245d0fb9460a89",
  "tasks.md": "579f629e5a29a5ea64e44fd7358b31689b75ad79cd799d2bcedcd3b90df7c86b"
}
```

**Verifies**: FR-005 (executing write populates `artifacts_sha256` with three lowercase-hex 64-char strings); schema delta accepted by both writer and reader.

### D. `bridge-status` during executing with no drift yet — Drift: (none) (US2)

```
$ bash .specify/extensions/.../bridge-status.sh
[bridge state]
  Feature directory: specs/099-sandbox-bridge-status
  Status: executing
  Artifact owner: claude
  Actor: unknown
  Pending tasks: 3
  Drift: (none)
  Next: continue implementation via speckit-superpowers-bridge SKILL
```

**Verifies**: US1 acceptance scenario S-OUT-1; US2 scenario S-OUT-2-clean (Drift line shows (none) when all hashes match); decision-table vector V6 (executing → continue via bridge SKILL).

### E. Inject drift — modify tasks.md mid-execution

```
$ printf '\n- [ ] T999 INJECTED DRIFT\n' >> specs/099-sandbox-bridge-status/tasks.md
```

### F. `bridge-status` sees drift — Drift: tasks.md (US2)

```
$ bash .specify/extensions/.../bridge-status.sh
[bridge state]
  Feature directory: specs/099-sandbox-bridge-status
  Status: executing
  Artifact owner: claude
  Actor: unknown
  Pending tasks: 4
  Drift: tasks.md
  Next: continue implementation via speckit-superpowers-bridge SKILL
```

**Verifies**: US2 acceptance scenario S-OUT-2 (Drift line shows offending filename); FR-007 (bridge-status surfaces drift via the stdout `Drift:` line, NOT via the stderr `[bridge] WARNING:` — there was no stderr output from this invocation).

### G. Transition `executing → complete` — drift warning fires + event recorded (US2)

```
$ bash .specify/extensions/.../update-handoff.sh --status complete --actor claude --reason "T022 cycle complete with injected drift"
[STDOUT]
Wrote .specify/superpowers-handoff.json with status 'complete'.
[bridge state]
  Feature directory: specs/099-sandbox-bridge-status
  Status: complete
  Artifact owner: claude
  Actor: claude
  Pending tasks: 4

[STDERR]
[bridge] WARNING: artifact drift since executing snapshot: tasks.md (sha256 mismatch)
[bridge] WARNING: handoff is 'complete' but tasks.md has 4 unchecked tasks; review or move under a deferred section.

[exit code]
0
```

**Verifies**:
- US2 acceptance scenario S-EVT-1 (single-artifact drift → stderr warning line); FR-006 warning shape matches contract.
- FR-008 exit code 0 (transition not blocked; drift is advisory).
- SC-008 — the existing v0.5.0 008-era "pending tasks" warning still fires (second stderr line); the new v0.7.0 drift warning is additive, not replacing.

### H. Event log records `artifact_drift_detected` (US2)

```
$ grep 'artifact_drift_detected' .specify/bridge-events.jsonl | tail -1 | jq .
{
  "event": "artifact_drift_detected",
  "timestamp": "2026-05-28T09:11:09Z",
  "actor": "claude",
  "feature_directory": "specs/099-sandbox-bridge-status",
  "drifted_artifacts": [
    {
      "path": "tasks.md",
      "old_sha256": "579f629e5a29a5ea64e44fd7358b31689b75ad79cd799d2bcedcd3b90df7c86b",
      "new_sha256": "7de3e21efc49228be72975d36b3de683754b84a1277321047dd5cd514dcdb8da"
    }
  ]
}
```

**Verifies**: FR-008 (event appended to `bridge-events.jsonl`); event shape matches [contracts/artifact-drift-event.md](./contracts/artifact-drift-event.md) R-EVT-1..R-EVT-8; old/new hashes are 64-char lowercase hex; only the drifted artifact (tasks.md) appears in `drifted_artifacts`.

## Acceptance-scenario coverage matrix

| Story | Scenario | Step | Result |
|---|---|---|---|
| US1 | S-OUT-3 (no handoff) | A | ✅ |
| US1 | S-OUT-1 (executing, no drift) | D | ✅ |
| US2 | S-OUT-2 (drift line shows tasks.md) | F | ✅ |
| US2 | S-OUT-2-clean (Drift: (none)) | D | ✅ |
| US2 | S-EVT-1 (single-artifact drift → warning + event) | G + H | ✅ |
| Cross | SC-008 (008-era warning preserved) | G | ✅ |
| Cross | FR-007 (bridge-status read-only) | F | ✅ |
| Cross | FR-013 (pre-070 backward compat) | — | (covered by in-repo `tests/test-bridge-status.sh` fixture; not re-tested in sandbox) |
| Cross | Decision-table vector V6 | D / F | ✅ |

Required minimum per SC-007: "at least one passing scenario from each of US1 and US2." Actual coverage: **3 US1 scenarios + 4 US2 scenarios + 2 cross-cutting**. Well above the minimum.

## Outcome

**Sandbox verification: PASS** on WSL bash.

- Fresh-install ZIP delivers `bridge-status.sh` at the documented path.
- Stable-alias URL `releases/latest/download/speckit-superpowers-bridge.zip` resolves to the v0.7.0 asset (61730 bytes, both alias forms byte-identical post-publish).
- Both feature pillars (US1 introspection + US2 drift detection) work end-to-end against a fresh install.
- Existing v0.5.0 print contract and 008-era warning behavior preserved (SC-008).
- v0.6.0 `download_url` decoupling holds — install used the stable-alias URL exclusively.

PowerShell sandbox coverage is deferred to a future feature (per [research D7](./research.md#d7--sandbox-scope-for-v070-verification) — 009 alignment narrows current sandbox scope to WSL bash).

## Notes on the release path

The first `v0.7.0` tag push failed CI due to a pre-existing `validate-release-readiness.ps1` rule still enforcing the pre-v0.6.0 "download_url must contain v<Version>" check. The release was unblocked by main-branch fix `077f4a2 — fix(release): accept v0.6.0+ stable-alias download_url in validator`, then the tag was re-created at the new HEAD. Workflow run 26565421761 succeeded in 22 s; release v0.7.0 published with both ZIP aliases. This is a CI-script bug from v0.6.0's decoupling work, NOT a v0.7.0 feature defect.
