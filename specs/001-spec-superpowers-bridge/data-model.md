# Data Model: Spec Kit Superpowers Bridge

## Bridge Handoff

Machine-readable state in `.specify/superpowers-handoff.json`.

**Fields**
- `schema_version`: integer schema version.
- `updated_at`: ISO-8601 timestamp.
- `feature_directory`: project-relative active feature directory, or null when none is active.
- `source_of_truth`: object with paths for `constitution`, `spec`, `plan`, and `tasks`.
- `supersedes`: list of Spec Kit flows replaced by the bridge, including `speckit.implement`.
- `executor`: implementation executor, currently `superpowers`.
- `capabilities`: allowed Superpowers execution-discipline skills.
- `status`: `ready`, `executing`, `blocked`, or `complete`.
- `blocked_reason`: nullable text explaining why implementation stopped.
- `artifact_owner`: nullable agent key that owns Spec Kit artifact writes, such as `codex` or `claude`.
- `review_only_agents`: list of agent keys that may read/review but not write Spec Kit artifacts.
- `notes`: human-readable instruction or state note.
- `last_snapshot_id`: nullable bridge snapshot id.
- `instructions`: pointer to the bridge skill and protocol rules.

**Validation Rules**
- `executor` must be `superpowers` for bridged features.
- `status` must be one of the allowed lifecycle values.
- `source_of_truth.spec`, `source_of_truth.plan`, and `source_of_truth.tasks` must point inside `feature_directory` when a feature is active and tasks exist.
- `artifact_owner` must be null or one installed agent key.
- `review_only_agents` must not include `artifact_owner`.

**State Transitions**
- `ready -> executing`: Superpowers implementation begins.
- `executing -> blocked`: implementation found a Spec Kit artifact problem.
- `blocked -> ready`: Spec Kit artifact repair completed.
- `executing -> complete`: all tasks and verification completed.
- `complete -> blocked`: maintainer reopens the feature for repair.

## Guard Decision

Logged allow/deny result for a command or skill request.

**Fields**
- `timestamp`: ISO-8601 timestamp.
- `action`: requested command or skill action, such as `speckit.plan` or `superpowers.writing-plans`.
- `status`: current handoff status.
- `feature_directory`: active feature directory.
- `decision`: `allow` or `deny`.
- `reason`: actionable explanation.
- `actor`: agent key or `unknown`.
- `snapshot_id`: latest snapshot id when relevant.

**Validation Rules**
- Every guard execution appends exactly one event.
- Denied decisions must include a reason.
- Spec Kit mutating actions must be denied when `actor` is not `artifact_owner`.

## Bridge Event

Append-only audit entry in `.specify/bridge-events.jsonl`.

**Actions**
- `handoff`
- `guard`
- `snapshot`
- `rollback`

**Validation Rules**
- Each line must be valid JSON.
- Events must not require rewriting prior log lines.

## Bridge Snapshot

Rollback point under `.specify/bridge-snapshots/<snapshot-id>/`.

**Captured Artifacts**
- Active feature `spec.md`
- Active feature `plan.md`
- Active feature `tasks.md`
- `.specify/superpowers-handoff.json`

**Validation Rules**
- Source files outside Spec Kit control artifacts are never copied or restored by bridge rollback.
- Snapshot id is timestamp-based and stable enough to pass to `restore-snapshot.ps1 -SnapshotId`.

## Agent Context File

Agent-readable project protocol file.

**Files**
- `AGENTS.md`: master bridge protocol for all agents.
- `CLAUDE.md`: Claude Code supplement that tells Claude Code to read `AGENTS.md` and gives Claude-specific invocation examples.

**Validation Rules**
- `AGENTS.md` must define ownership boundaries, denied skills, allowed execution skills, command syntax mapping, and single-writer policy.
- `CLAUDE.md` must not duplicate full bridge rules; it must reference `AGENTS.md` and include only Claude-specific supplement.
- If both files contain bridge rules, `AGENTS.md` wins on conflict.

## Integration Installation

Spec Kit integration state for a supported agent.

**Fields**
- `installed_integrations`: includes `codex` and/or `claude`.
- `default_integration`: single integration selected for generated shared references.
- integration manifests: vendor-managed file hashes under `.specify/integrations/*.manifest.json`.

**Validation Rules**
- Both `codex` and `claude` may be installed in either order.
- The bridge must not depend on `default_integration` to choose the feature contract.
- Official generated `speckit-*` skill files are not edited by the bridge.

## Bridge Skill

Local non-vendor skill that tells an agent how to execute Spec Kit `tasks.md` through Superpowers discipline.

**Files**
- `.agents/skills/speckit-superpowers-bridge/SKILL.md`
- `.claude/skills/speckit-superpowers-bridge/SKILL.md`

**Validation Rules**
- Both variants must load `.specify/superpowers-handoff.json`.
- Both variants must read `spec.md`, `plan.md`, and `tasks.md` before implementation.
- Both variants must deny `speckit.implement`, `superpowers:brainstorming`, and `superpowers:writing-plans` for active Spec Kit features unless the user explicitly discards Spec Kit artifacts.
