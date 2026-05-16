# Data Model: Bridge Hardening & 0.5.0 Cleanup

**Phase 1 output for** [plan.md](./plan.md). Captures the entities, attributes, validation rules, and state transitions introduced by v0.5.0. Nothing here defines new persisted JSON schemas — most entities are either *computed at runtime* or *additive fields in append-only logs*.

## Entities

### 1. State Summary Block (printed; not persisted)

**What it represents**: A human-readable snapshot of the bridge's current handoff state, printed by `update-handoff.{ps1,sh}` and `guard-command.{ps1,sh}` on every successful invocation. The substrate that surfaces drift between handoff.json and tasks.md.

**Source of truth**: Computed live from:
- `.specify/superpowers-handoff.json` (current state after the operation completes).
- `<feature_directory>/tasks.md` (read fresh on every print).

**Lifecycle**: Ephemeral. Printed to stdout once per script invocation. Never stored.

**Field contract**:

| Field | Type | Notes |
|---|---|---|
| `feature_directory` | string (path) | From `superpowers-handoff.json.feature_directory`. May be empty if no active handoff. |
| `status` | enum | `ready | executing | complete | blocked` per existing handoff schema. |
| `artifact_owner` | string | Resolved per the 4-step actor chain (explicit arg → prior handoff value → resolved actor → `unknown`). |
| `actor` | string | The actor for THIS invocation (new actor). |
| `prior_actor` | string \| absent | The actor value present in `superpowers-handoff.json` immediately before this call. Omitted from the printed line if equal to `actor` (reduces noise). |
| `pending_tasks` | integer ≥ 0 \| `(no tasks.md)` | Count of `^- \[ \] T\d+` lines NOT under a deferred-exemption section header (per FR-005). Special sentinel `(no tasks.md)` if `<feature_directory>/tasks.md` does not exist. |

**Validation rules**:
- VR-1: `feature_directory` MUST be the value read from handoff after the write (R1).
- VR-2: `pending_tasks` MUST use the canonical regex `^- \[ \] T\d+` per FR-001 / Clarifications Q4.
- VR-3: Header-exemption logic MUST use the FR-005 regex (R2) with case-insensitive matching.
- VR-4: When `actor != prior_actor`, both MUST appear in the printed line (e.g., `Actor: claude → codex`).

**Printed format contract**: See [contracts/bridge-state-summary.md](./contracts/bridge-state-summary.md).

### 2. Prior Actor (event log additive field)

**What it represents**: The `actor` value present in `superpowers-handoff.json` immediately before the current `update-handoff` invocation. Persists in the JSONL audit trail so any later auditor can reconstruct handoff ownership lineage without snapshot diffing.

**Source of truth**: Read from `superpowers-handoff.json` at the start of `update-handoff` execution (BEFORE the write), captured in memory, then emitted to the event log alongside the `actor` field after the write succeeds.

**Lifecycle**: Append-only. Written once per handoff transition, never modified.

**Schema location**: `.specify/bridge-events.jsonl` (existing file, additive field).

**Field contract**:

| Field | Type | Notes |
|---|---|---|
| `prior_actor` | string \| null | `null` when no prior handoff existed (e.g., first `update-handoff` call after archive). |

