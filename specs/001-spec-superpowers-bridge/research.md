# Research: Spec Kit Superpowers Bridge

## Decision: Keep the bridge repo-local for v1

**Decision**: Implement as a local Spec Kit extension plus local Codex/Claude bridge skills, not as a marketplace package or global Superpowers plugin modification.

**Rationale**: The user goal is fastest usable behavior with minimal overlap and no missing functionality. The existing prototype already works locally and has guard/log/rollback tests. Publishing or editing global plugin caches would add upgrade and compatibility risk without improving the immediate workflow.

**Alternatives considered**:
- Marketplace-style package: rejected for v1 because it adds release/distribution work before the protocol is validated.
- Editing global Superpowers skills: rejected because project-level instructions are easier to test, safer to roll back, and do not affect other repos.

## Decision: Use AGENTS.md as the master protocol

**Decision**: `AGENTS.md` is the canonical cross-agent bridge protocol. `CLAUDE.md` is a Claude Code supplement that must direct Claude Code to read `AGENTS.md` before applying Claude-specific guidance.

**Rationale**: Codex and Claude Code do not share the same primary context files. A single master protocol avoids duplicated rules drifting apart. Claude Code supports project memory in `CLAUDE.md`, while Codex supports repository guidance in `AGENTS.md`.

**Alternatives considered**:
- Duplicate complete rules in both files: rejected because drift would be likely.
- Put all rules in `CLAUDE.md`: rejected because Codex may not read it.

## Decision: Separate command IDs from agent invocation syntax

**Decision**: Use dotted names for internal Spec Kit/extension command IDs, but document concrete agent invocation forms separately:
- Internal command ID: `speckit.plan`, `speckit.superpowers.guard`
- Codex invocation: `$speckit-plan`
- Claude Code invocation: `/speckit-plan`

**Rationale**: Local official Claude integration skills are named with hyphens, and the generated Claude skill instructions state that hook command names with dots are converted to hyphens for slash commands. Treating dotted names as internal IDs avoids hard-coding the wrong user command string.

**Alternatives considered**:
- Document Claude commands as `/speckit.plan`: rejected for concrete usage because the installed Claude skill names and hook guidance use hyphens.
- Only document one default integration's style: rejected because Spec Kit may switch `default_integration` while both integrations remain installed.

## Decision: Keep official Spec Kit skills vendor-managed

**Decision**: Do not modify `.agents/skills/speckit-*` or `.claude/skills/speckit-*`. Put bridge-specific behavior in `.agents/skills/speckit-superpowers-bridge/` and `.claude/skills/speckit-superpowers-bridge/`.

**Rationale**: Spec Kit integration manifests track official generated files. Integration upgrades can detect local modifications and may refuse overwrites. Separate bridge skills keep custom behavior stable and easier to review.

**Alternatives considered**:
- Patch official `speckit-implement` to disable implementation: rejected because the guard can block it while preserving official files.
- Patch official planning/task skills to mention Superpowers: rejected because `AGENTS.md`, `CLAUDE.md`, and the bridge skill can provide the policy without forking vendor assets.

## Decision: Enforce single-writer ownership in handoff state

**Decision**: Extend `.specify/superpowers-handoff.json` with minimal ownership metadata:
- `artifact_owner`: current write owner for Spec Kit control artifacts
- `review_only_agents`: agents allowed to review but not write
- optional `actor` on guard calls and log events

**Rationale**: Guarding by handoff status alone prevents mid-execution Spec Kit changes, but it does not prevent Codex and Claude Code from concurrently changing the same Spec Kit artifacts before handoff. A lightweight ownership field covers the concurrency risk without a lock daemon.

**Alternatives considered**:
- File-system lock files: rejected for v1 because agents can ignore stale locks and the status file already exists.
- Git-only conflict handling: rejected because semantic overwrite can happen before Git reports a conflict.

## Decision: Reuse existing log and snapshot model

**Decision**: Continue appending JSONL events to `.specify/bridge-events.jsonl` and snapshot only Spec Kit control artifacts under `.specify/bridge-snapshots/`.

**Rationale**: The existing rollback boundary is clean: bridge state and Spec Kit artifacts are restored by bridge scripts, while source code rollback remains Git/worktree responsibility.

**Alternatives considered**:
- Snapshot all repository files: rejected because it duplicates Git and increases rollback risk.
- No snapshots: rejected because early protocol testing needs a quick way to undo handoff/control-artifact mistakes.

## Sources Checked

- Spec Kit integrations reference: https://github.github.io/spec-kit/reference/integrations.html
- Codex `AGENTS.md` guidance: https://developers.openai.com/codex/guides/agents-md
- Claude Code memory guidance: https://docs.anthropic.com/en/docs/claude-code/memory
- Claude Code skills guidance: https://docs.anthropic.com/en/docs/claude-code/skills
- Local generated Claude integration skill: `.claude/skills/speckit-plan/SKILL.md`
