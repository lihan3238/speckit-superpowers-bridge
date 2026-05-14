# Compatibility Gap Log: Polish & Publish

**Feature**: 004-polish-and-publish
**Last updated**: 2026-05-15

Live log of compatibility gaps observed during agent validation runs against this
feature's protocol. Append-only after a row is added; rows are never deleted.
Schema: see [contracts/compat-gap-record-contract.md from feature 002](../002-complete-bridge-protocol/contracts/compat-gap-record-contract.md).

## Records (carried forward from feature 002)

| ID    | Severity | Description | Proposed Resolution | Status | Closes In | Related | Observed At | Observed By |
|-------|----------|-------------|---------------------|--------|-----------|---------|-------------|-------------|
| CG-006 | P2 | `.specify/extensions/speckit-superpowers-bridge/commands/speckit.superpowers.handoff.md` shows the hook's executable invocation as `update-handoff.ps1 -Status ready -Actor codex` — the `-Actor codex` is hardcoded. When the after-tasks hook fires from Claude Code, the handoff is written with `artifact_owner: codex` and `review_only_agents: [claude]`, locking Claude out of executing its own implementation. Observed live during the feature 002 session. | Replace hard-coded `-Actor codex` in the handoff command template with a documented resolution-order pointer (explicit arg → `SPECKIT_BRIDGE_ACTOR` env → `default_integration` → `unknown`). Update both bridge SKILL.md files to invoke handoff with explicit `-Actor` per the active agent. See plan.md Decision #1 + #9. | OPEN | 004-polish-and-publish | FR-003, SC-001 | 2026-05-15 | claude |

## Records discovered in feature 004 (live validation)

_None yet — populate as the validation pass and live runs surface them._

## How to append

When a future validation run on this branch surfaces a new gap, append a new row at the bottom following the schema in `specs/002-complete-bridge-protocol/contracts/compat-gap-record-contract.md`. Use the next sequential CG-NNN ID (continuing from CG-006). Do not edit existing rows except to flip `Status` and add `Closes In` when a fix lands.
