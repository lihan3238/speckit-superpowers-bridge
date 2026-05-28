# Contract: `artifact_drift_detected` Event

**Owner**: `.specify/extensions/speckit-superpowers-bridge/scripts/{bash,powershell}/update-handoff.{sh,ps1}` (v0.7.0+). Emitted to `.specify/bridge-events.jsonl`.

**Consumers**: audit/grep tools, future bridge-status JSON consumers, the smoke test in `tests/test-bridge-status.sh`.

**Stability**: line shape is part of the published contract from v0.7.0 onward.

## Shape

One JSON object per line, identical line-format convention to the existing event types (`handoff`, `guard_allow`, `guard_deny`, `archive`).

```json
{"event":"artifact_drift_detected","timestamp":"2026-05-28T07:42:11Z","actor":"claude","feature_directory":"specs/012-bridge-status-and-hash","drifted_artifacts":[{"path":"tasks.md","old_sha256":"5e88...d8","new_sha256":"9d4f...02"}]}
```

Pretty-printed for clarity (the actual JSONL is single-line):

```jsonc
{
  "event": "artifact_drift_detected",
  "timestamp": "2026-05-28T07:42:11Z",
  "actor": "claude",
  "feature_directory": "specs/012-bridge-status-and-hash",
  "drifted_artifacts": [
    {
      "path": "tasks.md",
      "old_sha256": "5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8",
      "new_sha256": "9d4fab7f2f4b7a1a6cd6c5b3f0e1f0a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8"
    }
  ]
}
```

## Field rules

| Field | Type | Rule |
|---|---|---|
| `event` | string const | MUST be the exact literal `"artifact_drift_detected"`. |
| `timestamp` | string | ISO-8601 UTC, `Z` suffix. Matches existing event entries. |
| `actor` | string enum | `claude`, `codex`, or `human`. Resolved via `common-actor-resolution.{sh,ps1}` from the `--actor` CLI arg, the `SPECKIT_BRIDGE_ACTOR` env var, or default `unknown`. |
| `feature_directory` | string | Relative path from repo root, no trailing slash. Sourced from the handoff's `feature_directory` field at write time. MUST NOT be empty. |
| `drifted_artifacts` | array | Non-empty array of objects. MUST contain only the artifacts that drifted; matching artifacts MUST NOT appear. |
| `drifted_artifacts[i].path` | string | One of `spec.md`, `plan.md`, `tasks.md`. No path prefix. |
| `drifted_artifacts[i].old_sha256` | string-or-null | 64-char lowercase hex from the prior `artifacts_sha256` field, OR `null` if the prior snapshot stored null (file did not exist at snapshot time). |
| `drifted_artifacts[i].new_sha256` | string-or-null | 64-char lowercase hex of the current file contents, OR `null` if the file no longer exists at complete time. |

## Emission rules

- **R-EVT-1**: Emitted ONLY by `update-handoff` (FR-008). NEVER by `bridge-status`.
- **R-EVT-2**: Emitted ONLY on transitions `executing → complete`. NOT on `executing → blocked`, NOT on `executing → executing`, NOT on `complete → ready` (auto-archive flow).
- **R-EVT-3**: Emitted ONLY when the on-disk handoff being read had a non-empty `artifacts_sha256` AND at least one stored value differs from the freshly-computed value.
- **R-EVT-4**: Exactly ONE event per offending `update-handoff` invocation. Multiple drifted artifacts → ONE event with multiple entries in `drifted_artifacts`. The array preserves the canonical order `spec.md, plan.md, tasks.md` (only the drifted subset, in that relative order).
- **R-EVT-5**: The companion stderr warning line (per spec FR-006) is emitted in the SAME invocation, before the `[bridge state]` block. The warning format is: `[bridge] WARNING: artifact drift since executing snapshot: <comma-joined filenames> (sha256 mismatch)`.
- **R-EVT-6**: The `complete` write itself MUST complete successfully (exit code 0) even when drift is detected. The warning + event are advisory, not blocking. Per the spec, the user decides whether to abort or roll back.

## Append semantics

- **R-EVT-7**: The event line is appended to `.specify/bridge-events.jsonl` AFTER the corresponding `handoff` event for the `complete` transition. Order: `handoff` (success) → `artifact_drift_detected` (advisory). Both events share the same `timestamp` value (or differ by at most 1 second on slow filesystems).
- **R-EVT-8**: The event log is append-only per Constitution Principle IV. The script MUST NOT rewrite or truncate prior entries.

