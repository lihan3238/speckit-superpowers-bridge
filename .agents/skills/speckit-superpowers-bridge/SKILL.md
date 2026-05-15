---
name: "speckit-superpowers-bridge"
description: "Execute Spec Kit tasks.md with Superpowers implementation discipline while preserving Spec Kit as the source of truth. Use when .specify/superpowers-handoff.json exists or when asked to bridge Spec Kit tasks to Superpowers."
compatibility: "Requires a Spec Kit project with .specify/ and Superpowers skills available in the agent runtime."
---

# Spec Kit + Superpowers Bridge

Use this skill when Spec Kit has produced implementation artifacts and Superpowers should execute them.

This is the Codex bridge skill at `.agents/skills/speckit-superpowers-bridge/SKILL.md`. Claude Code uses the sibling bridge skill at `.claude/skills/speckit-superpowers-bridge/SKILL.md`.

## Ownership Boundary

- Spec Kit owns `constitution.md`, `spec.md`, `plan.md`, `tasks.md`, checklists, and analysis.
- Superpowers owns implementation execution: worktree isolation, TDD, debugging, subagent or inline execution, review, verification, and branch finishing.
- `tasks.md` is the implementation contract. Do not call `speckit.implement`.
- Do not invoke Superpowers `writing-plans` when Spec Kit `plan.md` and `tasks.md` already exist.
- Do not invoke Superpowers `brainstorming` for an active Spec Kit feature with `spec.md`, `plan.md`, and `tasks.md`, unless the user explicitly discards those Spec Kit artifacts.
- Use Superpowers `subagent-driven-development` and `executing-plans` only as executors of Spec Kit `tasks.md`, not as planners.

## Handoff Loading

1. Read `.specify/superpowers-handoff.json`.
2. If it is missing or stale, run:
   ```powershell
   .\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status ready -Actor codex
   ```
3. Resolve `feature_directory` from the handoff. If it is empty, read `.specify/feature.json`.
4. Read these files before implementation:
   - `.specify/memory/constitution.md`
   - `<feature_directory>/spec.md`
   - `<feature_directory>/plan.md`
   - `<feature_directory>/tasks.md`

If any required feature artifact is missing, set the handoff status to `blocked` and return to Spec Kit.

## Resume Signal

