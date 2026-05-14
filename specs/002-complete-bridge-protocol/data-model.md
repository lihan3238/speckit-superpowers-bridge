# Data Model: Complete Bridge Protocol

**Feature**: 002-complete-bridge-protocol
**Date**: 2026-05-15

The bridge's "data" is small and file-shaped: YAML config, JSON state, JSONL events.
Every entity below maps to either a file on disk, a record inside a file, or a
state transition the bridge enforces.

---

## Disposition Entry

Single record in the disposition matrix; one per Spec Kit command or Superpowers skill.

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string | yes | Canonical command/skill ID. Spec Kit IDs use dotted form (`speckit.plan`); Superpowers IDs use namespace form (`superpowers:brainstorming`). Globally unique within the matrix. |
| `kind` | enum: `spec_kit_command` \| `superpowers_skill` \| `bridge_meta_command` | yes | Categorizes the entry; the parity check uses this to drive enumeration against upstream surfaces. |
| `disposition` | enum: `COMBINE` \| `FORBID-UNDER-HANDOFF` \| `SUPERSEDED-BY` \| `REVIEW-ONLY` | yes | The decision; see FR-001. |
| `applicability` | array of enum: `executing` \| `blocked` \| `complete` | only for `FORBID-UNDER-HANDOFF` | Non-empty subset of handoff statuses that trigger the deny. See FR-002. |
| `superseded_by` | string (entry `id`) | only for `SUPERSEDED-BY` (optional advisory for other dispositions) | Pointer to the replacement entry. Parity check verifies the target exists. |
| `rationale` | string | yes | Human-readable one-liner; rendered in deny messages. See FR-002. |
| `verified_against` | string | yes | The `spec_kit_version` or Superpowers skill version this entry was verified against (matches `verified-versions.yml`). |

**Validation rules**:
- `applicability` MUST be present and non-empty if `disposition == FORBID-UNDER-HANDOFF`; MUST be absent otherwise.
- `superseded_by` MUST be present if `disposition == SUPERSEDED-BY`.
- Each `id` MUST appear at most once in the matrix.
- `rationale` MUST be non-empty.

**Relationships**:
- → `Disposition Matrix` (1: contained-in 1)
- → `Verified Versions Record` (via `verified_against`)
- → another `Disposition Entry` (via optional `superseded_by`)

---

## Disposition Matrix

Top-level container for all `Disposition Entry` records.

| Field | Type | Required | Notes |
|---|---|---|---|
| `schema_version` | integer | yes | Currently `1`. Bumped on incompatible structural change. |
| `entries` | array of `Disposition Entry` | yes | Order is not significant; loader sorts by `id` for diff readability. |
| `last_audited_at` | string (ISO 8601) | yes | When the matrix was last reviewed against upstream surface area. |

**Validation rules**:
- The set of `entries[].id` MUST cover every command in the `Verified Versions Record`'s Spec Kit surface and every skill in its Superpowers surface (no missing, no extras → parity-check failure).

**Storage**: `.specify/extensions/speckit-superpowers-bridge/disposition-matrix.yml`.

---

## Verified Versions Record

The version pin against which the matrix was verified.

| Field | Type | Required | Notes |
|---|---|---|---|
| `schema_version` | integer | yes | Currently `1`. |
| `spec_kit_version` | string (semver) | yes | E.g., `"0.8.9"`. |
| `superpowers_skills` | array of `{ name: string, version: string }` | yes | One entry per skill surfaced in the verified pack. `version` is upstream semver, or the literal string `"runtime-exposed"` for skills surfaced only via agent runtime. |
| `verified_at` | string (ISO 8601 UTC) | yes | Pin timestamp. |
| `verified_by` | string | yes | Free-text author identifier. |

**Validation rules**:
- `spec_kit_version` MUST be a parseable semver string.
- Every `superpowers_skills[].name` MUST appear in the disposition matrix (parity check enforces).

**Storage**: `.specify/extensions/speckit-superpowers-bridge/verified-versions.yml`.

---

## Bridge Handoff (existing entity, schema extended)

Top-level handoff state. Existing fields are retained; the only schema change is the
addition of an explicit terminal-not-active semantic for `status: complete`.

| Field | Type | Required | Notes |
|---|---|---|---|
| `schema_version` | integer | yes | Bumped to `2` (was `1`). |
| `updated_at` | string (ISO 8601) | yes | Existing. |
| `feature_directory` | string | yes (may be empty when `status == ready` and no feature is active) | Existing. |
| `source_of_truth` | object `{constitution, spec, plan, tasks}` | yes | Existing. |
| `supersedes` | array of string | yes | Existing. |
| `executor` | string | yes | Existing. |
| `capabilities` | array of string | yes | Existing. |
| `status` | enum: `ready` \| `executing` \| `blocked` \| `complete` | yes | Existing; semantics for `complete` clarified — see "State transitions" below. |
| `blocked_reason` | string \| null | yes | Existing. |
| `artifact_owner` | enum: `codex` \| `claude` \| `unknown` | yes | Existing. |
| `review_only_agents` | array of agent enum | yes | Existing. |
| `notes` | string \| null | yes | Existing. |
| `last_snapshot_id` | string \| null | yes | Existing. |
| `instructions` | string | yes | Existing. |
| `archive_history` | array of `{ feature_directory, status_at_archive, snapshot_id, archived_at, archived_by }` | yes | NEW: append-only audit trail of prior features' terminal states; one entry added on each `complete` → `ready` auto-archive. |

**State transitions** (the state machine extension):

```text
ready --(speckit.tasks runs and handoff created)--> executing
executing --(implementation finished + verification passed)--> complete
executing --(spec gap discovered)--> blocked
blocked --(repair done)--> executing
complete --(new feature begins via /speckit-specify)--> ready   [NEW, via auto-archive helper]
```