## Acceptance scenarios

### S-EVT-1. Single-artifact drift

**Given** a handoff with `artifacts_sha256.tasks.md = "5e88…d8"`, `artifacts_sha256.spec.md = "abc…12"`, `artifacts_sha256.plan.md = "def…34"`, and tasks.md is modified to have new hash `"9d4f…02"` (spec.md and plan.md unchanged).

**When** `update-handoff --status complete --actor claude` runs.

**Then** `.specify/bridge-events.jsonl` gains exactly two new lines: one `handoff` event for the complete transition, then one `artifact_drift_detected` event with `drifted_artifacts: [{"path":"tasks.md","old_sha256":"5e88…d8","new_sha256":"9d4f…02"}]`. Stderr contains exactly one line: `[bridge] WARNING: artifact drift since executing snapshot: tasks.md (sha256 mismatch)`. Stdout contains the `[bridge state]` block. Exit code 0.

### S-EVT-2. Multi-artifact drift

**Given** a handoff where both `tasks.md` AND `plan.md` differ from their snapshots (spec.md matches).

**When** `update-handoff --status complete --actor claude` runs.

**Then** exactly ONE `artifact_drift_detected` event is appended, with `drifted_artifacts` array of length 2 in order `[plan.md, tasks.md]` (canonical source-of-truth order, drifted subset only — note `plan` precedes `tasks`). The stderr warning line reads: `[bridge] WARNING: artifact drift since executing snapshot: plan.md, tasks.md (sha256 mismatch)`.

### S-EVT-3. File deleted between snapshot and complete

**Given** a handoff with `artifacts_sha256.tasks.md = "5e88…d8"` and tasks.md has been deleted (file no longer exists) before the complete write.

**When** `update-handoff --status complete --actor claude` runs.

**Then** the event's `drifted_artifacts: [{"path":"tasks.md","old_sha256":"5e88…d8","new_sha256":null}]`. The handoff's `artifacts_sha256.tasks.md` is overwritten to `null`. The stderr warning's filename rendering reads `tasks.md` (no special "deleted" suffix at the warning line; the JSON event carries the precise old/new values).

### S-EVT-4. File created between snapshot and complete

**Given** a handoff with `artifacts_sha256.tasks.md = null` (tasks.md did not exist at snapshot time) and tasks.md NOW exists with hash `"9d4f…02"`.

**When** `update-handoff --status complete --actor claude` runs.

**Then** the event's `drifted_artifacts: [{"path":"tasks.md","old_sha256":null,"new_sha256":"9d4f…02"}]`. This is treated as drift per spec Assumptions (creation drift). Warning fires.

### S-EVT-5. No drift

**Given** all three artifacts match their snapshots.

**When** `update-handoff --status complete --actor claude` runs.

**Then** NO `artifact_drift_detected` event is appended. Only the standard `handoff` event for the complete transition. Stderr is empty (no warning). Stdout block shows `Status: complete`.

### S-EVT-6. Pre-0.7.0 handoff (no artifacts_sha256)

**Given** a handoff document with `status: executing` and no `artifacts_sha256` field (e.g., written by v0.6.0).

**When** `update-handoff --status complete --actor claude` runs under v0.7.0.

**Then** NO `artifact_drift_detected` event is appended (no prior snapshot to compare against). Stderr is empty. The complete write populates `artifacts_sha256` with fresh values. Exit code 0.

## Smoke-test coverage

The `tests/test-bridge-status.sh` file MUST include at least these assertions (FR-008 + FR-012):

1. **Event-emission test**: drift induced → assert `.specify/bridge-events.jsonl` last line parses as JSON with `event == "artifact_drift_detected"`.
2. **Field-shape test**: drift induced → assert the event has all 5 fields (`event`, `timestamp`, `actor`, `feature_directory`, `drifted_artifacts`) and that `drifted_artifacts` is a non-empty array of well-formed objects.
3. **No-drift no-event test**: clean run (no drift) → assert no `artifact_drift_detected` line was appended in the most recent N event entries (where N = number of new entries since pre-test snapshot).
4. **Read-only test**: `bridge-status` invocation when drift exists → assert event log line count is unchanged before and after (FR-008 second sentence: bridge-status MUST NOT append events).
