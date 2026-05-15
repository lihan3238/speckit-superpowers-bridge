---
description: "Guard Spec Kit and Superpowers commands from crossing bridge ownership boundaries"
---

# Superpowers Bridge Guard

Block commands that would overlap responsibilities after Spec Kit has handed implementation to Superpowers.

## Behavior

The guard reads `.specify/superpowers-handoff.json` and the active feature artifacts.

- Deny `speckit.implement` when the handoff executor is `superpowers`.
- Deny `speckit.clarify`, `speckit.plan`, and `speckit.tasks` while handoff status is `executing` or `complete`.
- Allow Spec Kit repair commands when handoff status is `blocked`.
- Deny Spec Kit artifact-writing actions when `artifact_owner` is set and `-Actor` is a different agent.
- Deny `superpowers:brainstorming` and `superpowers:writing-plans` when an active Spec Kit feature has `spec.md`, `plan.md`, and `tasks.md`, unless the user explicitly discards those artifacts.
- Log every allow or deny decision to `.specify/bridge-events.jsonl`.

## Execution

Map the triggering hook or requested skill to an action and run:

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\guard-command.ps1 -Action <action> -Actor <codex|claude|unknown>
```

Examples:

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\guard-command.ps1 -Action speckit.implement
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\guard-command.ps1 -Action speckit.tasks -Actor codex
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\guard-command.ps1 -Action superpowers.writing-plans -Actor codex
```

Only use `-AllowDiscardSpecArtifacts` after the user explicitly says to discard or replace the existing Spec Kit artifacts.
