<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan:
`specs/005-marketplace-alignment/plan.md`
<!-- SPECKIT END -->

## Claude Code Supplement

- The project's primary design reference is the dev.to comparison article — see the "Primary Design Reference" section in `AGENTS.md`. Consult it first on any architectural question.
- `AGENTS.md` is the master bridge protocol and wins on conflict.
- `AGENTS.md` owns language routing; Claude Code should follow it before applying Claude-specific command style notes.
- Claude Code should use slash commands generated from skill names, such as `/speckit-plan`, `/speckit-tasks`, and `/speckit-speckit-superpowers-bridge-execute`.
- Internal Spec Kit command IDs may still be dotted, such as `speckit.plan` or `speckit.speckit-superpowers-bridge.guard`.
- Treat official generated `.claude/skills/speckit-*` files as vendor-managed. Do not hand-edit them; custom bridge behavior belongs in `.claude/skills/speckit-superpowers-bridge/`.
- For implementation handoff, use `.claude/skills/speckit-superpowers-bridge/SKILL.md` and pass `-Actor claude` to bridge guard or handoff scripts.
- For on-demand non-overlap audits, invoke `/speckit-speckit-superpowers-bridge-parity` (covers the disposition matrix, per-agent skill parity, and verified-version drift). See `.specify/extensions/speckit-superpowers-bridge/disposition-matrix.json` and `verified-versions.json` for the data this check consumes.
- For install diagnostics, invoke `/speckit-speckit-superpowers-bridge-audit`.
- Before completion, invoke `/speckit-speckit-superpowers-bridge-validate` to run the end-to-end validation pass.
- Before opening the upstream Spec Kit catalog PR, invoke `/speckit-speckit-superpowers-bridge-submission-checklist`. Before tagging a release, invoke `/speckit-speckit-superpowers-bridge-cleanup-audit`.
- The disposition matrix is the authoritative non-overlap policy; the guard consults it before falling back to legacy rules. Constitution edits during an `executing` handoff are denied; checklist generation is always allowed.
