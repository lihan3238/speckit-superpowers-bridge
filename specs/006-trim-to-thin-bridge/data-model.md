# Data Model: Trim To Thin Bridge

**Feature**: 006-trim-to-thin-bridge
**Date**: 2026-05-15

This document describes the entities and state transitions that survive the trim. Everything here is repo-local JSON / PowerShell-object state; there is no database.

---

## Entity 1: Handoff State (v1 shape)

**File**: `.specify/superpowers-handoff.json`
**Schema**: `specs/006-trim-to-thin-bridge/contracts/handoff.v1.schema.json`
**Writer**: `update-handoff.ps1`
**Readers**: `guard-command.ps1`, `auto-archive-handoff.ps1`, the bridge SKILL.md (via the agent loading it)

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `schema_version` | integer | yes | Always `1` post-trim. Older files may read `2` or `3`; readers must accept them. |
| `updated_at` | string (ISO 8601 UTC) | yes | Timestamp of last write. |
| `feature_directory` | string \| null | yes | `"specs/<NNN>-<slug>"` or `null` if no active handoff. |
| `source_of_truth` | object | yes | Contains four file paths. |
| `source_of_truth.constitution` | string | yes | Always `.specify/memory/constitution.md`. |
| `source_of_truth.spec` | string | yes | `<feature_directory>/spec.md`. |
| `source_of_truth.plan` | string | yes | `<feature_directory>/plan.md`. |
| `source_of_truth.tasks` | string | yes | `<feature_directory>/tasks.md`. |
| `supersedes` | string \| null | no | Last completed feature directory (for traceability). |
| `executor` | string | yes | `"superpowers"` while a handoff is active; `"speckit"` when status is `ready`. |
| `capabilities` | array of string | no | Optional list of Superpowers skills the executor will use. May be empty. |
| `status` | enum | yes | One of `ready` \| `executing` \| `complete` \| `blocked`. |
| `blocked_reason` | string \| null | when `status==blocked` | Why execution is paused. |
| `artifact_owner` | string | yes | `"codex"` or `"claude"` — who owns Spec Kit design-artifact writes. |
| `review_only_agents` | array of string | no | The agents that may read but not write Spec Kit artifacts. |
| `notes` | string | no | Free-form. |
| `last_snapshot_id` | string \| null | no | Pointer into `.specify/bridge-snapshots/`. |
| `instructions` | string | no | Optional human-readable next-step hint. |

### Fields dropped from v2/v3

- `archive_history` (v2): optional in v1; readers ignore; new writers do NOT emit.
- `autonomous_mode` (v3): readers ignore; new writers do NOT emit.
- `resume_context` (v3): readers ignore; new writers do NOT emit.

### Validation rules

- `schema_version` must be present and an integer; the schema permits `1..3` for backward read.
- `status` value must be one of the 4 enum values.
- When `status == "executing"`, `feature_directory` and `artifact_owner` MUST be non-null.
- When `status == "blocked"`, `blocked_reason` MUST be non-empty.
- When `status == "ready"`, `feature_directory` MAY be null (no active feature).

### State transitions

```text
                                   /speckit-specify
                                   (new feature begins)
                                            │
                                            ▼
  [ready] ────────── start ────────► [executing]
     ▲                                    │
     │ auto-archive                       │ complete
     │ (after new                         │
     │  /speckit-specify)                 ▼
     └────────────── reset ─────────  [complete]
                                            │
                                            │ block
                                            ▼
                                       [blocked]
                                            │
                                            │ resume (becomes executing again)
                                            └─────────────► [executing]
```

State transition triggers:

| From | To | Trigger | Performer |
|------|----|---------|-----------|
| (no file) | `ready` | First-ever write | `update-handoff.ps1 -Action start` with no prior file |
| `ready` | `executing` | After Spec Kit `tasks.md` exists and bridge is invoked | `update-handoff.ps1 -Action start -FeatureDirectory ...` |
| `executing` | `complete` | All tasks done + verification + review + branch-finish complete | `update-handoff.ps1 -Action complete` |
| `executing` | `blocked` | Implementer finds missing/wrong spec | `update-handoff.ps1 -Action block -BlockedReason ...` |
| `blocked` | `executing` | Spec is fixed; resuming | `update-handoff.ps1 -Action start` (resumes prior feature) |
| `complete` | `ready` | New `/speckit-specify` triggers auto-archive | `auto-archive-handoff.ps1` |

---

## Entity 2: Bridge Event (log entry)

