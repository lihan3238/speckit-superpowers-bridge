<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan
<!-- SPECKIT END -->

## Claude Code Supplement

- `AGENTS.md` is the master bridge protocol and wins on conflict.
- Claude Code should use slash commands generated from skill names, such as `/speckit-plan`, `/speckit-tasks`, and `/speckit-superpowers-bridge`.
- Internal Spec Kit command IDs may still be dotted, such as `speckit.plan` or `speckit.superpowers.guard`.
- Treat official generated `.claude/skills/speckit-*` files as vendor-managed. Do not hand-edit them; custom bridge behavior belongs in `.claude/skills/speckit-superpowers-bridge/`.
- For implementation handoff, use `.claude/skills/speckit-superpowers-bridge/SKILL.md` and pass `-Actor claude` to bridge guard or handoff scripts.
- For on-demand non-overlap audits, invoke `/speckit-superpowers-parity` (covers the disposition matrix, per-agent skill parity, and verified-version drift). See `.specify/extensions/speckit-superpowers-bridge/disposition-matrix.json` and `verified-versions.json` for the data this check consumes.
- The disposition matrix is the authoritative non-overlap policy; the guard consults it before falling back to legacy rules. Constitution edits during an `executing` handoff are denied; checklist generation is always allowed.
