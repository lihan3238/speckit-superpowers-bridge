# Data Model: Bridge Cross-Platform Scripts

**Feature**: 003-bridge-cross-platform-scripts
**Date**: 2026-05-15

This feature does NOT introduce new runtime entities. It adds bash flavors of existing PowerShell scripts that operate on the **same** state machine, schemas, and on-disk files defined by feature 006. This document enumerates the entities each new bash script touches and pins the parity contract with the PS version.

---

## Entity 1: Handoff State (v1, unchanged)

**File**: `.specify/superpowers-handoff.json`
**Schema**: `specs/006-trim-to-thin-bridge/contracts/handoff.v1.schema.json`
**Writers**: `update-handoff.ps1`, `update-handoff.sh` (NEW)
**Readers**: `guard-command.ps1`, `guard-command.sh` (NEW), `auto-archive-handoff.ps1`, `auto-archive-handoff.sh` (NEW), and the bridge `SKILL.md` peers.

The schema is unchanged from feature 006. Both flavors emit the same v1 shape; both tolerantly read v2/v3 documents (unknown fields silently ignored).

### Parity contract

For identical inputs:

- Identical `schema_version` (always 1 in new writes).
- Identical `source_of_truth` object structure.
- Identical `status`, `executor`, `artifact_owner`, `review_only_agents`.
- Same enum values, same JSON types.

The ONLY tolerated differences:

- `updated_at`: distinct timestamps because invocations happen at different wall-clock moments.
- `last_snapshot_id`: distinct because the timestamp segment differs per invocation. Both follow the format described in research.md R2.

---

## Entity 2: Bridge Event (log line, unchanged)

**File**: `.specify/bridge-events.jsonl`
**Writers**: all four scripts in both flavors.

Same one-JSON-object-per-line format as feature 006 data-model §2. Same fields.

### Parity contract

Bash writers MUST emit the same field set: `timestamp`, `action`, `status`, `feature_directory`, `decision`, `reason`, `actor`, `snapshot_id` (and for guard: `checked_action`). Field ORDER may differ (JSON is unordered, but jq output is order-stable per query); consumers don't depend on order.

UTF-8 bytes, LF line terminator, no trailing whitespace. Bash naturally produces this via `printf '%s\n'`.

---

## Entity 3: Snapshot Directory (unchanged)

**Path**: `.specify/bridge-snapshots/<snapshot-id>/`
**Writers**: `update-handoff.ps1`, `update-handoff.sh` (NEW)

Same directory layout as feature 006 data-model §4: `constitution.md`, `spec.md`, `plan.md`, `tasks.md` copied from the source feature directory.

### Parity contract

- Same source files copied.
- Same destination filenames.
- Same `<snapshot-id>` format (per research.md R2: `yyyymmddThhmmssfffZ-<status>` for bash, `yyyymmddThhmmssfffffffZ-<status>` for PS — both sortable, both unique).

---

## Entity 4: `extension.yml.requires.tools` (modified shape)

**File**: `.specify/extensions/speckit-superpowers-bridge/extension.yml`
**Modifier**: hand-edit during commit 6 of this feature.

The `requires.tools` array changes from the v0.3.x baseline (PowerShell + git, both informal) to the explicit 4-tool list from research.md R12.

### Validation

- The catalog accepts the shape (verified live against `agent-governance` and `azure-devops`).
- The `validate-release-readiness.ps1` validator does NOT currently introspect this field; the field is informational for the catalog and the README.

---

## Entity 5: `.gitattributes` (NEW)

**Path**: `<repo-root>/.gitattributes`
**Owner**: this feature.

A new repo-root file controlling how git treats certain file extensions on checkout/clone. Content per research.md R8.

### Validation

The release validator checks this file exists and contains the `*.sh text eol=lf` line (FR-012). The check is added by this feature.

---

## Entity 6: Cross-Flavor Test Helper (NEW, inline)

**Location**: Defined inline inside `tests/test-handoff-shape.ps1` and `tests/test-guard-hardcoded-rules.ps1`.

A 6-line `Get-AvailableFlavors` function that returns an array of flavor strings (`"ps"` and/or `"bash"`) based on which `scripts/<flavor>/` directories exist under the bridge.

### Behavior

```text
Inputs:  BridgeRoot path
Outputs: array of "ps" | "bash"

Rules:
  if scripts/powershell exists  → "ps" in output
  if scripts/bash exists        → "bash" in output
  if neither                    → empty array (test should fail with clear msg)
```

The function is NOT exported, NOT shared between tests — duplicated by design (research.md R10) so each test stays self-contained.

---

## Relationships

```text
[Handoff State] ◄────────── written by ─── update-handoff.{ps1,sh}
       │                                          │
       │ status read                              │ before write
       ▼                                          ▼
[Bridge Event log] ◄── append by all 4 scripts (both flavors)
       │
       │
       ▼
[Snapshot Directory] ◄── created by update-handoff.{ps1,sh} before status change
```

Same relationships as feature 006 data-model. Bash flavor inserts itself as an additional writer of every node — no structural change.

---

## Schemas

No new JSON schemas. The v1 handoff schema from feature 006 (`specs/006-trim-to-thin-bridge/contracts/handoff.v1.schema.json`) is the authoritative contract both flavors implement.

A new **CLI parity contract** is documented in `contracts/bash-cli-contract.md` (per Phase 1 deliverable below) — it's a markdown table mapping each PS parameter name to its bash long-flag equivalent, with exit-code parity assertions.

---

## State transitions

Unchanged from feature 006 data-model §1 (handoff state machine: ready → executing → complete | blocked; auto-archive complete → ready). Bash scripts implement the same transitions via the same parameter set (with `--` instead of `-` prefix).
