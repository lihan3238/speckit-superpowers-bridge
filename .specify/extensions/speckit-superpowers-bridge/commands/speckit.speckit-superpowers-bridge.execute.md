---
description: "Execute Spec Kit tasks.md through the Superpowers bridge"
---

# Bridge Execute

Execute the active Spec Kit feature through Superpowers without running `speckit.implement`.

## Behavior

1. Read `.specify/superpowers-handoff.json`; if it is missing or stale, create a ready handoff with `update-handoff.ps1`.
2. Read `.specify/memory/constitution.md`, `spec.md`, `plan.md`, and `tasks.md` before touching implementation files.
3. Run the bridge guard for `superpowers.executing-plans`.
4. Execute `tasks.md` with Superpowers implementation discipline: TDD, systematic debugging, review, verification, and branch finishing.
5. Keep task checkboxes and handoff state current. If the Spec Kit contract is wrong or incomplete, stop and set handoff status to `blocked`.

## Execution

Use this generated command/skill as the marketplace-installed implementation driver.
In this source repository, the same protocol is mirrored in the project-local bridge skills:

- Codex: `.agents/skills/speckit-superpowers-bridge/SKILL.md`
- Claude Code: `.claude/skills/speckit-superpowers-bridge/SKILL.md`

If those local bridge skill files are not present after marketplace installation, this command is authoritative.

Before implementation begins, run:

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status executing -Actor <codex|claude>
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\guard-command.ps1 -Action superpowers.executing-plans -Actor <codex|claude>
```

Do not invoke Superpowers `brainstorming` or `writing-plans` for this active feature. Spec Kit artifacts are the only design and execution contract.

## Required Superpowers Discipline

Use Superpowers execution skills only against Spec Kit `tasks.md`:

- `superpowers:test-driven-development` before each code-modifying task.
- `superpowers:systematic-debugging` before fixing any failure or unexpected behavior.
- `superpowers:verification-before-completion` before marking a phase complete.
- `superpowers:requesting-code-review` before final completion.
- `superpowers:finishing-a-development-branch` before handing off merge, PR, or branch cleanup decisions.

Before each required Superpowers skill invocation, persist resume context and append an audit event:

```powershell
$resume = @{ current_task_id = "<T###>"; current_skill = "superpowers:test-driven-development"; current_phase = "before-implementation-task"; next_expected_action = "Start implementation task <T###>" } | ConvertTo-Json -Compress
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status executing -ResumeContext $resume -Actor <codex|claude>
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\emit-skill-invocation.ps1 -SkillId superpowers:test-driven-development -Phase before-implementation-task -TaskId <T###> -Actor <codex|claude> -Decision invoked -Reason "Start implementation task"
```

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

Set the handoff to `complete` only after all required task checkboxes are complete, code review has been requested, verification has fresh passing evidence, and branch finishing has run:

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status complete -Actor <codex|claude>
```