On session resume, before any other non-tool output, run:

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\emit-resume-signal.ps1
```

If `.specify/superpowers-handoff.json.resume_context` is non-null, print that one-line signal first. It names the active task, active Superpowers skill, phase, and next expected action.

## Autonomous Mode

`autonomous_mode` defaults to `false`. When it is `true`, or when `SPECKIT_BRIDGE_AUTONOMOUS=1`, continue across implementation task boundaries without asking for confirmation. Still pause at the named review checkpoints: `superpowers:verification-before-completion`, `superpowers:requesting-code-review`, and `superpowers:finishing-a-development-branch`.

## Execution Rules

1. Set handoff status to `executing` before making implementation changes:
   ```powershell
   .\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status executing -Actor codex
   ```
2. Run the guard before using any potentially overlapping command:
   ```powershell
   .\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\guard-command.ps1 -Action superpowers.executing-plans -Actor codex
   ```
3. Execute `tasks.md` phase by phase and keep checkboxes updated.
4. Include `spec.md`, `plan.md`, `tasks.md`, and this denylist in every delegated prompt:
   - Deny `speckit.implement`
   - Deny `superpowers:brainstorming`
   - Deny `superpowers:writing-plans`
   - Do not add requirements outside Spec Kit artifacts
5. Before each code-modifying task, persist resume context, record the invocation, and use `$superpowers-test-driven-development` for `superpowers:test-driven-development`:
   ```powershell
   $resume = @{ current_task_id = "<T###>"; current_skill = "superpowers:test-driven-development"; current_phase = "before-implementation-task"; next_expected_action = "Start implementation task <T###>" } | ConvertTo-Json -Compress
   .\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status executing -ResumeContext $resume -Actor codex
   .\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\emit-skill-invocation.ps1 -SkillId superpowers:test-driven-development -Phase before-implementation-task -TaskId <T###> -Actor codex -Decision invoked -Reason "Start implementation task"
   ```
6. On any failure or unexpected behavior, persist resume context, record the invocation, and use `$superpowers-systematic-debugging` for `superpowers:systematic-debugging`:
   ```powershell
   $resume = @{ current_task_id = "<T###>"; current_skill = "superpowers:systematic-debugging"; current_phase = "on-failure"; next_expected_action = "Investigate failure for <T###>" } | ConvertTo-Json -Compress
   .\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status executing -ResumeContext $resume -Actor codex
   .\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\emit-skill-invocation.ps1 -SkillId superpowers:systematic-debugging -Phase on-failure -TaskId <T###> -Actor codex -Decision invoked -Reason "Investigate failure"
   ```
7. Before marking a phase complete, persist resume context, record the invocation, and use `$superpowers-verification-before-completion` for `superpowers:verification-before-completion`:
   ```powershell
   $resume = @{ current_task_id = $null; current_skill = "superpowers:verification-before-completion"; current_phase = "before-phase-completion"; next_expected_action = "Run phase verification" } | ConvertTo-Json -Compress
   .\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status executing -ResumeContext $resume -Actor codex
   .\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\emit-skill-invocation.ps1 -SkillId superpowers:verification-before-completion -Phase before-phase-completion -Actor codex -Decision invoked -Reason "Verify phase"
   ```
8. Before marking the feature complete, persist resume context before each completion skill, record both completion invocations, and use `$superpowers-requesting-code-review` for `superpowers:requesting-code-review`, then `$superpowers-finishing-a-development-branch` for `superpowers:finishing-a-development-branch`:
   ```powershell
   $resume = @{ current_task_id = $null; current_skill = "superpowers:requesting-code-review"; current_phase = "before-feature-completion"; next_expected_action = "Request code review" } | ConvertTo-Json -Compress
   .\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status executing -ResumeContext $resume -Actor codex
   .\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\emit-skill-invocation.ps1 -SkillId superpowers:requesting-code-review -Phase before-feature-completion -Actor codex -Decision invoked -Reason "Request review"
   $resume = @{ current_task_id = $null; current_skill = "superpowers:finishing-a-development-branch"; current_phase = "before-feature-completion"; next_expected_action = "Finish development branch" } | ConvertTo-Json -Compress
   .\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status executing -ResumeContext $resume -Actor codex
   .\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\emit-skill-invocation.ps1 -SkillId superpowers:finishing-a-development-branch -Phase before-feature-completion -Actor codex -Decision invoked -Reason "Finish branch"
   ```
9. Do not add requirements beyond `spec.md`, `plan.md`, and `tasks.md`.
10. If the task list is wrong or incomplete, stop implementation and set:
    ```powershell
    .\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status blocked -Reason "Describe the Spec Kit artifact gap" -Actor codex
    ```

## Logs and Rollback

- Handoff updates, snapshots, guard decisions, and rollbacks append events to `.specify/bridge-events.jsonl`.
- Handoff updates snapshot Spec Kit control artifacts under `.specify/bridge-snapshots/<snapshot-id>/`.
- Restore a snapshot with:
  ```powershell
  .\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\restore-snapshot.ps1 -SnapshotId <snapshot-id>
  ```

## Completion Rules

Only set the handoff to `complete` after all required task checkboxes are complete and fresh verification has passed:

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status complete
```

Report the verification commands and results with the final implementation summary.

## Auto-archive between features

A `complete` handoff for one feature must NOT block contract changes on the next feature. When starting a new feature:

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\auto-archive-handoff.ps1 -Actor codex
```

The helper is idempotent: if the current status is not `complete`, it exits success without changes. When it does fire, it snapshots the prior feature's artifacts, appends an entry to `archive_history` in `superpowers-handoff.json`, clears `feature_directory`/`artifact_owner`/`review_only_agents`, and appends an `auto_archive` event.

When invoking the guard from a known feature context, pass `-TargetFeatureDirectory <project-relative-path>` so the guard can distinguish same-feature requests (still denied when status is `complete`) from cross-feature requests (allowed).

## Parity Check

For non-overlap policy audits, use:

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\parity-check.ps1 -Json -Actor codex
```

The check inspects the disposition matrix (`.specify/extensions/speckit-superpowers-bridge/disposition-matrix.json`), verified-versions pin (`.specify/extensions/speckit-superpowers-bridge/verified-versions.json`), per-agent skill parity, and doc-matrix consistency. Exit code 0 = clean; 1 = P0 finding; 2 = P1 finding. See `specs/002-complete-bridge-protocol/contracts/parity-check-contract.md` for the full contract.

## Disposition Matrix

The bridge guard consults `disposition-matrix.json` for every command/skill before falling back to legacy rules. Keep the matrix as the source of truth; do not duplicate policy in the guard or in agent skill files. Adding a new Spec Kit command or Superpowers skill requires an explicit matrix entry — the parity check fails until one is added.
