# Spec Kit + Superpowers Bridge Parameter Reference

This document defines the user-facing parameters for the bridge PowerShell scripts. The bridge is intentionally small: Spec Kit remains the source of truth for governance and design artifacts, while Superpowers executes `tasks.md`.

## Constitution In The Flow

`constitution.md` is part of this protocol.

- File: `.specify/memory/constitution.md`
- Owner: Spec Kit
- Role: project-level governance, non-negotiable principles, quality gates, and artifact policy
- When to run: at project setup, and again only when governance changes
- Command surface: Codex uses `$speckit-constitution`; Claude Code uses `/speckit-constitution`

Typical order:

```text
$speckit-constitution
$speckit-specify "Describe the feature"
$speckit-clarify
$speckit-checklist
$speckit-plan
$speckit-tasks
$speckit-analyze
$speckit-superpowers-bridge
```

The bridge handoff records constitution as `source_of_truth.constitution`, and the bridge skill reads it before implementation. Superpowers does not replace constitution. If implementation reveals a governance conflict, mark the handoff `blocked`, revise through Spec Kit, then resume.

## Actor Resolution

Scripts that accept `-Actor` resolve the actor in this order:

1. Explicit `-Actor`
2. `SPECKIT_BRIDGE_ACTOR`
3. `.specify/integration.json.default_integration`
4. `unknown`

Use `-Actor codex` from Codex and `-Actor claude` from Claude Code when the caller is known. This keeps `artifact_owner`, event logs, and review-only behavior deterministic.

## update-handoff.ps1

Path:

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1
```

Purpose: create or update `.specify/superpowers-handoff.json`, snapshot Spec Kit control artifacts, and append bridge events.

| Parameter | Type | Values | Default | Use |
|---|---|---|---|---|
| `-Status` | string | `ready`, `executing`, `blocked`, `complete` | `ready` | Handoff state transition. |
| `-FeatureDirectory` | string | repo-relative or absolute path | active `.specify/feature.json` | Feature directory containing `spec.md`, `plan.md`, `tasks.md`. |
| `-Reason` | string | any short text | empty | Reason for blocked state or audit context. |
| `-ArtifactOwner` | string | `codex`, `claude`, `unknown` | resolved actor/default integration | Agent allowed to write Spec Kit artifacts for this feature. |
| `-ReviewOnlyAgents` | string[] | `codex`, `claude`, `unknown` | other installed agents | Agents that may review but not write Spec Kit artifacts. |
| `-Actor` | string | usually `codex` or `claude` | resolved | Caller recorded in logs and ownership defaults. |
| `-AutonomousMode` | bool-like object | `$true`, `$false` | preserve existing, initial false | Persist autonomous execution preference. |
| `-ResumeContext` | JSON string or object | resume context object | preserve existing unless ready/complete | Persist current task/skill/phase for deterministic resume. |
| `-ClearFeatureDirectory` | switch | present/absent | absent | Clear active feature during auto-archive. |
| `-AppendArchiveEntry` | object | archive entry | null | Internal auto-archive support. |

Examples:

```powershell
# Standard handoff after tasks.md exists
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status ready -Actor codex

# Start execution
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status executing -Actor codex

# Stop implementation and return to Spec Kit repair
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status blocked -Reason "Plan needs revision" -Actor codex

