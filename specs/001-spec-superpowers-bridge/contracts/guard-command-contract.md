# Contract: Bridge Guard Command

## Purpose

`guard-command.ps1` decides whether a requested Spec Kit command or Superpowers skill is allowed under the current bridge ownership state.

## Invocation

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\guard-command.ps1 -Action <action> [-Actor <codex|claude|unknown>] [-AllowDiscardSpecArtifacts]
```

## Inputs

- `-Action`: required action id.
  - Spec Kit examples: `speckit.clarify`, `speckit.plan`, `speckit.tasks`, `speckit.implement`
  - Superpowers examples: `superpowers.brainstorming`, `superpowers.writing-plans`, `superpowers.subagent-driven-development`
- `-Actor`: optional agent key. Defaults to `unknown` for backward compatibility.
- `-AllowDiscardSpecArtifacts`: optional explicit override only when the user has said to discard or replace Spec Kit artifacts.

## Allow/Deny Rules

- Deny `speckit.implement` whenever handoff `executor` is `superpowers`.
- Deny `speckit.clarify`, `speckit.plan`, and `speckit.tasks` when handoff status is `executing` or `complete`.
- Allow Spec Kit repair commands when status is `blocked`.
- Deny Spec Kit artifact-writing actions when `artifact_owner` is set and `Actor` differs from `artifact_owner`.
- Deny `superpowers.brainstorming` and `superpowers.writing-plans` when active feature artifacts `spec.md`, `plan.md`, and `tasks.md` all exist, unless `-AllowDiscardSpecArtifacts` is present.
- Allow `superpowers.subagent-driven-development` and `superpowers.executing-plans` only as execution of Spec Kit `tasks.md`.
- Allow execution-discipline skills such as TDD, debugging, review, verification, and finishing.

## Output

- Success exit code with an allow message for allowed actions.
- Non-zero exit code with a denial reason for denied actions.
- Exactly one JSONL event appended for every decision.

## Compatibility

Existing calls without `-Actor` remain valid for hook compatibility. They use `unknown`; explicit single-writer enforcement applies when the caller supplies `codex` or `claude`.
