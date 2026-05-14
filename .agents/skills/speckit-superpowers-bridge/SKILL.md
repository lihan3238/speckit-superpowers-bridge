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

## Execution Rules

1. Set handoff status to `executing` before making implementation changes:
   ```powershell
   .\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status executing -Actor codex
   ```
2. Run the guard before using any potentially overlapping command:
   ```powershell
   .\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\guard-command.ps1 -Action superpowers.subagent-driven-development -Actor codex
   ```
3. Execute `tasks.md` phase by phase and keep checkboxes updated.
4. Include `spec.md`, `plan.md`, `tasks.md`, and this denylist in every subagent prompt:
   - Deny `speckit.implement`
   - Deny `superpowers:brainstorming`
   - Deny `superpowers:writing-plans`
   - Do not add requirements outside Spec Kit artifacts
5. Use Superpowers skills for implementation discipline:
   - `using-git-worktrees` when an isolated workspace is requested or already available.
   - `test-driven-development` for feature, bugfix, refactor, or behavior changes.
   - `systematic-debugging` for failures or unexpected behavior.
   - `subagent-driven-development` when explicitly allowed and tasks are independent; otherwise use `executing-plans`.
   - `requesting-code-review`, `verification-before-completion`, and `finishing-a-development-branch` before completion.
6. Do not add requirements beyond `spec.md`, `plan.md`, and `tasks.md`.
7. If the task list is wrong or incomplete, stop implementation and set:
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
