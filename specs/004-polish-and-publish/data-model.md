# Data Model: Polish & Publish

**Feature**: 004-polish-and-publish
**Date**: 2026-05-15

Entities introduced or extended by this feature. The bridge keeps everything file-shaped; no new databases or schemas beyond what's documented here.

---

## Bridge Handoff (existing entity, extended)

`schema_version` bumped from 2 to 3. Two field blocks added; everything else preserved.

| Field | Type | Required | Notes |
|---|---|---|---|
| `schema_version` | integer | yes | Bumped to `3`. |
| `autonomous_mode` | boolean | yes | NEW (default `false`). When `true`, the bridge proceeds through task boundaries without confirmation prompts, pausing only at the named review checkpoints. Env var `SPECKIT_BRIDGE_AUTONOMOUS=1` is an override but does NOT mutate this field. |
| `resume_context` | object \| null | yes | NEW. Persisted before each Superpowers skill invocation; cleared on `complete`/`ready` auto-archive. See **Resume Context** below. |
| _(all other fields from schema_version 2)_ | _(unchanged)_ | yes | `updated_at`, `feature_directory`, `source_of_truth`, `supersedes`, `executor`, `capabilities`, `status`, `blocked_reason`, `artifact_owner`, `review_only_agents`, `notes`, `last_snapshot_id`, `archive_history`, `instructions` |

**Validation rules**:
- `autonomous_mode` MUST be set on every write (even if `false`).
- `resume_context` MAY be `null` when no skill is in flight; MUST be a populated object during an active Superpowers invocation.

**Storage**: `.specify/superpowers-handoff.json` (unchanged path).

---

## Resume Context (new entity, sub-object of Bridge Handoff)

| Field | Type | Required | Notes |
|---|---|---|---|
| `current_task_id` | string \| null | yes | The task ID from `tasks.md` currently being worked (e.g. `T012`). |
| `current_skill` | string \| null | yes | The Superpowers skill ID currently invoked (e.g. `superpowers:test-driven-development`). |
| `current_phase` | string \| null | yes | The named lifecycle phase (e.g. `before-implementation-task`, `before-phase-completion`, `before-feature-completion`). |
| `next_expected_action` | string \| null | yes | A one-line human-readable description of the next thing the agent should do on resume (e.g. "write failing test for T012 then implement"). |
| `last_verification_command` | string \| null | no | The most recent command that verified state (e.g. `powershell.exe -File tests/test-bridge-guard.ps1`); used for "what did we last validate" context. |

**Validation rules**:
- If `current_skill` is non-null, `current_phase` MUST also be non-null.
- `next_expected_action` MUST be ≤ 200 characters to satisfy SC-004.

**Storage**: embedded inside `Bridge Handoff.resume_context`.

---

## Install-State Audit Report (new entity)

The output of `audit-install-state.ps1` (emitted on stdout when `-Json`).

| Field | Type | Required | Notes |
|---|---|---|---|
| `schema_version` | integer | yes | Currently `1`. |
| `generated_at` | string (ISO 8601) | yes | Run timestamp. |
| `spec_kit` | object `{version, default_integration}` | yes | Read from `.specify/integration.json`. |
| `integrations` | array of `{name, manifest_present}` | yes | Each installed agent integration. |
| `git_extension` | object `{installed: bool, version, commands: [...]}` | yes | Read from `.specify/extensions/git/extension.yml` if present. |
| `skills_parity` | object `{missing_on_claude: [...], missing_on_codex: [...], diverged: [...]}` | yes | Computed by enumerating `.agents/skills/` + `.claude/skills/` and SHA-256ing each `SKILL.md`. |
| `script_flavour` | enum: `ps` \| `sh` | yes | Read from `.specify/init-options.json.script`. |
| `findings` | array of `Finding` | yes | Same `Finding` shape as Parity Check Report (from feature 002 data-model). |
| `summary` | object `{total, by_severity: {P0,P1,P2,P3}}` | yes | Counts. |
| `exit_code` | integer | yes | `0` clean, `1` P0, `2` P1, `3` P2-in-strict-mode. |

**Storage**: not persisted; emitted to stdout.

