<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan:
`specs/003-bridge-cross-platform-scripts/plan.md`
<!-- SPECKIT END -->

## Claude Code Supplement

- The project's primary design reference is the dev.to comparison article — see the "Primary Design Reference" section in `AGENTS.md`. Consult it first on any architectural question.
- `AGENTS.md` is the master bridge protocol and wins on conflict.
- `AGENTS.md` owns language routing; Claude Code should follow it before applying Claude-specific command style notes.
- Claude Code should use slash commands generated from skill names, such as `/speckit-plan`, `/speckit-tasks`, and `/speckit-superpowers-bridge`.
- Internal Spec Kit command IDs may still be dotted, such as `speckit.plan` or `speckit.speckit-superpowers-bridge.guard`.
- Treat official generated `.claude/skills/speckit-*` files as vendor-managed. Do not hand-edit them; custom bridge behavior belongs in `.claude/skills/speckit-superpowers-bridge/`.
- For implementation handoff, use `.claude/skills/speckit-superpowers-bridge/SKILL.md` and pass `-Actor claude` to bridge guard or handoff scripts.
- The bridge guard enforces 5 hardcoded rules in `guard-command.ps1`: deny `speckit.implement` during executing handoff, deny `superpowers:writing-plans` / `:brainstorming` when active feature has design artifacts, deny `speckit.constitution` during executing handoff, allow other `speckit.*`, default allow. There is no matrix lookup.
