[简体中文](README.zh-CN.md)

# speckit-superpowers-bridge

Spec Kit + Superpowers Bridge is a lightweight local extension protocol that keeps Spec Kit as the source of truth for specification, planning, and tasks while using Superpowers for implementation discipline.

## installation

Install or copy the bridge assets listed in `.specify/extensions/speckit-superpowers-bridge/plugin-distribution-manifest.yml` into a Spec Kit project with Codex, Claude Code, or both integrations installed.

```powershell
specify init . --integration codex
specify integration install claude
```

Run the install-state audit after installation:

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\audit-install-state.ps1 -Json
```

## quick-usage-example

### 0. Install once

Start from a Spec Kit project and install one or both agent integrations:

```powershell
specify init . --integration codex
specify integration install claude
specify integration use codex
```

Copy or install this bridge's manifest-listed files, then verify the local install:

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\audit-install-state.ps1 -Json
```

### 1. Pick the Spec Kit writer

Only one agent should write Spec Kit control artifacts for a feature. The other agent can review.

- Codex command style: `$speckit-specify`, `$speckit-plan`, `$speckit-tasks`
- Claude Code command style: `/speckit-specify`, `/speckit-plan`, `/speckit-tasks`

### 2. Create the Spec Kit artifacts

Run constitution once when project governance is new or changing, then run the normal Spec Kit design flow with the selected writer:

```text
$speckit-constitution
$speckit-specify "Describe the feature to build"
$speckit-clarify
$speckit-checklist
$speckit-plan
$speckit-tasks
$speckit-analyze
```

For Claude Code, use the same names with slash commands, for example `/speckit-specify`.

### 3. Hand off implementation

The `after_tasks` hook should create `.specify/superpowers-handoff.json`. If you need to refresh it manually:

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status ready -Actor codex
```

Use `-Actor claude` when Claude Code owns execution. Enable long unattended runs only when that is intentional:

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status ready -AutonomousMode $true -Actor codex
```

### 4. Execute with Superpowers

Invoke the bridge instead of `speckit.implement`:

```text
$speckit-superpowers-bridge
```

Claude Code uses `/speckit-superpowers-bridge`.

The bridge reads `constitution.md`, `spec.md`, `plan.md`, and `tasks.md`, then executes `tasks.md` with Superpowers discipline: TDD, debugging, review, verification, and branch finishing. It updates task checkboxes and handoff state as execution progresses.

### 5. Handle requirement gaps

If implementation reveals a missing or wrong requirement, stop coding and mark the handoff blocked:

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status blocked -Reason "Spec Kit artifact needs revision" -Actor codex
```

Return to Spec Kit, revise `spec.md`, `plan.md`, or `tasks.md`, then create a fresh ready handoff and resume bridge execution.

### 6. Verify and finish

Before considering the feature complete:

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\validation-pass.ps1 -Json -Actor codex
```

The bridge marks handoff status `complete` only after tasks are complete and verification passes. For the next feature, the `before_specify` hook auto-archives the completed handoff; you can also run:

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\auto-archive-handoff.ps1 -Actor codex
```

### 7. Guardrails

- Do not run `speckit.implement` while handoff executor is `superpowers`.
- Do not use Superpowers `brainstorming` or `writing-plans` to replace an existing Spec Kit `spec.md`, `plan.md`, or `tasks.md`.
- Do not let Codex and Claude Code write the same Spec Kit artifacts at the same time.
- Use `speckit.superpowers.audit`, `speckit.superpowers.parity`, and `speckit.superpowers.validate` when something feels out of sync.

## configuration

The handoff file is `.specify/superpowers-handoff.json`.

Key fields:

- `executor`: must be `superpowers`
- `autonomous_mode`: default `false`
- `resume_context`: current task, skill, phase, and next expected action
- `artifact_owner`: the single agent allowed to write Spec Kit control artifacts

Detailed script parameters and handoff field behavior are documented in `.specify/extensions/speckit-superpowers-bridge/docs/parameter-reference.md`.

Environment variables:

- `SPECKIT_BRIDGE_ACTOR`: overrides actor detection
- `SPECKIT_BRIDGE_AUTONOMOUS=1`: runtime override for autonomous execution

## architecture

Spec Kit owns WHAT: constitution, specification, planning, task generation, checklists, and analysis. Superpowers owns HOW: TDD, debugging, execution, review, verification, and branch finishing. This follows the design direction in the Spec Kit vs Superpowers comparison article referenced by `AGENTS.md`.

## commands

Bridge meta-commands:

- `speckit.superpowers.guard`: enforce responsibility boundaries
- `speckit.superpowers.handoff`: create or refresh the handoff
- `speckit.superpowers.parity`: audit disposition matrix coverage
- `speckit.superpowers.audit`: audit install state and per-agent skill parity
- `speckit.superpowers.validate`: run the end-to-end bridge validation pass
- `speckit.superpowers.recommend-route`: advisory light/heavy workflow route hint

## skill-sync-upgrade

Codex and Claude Code maintain separate skill directories. Keep them synchronized with:

```powershell
specify integration upgrade codex
specify integration upgrade claude
```

If upstream Spec Kit does not mirror extension skills, manually copy only the bridge skill pair:

```powershell
Copy-Item .agents\skills\speckit-superpowers-bridge .claude\skills\speckit-superpowers-bridge -Recurse
```

Do not hand-edit official generated `.agents/skills/speckit-*` or `.claude/skills/speckit-*` files.

## troubleshooting

Run these checks first:

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\parity-check.ps1 -Json
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\audit-install-state.ps1 -Json
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\validation-pass.ps1 -Json
```

If implementation reveals a requirement gap, set the handoff to `blocked` and return to Spec Kit artifacts before resuming.

## license

MIT. See the extension manifest for package metadata.
