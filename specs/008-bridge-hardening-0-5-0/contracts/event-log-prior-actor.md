# Contract: bridge-events.jsonl `prior_actor` field

**Owner**: `update-handoff.{ps1,sh}` (v0.5.0+).

**Consumers**: Auditors reading `.specify/bridge-events.jsonl`; the bridge SKILL.md and any tooling that reconstructs cycle ownership.

**Stability**: Field is additive and OPTIONAL for parsers. Adding fields is backward-compatible for any reasonable JSONL consumer.

## Contract

Each line in `.specify/bridge-events.jsonl` representing a handoff transition (`action: "handoff"`) MUST include the field `prior_actor` (sibling of the existing `actor` field) from v0.5.0 onward.

### Schema delta (handoff action only)

```json
{
  "timestamp": "2026-05-16T12:34:56.789Z",
  "action": "handoff",
  "status": "executing",
  "feature_directory": "specs/008-bridge-hardening-0-5-0",
  "decision": "updated",
  "reason": "actor change claude → codex; explicit Reason='midpoint transfer'",
  "actor": "codex",
  "prior_actor": "claude",
  "snapshot_id": "20260516T123456789Z-executing"
}
```

### Rules

- **R-EVT-1**: `prior_actor` MUST be present on every `action: "handoff"` event from v0.5.0+. Absent on events before the v0.5.0 cycle (we do NOT backfill historical lines).
- **R-EVT-2**: `prior_actor` is `null` (JSON null) when no prior `actor` value existed in handoff.json at the time of the call (e.g., the very first `update-handoff` after archive). It is a string when a prior value existed.
- **R-EVT-3**: Guard events (`action: "guard"`) do NOT include `prior_actor`. The field is meaningless for guard evaluations.
- **R-EVT-4**: Archive events (`action: "archive"`) MAY include `prior_actor` (carrying through from the immediately-preceding handoff line) but are not required to.
- **R-EVT-5**: When `actor` and `prior_actor` differ AND `prior_actor` is not null, the `reason` field on the same line MUST begin with or contain the substring `actor change <prior_actor> → <actor>`. If the operator passed an explicit `-Reason` argument, the actor-change note is **prepended** with a semicolon separator: `"actor change claude → codex; <operator-reason>"`. The operator's text is never silently overwritten.
- **R-EVT-6**: Existing readers (pre-v0.5.0 tooling) that ignore unknown JSON fields MUST continue to parse v0.5.0+ event lines without error. This is the backward-compat invariant.

### Compatibility verification

A trivial parse test against a fresh post-v0.5.0 `bridge-events.jsonl`:

```bash
jq '.action, .actor, .prior_actor' .specify/bridge-events.jsonl | head -30
```

Pre-v0.5.0 readers using `jq '.action'` continue to work. Readers using `jq '.prior_actor'` get `null` for legacy lines (handoff or otherwise) and the populated value for v0.5.0+ handoff lines.

## Acceptance scenarios

### S1. First-ever handoff (no prior)

**Given** fresh repo with no `superpowers-handoff.json`.

**When** `update-handoff -Status ready -FeatureDirectory specs/008-... -Actor claude` runs.

**Then** the emitted event line has `"actor": "claude"`, `"prior_actor": null`.

### S2. Same-actor continuation

**Given** existing handoff with `actor: "claude"`, status `ready`.

**When** `update-handoff -Status executing -Actor claude` runs.

**Then** the line has `"actor": "claude"`, `"prior_actor": "claude"`, `"reason": ""` (or whatever operator supplied — no actor-change prepend because they match).

### S3. Actor change

**Given** existing handoff with `actor: "claude"`, status `executing`.

**When** `update-handoff -Status executing -Actor codex -Reason "shift change"` runs.

**Then** the line has:
- `"actor": "codex"`
- `"prior_actor": "claude"`
- `"reason": "actor change claude → codex; shift change"`

### S4. Auto-archive (separate event line)

**Given** a complete handoff for feature 007.

**When** `update-handoff -Status ready -FeatureDirectory specs/008-... -Actor claude` runs, triggering the auto-archive of 007.

**Then** TWO event lines are appended:
1. An `action: "archive"` line referencing 007's snapshot.
2. An `action: "handoff"` line opening 008 with `prior_actor: null` (the auto-archive cleared the handoff before the new write).

### S5. Pre-v0.5.0 line co-existence

**Given** a `bridge-events.jsonl` that contains both pre-v0.5.0 and post-v0.5.0 lines.

**When** a consumer runs `jq -c '. | {action, actor, prior_actor}' bridge-events.jsonl`.

**Then** pre-v0.5.0 handoff lines emit `{ "action": "handoff", "actor": "<x>", "prior_actor": null }` (jq defaults missing fields to null); post-v0.5.0 handoff lines emit the populated `prior_actor`. The reader handles both uniformly.

## Constraints

- **C-EVT-1**: Field name is exactly `prior_actor` (snake_case to match existing fields `feature_directory`, `snapshot_id`).
- **C-EVT-2**: This is the SOLE structural change to `bridge-events.jsonl` in v0.5.0. No other fields are added, removed, renamed, or repurposed.
- **C-EVT-3**: Field never appears with a non-string non-null value. JSON validators may rely on `"prior_actor": string | null`.
