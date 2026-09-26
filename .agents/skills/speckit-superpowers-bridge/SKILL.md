---
name: "speckit-superpowers-bridge"
description: "Orchestrate native Superpowers skills against a Spec Kit tasks.md. Invoke when .specify/superpowers-handoff.json exists or when the user asks to bridge Spec Kit design artifacts into Superpowers implementation."
compatibility: "Requires a Spec Kit project with .specify/ and Superpowers skills available in the agent runtime."
---

# Spec Kit <-> Superpowers Bridge (Codex peer)

This skill is the **thin orchestrator** between Spec Kit (design) and Superpowers (implementation). It does not implement TDD, debugging, verification, code review, or branch finishing itself - those are native Superpowers skills. The bridge's only job is to derive a disposable Superpowers adapter from the Spec Kit `tasks.md`, then invoke native skills in order without replacing the canonical task contract.

## When to use

- A feature has `spec.md`, `plan.md`, and `tasks.md` in its `specs/<NNN>-.../` directory.
- The user invoked `$speckit-superpowers-bridge` (recommended marketplace alias) or `$speckit-speckit-superpowers-bridge-execute` (canonical fallback).
- `.specify/superpowers-handoff.json` exists and points at the feature.

## What this skill does

1. Read `.specify/superpowers-handoff.json` to find `feature_directory`. If status is `complete`, run the platform-selected auto-archive script first so the new feature begins from `ready`.
2. Read `<feature_directory>/spec.md`, `plan.md`, `tasks.md`, and `.specify/memory/constitution.md`.
3. Fire the `before_implement` extension hooks from `.specify/extensions.yml` (see "Extension hooks" below).
4. Transition handoff to `executing` using `.specify/init-options.json.script` (`ps` => PowerShell, `sh` => bash). **Do NOT pass `-ArtifactOwner` / `--artifact-owner`** — the script silently preserves the prior owner from the handoff JSON when the flag is omitted (per spec 003-bridge-cross-platform-scripts FR-001). Pass `-ArtifactOwner` only if you are intentionally transferring ownership (e.g., a maintainer rebasing a feature onto a different designer).
   ```powershell
   .\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status executing -FeatureDirectory <project-relative-path> -Actor codex
   ```
   ```bash
   bash .specify/extensions/speckit-superpowers-bridge/scripts/bash/update-handoff.sh --status executing --feature-directory <project-relative-path> --actor codex
   ```
5. Derive a disposable adapter plan outside `.superpowers/sdd/` (for example, a stable repository/feature-derived OS temporary path reused on resume) from the canonical `tasks.md`. Each adapter entry MUST use a `### Task N: T###` heading and copy the exact Spec Kit task text; include pointers to `spec.md`, `plan.md`, the constitution, and the global constraints. Do not change the task meaning or create a second requirements source.
6. Invoke `superpowers:executing-plans` against that adapter. Superpowers 6.4.2 executes it inline and requires the heading format; it cannot consume Spec Kit checkbox lines directly.
7. After each native task completes, update the corresponding canonical `tasks.md` checkbox and verify the adapter and canonical task ID agree. Remove the temporary adapter after execution.
8. At completion of all tasks, invoke `superpowers:verification-before-completion`.
9. Invoke `superpowers:requesting-code-review`.
10. Invoke `superpowers:finishing-a-development-branch`.
11. Fire the `after_implement` extension hooks from `.specify/extensions.yml` (see "Extension hooks" below).
12. Transition handoff to `complete` with the same platform flavor only after mandatory post-hooks succeed:
   ```powershell
   .\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status complete -Actor codex
   ```
   ```bash
   bash .specify/extensions/speckit-superpowers-bridge/scripts/bash/update-handoff.sh --status complete --actor codex
   ```

## Extension hooks (before_implement / after_implement)

