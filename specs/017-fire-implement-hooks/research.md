# Research: How Spec Kit fires implement hooks (and why the bridge must mirror it)

**Feature**: `017-fire-implement-hooks` | **Date**: 2026-08-17

## R1 — Spec Kit hooks are agent-driven markdown, not CLI

Inspected the installed Spec Kit CLI (`specify_cli` package) to confirm the
hook mechanism:

- `specify_cli/extensions.py` `HookExecutor` registers hooks into
  `.specify/extensions.yml` (per-extension `hooks` mapping → list of
  `{extension, command, enabled, optional, prompt, condition}` entries).
- `HookExecutor._render_hook_invocation(command)` maps a dotted command id to an
  agent-specific invocation string: `speckit.git.commit` →
  `$speckit-git-commit` (Codex, `ai_skills`), `/speckit-git-commit` (Claude
  Code), `/skill:...` (Kimi), etc. Dots become hyphens.
- The actual firing happens in the **command markdown**, not in a script. The
  bundled `core_pack/commands/implement.md` contains:
  - "Pre-Execution Checks" → reads `.specify/extensions.yml`, looks up
    `hooks.before_implement`, filters `enabled: false` and non-empty
    `condition`, and fires each executable hook (mandatory = execute + wait,
    optional = prompt).
  - "Mandatory Post-Execution Hooks" → same for `hooks.after_implement`.

There is **no** `specify hooks run <event>` CLI command and no workflow step
named `run_hooks` in the workflow engine (`specify_cli/workflows/` has no hook
step). Conclusion: hooks are dispatched by the agent following command-markdown
instructions.

## R2 — The gap in the bridge

The bridge's `execute` command (`commands/speckit.speckit-superpowers-bridge.execute.md`)
and both SKILL peers never read `hooks.before_implement` / `hooks.after_implement`.
They replace `speckit.implement` without reproducing its hook sections, so user
and third-party hooks registered on those events never fire.

## R3 — The self-guard hazard

The bridge's own `extension.yml` registers `before_implement` →
`speckit.speckit-superpowers-bridge.guard` (optional: false). The guard command
markdown maps the triggering hook to an action (`before_implement` →
`speckit.implement`), and `guard-command.sh` rule 1 denies `speckit.implement`
when the handoff is `executing`. If the bridge fired `before_implement` hooks
naively it would invoke its own guard while `executing`, and deny itself.

Therefore the dispatch must **skip hooks whose `extension` is
`speckit-superpowers-bridge`**. The bridge registers no `after_implement` hook,
so the rule is trivially satisfied there but is kept uniform for future-proofing.

## R4 — Design choice: mirror Spec Kit's markdown mechanism (Principle VI)

Two candidate implementations were considered:

1. **New script** (`run-hooks.sh` / `run-hooks.ps1`) that reads
   `.specify/extensions.yml` and invokes hook commands deterministically.
2. **Markdown instructions** mirroring `implement.md` in the bridge's
   `execute.md` + SKILL peers.

Chosen: **(2)**. Spec Kit already owns this exact mechanism, so a script would
re-implement upstream's hook dispatch and violate constitution Principle VI
("does upstream already do this?" → yes; "is upstream the right place?" → yes;
the bridge only needs to *compose* it, not duplicate it). Markdown also keeps
the bridge thin (Principle I) and automatically stays consistent with how Spec
Kit renders invocations per agent.

The trade-off (agent must follow instructions rather than a deterministic
runner) is exactly the trade-off Spec Kit itself makes, so it is the correct
native behavior to inherit.

## R5 — Ordering relative to the handoff transition

Mirroring `speckit.implement` (before hooks fire before the outline, after hooks
fire before the completion report):

- `before_implement` fires **before** the handoff transitions `ready` →
  `executing`.
- `after_implement` fires **after** the handoff transitions `executing` →
  `complete`.

This keeps the bridge's existing 8-step orchestration and inserts the hook
dispatch as two new lifecycle points (steps 3 and 10 after renumbering).

## R6 — Test strategy

Because the dispatch is instruction-only, the deterministic CI assertion is a
grep-based smoke test over the three authoritative files (execute.md + both
SKILL peers), asserting presence of `before_implement`, `after_implement`, the
skip-own-guard rule, and the before/after ordering. Live hook firing is verified
in the end-user sandbox (deferred to the release step, as with prior features).