# Complete after tasks and validation pass
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status complete -Actor codex
```

## Autonomous Mode

`-AutonomousMode $true` sets `autonomous_mode: true` in `.specify/superpowers-handoff.json`.

What changes:

- The bridge may continue across implementation task boundaries without asking for confirmation.
- It still reads Spec Kit artifacts first.
- It still follows the denylist: no `speckit.implement`, no Superpowers `brainstorming`, no Superpowers `writing-plans` for active Spec Kit artifacts.
- It still pauses at named review/checkpoint phases:
  - `superpowers:verification-before-completion`
  - `superpowers:requesting-code-review`
  - `superpowers:finishing-a-development-branch`
- It still stops and marks `blocked` if the Spec Kit contract is missing, wrong, or contradictory.

What does not change:

- It does not change requirements.
- It does not auto-rewrite `spec.md`, `plan.md`, or `tasks.md`.
- It does not bypass tests or verification.
- It does not merge, push, or discard branches without an explicit user decision.

Use it for long task lists where the implementation contract is stable. Avoid it when requirements are still fluid, the feature is high risk, or you want manual review after every task.

Runtime override:

```powershell
$env:SPECKIT_BRIDGE_AUTONOMOUS = "1"
```

The env var is an execution-time override. Persisted handoff state remains controlled by `-AutonomousMode`.

## Resume Context

`resume_context` captures the in-flight Superpowers step so an interrupted session can resume with a short signal.

Shape:

```json
{
  "current_task_id": "T042",
  "current_skill": "superpowers:test-driven-development",
  "current_phase": "before-implementation-task",
  "next_expected_action": "write failing test for T042",
  "last_verification_command": null
}
```

Valid phases:

- `before-implementation-task`
- `on-failure`
- `before-phase-completion`
- `before-feature-completion`
- `other`

Example:

```powershell
$resume = @{
  current_task_id = "T042"
  current_skill = "superpowers:test-driven-development"
  current_phase = "before-implementation-task"
  next_expected_action = "write failing test for T042"
} | ConvertTo-Json -Compress

.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status executing -ResumeContext $resume -Actor codex
```

`resume_context` is cleared automatically when status becomes `ready` or `complete`, or when the feature directory is cleared during auto-archive.

## guard-command.ps1

Purpose: enforce the non-overlap policy before running Spec Kit or Superpowers commands.

| Parameter | Type | Values | Default | Use |
|---|---|---|---|---|
| `-Action` | string | e.g. `speckit.implement`, `superpowers.writing-plans` | required | Command or skill to check. `:` and `.` are normalized. |
| `-AllowDiscardSpecArtifacts` | switch | present/absent | absent | Allows `brainstorming`/`writing-plans` only after explicit user approval to discard Spec Kit artifacts. |
| `-Reason` | string | any short text | empty | Adds context to deny logs. |
| `-Actor` | string | `codex`, `claude`, `unknown` | resolved | Caller. |
| `-TargetFeatureDirectory` | string | repo-relative path | active feature | Distinguishes same-feature from cross-feature checks. |

Examples:

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\guard-command.ps1 -Action speckit.implement -Actor codex
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\guard-command.ps1 -Action superpowers.executing-plans -Actor codex
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\guard-command.ps1 -Action speckit.plan -TargetFeatureDirectory specs/005-next-feature -Actor claude
```

## emit-skill-invocation.ps1

Purpose: append a `skill_invocation` event before a Superpowers skill is used.

| Parameter | Type | Values | Default | Use |
|---|---|---|---|---|
| `-SkillId` | string | `superpowers:<skill-name>` | required | Superpowers skill being invoked. |
| `-Phase` | string | listed phases | required | Lifecycle phase. |
| `-TaskId` | string | `T###` | empty | Task ID when invocation belongs to a task. |
| `-Actor` | string | `codex`, `claude`, `unknown` | resolved | Caller. |
| `-Decision` | string | `invoked`, `failed` | `invoked` | Whether the skill invocation happened or failed. |
| `-Reason` | string | any short text | phase | Human-readable reason. |

Example:

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\emit-skill-invocation.ps1 `
  -SkillId superpowers:test-driven-development `
  -Phase before-implementation-task `
  -TaskId T042 `
  -Actor codex `
  -Decision invoked `
  -Reason "Start implementation task"
```

## emit-resume-signal.ps1

Purpose: read `resume_context` and print one concise resume line.

Parameters: none.

Example:

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\emit-resume-signal.ps1
```

Expected output when context exists:

```text
Resuming T042 via superpowers:test-driven-development (phase: before-implementation-task) - next: write failing test for T042
```

## auto-archive-handoff.ps1

Purpose: archive a prior `complete` handoff so a new feature can start cleanly.

| Parameter | Type | Values | Default | Use |
|---|---|---|---|---|
| `-Actor` | string | `codex`, `claude`, `unknown` | resolved | Caller. |
| `-Reason` | string | any short text | auto-archive reason | Event reason. |

Behavior:

- If current handoff is not `complete`, exits successfully without changes.
- If current handoff is `complete`, snapshots prior artifacts, appends `archive_history`, clears `feature_directory`, and writes an `auto_archive` event.