**Validation rules**:
- VR-5: `prior_actor` MUST be present on every handoff-transition event (`action: "handoff"`); guard events do NOT carry `prior_actor`.
- VR-6: When `actor != prior_actor` AND `prior_actor != null`, the entry's `reason` field MUST also reflect the change (e.g., `"reason": "actor change claude → codex"`). When the operator supplies an explicit `-Reason`, the prepended actor-change note is appended to the operator's reason; we do not silently overwrite operator intent.
- VR-7: Backwards compatibility — existing event-log readers MUST continue to parse the line: `prior_actor` is purely additive (JSON, ignored by consumers that don't know it).

**Schema delta diagram**:

```text
Before v0.5.0:
{ "timestamp", "action", "status", "feature_directory", "decision", "reason", "actor", ... }

After v0.5.0 (handoff action only):
{ ..., "actor", "prior_actor", "reason", ... }
                ^^^^^^^^^^^^^
                NEW: nullable string
```

See [contracts/event-log-prior-actor.md](./contracts/event-log-prior-actor.md).

### 3. Gate Evidence Record

**What it represents**: A frozen-in-time record of computed gate values (SC-005 byte-freeze diff, SC-006 spec-history checksum) at the moment a release cycle hits `complete`. Same audit-trail philosophy as the existing PASS/PENDING rows in `verification.md`.

**Source of truth**: Computed at the moment of the cycle's completion by the operator (or a script the operator runs).

**Lifecycle**: Append-only. One subsection per release cycle. Older subsections are NEVER edited retroactively (constitution-grade audit hygiene).

**Schema location**: `## Gate evidence` H2 subsection inside `<feature_directory>/verification.md`. For v0.5.0 the location is `specs/008-bridge-hardening-0-5-0/verification.md`. The same shape is applied retroactively to `specs/007-catalog-distribution-polish/verification.md` for the 007 cycle (FR-008).

**Field contract** (see [research.md R8](./research.md) for full markdown form):

| Field | Type | Notes |
|---|---|---|
| `gate_id` | string | E.g., `SC-005`, `SC-006`. Matches a Success Criterion ID in the source spec. |
| `computed_value` | string | Free-form: "0 lines diff" or a hex SHA. Length ≤ 100 chars. |
| `command` | string \| absent | The exact shell command that produced the value, for reproducibility. Optional but strongly recommended. |
| `date` | string (YYYY-MM-DD) | UTC date of computation. |
| `operator` | string | Same vocabulary as the existing PASS rows (`claude`, `codex`, `human`). |

**Validation rules**:
- VR-8: One row per gate per release cycle.
- VR-9: Gate IDs MUST reference SCs that exist in the same release's spec; orphan gate records (no matching SC) are an audit defect.
- VR-10: For SC-005 the `computed_value` MUST be machine-parseable (a line count, integer or "0 lines diff").
- VR-11: For SC-006 the `computed_value` MUST be a 64-char hex SHA-256.

### 4. Compatibility Baseline Declaration

**What it represents**: A single named version that is the lowest version users can directly upgrade FROM, captured in CHANGELOG `[0.5.0] § Compatibility`. Reduces support-matrix tail.

**Source of truth**: A line in `CHANGELOG.md` under the `[0.5.0]` section.

**Lifecycle**: Written once per release that resets the baseline. Subsequent releases inherit the baseline until another reset is announced. v0.5.0 is the first reset (declares v0.4.2 as the new floor).

**Schema location**: `CHANGELOG.md` `[0.5.0]` section, subsection `### Compatibility`.

**Field contract** (free-form text, but MUST contain the structured triple):

| Field | Type | Notes |
|---|---|---|
| `min_direct_upgrade_from` | string | Version, e.g., `0.4.2`. |
| `schema_status` | enum (`byte-stable` / `breaking`) | Whether the handoff schema changed since the prior baseline. v0.5.0 = byte-stable. |
| `older_version_advice` | string | Free-form instruction, e.g., "v0.4.0/v0.4.1 users upgrade through v0.4.2 first, or re-install fresh". |

**Validation rules**:
- VR-12: Future spec/AGENTS.md edits MUST reference `min_direct_upgrade_from` when discussing compat — no "we support v0.x.y and up" hand-waving.
- VR-13: When `schema_status: byte-stable`, the spec's SC-013 north-star (no new commands/skills) MUST also hold for this release.

### 5. Catalog-Update Policy Statement

**What it represents**: A documented decision on when (which version bump magnitudes) we file an upstream catalog-update issue against `github/spec-kit`.

**Source of truth**: `marketplace/README.md`. Updated as policy evolves; current statement dates 2026-05-16.

**Lifecycle**: Mostly static. Updated only when upstream's documented method changes or when our own policy stance changes.

**Schema location**: `marketplace/README.md`, with the citation URL inline.

**Field contract** (prose form, see [contracts/catalog-update-policy.md](./contracts/catalog-update-policy.md) for the exact wording template):

| Field | Type | Notes |
|---|---|---|
| `upstream_citation` | URL + section anchor | Required. Dated. |
| `policy_summary` | string | E.g., "Minor/major bumps file a fresh Extension Submission issue; patch bumps skip (users get the latest via stable-alias URL)." |
| `policy_basis` | string | Reference to the Clarifications Q5 decision. |

**Validation rules**:
- VR-14: `upstream_citation` MUST be a permalink (commit SHA or tag-pinned URL), NOT a `blob/main` URL that can shift.

## Relationships

- **State Summary** depends on **handoff.json** (read) AND tasks.md (scan); writes nothing.
- **Prior Actor** is read from **handoff.json** at the start of `update-handoff`, written to **bridge-events.jsonl** at end.
- **Gate Evidence** depends on **git history** + `.specify/extensions/.../scripts/` (for SC-005) + earlier-release tag refs (for SC-006).
- **Compat Baseline** depends on the **handoff.json schema-version** history; it asserts compatibility by reference, not by re-verification.
- **Catalog Policy** depends on the **upstream `github/spec-kit`** doc state at a fixed date.

## State Transitions

### `update-handoff` operation (PowerShell + bash, identical surface)

```text
read handoff.json (capture prior_actor) ──┐
                                          │
parse args (Status, Actor, ...) ──────────┤
                                          │
resolve actor via 4-step chain ───────────┤
                                          │
[guard: if status='executing' and       ──┤
 attempting to write 'complete' on a       │
 different feature, deny]                  │
                                          │
write handoff.json (atomic)             ──┤
                                          │
append snapshot to bridge-snapshots/    ──┤
                                          │
append event to bridge-events.jsonl    ───┼─── includes prior_actor + actor + reason
 ↓                                        │
compute pending_tasks (R3/R4)          ───┤
                                          │
[FR-003 check: if status=='complete'    ──┤
 AND pending_tasks > 0:                   │
   write WARNING line to stderr]          │
                                          │
print state summary block (stdout)      ──┘
```

### `guard-command` operation (PowerShell + bash)

```text
read handoff.json (no mutation) ──────────┐
                                          │
evaluate 5 hardcoded rules (existing) ──┐ │
 ↓                                      │ │
write event to bridge-events.jsonl    ──┤ │
 ↓                                      │ │
print [bridge state] summary (stdout)  ─┴─┴── always; includes pending_tasks
 ↓
print Guard allowed/denied <action> ────── (existing output, retained)
 ↓
exit 0 (allow) or non-zero (deny)
```

Guard does not mutate handoff; it does not invoke FR-003 warning (only `update-handoff` does).

## Backward compatibility

All entity additions are either ephemeral (printed lines), additive (event log JSON field), or new files (`verification.md` for 008). No existing handoff JSON or event-log JSON consumers should break.

Detection: `tests/test-handoff-shape.ps1` continues to pass unchanged. New `tests/test-bridge-state-summary.ps1` covers the new contracts. `tests/test-guard-hardcoded-rules.ps1` continues to pass with the addition of one assertion confirming the state-summary block is now printed on each guard call.
