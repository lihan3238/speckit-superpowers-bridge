# Handoff Transitions Contract

**Feature**: 002-complete-bridge-protocol

## State machine (extended)

```
                         (speckit.tasks completes; handoff is created)
        +---------+ ----------------------------------------------> +-----------+
        |  ready  |                                                 | executing |
        +---------+                                                 +-----------+
            ^                                                          |     |
            |                                                          |     |
            |                       (verification passes;              |     | (spec gap discovered;
            |                        all tasks complete)               |     |  bridge needs repair)
            |                                                          v     v
            |  (NEW: /speckit-specify on new feature                +---------+
            |   auto-archives; helper script only)                  | complete|
            |                                                       +---------+
            |                                                          |
            |                                                          |   (repair: implementation
            |                                                          |    surfaces blocked spec)
            |                                                          v
            |                                                       +---------+
            +-------------------------------------------------------| blocked |
                                                                    +---------+
                                                                       ^
                                                                       |
                                                                  (Spec Kit edits resume)
```

## Permitted transitions

| From | To | Trigger | Helper script | Snapshot taken? |
|---|---|---|---|---|
| `ready` | `executing` | `speckit.tasks` completes; bridge handoff created/refreshed | `update-handoff.ps1 -Status executing` | yes |
| `executing` | `complete` | All `tasks.md` items checked and verification passed | `update-handoff.ps1 -Status complete` | yes |
| `executing` | `blocked` | Implementation discovers missing/wrong requirement in spec/plan/tasks | `update-handoff.ps1 -Status blocked -Reason "<details>"` | yes |
| `blocked` | `executing` | Spec Kit repair complete; ready to resume | `update-handoff.ps1 -Status executing` | yes |
| `blocked` | `ready` | Feature abandoned; reset for next | `update-handoff.ps1 -Status ready` | yes |
| **`complete` → `ready`** (NEW) | **`/speckit-specify` runs on a new feature OR maintainer explicitly clears** | `auto-archive-handoff.ps1` (only) | yes |

All other transitions are denied by `update-handoff.ps1` with a non-zero exit and a clear error message.

## Auto-archive helper

`auto-archive-handoff.ps1` is a tiny wrapper around the existing snapshot + write
sequence. Pseudocode:

```pwsh
param([string]$Actor = "unknown")

$ErrorActionPreference = "Stop"

$handoffPath = (Resolve-Path .specify/superpowers-handoff.json).Path
$state = Get-Content $handoffPath -Raw | ConvertFrom-Json

if ($state.status -ne "complete") {
    # Nothing to archive; just exit successfully so callers can blindly invoke this on /speckit-specify
    Write-Output "No complete handoff to archive (current status: $($state.status))."
    exit 0
}

# 1. Snapshot
$snapId = & .specify/extensions/speckit-superpowers-bridge/scripts/powershell/<snapshot-helper>.ps1 -Reason "auto-archive complete handoff before new feature"

# 2. Append to archive_history
$archiveEntry = [pscustomobject]@{
    feature_directory   = $state.feature_directory
    status_at_archive   = "complete"
    snapshot_id         = $snapId
    archived_at         = (Get-Date).ToUniversalTime().ToString("o")
    archived_by         = $Actor
}
if (-not $state.archive_history) { $state | Add-Member -NotePropertyName archive_history -NotePropertyValue @() }
$state.archive_history += $archiveEntry

# 3. Reset to ready
$state.status = "ready"
$state.feature_directory = ""
$state.artifact_owner = "unknown"
$state.review_only_agents = @()
$state.blocked_reason = $null
$state.notes = $null
$state.updated_at = (Get-Date).ToUniversalTime().ToString("o")
$state.last_snapshot_id = $snapId

$state | ConvertTo-Json -Depth 10 | Set-Content -Path $handoffPath -Encoding UTF8

# 4. Append bridge event
& .specify/extensions/speckit-superpowers-bridge/scripts/powershell/<event-helper>.ps1 `
    -Action "auto_archive" -Decision "archive" -Reason "auto-archive on new feature" -SnapshotId $snapId -Actor $Actor

Write-Output "Auto-archived handoff (snapshot: $snapId)."
```

The helper is idempotent: invoking it when status is anything other than `complete` is a no-op success exit.

## Guard treatment of `complete`

In `guard-command.ps1`, the existing "block contract changes when status is `complete`" rule MUST be modified to differentiate:

| Pre-existing behavior | New behavior |
|---|---|
| Any Spec Kit contract action denied when `status == complete` | Spec Kit contract action allowed when `status == complete` AND the requested action's target feature differs from `handoff.feature_directory`; auto-archive is recommended to the caller |
| `speckit.implement` denied when `status == complete` | Unchanged (still denied; `speckit.implement` is FORBID-UNDER-HANDOFF with `applicability: [ready, executing, blocked, complete]`) |

The change is one boolean in the guard: "is the current request scoped to the same feature as the active handoff?". If yes → preserve previous strict block. If no → defer the check to the disposition matrix.

## Bridge events

One new `action` value: `auto_archive`. One new optional field on guard events: `policy_ref` (the matching disposition entry `id` when a deny is driven by the matrix). Both are additive; no existing consumer breaks.

## Atomicity

The auto-archive sequence (snapshot → write → log) MUST be all-or-nothing. If
the JSON write fails mid-way, the snapshot remains valid for manual restore and
the bridge event recording the failure MUST still be appended. The helper script
uses PowerShell's `try { ... } catch { ... }` with a `finally` block that
guarantees the event log entry is written even on a partial failure.

## Tests

`test-bridge-guard.ps1` is extended with:

1. **Auto-archive happy path**: seed `handoff.json` with `status=complete, feature_directory=foo`; run auto-archive; assert final state is `ready`, `feature_directory=""`, snapshot exists, archive_history has one entry, bridge-events.jsonl has new `auto_archive` line.
2. **Auto-archive no-op**: seed status `ready`; run auto-archive; assert no change to file.
3. **Cross-feature contract change with complete handoff**: seed status `complete, feature_directory=001-x`; invoke guard for `speckit.clarify` with feature 002 in scope; assert allow.
4. **Same-feature contract change with complete handoff**: seed status `complete, feature_directory=002-y`; invoke guard for `speckit.clarify` on feature 002; assert deny (or auto-archive first, then allow — choose one consistent path; current decision: deny with hint "auto-archive recommended").
5. **`speckit.implement` under complete handoff**: still denied per FR-012 + matrix entry.