The `complete` → `ready` transition MUST be performed only by
`auto-archive-handoff.ps1`, MUST take a snapshot first, MUST append to
`archive_history`, and MUST clear `feature_directory`, `artifact_owner`,
`review_only_agents` so the next feature starts clean.

**Storage**: `.specify/superpowers-handoff.json`.

---

## Bridge Event (existing entity, new event types)

Existing JSONL log line shape preserved; one new `action` value added.

| Field | Type | Required | Notes |
|---|---|---|---|
| `timestamp` | string (ISO 8601 UTC) | yes | Existing. |
| `action` | string | yes | Existing values + NEW `auto_archive`. |
| `status` | string | yes | Existing. |
| `feature_directory` | string | yes | Existing. |
| `decision` | string | yes | Existing (`allow` / `deny` / `state_change` / `snapshot` / `restore` / `archive`). |
| `reason` | string | yes | Existing. |
| `snapshot_id` | string \| null | yes | Existing. |
| `artifact_owner` | string | yes | Existing. |
| `review_only_agents` | array | yes | Existing. |
| `actor` | string | yes | Existing. |
| `policy_ref` | string \| null | NEW (optional) | When a guard decision is driven by the disposition matrix, this field carries the matching entry `id` so reviewers can trace back. |

**Storage**: `.specify/bridge-events.jsonl` (append-only).

---

## Compatibility Gap Record (new entity)

A single record describing one observed compatibility gap from a live agent run.

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string (`CG-NNN`) | yes | Globally unique within the feature; sequential 3-digit. |
| `severity` | enum: `P0` \| `P1` \| `P2` \| `P3` | yes | P0 blocks any usage; P1 blocks the documented happy path; P2 is a workaround-with-pain; P3 is nice-to-have. |
| `description` | string | yes | One-paragraph factual description of the observed behavior. |
| `proposed_resolution` | string | yes | One-paragraph proposed fix. |
| `status` | enum: `OPEN` \| `CLOSED-IN-FEATURE` \| `DEFERRED` | yes | Lifecycle. |
| `closes_in_feature` | string \| null | yes | Feature directory ID (e.g. `002-complete-bridge-protocol`) that closes the gap; null for `DEFERRED`. |
| `related_requirements` | array of FR / SC IDs | yes | Backreferences to spec.md identifiers. |
| `observed_at` | string (ISO 8601) | yes | When the gap was first hit. |
| `observed_by_actor` | string | yes | Which agent ran into it. |

**Validation rules**:
- `closes_in_feature` MUST be non-null if `status == CLOSED-IN-FEATURE`.
- `proposed_resolution` MUST reference a concrete file/command/script — no vague "investigate" entries.

**Storage**: `specs/<feature>/compat-gaps.md` (a Markdown table per feature; the same shape across features).

---

## Parity Check Report (new entity)

The output of running `parity-check.ps1`. Not persisted by default; emitted to
stdout (as JSON when invoked with `-Json`) or to stderr (human-readable otherwise).

| Field | Type | Required | Notes |
|---|---|---|---|
| `schema_version` | integer | yes | Currently `1`. |
| `generated_at` | string (ISO 8601) | yes | Run timestamp. |
| `installed` | object `{ spec_kit_version, superpowers_skills: [{name, version}] }` | yes | Live install state. |
| `verified` | object (same shape) | yes | Pin from `verified-versions.yml`. |
| `findings` | array of `Finding` | yes | One entry per detected issue. |
| `summary` | object `{ total, by_severity: {P0, P1, P2, P3} }` | yes | Counts. |
| `exit_code` | integer | yes | `0` = all-pass, non-zero on any P0/P1 finding. |

Where `Finding` is:

| Field | Type | Required | Notes |
|---|---|---|---|
| `code` | enum: `missing_disposition` \| `missing_replacement` \| `missing_invocation_surface` \| `version_drift` \| `matrix_doc_inconsistency` | yes | Category. |
| `severity` | enum: `P0` \| `P1` \| `P2` \| `P3` | yes | Finding severity. |
| `target` | string | yes | The skill / command / file the finding refers to. |
| `agent` | enum: `codex` \| `claude` \| `both` \| `n/a` | yes | Scope of the finding. |
| `message` | string | yes | Human-readable detail. |
| `suggested_fix` | string | yes | Concrete proposed action. |

---

## Agent Invocation Surface (existing concept, formalized)

| Field | Type | Required | Notes |
|---|---|---|---|
| `command_id` | string | yes | E.g. `speckit.plan`. |
| `codex_surface` | string \| null | yes | E.g. `$speckit-plan`. |
| `claude_surface` | string \| null | yes | E.g. `/speckit-plan`. |
| `script_path` | string \| null | yes | If the surface delegates to a script (e.g. `.specify/scripts/powershell/...`). |
| `via_extension` | string \| null | yes | If the surface is provided by a Spec Kit extension (`speckit-superpowers-bridge` or `git`). |

Surfaces with `null` on either agent fail parity check (FR-007).

---

## Relationships Summary

```
Verified Versions Record  ◄── Disposition Entry.verified_against
Disposition Matrix        ──contains──► Disposition Entry
Disposition Entry         ──(optional)── superseded_by ──► Disposition Entry
Bridge Handoff            ──append──► Bridge Event (on every transition)
Bridge Handoff            ──contains──► archive_history[] (NEW)
Compatibility Gap Record  ──references──► FR/SC ids in spec.md
Parity Check Report       ──reads──► Disposition Matrix, Verified Versions Record, Agent Invocation Surfaces, .specify/extensions.yml
```
