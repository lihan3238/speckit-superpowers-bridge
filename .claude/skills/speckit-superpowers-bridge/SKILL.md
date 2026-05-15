---
name: "speckit-superpowers-bridge"
description: "Orchestrate native Superpowers skills against a Spec Kit tasks.md. Invoke when .specify/superpowers-handoff.json exists or when the user asks to bridge Spec Kit design artifacts into Superpowers implementation."
compatibility: "Requires a Spec Kit project with .specify/ and Superpowers skills available in Claude Code."
argument-hint: "Optional execution guidance"
user-invocable: true
disable-model-invocation: false
---

# Spec Kit ↔ Superpowers Bridge (Claude Code peer)

This skill is the **thin orchestrator** between Spec Kit (design) and Superpowers (implementation). It does not implement TDD, debugging, verification, code review, or branch finishing itself — those are native Superpowers skills. The bridge's only job is to invoke them in order against the Spec Kit `tasks.md`.

## When to use

- A feature has `spec.md`, `plan.md`, and `tasks.md` in its `specs/<NNN>-…/` directory.
- The user invoked `/speckit-superpowers-bridge` (or the marketplace-installed `/speckit-speckit-superpowers-bridge-execute`).
- `.specify/superpowers-handoff.json` exists and points at the feature.

## What this skill does

1. Read `.specify/superpowers-handoff.json` to find `feature_directory`. If status is `complete`, run `auto-archive-handoff.ps1 -Actor claude` first so the new feature begins from `ready`.
2. Read `<feature_directory>/spec.md`, `plan.md`, `tasks.md`, and `.specify/memory/constitution.md`.
3. Transition handoff to `executing`:
   ```powershell
   .\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status executing -FeatureDirectory <project-relative-path> -ArtifactOwner claude -Actor claude
   ```
4. Invoke `superpowers:executing-plans` against `tasks.md`. That skill drives the per-task loop and dispatches `superpowers:test-driven-development` and `superpowers:systematic-debugging` as needed.
5. At completion of all tasks, invoke `superpowers:verification-before-completion`.
6. Invoke `superpowers:requesting-code-review`.
7. Invoke `superpowers:finishing-a-development-branch`.
8. Transition handoff to `complete`:
   ```powershell
   .\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status complete -Actor claude
   ```

## Boundary rules (denied operations)

The hardcoded guard at `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/guard-command.ps1` enforces, and this skill MUST respect:

- Do not run `speckit.implement` while a handoff is `executing`.
- Do not invoke `superpowers:writing-plans` or `superpowers:brainstorming` when an active Spec Kit feature has `spec.md` and `plan.md`.
- Do not edit `.specify/memory/constitution.md` while a handoff is `executing` — set the handoff to `blocked` first.
- Do not add requirements beyond what `spec.md`, `plan.md`, and `tasks.md` already define.

## Cross-agent notes

This skill has an identical-content peer at `.agents/skills/speckit-superpowers-bridge/SKILL.md` for Codex. To hand off mid-feature, the next agent simply re-invokes `/speckit-superpowers-bridge` (Claude Code) or `$speckit-superpowers-bridge` (Codex) on the same repo — the handoff JSON tells it where to pick up. `AGENTS.md` is the master cross-agent protocol; consult it for the language-routing and ownership rules.

## When something goes wrong

If implementation surfaces a missing or wrong requirement, stop and mark the handoff blocked so Spec Kit can repair the design artifacts:

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status blocked -Reason "<describe the spec/plan/tasks gap>" -Actor claude
```

Then return control to the user / Spec Kit. After `/speckit-clarify` or `/speckit-tasks` regenerates the artifacts, re-invoke this skill to resume.

## Logs and snapshots

Every handoff transition and guard decision appends one line to `.specify/bridge-events.jsonl` (append-only). Each handoff write also snapshots Spec Kit artifacts under `.specify/bridge-snapshots/<id>/` (rollback is manual: `cp -r .specify/bridge-snapshots/<id>/* <destination>`).
