# Phase 1 Data Model: Bridge Status Command + SHA256 Handoff Artifact Hash

**Feature**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md) | **Research**: [research.md](./research.md) | **Date**: 2026-05-28

This file defines the four entities introduced by the feature and explicitly lists the files NOT changed (negative space, per the 011 precedent). The data model is deliberately small — the feature is mostly process and protocol, not data — but each entity has clear ownership and a precise schema so contracts can reference them by name.

## Entity 1 — `bridge-status` command

**Owner**: `.specify/extensions/speckit-superpowers-bridge/scripts/bash/bridge-status.sh` (canonical) + `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/bridge-status.ps1` (parity).

**Kind**: Platform-flavored helper script. Read-only.

**Inputs**:

| Flag (bash / PowerShell) | Type | Default | Purpose |
|---|---|---|---|
| `--json` / `-Json` | boolean | false | Emit single-line JSON object instead of human block |
| `--actor` / `-Actor` | string `claude\|codex\|human` | resolved via `common-actor-resolution` | Override actor for display (does not write event) |
| `--no-drift-check` / `-NoDriftCheck` | boolean | false | Skip drift comparison (faster; for callers that only want the recommendation) |

**Outputs**:

- Human mode (default): 7-line `[bridge state]` block per [contracts/bridge-status-output.md](./contracts/bridge-status-output.md). Stdout only.
- JSON mode: single-line JSON object per [contracts/bridge-status-output.md](./contracts/bridge-status-output.md) §JSON shape. Stdout only.
- Both modes: empty stderr in non-error states. Exit code 0, 2, or 3 per FR-004.

**Side effects**: ZERO. Does not write `superpowers-handoff.json`, does not append `bridge-events.jsonl`, does not modify any file. Verified by SC-003 (byte-identical idempotency) and FR-007 / FR-008 (no events).

**Dependencies**: `jq`, `sha256sum` (bash) / `Get-FileHash` (PowerShell), and the existing shared helpers `bridge-state.{sh,ps1}` + `common-actor-resolution.{sh,ps1}`. No new dependencies.

**Lifecycle / state**: stateless. Each invocation re-reads `superpowers-handoff.json` + `.specify/feature.json` + on-disk files; no caching.

---

## Entity 2 — `artifacts_sha256` field on handoff JSON

**Owner**: declared in [contracts/handoff-v1.1.delta.md](./contracts/handoff-v1.1.delta.md); added to the canonical [specs/006-trim-to-thin-bridge/contracts/handoff.v1.schema.json](../006-trim-to-thin-bridge/contracts/handoff.v1.schema.json) as an optional property.

