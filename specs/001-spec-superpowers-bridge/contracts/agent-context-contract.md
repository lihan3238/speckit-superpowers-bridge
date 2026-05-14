# Contract: Agent Context Files

## Master Protocol

`AGENTS.md` is the canonical bridge protocol for all agents. It must define:

- Spec Kit owns spec, plan, tasks, checklists, and analysis.
- Superpowers owns implementation discipline after handoff.
- `speckit.implement` is blocked when handoff executor is `superpowers`.
- Superpowers `brainstorming` and `writing-plans` are blocked for active Spec Kit features unless Spec Kit artifacts are explicitly discarded.
- `tasks.md` is the only implementation contract.
- One agent owns Spec Kit artifact writes at a time.
- Official generated Spec Kit skills are vendor-managed and must not be hand-edited.
- Command syntax mapping:
  - Internal command IDs: `speckit.plan`, `speckit.superpowers.guard`
  - Codex: `$speckit-plan`
  - Claude Code: `/speckit-plan`

## Claude Supplement

`CLAUDE.md` must:

- Instruct Claude Code to read `AGENTS.md` first.
- Keep only Claude-specific additions.
- State that official `.claude/skills/speckit-*` are vendor-managed.
- Point Claude Code to `.claude/skills/speckit-superpowers-bridge/SKILL.md` for bridge execution.
- Use slash-hyphen examples such as `/speckit-plan` and `/speckit-tasks`.
- Tell Claude Code to pass `-Actor claude` to bridge guard and handoff scripts.

## Conflict Rule

If `AGENTS.md` and `CLAUDE.md` conflict, `AGENTS.md` wins and `CLAUDE.md` must be corrected.

## Validation

- `AGENTS.md` contains the bridge ownership boundary.
- `CLAUDE.md` references `AGENTS.md`.
- Both files reference concrete command syntax.
- Neither file instructs agents to edit official generated `speckit-*` skills.
