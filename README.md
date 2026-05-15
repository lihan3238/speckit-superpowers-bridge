[简体中文](README.zh-CN.md)

# speckit-superpowers-bridge

Spec Kit + Superpowers Bridge is a lightweight integration protocol: Spec Kit remains the source of truth for constitution, specification, planning, tasks, checklists, and analysis; Superpowers executes implementation discipline only.

## overview

This is not another full Superpowers workflow replacement. The bridge deliberately avoids duplicating either tool:

- Spec Kit owns the design contract.
- Superpowers owns TDD, debugging, execution, review, verification, and branch finishing.
- `tasks.md` is the only implementation contract.
- Guard, handoff, audit, and rollback state keep the two systems from overlapping or leaving gaps.
- The package is repo-local and small: one Spec Kit extension, one bridge skill pair, one handoff JSON, one JSONL event log, and rollback snapshots. No service, database, daemon, or global Superpowers patching.

## installation

Marketplace release install:

```powershell
specify extension add speckit-superpowers-bridge --from https://github.com/lihan3238/speckit-superpowers-bridge/releases/download/v0.1.1/speckit-superpowers-bridge-v0.1.1.zip
```

Local development install:

```powershell
specify extension add --dev .\.specify\extensions\speckit-superpowers-bridge
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

Install the bridge, then verify the local install:

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

Invoke the marketplace-compliant execute command instead of `speckit.implement`:

```text
$speckit-speckit-superpowers-bridge-execute
```

Claude Code uses `/speckit-speckit-superpowers-bridge-execute`.

The generated execute command is the marketplace-installed bridge driver. It reads `constitution.md`, `spec.md`, `plan.md`, and `tasks.md`, then executes `tasks.md` with Superpowers discipline: TDD, debugging, review, verification, and branch finishing. It updates task checkboxes and handoff state as execution progresses. In this source repository, `.agents/skills/speckit-superpowers-bridge` and `.claude/skills/speckit-superpowers-bridge` mirror the same protocol for local development.

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
- Use `speckit.speckit-superpowers-bridge.audit`, `speckit.speckit-superpowers-bridge.parity`, and `speckit.speckit-superpowers-bridge.validate` when something feels out of sync.

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

Spec Kit owns WHAT: constitution, specification, planning, task generation, checklists, and analysis. Superpowers owns HOW: TDD, debugging, execution, review, verification, and branch finishing. The bridge's advantage is strict separation with minimal glue: it lets each tool do what it is best at without rewriting or replacing the other.

## commands

Official extension command IDs:

- `speckit.speckit-superpowers-bridge.execute`: execute Spec Kit `tasks.md` through Superpowers
- `speckit.speckit-superpowers-bridge.guard`: enforce responsibility boundaries
- `speckit.speckit-superpowers-bridge.handoff`: create or refresh the handoff
- `speckit.speckit-superpowers-bridge.parity`: audit disposition matrix coverage
- `speckit.speckit-superpowers-bridge.audit`: audit install state and per-agent skill parity
- `speckit.speckit-superpowers-bridge.validate`: run the end-to-end bridge validation pass
- `speckit.speckit-superpowers-bridge.recommend-route`: advisory light/heavy workflow route hint

Agent integrations render these command IDs into their own invocation style. For example, Codex renders the execute command as `$speckit-speckit-superpowers-bridge-execute`; Claude Code renders it as `/speckit-speckit-superpowers-bridge-execute`.

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

## marketplace-positioning

The community catalog already contains broader Superpowers bridges. This extension is intentionally narrower: it is a compatibility protocol for teams that want Spec Kit to remain the full design spine while Superpowers supplies execution discipline. The differentiator is the guard/handoff/audit/rollback contract, not another planning layer.

## license

MIT. See the extension manifest for package metadata.
