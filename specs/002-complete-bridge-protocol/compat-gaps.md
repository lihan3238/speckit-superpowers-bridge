# Compatibility Gap Log: Complete Bridge Protocol

**Feature**: 002-complete-bridge-protocol
**Last updated**: 2026-05-15

Live log of compatibility gaps observed during agent validation runs against this
feature's protocol. Append-only after a row is added; rows are never deleted.
Schema: see [contracts/compat-gap-record-contract.md](contracts/compat-gap-record-contract.md).

## Records

| ID    | Severity | Description | Proposed Resolution | Status | Closes In | Related | Observed At | Observed By |
|-------|----------|-------------|---------------------|--------|-----------|---------|-------------|-------------|
| CG-001 | P1 | `.claude/skills/` is missing peer SKILL.md files for `speckit-git-commit`, `speckit-git-feature`, `speckit-git-initialize`, `speckit-git-remote`, `speckit-git-validate`. Spec Kit hooks reference these via `before_*` slots, but Claude Code cannot resolve the slash command surface, so the hooks effectively fail or get worked around with direct PowerShell invocations. | Mirror each SKILL.md from `.agents/skills/<id>/SKILL.md` to `.claude/skills/<id>/SKILL.md`. Scripts in `.specify/extensions/git/scripts/powershell/` are shared and unchanged. Per [research R7](research.md). | CLOSED-IN-FEATURE | 002-complete-bridge-protocol | FR-007, FR-009, SC-003, SC-004 | 2026-05-14 | claude |
| CG-002 | P1 | `speckit.superpowers.guard` and `speckit.superpowers.handoff` are declared in the bridge extension's `commands/` directory but neither agent's integration manifest exposes them as standalone slash commands. The `/speckit-superpowers-bridge` parent skill exists; the per-command surfaces do not. | Add `commands/speckit.superpowers.parity.md` to the extension, then re-run Spec Kit's integration refresh so both agent manifests pick up all three commands. Verify on Claude Code during validation. | CLOSED-IN-FEATURE | 002-complete-bridge-protocol | FR-007, FR-009 | 2026-05-15 | claude |
| CG-003 | P1 | The bridge guard denies any Spec Kit contract-change action when `superpowers-handoff.json.status == complete`, even when the current branch is a brand-new feature with no relationship to the completed one. Observed: feature 001 was `complete`; on feature 002 branch, `/speckit-clarify` was denied by the guard. | Update `guard-command.ps1` to differentiate "same-feature contract change while complete" (still deny) from "different-feature contract change while complete" (allow; recommend auto-archive). Add the `complete` → `ready` auto-archive transition path. Per [contracts/handoff-transitions-contract.md](contracts/handoff-transitions-contract.md). | CLOSED-IN-FEATURE | 002-complete-bridge-protocol | FR-015, SC-009 | 2026-05-15 | claude |
| CG-004 | P1 | The bridge guard requires `handoff.artifact_owner` to be set before any new feature's Spec Kit commands pass, but on a fresh feature there is no automatic mechanism to claim ownership for the active agent. The maintainer must manually invoke `update-handoff.ps1 -ArtifactOwner claude` first. | Have `auto-archive-handoff.ps1` (CG-003) accept an `-Actor` and set `artifact_owner` to that actor as part of resetting the file to `ready`. The wrapper invoked by `/speckit-specify` passes `-Actor claude` (or `codex`). | CLOSED-IN-FEATURE | 002-complete-bridge-protocol | FR-007, SC-009 | 2026-05-15 | claude |
| CG-005 | P3 | All bridge scripts (`guard-command.ps1`, `update-handoff.ps1`, `restore-snapshot.ps1`, the new `parity-check.ps1`, `auto-archive-handoff.ps1`) are PowerShell-only. A contributor on Linux or macOS cannot run them natively. | Port the four scripts to Bash equivalents under `.specify/extensions/speckit-superpowers-bridge/scripts/bash/` and `.specify/extensions/git/scripts/bash/`; mirror existing `<script>.sh` naming where Spec Kit already provides Bash variants of other scripts. | DEFERRED | 003-bridge-cross-platform-scripts (proposed follow-up) | FR-009 (Constraints) | 2026-05-15 | claude |
| CG-006 | P2 | `.specify/extensions/speckit-superpowers-bridge/commands/speckit.superpowers.handoff.md` shows the hook's executable invocation as `update-handoff.ps1 -Status ready -Actor codex` — the `-Actor codex` is hardcoded. When the after-tasks hook fires from Claude Code, the handoff is written with `artifact_owner: codex` and `review_only_agents: [claude]`, locking Claude out of executing its own implementation. Observed live during this session. | Make the handoff command template parameterize `-Actor` based on the calling agent (read from the integration context). Until then, document that Claude users must immediately re-claim ownership via `update-handoff.ps1 -ArtifactOwner claude -Status executing -Actor claude` after the hook fires. | OPEN | 002-complete-bridge-protocol | FR-007, FR-009, SC-003 | 2026-05-15 | claude |

## Lifecycle notes

- Rows above CG-005 are owned by this feature's implementation; the `Status` flips to `CLOSED-IN-FEATURE` when the corresponding task completes.
- CG-005 is explicitly `DEFERRED` and lists a proposed follow-up feature directory. SC-007 permits this provided the follow-up is named in the project backlog before this feature ships; add the follow-up feature directory or a GitHub issue as part of feature close-out.

## How to append

When a future validation run on this branch surfaces a new gap, append a new row at the bottom following the schema in [contracts/compat-gap-record-contract.md](contracts/compat-gap-record-contract.md). Use the next sequential CG-NNN ID. Do not edit existing rows except to flip `Status` and add `Closes In` when a fix lands.
