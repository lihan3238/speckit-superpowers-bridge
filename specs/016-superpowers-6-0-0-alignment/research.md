# Research: Superpowers 5.1.0 → 6.0.0 upstream-impact analysis

**Feature**: `specs/016-superpowers-6-0-0-alignment/` | **Date**: 2026-06-17

**Method**: Direct source-tree diff of the two cached plugin releases plus a
grep audit of the bridge surface. Both 5.1.0 and 6.0.0 are present on disk under
`~/.claude/plugins/cache/claude-plugins-official/superpowers/`, so the diff is
authoritative (not release-note paraphrase).

## R1 — Installed/live versions (reproducible)

```bash
# bridge env: which Superpowers is live?
grep -o '"version": "[0-9.]*"' \
  ~/.claude/plugins/cache/claude-plugins-official/superpowers/6.0.0/.claude-plugin/plugin.json | head -1
# -> "version": "6.0.0"

jq -r '.plugins["superpowers@claude-plugins-official"][0].version' \
  ~/.claude/plugins/installed_plugins.json    # -> 6.0.0  (gitCommitSha f2cbfbef…)

specify --version          # -> specify 0.10.2  (Spec Kit side unchanged)
codex --version            # -> codex-cli 0.140.0
claude --version           # -> 2.1.178 (Claude Code)
```

## R2 — Skill *name* set is identical across the major bump

```bash
SP=~/.claude/plugins/cache/claude-plugins-official/superpowers
diff <(ls -1 $SP/5.1.0/skills) <(ls -1 $SP/6.0.0/skills)
# -> (no output): same 14 skills, none added / removed / renamed.
```

The bridge invokes Superpowers **by skill name** only. Because no name changed,
the bridge's invocation contract is intact by construction.

## R3 — What the 6.0.0 major actually changed (from `diff -rq` + RELEASE-NOTES)

| 6.0.0 change | Where it lives | Bridge-impact verdict |
|---|---|---|
| Two per-task reviewer prompts → one `task-reviewer-prompt.md`; `spec-reviewer-prompt.md` + `code-quality-reviewer-prompt.md` deleted; new `scripts/` (`task-brief`, `review-package`) | **inside** `skills/subagent-driven-development/` (dispatched via relative `./…` paths by the skill) | **Transparent** — bridge dispatches the skill by name, never the prompt files |
| Global worktree dir `~/.config/superpowers/worktrees/` removed; worktrees now land in project `.worktrees/` | **inside** `using-git-worktrees` + `finishing-a-development-branch` | **Transparent** to protocol; worktree *location* is user-observable. Bridge never created/managed that dir |
| Vendor-neutral prose ("dispatch a subagent" / "your instructions file"); per-harness tool refs added (`claude-code-tools.md`, `antigravity-tools.md`, `pi-tools.md`) | `skills/using-superpowers/references/` and prose across skills | **No bridge change** — bridge already ships dual `.claude`/`.agents`; `.agents` prose already harness-neutral |
| `writing-plans` adds Global Constraints + per-task Interfaces blocks; right-sizing guidance | `skills/writing-plans/SKILL.md` (a *producer*) | **N/A** — bridge **disables** `writing-plans`; Spec Kit owns `tasks.md` |
| `executing-plans` / `subagent-driven-development` "note … global constraints" when loading a plan | the *consumers* | **Contract holds** — they still load a plan-as-task-list and only *note* constraints if present; `tasks.md` needs no new blocks |
| Three new harnesses (Kimi Code, Pi, Antigravity); `evals/` submodule; hooks-codex split | additive top-level | **Additive** — no bridge impact |
| systematic-debugging no longer force-trips extended thinking; Windows hook write-error fix; misc | bug fixes inside skills | **Transparent** — bridge dispatches by name |

### Consumer-contract confirmation (the one non-obvious risk)

The only way a 6.0.0 change could reach the thin bridge is if a skill the bridge
*invokes* changed what it **consumes**. The bridge routes implementation through
`executing-plans` (SKILL.md step 4) and optionally `subagent-driven-development`.
Diff of `executing-plans/SKILL.md` 5.1.0→6.0.0:

```
14c14  (platform note: more harnesses listed)
22c22  < 4. If no concerns: Create TodoWrite and proceed
       > 4. If no concerns: Create todos for the plan items and proceed
```

Both diffs are vendor-neutral prose; the process is still "Load plan → review →
execute all tasks." `subagent-driven-development` 6.0.0 reads "Read plan, note
context and global constraints, create todos" — it *notes* constraints if the
plan has them and does not *require* them. Spec Kit `tasks.md` (a checkbox task
list) satisfies both consumers unchanged.

## R4 — Bridge surface references NONE of the changed internals (grep audit)

Run from repo root; `.git`, `specs/**` history, and CHANGELOG excluded as
non-surface:

```bash
# renamed reviewer prompt files + new helper scripts
grep -rn -i "spec-reviewer\|code-quality-reviewer\|task-reviewer\|review-package\|task-brief" \
  --include="*.md" --include="*.sh" --include="*.ps1" --include="*.json" --include="*.yml" . \
  | grep -v "^./.git/" | grep -v "specs/0"
# -> (no hits across bridge SKILLs, commands, scripts, extension.yml, marketplace/)

# global worktree path removed in 6.0.0
grep -rn "config/superpowers/worktrees" --include="*.md" --include="*.sh" --include="*.ps1" .
# -> (no hits)
```

The bridge SKILL.md execution flow (`.claude` + `.agents`) names only:
`executing-plans`, `test-driven-development`, `systematic-debugging`,
`verification-before-completion`, `requesting-code-review`,
`finishing-a-development-branch` (and the guarded `writing-plans`/
`brainstorming`). All unchanged names → confirmed clean.

## R5 — Precedent

This is structurally identical to **feature 011 (v0.6.0)**, which aligned the
bridge to Superpowers **5.1.0**: that bump's breaking changes (slash-command
removal, `code-reviewer` named-agent removal, provenance-scoped worktree
cleanup) were also all internal to upstream skills, the bridge surface grepped
clean, and the remediation was version-bump + evidence + an informational
upstream note. The 6.0.0 alignment follows the same shape — the difference is
only that it is a *major* upstream bump, which is why it earns a MINOR bridge
bump (v1.1.0) as a visible "verified against the Superpowers 6.x line"
milestone rather than a patch.

## R6 — Decision

No bridge runtime change. Ship v1.1.0 as a compatibility-alignment + evidence
refresh. Constitution Principle VI (Native-First / Trust Upstream Growth) is the
governing principle and is *satisfied by not changing the bridge*, not by
patching it to track the major.