## restore-snapshot.ps1

Purpose: restore Spec Kit control artifacts from `.specify/bridge-snapshots/<snapshot-id>/`.

| Parameter | Type | Values | Default | Use |
|---|---|---|---|---|
| `-SnapshotId` | string | snapshot directory name | required | Snapshot to restore. |
| `-Actor` | string | `codex`, `claude`, `unknown` | resolved | Caller. |

Only Spec Kit control artifacts are restored. Implementation source rollback remains Git/worktree responsibility.

## validation-pass.ps1

Purpose: run the bridge end-to-end validation pass and emit validation events.

| Parameter | Type | Values | Default | Use |
|---|---|---|---|---|
| `-Json` | switch | present/absent | absent | Machine-readable report. |
| `-Strict` | switch | present/absent | absent | Treat P2 findings as non-zero. |
| `-Actor` | string | `codex`, `claude`, `unknown` | resolved | Caller. |
| `-FeatureDirectory` | string | repo-relative path | handoff/feature.json | Feature to validate. |

Exit codes:

- `0`: no P0/P1 findings
- `1`: P0 finding exists
- `2`: P1 finding exists
- `3`: P2 finding exists and `-Strict` was used

## audit-install-state.ps1

Purpose: audit local install state, integration state, generated skills, and Codex/Claude parity.

| Parameter | Type | Values | Default | Use |
|---|---|---|---|---|
| `-Json` | switch | present/absent | absent | Machine-readable report. |
| `-Strict` | switch | present/absent | absent | Treat P2 findings as non-zero. |
| `-Actor` | string | `codex`, `claude`, `unknown` | resolved | Caller. |

Use after install, after Spec Kit integration upgrades, and before marketplace submission.

## parity-check.ps1

Purpose: verify disposition matrix coverage, verified version records, command/skill parity, and doc consistency.

| Parameter | Type | Values | Default | Use |
|---|---|---|---|---|
| `-Json` | switch | present/absent | absent | Machine-readable report. |
| `-Strict` | switch | present/absent | absent | Treat P2 findings as non-zero. |
| `-Actor` | string | `codex`, `claude`, `unknown` | `unknown` | Caller for event logs. |

## recommend-route.ps1

Purpose: advisory workflow routing before full Spec Kit specification.

| Parameter | Type | Values | Default | Use |
|---|---|---|---|---|
| `-Description` | string | feature request text | empty | Input used by the heuristic. |
| `-Json` | switch | present/absent | absent | Machine-readable output. |

If `-Description` is empty, the script checks `SPECKIT_FEATURE_DESCRIPTION`, then `SPECKIT_SPEC_DESCRIPTION`. If still empty, it returns `no-recommendation` and exits 0.

Heuristic:

- `direct-superpowers`: length under 200, contains a small-scope keyword, and contains no big-scope keyword
- `full-pipeline`: otherwise
- `no-recommendation`: no description

This command never auto-routes. It only advises.

## Packaging Checks

### check-readme-bilingual-parity.ps1

| Parameter | Type | Use |
|---|---|---|
| `-Json` | switch | Machine-readable report. |
| `-Strict` | switch | Treat P2 heading/count drift as non-zero. |

### check-distribution-manifest.ps1

| Parameter | Type | Use |
|---|---|---|
| `-Json` | switch | Machine-readable report. |
| `-SimulateInstall` | string | Copy manifest-listed files to a temporary target with no-clobber checks. |
| `-ManifestPath` | string | Validate a non-default manifest, mainly for tests. |

## State Files

| File | Tracked in Git | Purpose |
|---|---|---|
| `.specify/superpowers-handoff.json` | no | Runtime handoff state. |
| `.specify/bridge-events.jsonl` | no | Runtime audit log. |
| `.specify/bridge-snapshots/` | no | Runtime rollback snapshots. |
| `.specify/extensions/speckit-superpowers-bridge/disposition-matrix.json` | yes | Policy source of truth. |
| `.specify/extensions/speckit-superpowers-bridge/verified-versions.json` | yes | Version verification record. |
| `.specify/extensions/speckit-superpowers-bridge/plugin-distribution-manifest.yml` | yes | Marketplace/package file list. |