---

## Skill Invocation Event (new entity, sub-type of Bridge Event)

A bridge event recording an explicit Superpowers skill invocation issued by the bridge.

| Field | Type | Required | Notes |
|---|---|---|---|
| `timestamp` | string (ISO 8601 UTC) | yes | Existing event-envelope field. |
| `action` | const: `"skill_invocation"` | yes | New value. |
| `status` | string | yes | Handoff status at invocation time. |
| `feature_directory` | string | yes | Existing. |
| `decision` | const: `"invoked"` \| `"failed"` | yes | `invoked` = pre-call log; if the invocation throws or returns non-zero, the bridge writes a second event with `decision: "failed"` and a `reason`. |
| `reason` | string \| null | yes | The phase name or error message. |
| `actor` | string | yes | Existing. |
| `snapshot_id` | string \| null | yes | Existing. |
| `skill_id` | string | yes | NEW. E.g. `superpowers:test-driven-development`. |
| `phase` | string | yes | NEW. Named lifecycle phase: `before-implementation-task`, `on-failure`, `before-phase-completion`, `before-feature-completion`. |
| `task_id` | string \| null | no | NEW (optional). Set when the invocation is tied to a specific task. |

**Validation rules**:
- `action` MUST equal `"skill_invocation"` for this event subtype.
- Two events MUST be emitted around any failed invocation: pre-call (`invoked`) and post-failure (`failed`).

**Storage**: appended to `.specify/bridge-events.jsonl` like every other event.

---

## Plugin Distribution Manifest (new entity)

YAML at `.specify/extensions/speckit-superpowers-bridge/plugin-distribution-manifest.yml`.

| Field | Type | Required | Notes |
|---|---|---|---|
| `schema_version` | integer | yes | Currently `1`. |
| `includes` | array of `{path: string, condition?: string}` | yes | Files/globs that get copied into a host project on install. `condition` is an optional human-readable note (e.g. "skip if host already has AGENTS.md"). |
| `excludes` | array of `{path: string, reason: string}` | yes | Globs that MUST NOT be copied. Each entry carries a `reason` for the exclusion. |
| `notes` | array of string | no | Free-form notes about conditional installs, merge semantics, etc. |

**Validation rules**:
- No path appears in both `includes` and `excludes`.
- Every `includes[].path` MUST exist in the source repo at audit time.
- The validator script `check-distribution-manifest.ps1` enforces both.

---

## Workflow Routing Recommendation (new entity, ephemeral)

The output of the `/speckit-superpowers-recommend-route` command (US5). Not persisted; printed to stdout / appended as a one-line bridge event.

| Field | Type | Required | Notes |
|---|---|---|---|
| `recommendation` | enum: `direct-superpowers` \| `full-pipeline` \| `no-recommendation` | yes | Result of the heuristic. |
| `reason` | string | yes | One-line explanation (e.g. "description is short and contains 'fix'; consider going direct to Superpowers"). |
| `description_length` | integer | yes | Computed length of the feature description. |
| `matched_keywords` | array of string | yes | Keywords from the small-scope heuristic that fired. |

---

## Relationships

```
Bridge Handoff (schema_v3)
  ├── archive_history[]            (from feature 002)
  ├── autonomous_mode  (NEW boolean)
  └── resume_context   (NEW; populated during active Superpowers invocations)

Bridge Event (append-only log)
  └── skill_invocation events (NEW subtype) ──referenced by──> validation pass (US3)

Install-State Audit Report  ──readable by──> validation pass (US3)
                            ──readable by──> parity-check.ps1 (FR-012 — divergence detection)

Plugin Distribution Manifest  ──governs──> marketplace install
                              ──validated by──> check-distribution-manifest.ps1

Workflow Routing Recommendation  ──advises──> user (never auto-actions; US5 P3)
```

---

## Schema files

- [contracts/skill-invocation-event.schema.json](contracts/skill-invocation-event.schema.json)
- [contracts/resume-context.schema.json](contracts/resume-context.schema.json)
- [contracts/plugin-distribution-manifest.schema.json](contracts/plugin-distribution-manifest.schema.json)