**File**: `.specify/bridge-events.jsonl` (append-only)
**Writer**: `update-handoff.ps1` (handoff transitions), `guard-command.ps1` (guard decisions)
**Reader**: humans, audit scripts (none retained post-trim; future audits read by hand)

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `timestamp` | string (ISO 8601 UTC) | yes | When the event occurred. |
| `action` | enum | yes | One of `handoff` \| `guard` \| `archive`. (Drops the v2+ types `skill_invocation`, `parity_check`, `submission_check`, `auto_archive` — `archive` consolidates the last.) |
| `status` | string | yes | Action-specific. For `handoff`: matches the new handoff status. For `guard`: `allow` or `deny`. For `archive`: `archived`. |
| `feature_directory` | string \| null | yes | The feature this event pertains to. |
| `decision` | string \| null | no (yes for `guard`) | For guard events: `allow` / `deny`. |
| `reason` | string \| null | no | Free-form. |
| `actor` | string | yes | `"codex"` / `"claude"` / `"unknown"`. |
| `snapshot_id` | string \| null | no | If a snapshot was created/restored. |
| `checked_action` | string | no (yes for `guard`) | The Spec Kit / Superpowers command being checked. |

### Validation rules

- One JSON object per line; no comments; no trailing comma.
- File is append-only; the bridge MUST NOT rewrite or truncate prior lines.

### Event types removed by trim

- `skill_invocation` (custom event from feature 004): removed.
- `parity_check` (custom event from feature 002): removed.
- `submission_check` (custom event from feature 005): removed.
- `auto_archive` is renamed/consolidated to `archive` with `status: "archived"`.

---

## Entity 3: Cut Inventory

**File**: `specs/006-trim-to-thin-bridge/cut-inventory.md` (created during `/speckit-tasks` execution, not a runtime entity)
**Purpose**: Enumerate every removal so reviewers and future maintainers can audit completeness against FR-001..003, FR-011, FR-012.

### Fields (markdown table)

| Path | Type | Deleted In Commit | Reason |
|------|------|-------------------|--------|
| `.specify/extensions/.../scripts/powershell/parity-check.ps1` | script | commit 1 | custom feature beyond thin-bridge scope |
| ... | ... | ... | ... |

(Full enumeration filled in during implementation per `research.md` R9.)

### Validation rules

- Every path listed MUST be absent from the working tree at HEAD after the final commit.
- Every path listed MUST exist somewhere in `git log -- <path>` history.
- Total entries ≥ 28 (target count derived from R9 commit groups).

---

## Entity 4: Snapshot Directory

**Path**: `.specify/bridge-snapshots/<snapshot-id>/`
**Writer**: `update-handoff.ps1` (when taking pre-handoff snapshot of Spec Kit artifacts)
**Reader**: humans, manual `cp -r` for rollback. (`restore-snapshot.ps1` is REMOVED in this trim; rollback becomes manual.)

### Structure

```text
.specify/bridge-snapshots/<snapshot-id>/
├── constitution.md     # copy of .specify/memory/constitution.md
├── spec.md             # copy of specs/<feature>/spec.md
├── plan.md             # copy of specs/<feature>/plan.md
└── tasks.md            # copy of specs/<feature>/tasks.md
```

### Validation rules

- `<snapshot-id>` is a timestamp-based string: `YYYYMMDD-HHMMSS-<short-hash>`.
- Snapshots are write-once; once a snapshot directory exists it MUST NOT be modified.
- A handoff's `last_snapshot_id` field MUST reference an existing snapshot directory.

### Trim impact

- The pre-trim `restore-snapshot.ps1` automated copying back from a snapshot. Post-trim, this is a manual operation: `cp -r .specify/bridge-snapshots/<id>/* <appropriate-dest>/`.
- The constitution's Principle IV still requires that snapshots are taken; the trim does NOT remove the snapshot-taking step inside `update-handoff.ps1`.

---

## Relationships

```text
[Handoff State]
     │
     │ 1
     │  ├─── many ──► [Bridge Event] (handoff/guard/archive log)
     │  │
     │ 1 │
     ▼   ▼
[Snapshot Directory]
     ▲
     │ created by update-handoff.ps1 when transitioning ready → executing
     │ referenced by Handoff State.last_snapshot_id
```

- One handoff JSON exists at a time; events accumulate across all handoffs (append-only).
- Many snapshots may exist; the current handoff references the most recent one.
- The Cut Inventory is a one-shot design artifact, not a runtime entity.

---

## Schema files

The single contract written for this feature:

- `contracts/handoff.v1.schema.json` — JSON Schema for `superpowers-handoff.json` v1 shape (with `additionalProperties: true` for backward read).

No other schemas are introduced. Schemas removed from runtime:

- `.../contracts/plugin-distribution-manifest.schema.json` → DELETED (matrix is gone; manifest is gone).
- `specs/<n>/contracts/*.schema.json` historical copies → KEPT as record.
