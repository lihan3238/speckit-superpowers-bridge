---
description: "Execute Spec Kit tasks.md through the Superpowers bridge"
---

# Bridge Execute

Execute the active Spec Kit feature through Superpowers without running `speckit.implement`.

## Behavior

1. Read `.specify/superpowers-handoff.json`; if it is missing or stale, create a ready handoff with the platform-selected `update-handoff` script.
2. Read `.specify/memory/constitution.md`, `spec.md`, `plan.md`, and `tasks.md` before touching implementation files.
3. Run the bridge guard for `superpowers.executing-plans`.
4. Execute `tasks.md` with Superpowers implementation discipline: TDD, systematic debugging, review, verification, and branch finishing.
5. Keep task checkboxes and handoff state current. If the Spec Kit contract is wrong or incomplete, stop and set handoff status to `blocked`.

## Execution

Use the short marketplace alias as the normal implementation driver:

- Codex: `$speckit-superpowers-bridge`
- Claude Code: `/speckit-superpowers-bridge`

The canonical extension command remains available as a fallback:

- Codex: `$speckit-speckit-superpowers-bridge-execute`
- Claude Code: `/speckit-speckit-superpowers-bridge-execute`

In this source repository, the same protocol is mirrored in project-local bridge skill files:

- Codex: `.agents/skills/speckit-superpowers-bridge/SKILL.md`
- Claude Code: `.claude/skills/speckit-superpowers-bridge/SKILL.md`

Fresh marketplace installs do not copy those source-repository mirrors directly. Instead, Spec Kit generates skills from extension commands, including `.agents/skills/speckit-speckit-superpowers-bridge-*` / `.claude/skills/speckit-speckit-superpowers-bridge-*`; those generated directories are expected and authoritative.

Before implementation begins, run the platform flavor selected by `.specify/init-options.json.script`.

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status executing -Actor <codex|claude>
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\guard-command.ps1 -Action "superpowers:executing-plans" -Actor <codex|claude>
```

```bash
bash .specify/extensions/speckit-superpowers-bridge/scripts/bash/update-handoff.sh --status executing --actor <codex|claude>
bash .specify/extensions/speckit-superpowers-bridge/scripts/bash/guard-command.sh --action "superpowers:executing-plans" --actor <codex|claude>
```

Do not invoke Superpowers `brainstorming` or `writing-plans` for this active feature. Spec Kit artifacts are the only design and execution contract.

## Required Superpowers Discipline

Use Superpowers execution skills only against Spec Kit `tasks.md`:

- `superpowers:test-driven-development` before each code-modifying task.
- `superpowers:systematic-debugging` before fixing any failure or unexpected behavior.
- `superpowers:verification-before-completion` before marking a phase complete.
- `superpowers:requesting-code-review` before final completion.
- `superpowers:finishing-a-development-branch` before handing off merge, PR, or branch cleanup decisions.

Before each required Superpowers skill invocation, the agent simply calls the skill — no extra logging or resume-context plumbing is needed. The bridge's only state is `superpowers-handoff.json`, updated at lifecycle boundaries (start / block / complete) via `update-handoff.ps1` or `update-handoff.sh`. See the bridge `SKILL.md` (linked above) for the authoritative 8-step orchestration sequence.

For delegated implementation prompts, include:

- `.specify/memory/constitution.md`
- `<feature_directory>/spec.md`
- `<feature_directory>/plan.md`
- `<feature_directory>/tasks.md`
- Denylist: `speckit.implement`, `superpowers:brainstorming`, `superpowers:writing-plans`

Set the handoff to `blocked` if the Spec Kit contract is missing or wrong:

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status blocked -Reason "Describe the Spec Kit artifact gap" -Actor <codex|claude>
```

```bash
bash .specify/extensions/speckit-superpowers-bridge/scripts/bash/update-handoff.sh --status blocked --reason "Describe the Spec Kit artifact gap" --actor <codex|claude>
```

Set the handoff to `complete` only after all required task checkboxes are complete, code review has been requested, verification has fresh passing evidence, and branch finishing has run:

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status complete -Actor <codex|claude>
```

```bash
bash .specify/extensions/speckit-superpowers-bridge/scripts/bash/update-handoff.sh --status complete --actor <codex|claude>
```