This skill replaces `speckit.implement`, so it fires the same
`before_implement` / `after_implement` extension hooks that `speckit.implement`
would fire (mirroring Spec Kit's own `implement` command), so user and
third-party hooks stay plug-and-play:

- Source: `.specify/extensions.yml` (`hooks.before_implement` /
  `hooks.after_implement`). If the YAML is malformed, report the parser error,
  state that no hooks were checked (including mandatory hooks), and continue
  the core lifecycle normally. Skip hook checking when the file is absent.
- **Skip any hook whose `extension` is `speckit-superpowers-bridge`** — the
  bridge's own `before_implement` hook is its guard, which blocks
  `speckit.implement`, not the bridge.
- Skip hooks where `enabled` is `false` (missing `enabled` = enabled).
- Skip hooks with a non-empty `condition` (leave to upstream HookExecutor).
- Fire each remaining hook via its `command`, dots→hyphens:
  `speckit.git.commit` → `$speckit-git-commit` (Codex) or `/speckit-git-commit`
  (Claude Code). Optional (`optional: true`) hooks surface the extension,
  command, description, prompt, and agent-native invocation, then run only
  after confirmation.
- For every mandatory hook (`optional: false`), emit Spec Kit's
  phase-appropriate automatic-hook block before invocation:
  ```text
  ## Extension Hooks

  **Automatic Pre-Hook**: <extension>   # before_implement
  **Automatic Hook**: <extension>       # after_implement
  Executing: `/<dotted-command-id>`
  EXECUTE_COMMAND: <dotted-command-id>
  ```
- Emit only the phase-appropriate automatic label, not both labels in one live
  block. Keep the dotted ID in the directive; use the active agent's rendered
  command form for the actual invocation.
- Actually invoke the rendered agent command and wait for its result. Printing
  the directive or invocation name without calling the command is not success.
  A mandatory hook failure stops the lifecycle.

`before_implement` fires before the handoff transitions to `executing`.
Dispatch `after_implement` before transitioning the handoff to `complete`.
If a mandatory `after_implement` hook fails, do not transition the handoff to `complete`;
leave the non-complete state visible for recovery. Declining an optional hook
does not fail implementation.

## Superpowers 6.4.2 adapter contract

Spec Kit `tasks.md` remains the only source of requirements and completion
status. Before invoking `superpowers:executing-plans`, create an ephemeral
adapter plan outside the native `.superpowers/sdd/` workspace at a stable repository/feature-derived temporary path reused on resume. Give it a
`Global Constraints` section, pointers to the active Spec Kit artifacts, and
one `### Task N: T###` heading for every canonical task being executed. Under
each heading, copy the exact checkbox task text and its file paths. The
adapter may add execution metadata needed by Superpowers, but it MUST NOT
invent requirements or change ordering/dependencies. Mark the matching
checkbox in `tasks.md` only after the native task has completed and its
verification passed. Remove the adapter after the lifecycle. If a task ID
cannot be mapped exactly, stop and mark the handoff `blocked`.

Superpowers 6.4.2's `executing-plans` skill executes this adapter inline.
The bridge still invokes `verification-before-completion`, `requesting-code-review`,
and `finishing-a-development-branch` explicitly. It does not invoke
`superpowers:writing-plans` or `superpowers:brainstorming` for an active
Spec Kit feature. `subagent-driven-development` remains an upstream option,
not a new bridge command.

## Boundary rules (denied operations)

The hardcoded guard at `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/guard-command.ps1` and `.specify/extensions/speckit-superpowers-bridge/scripts/bash/guard-command.sh` enforces, and this skill MUST respect:

- Do not run `speckit.implement` while a handoff is `executing`.
- Do not invoke `superpowers:writing-plans` or `superpowers:brainstorming` when an active Spec Kit feature has `spec.md` and `plan.md`.
- Do not edit `.specify/memory/constitution.md` while a handoff is `executing` - set the handoff to `blocked` first.
- Do not add requirements beyond what `spec.md`, `plan.md`, and `tasks.md` already define.

## Cross-agent notes

This skill has an identical-content peer at `.claude/skills/speckit-superpowers-bridge/SKILL.md` for Claude Code. To hand off mid-feature, the next agent simply re-invokes `$speckit-superpowers-bridge` (Codex) or `/speckit-superpowers-bridge` (Claude Code) on the same repo - the handoff JSON tells it where to pick up. `AGENTS.md` is the master cross-agent protocol; consult it for the language-routing and ownership rules.

## When something goes wrong

If implementation surfaces a missing or wrong requirement, stop and mark the handoff blocked so Spec Kit can repair the design artifacts:

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status blocked -Reason "<describe the spec/plan/tasks gap>" -Actor codex
```

```bash
bash .specify/extensions/speckit-superpowers-bridge/scripts/bash/update-handoff.sh --status blocked --reason "<describe the spec/plan/tasks gap>" --actor codex
```

Then return control to the user / Spec Kit. After `$speckit-clarify` or `$speckit-tasks` regenerates the artifacts, re-invoke this skill to resume.

## Logs and snapshots

Every handoff transition and guard decision appends one line to `.specify/bridge-events.jsonl` (append-only). Each handoff write also snapshots Spec Kit artifacts under `.specify/bridge-snapshots/<id>/` (rollback is manual: `cp -r .specify/bridge-snapshots/<id>/* <destination>`).

## Bridge state output (v0.5.0+)

From v0.5.0 onward, every `update-handoff` and `guard-command` invocation prints a `[bridge state]` block to stdout showing `Feature directory`, `Status`, `Artifact owner`, `Actor` (with `prior → new` when the actor changed), and `Pending tasks: N` computed from the canonical `^- \[ \] T\d+` regex in `<feature_directory>/tasks.md`. When `update-handoff` transitions a feature to `complete` while non-deferred unchecked task-ID lines remain, an additional `[bridge] WARNING:` line is emitted to stderr (exit code stays 0; the warning surfaces the drift for the operator to resolve, it does not block the transition). The handoff event log additionally carries a `prior_actor` field for audit. Spec: `specs/008-bridge-hardening-0-5-0/contracts/bridge-state-summary.md`.

## Useful commands (v0.7.0+)

- `bridge-status.{sh,ps1}` — read-only on-demand introspection (prints `[bridge state]` + `Drift:` + `Next:` recommendation; never writes). See `specs/012-bridge-status-and-hash/`.
- `bridge-status.{sh,ps1} --readiness` / `-Readiness` — read-only install health report added for v1.0.0. It checks script flavor, required tools, namespace alignment, package files, bridge state, verified agent metadata, and next action; `--json` / `-Json` returns machine-readable readiness output.
