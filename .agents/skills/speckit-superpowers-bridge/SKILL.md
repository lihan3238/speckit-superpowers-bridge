---
name: "speckit-superpowers-bridge"
description: "Orchestrate native Superpowers skills against a Spec Kit tasks.md. Invoke when .specify/superpowers-handoff.json exists or when the user asks to bridge Spec Kit design artifacts into Superpowers implementation."
compatibility: "Requires a Spec Kit project with .specify/ and Superpowers skills available in the agent runtime."
---

# Spec Kit <-> Superpowers Bridge (Codex peer)

This skill is the **thin orchestrator** between Spec Kit (design) and Superpowers (implementation). It does not implement TDD, debugging, verification, code review, or branch finishing itself - those are native Superpowers skills. The bridge's only job is to invoke them in order against the Spec Kit `tasks.md`.

## When to use

- A feature has `spec.md`, `plan.md`, and `tasks.md` in its `specs/<NNN>-.../` directory.
- The user invoked `$speckit-superpowers-bridge` (recommended marketplace alias) or `$speckit-speckit-superpowers-bridge-execute` (canonical fallback).
- `.specify/superpowers-handoff.json` exists and points at the feature.

## What this skill does

1. Read `.specify/superpowers-handoff.json` to find `feature_directory`. If status is `complete`, run the platform-selected auto-archive script first so the new feature begins from `ready`.
2. Read `<feature_directory>/spec.md`, `plan.md`, `tasks.md`, and `.specify/memory/constitution.md`.
3. Transition handoff to `executing` using `.specify/init-options.json.script` (`ps` => PowerShell, `sh` => bash). **Do NOT pass `-ArtifactOwner` / `--artifact-owner`** — the script silently preserves the prior owner from the handoff JSON when the flag is omitted (per spec 003-bridge-cross-platform-scripts FR-001). Pass `-ArtifactOwner` only if you are intentionally transferring ownership (e.g., a maintainer rebasing a feature onto a different designer).
   ```powershell
   .\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status executing -FeatureDirectory <project-relative-path> -Actor codex
   ```
   ```bash
   bash .specify/extensions/speckit-superpowers-bridge/scripts/bash/update-handoff.sh --status executing --feature-directory <project-relative-path> --actor codex
   ```
4. Invoke `superpowers:executing-plans` against `tasks.md`. That skill drives the per-task loop and dispatches `superpowers:test-driven-development` and `superpowers:systematic-debugging` as needed.
5. At completion of all tasks, invoke `superpowers:verification-before-completion`.
6. Invoke `superpowers:requesting-code-review`.
7. Invoke `superpowers:finishing-a-development-branch`.
8. Transition handoff to `complete` with the same platform flavor:
   ```powershell
   .\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status complete -Actor codex
   ```
   ```bash
   bash .specify/extensions/speckit-superpowers-bridge/scripts/bash/update-handoff.sh --status complete --actor codex
   ```

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