**Kind**: New optional top-level JSON object on `.specify/superpowers-handoff.json`. Schema_version stays at 1 per [research D2](./research.md#d2--schema-evolution-additive-field-vs-version-bump).

**Shape** (illustrative, with comments):

```jsonc
{
  // ... existing v1 fields unchanged ...
  "artifacts_sha256": {
    "spec.md":  "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
    "plan.md":  "5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8",
    "tasks.md": null     // null means file did not exist at snapshot time
  }
}
```

**Rules**:

1. The key MUST be `artifacts_sha256` (lowercase, underscore-separated). Lowercase hex values, no `sha256:` prefix.
2. The object MUST have exactly three keys: `spec.md`, `plan.md`, `tasks.md` — matching the v1 schema's `source_of_truth` paths (excluding `constitution.md` per [spec Clarifications Q1](./spec.md#clarifications)).
3. Each value MUST be either a lowercase 64-character hex string (`/^[0-9a-f]{64}$/`) or the JSON literal `null` (file did not exist on disk at snapshot time).
4. The field is OPTIONAL on read (pre-0.7.0 handoffs lack it; readers treat missing-key as "no snapshot recorded").
5. The field is REQUIRED on write whenever status transitions to or stays at `executing` or `complete`.
6. The field MUST NOT appear on `ready` or `blocked` writes (clearing implicit; future reads will treat as "no snapshot").

**Lifecycle**:

| Transition | Action on `artifacts_sha256` |
|---|---|
| `ready → executing` | Compute fresh; write all three keys (file values or null) |
| `executing → executing` (e.g., actor switch) | Recompute fresh; overwrite |
| `executing → blocked` | Preserve from prior write (snapshot still valid for the next resumption) |
| `blocked → executing` | Recompute fresh; overwrite |
| `executing → complete` | Recompute; **compare against prior values**; if any differ, emit stderr warning + event; write fresh values |
| `complete → ready` (e.g., archive flow) | Remove the field (auto-archive helper or explicit `--clear`) |
| Any write with no prior `artifacts_sha256` | Treat prior values as "no snapshot"; no drift comparison possible; populate field anew |

**Validation**: schema delta is documented in [contracts/handoff-v1.1.delta.md](./contracts/handoff-v1.1.delta.md). The existing `additionalProperties: true` clause on the v1 schema permits the addition without a version bump.

---

## Entity 3 — Next-command decision table

**Owner**: [contracts/next-command-decision-table.md](./contracts/next-command-decision-table.md) is the canonical documentation. The decision logic is implemented inline in both flavors of `bridge-status` (per [research D3](./research.md#d3--decision-table-source-code-vs-data)).

**Kind**: Deterministic mapping from a state tuple to a single string recommendation.

**Input tuple**:

| Field | Type | Source |
|---|---|---|
| `has_handoff` | bool | `.specify/superpowers-handoff.json` exists and parses |
| `handoff_status` | enum `ready\|executing\|complete\|blocked\|null` | `.status` from handoff JSON; null when no handoff |
| `has_constitution` | bool | `.specify/memory/constitution.md` exists |
| `has_feature_dir` | bool | `feature_directory` value resolves to an existing directory |
| `has_spec` | bool | `<feature_dir>/spec.md` exists |
| `has_plan` | bool | `<feature_dir>/plan.md` exists |
| `has_tasks` | bool | `<feature_dir>/tasks.md` exists |
| `has_drift` | bool | derived from `artifacts_sha256` comparison; only relevant for tie-breaking warnings |

**Output**: a single recommendation string. Examples: `/speckit-constitution`, `/speckit-specify`, `/speckit-plan`, `/speckit-tasks`, `start handoff (update-handoff --status executing)`, `continue implementation via speckit-superpowers-bridge SKILL`, `auto-archive prior handoff or start new feature`, `clear handoff or restore feature directory`, `inspect .specify/superpowers-handoff.json`, `(none)`.

**Exhaustiveness invariant**: every reachable input tuple yields exactly one recommendation. Verified by the smoke test exhaustiveness check listed in [contracts/next-command-decision-table.md](./contracts/next-command-decision-table.md) §Test Vectors.

---

## Entity 4 — `artifact_drift_detected` event

**Owner**: `.specify/bridge-events.jsonl` (append-only, schema documented in [contracts/artifact-drift-event.md](./contracts/artifact-drift-event.md)).

**Kind**: New event type. Same line-per-JSON-object format as existing entries (`handoff`, `guard_allow`, `guard_deny`, `archive`).

**Shape**:

```json
{
  "event": "artifact_drift_detected",
  "timestamp": "2026-05-28T07:42:11Z",
  "actor": "claude",
  "feature_directory": "specs/012-bridge-status-and-hash",
  "drifted_artifacts": [
    {"path": "tasks.md", "old_sha256": "5e88...d8", "new_sha256": "9d4f...02"},
    {"path": "plan.md", "old_sha256": "7c3a...b1", "new_sha256": null}
  ]
}
```

**Rules**:

1. Emitted ONLY by `update-handoff` (FR-008). Never by `bridge-status` (FR-008 second sentence).
2. Emitted ONLY on `executing → complete` transitions where the prior handoff had `artifacts_sha256` AND at least one stored value differs from the freshly-computed value.
3. Exactly ONE event per offending `update-handoff` invocation (multiple drifted artifacts → ONE event with multiple entries in `drifted_artifacts`).
4. `drifted_artifacts[i].new_sha256` is `null` when the file no longer exists on disk (deletion drift, per spec Edge Cases).
5. `drifted_artifacts[i].old_sha256` is `null` when the snapshot recorded `null` AND the current file exists (creation drift — file was created between snapshot and complete; treated symmetrically to modification per spec Assumptions).
6. `drifted_artifacts` MUST list ONLY the artifacts that drifted; matching artifacts MUST NOT appear. The array is non-empty by definition (event only fires when drift exists).
7. Timestamp format: ISO-8601 UTC with `Z` suffix, matching existing event entries.

---

## Negative space — files NOT changed by this feature

Constitution Principle II + V + VI demand explicit byte-frozen lists for any feature touching the bridge surface. Per SC-005:

| Path | Reason byte-frozen |
|---|---|
| `.claude/skills/speckit-{analyze,checklist,clarify,constitution,implement,plan,specify,tasks,taskstoissues,git-*}/` | Vendor-managed; Principle II + Principle V |
| `.agents/skills/speckit-{analyze,checklist,clarify,constitution,implement,plan,specify,tasks,taskstoissues,git-*}/` | Vendor-managed; Principle II + Principle V |
| `.specify/extensions/speckit-superpowers-bridge/scripts/{bash,powershell}/guard-command.*` | 5 hardcoded guard rules; SC-005 + AGENTS.md "Guard rules" |
| `.specify/extensions/speckit-superpowers-bridge/scripts/{bash,powershell}/auto-archive-handoff.*` | Archive flow unchanged; SC-005 |
| `.specify/extensions/speckit-superpowers-bridge/scripts/{bash,powershell}/common-actor-resolution.*` | Actor resolution unchanged; SC-005 |
| `.specify/extensions.yml` | No new hooks introduced by this feature (FR-010 explicit) |
| `marketplace/catalog-entry.json.download_url` | Permanently decoupled to stable-alias per v0.6.0; FR-014 + Constitution §VI Q2 |
| `specs/006-trim-to-thin-bridge/contracts/handoff.v1.schema.json` `schema_version` integer range | Stays at 1..3; new field is additive (research D2) |
| Existing 12 smoke tests at `tests/test-*.sh` (except for unavoidable version-string updates) | SC-006 + SC-008 (no regression in 008 print contract) |

The only **modifiable** files in the bridge package per this feature:

| Path | Permitted change |
|---|---|
| `.specify/extensions/speckit-superpowers-bridge/scripts/bash/bridge-status.sh` | NEW file (≤ 200 lines per SC-010 a) |
| `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/bridge-status.ps1` | NEW file (≤ 200 lines per SC-010 b) |
| `.specify/extensions/speckit-superpowers-bridge/scripts/bash/update-handoff.sh` | ≤ 60 added lines per SC-010 c (hash snapshot + drift compare on writes) |
| `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/update-handoff.ps1` | ≤ 60 added lines per SC-010 d (parallel) |
| `.specify/extensions/speckit-superpowers-bridge/scripts/bash/bridge-state.sh` | Optional helper-arg addition for the new conditional print lines (D4) |
| `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/bridge-state.ps1` | Parallel |
| `.specify/extensions/speckit-superpowers-bridge/extension.yml` | Version 0.6.0 → 0.7.0 |
| `marketplace/catalog-entry.json` `version` field | 0.6.0 → 0.7.0; `download_url` unchanged |
| `CHANGELOG.md` | New `[0.7.0]` section per FR-014 |
| `README.md` | ≤ 13 added lines (FR-014; mention bridge-status in existing Skills/Commands section) |
| `README.zh-CN.md` | ≤ 12 added lines (FR-014; mirror) |
| `.claude/skills/speckit-superpowers-bridge/SKILL.md` | +1 line per FR-011 (project-owned, not vendor-managed) |
| `.agents/skills/speckit-superpowers-bridge/SKILL.md` | +1 line per FR-011 (project-owned, not vendor-managed) |
| `tests/test-bridge-status.sh` | NEW file (≤ 250 lines, fits < 10s suite budget) |
| `tests/fixtures/pre-070-handoff.json` | NEW fixture for SC-009 |
| `CLAUDE.md` `<!-- SPECKIT START -->` block | Plan-reference auto-updated by `/speckit-plan` |

Total additions: 4 new files (2 helpers + 1 test + 1 fixture). Total modifications: 8 existing files. All within Principle VI's lightness envelope.
