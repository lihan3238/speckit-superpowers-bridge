# Phase 0 Research: Trim To Thin Bridge

**Feature**: 006-trim-to-thin-bridge
**Date**: 2026-05-15

This research resolves the design decisions called out in `plan.md` Technical Context — the surfaces where the trim faces a real choice rather than a mechanical deletion.

## R1 — Removing `docs/` from git tracking while preserving local files

**Decision**: Use `git rm -r --cached docs/` followed by adding `docs/` (and `/docs/` for the root-level form) to `.gitignore` in the same commit. The files stay on the maintainer's disk; only the index entries are removed.

**Rationale**:
- `git rm --cached` is the canonical pattern for "stop tracking, keep on disk." It removes only from the index, not the working tree.
- Committing the `.gitignore` change in the same commit prevents the next `git status` from re-staging the directory.
- The `docs/release-runbook.md` is the only currently-tracked file under `docs/`; future maintainer-only notes the user adds locally will be silently ignored.

**Alternatives considered**:
- `git rm -rf docs/` (hard delete): rejected — user said "本地保留" (keep locally).
- Moving `docs/` to `.private-docs/` and gitignoring that: rejected — needless rename and breaks any external references.
- Leaving `docs/` tracked but writing maintainer-only files into a sibling untracked folder: rejected — clutters the repo root and confuses the convention.

**Implementation note for tasks**:
- The bridge's own `docs/parameter-reference.md` under `.specify/extensions/speckit-superpowers-bridge/docs/` is a separate file and is being **deleted entirely** (parameter reference belongs in the slimmed SKILL.md if anywhere). It's not affected by the root-level `docs/` gitignore.

---

## R2 — Backward-compat read of v2/v3 handoff JSON (FR-009)

**Decision**: Rely on PowerShell's default `ConvertFrom-Json` behavior (which silently ignores extra properties when binding to a property-by-property model) plus an explicit "read-tolerant, write-minimal" discipline in `update-handoff.ps1`:

1. On read: load the JSON, copy known fields into the in-memory state object, ignore unknown fields without warning. Do not error on missing optional fields (`archive_history`, `autonomous_mode`, `resume_context`).
2. On write: emit only the v1 shape fields listed in FR-006. Do not preserve unknown fields through a round-trip; their presence on read is forgiven, but they are not echoed back.

**Rationale**:
- PowerShell's `ConvertFrom-Json` produces a `PSCustomObject` whose property access is forgiving — `.archive_history` returns `$null` if the field is absent. We don't need a schema validator.
- The user's directive ("做好兼容就行") accepts that we drop the rich v3 state; we just don't crash on it.
- Re-emitting unknown fields would create a hidden upgrade path back to v3 shape and complicate the simplification. Keeping new writes minimal is consistent with the trim's spirit.

**Alternatives considered**:
- Round-tripping unknown fields: rejected — keeps v3 shape alive forever, defeats the simplification.
- Hard-fail on v3 fields and ask user to delete the handoff: rejected — bad UX for in-flight features at upgrade time.
- Adding a `--migrate` mode to update-handoff: rejected — adds custom feature surface, exactly what the trim removes.

**Implementation note for tasks**:
- The simplified handoff JSON schema (`contracts/handoff.v1.schema.json`) MUST set `additionalProperties: true` so v2/v3 documents validate against it (we only check the v1 fields we care about). This is a deliberate inversion of the strict `additionalProperties: false` from feature 002.
- Add one smoke test case: write a fake v3-shape handoff to a temp file, call `update-handoff.ps1 -Action read` (or a one-shot reader helper), confirm no error and the v1 fields parse correctly.

---

## R3 — Hardcoded guard rule set (FR-007)

**Decision**: The 5 hardcoded rules inside `guard-command.ps1`, in this evaluation order:

1. If the requested action is `speckit.implement` AND `superpowers-handoff.json` exists AND status is `executing` → **DENY** with reason `"speckit.implement blocked while superpowers handoff is executing"`.
2. If the requested action is `superpowers:writing-plans` OR `superpowers:brainstorming` AND the active feature directory has both `spec.md` AND `plan.md` → **DENY** with reason `"native superpowers planning is forbidden while spec kit owns design artifacts"`.
3. If the requested action is `speckit.constitution` AND `superpowers-handoff.json` exists AND status is `executing` → **DENY** with reason `"constitution edits blocked during active handoff; mark blocked first"`.
4. If the requested action starts with `speckit.` (any Spec Kit command other than those above) → **ALLOW** (Spec Kit design surface is always allowed; checklist generation is always allowed per the constitution).
5. **Default**: **ALLOW** (fail-open for unknown actions — the trim accepts this because the guard is no longer the authoritative classifier; the agent's own skill knows what to invoke).

**Rationale**:
- Rules 1–3 are the only enforcement that meaningfully prevents drift; everything else the old matrix did was advisory.
- Rule 4 codifies the disposition matrix's "design commands are always allowed" rule without consulting the matrix.
- Rule 5 (fail-open) is a tradeoff: the old matrix could deny unknown actions; the trim assumes the worst case is benign because the bridge doesn't drive execution — the agent does. The agent reading SKILL.md will know not to do something silly.

**Alternatives considered**:
- Fail-closed (default DENY): rejected — too aggressive without the matrix; would block every new Spec Kit command until a maintainer edits the script.
- Move rules into JSON config: rejected — that IS the matrix the trim removes.
- Drop rule 3 (constitution-during-executing): rejected — Principle II demands this and it's only one branch.

**Implementation note for tasks**:
- Each rule is a literal `if`/`elseif` block; no helper functions, no data lookups.
- The 4 deny reasons go directly into the log entry written to `bridge-events.jsonl`.

---

## R4 — Slimmed bridge SKILL.md content (FR-004)

**Decision**: Each `SKILL.md` (Claude + Codex peers) is restructured to ≤100 lines following this outline:

1. **Frontmatter** (5 lines): name, description, model, tags.
2. **Purpose** (8 lines): one paragraph stating "this skill orchestrates native Spec Kit + Superpowers skills; it does not implement custom discipline."
3. **When to use** (4 lines): bulleted list — when a feature has `spec.md`+`plan.md`+`tasks.md` and the user invokes the bridge command/slash.
4. **What this skill does** (20 lines): numbered steps the agent should follow:
   1. Read `.specify/superpowers-handoff.json` to find the active feature directory.
   2. Read `tasks.md`, `plan.md`, `spec.md` from that directory.
   3. Call `update-handoff.ps1 -Action start -Actor <agent>` to transition to `executing`.
   4. Invoke `superpowers:executing-plans` with `tasks.md` as the plan input.
   5. At each Superpowers TDD cycle, the agent invokes native `test-driven-development` and `debugging` skills as Superpowers prescribes.
   6. At completion of all tasks, invoke `superpowers:verification-before-completion`.
   7. Invoke `superpowers:requesting-code-review`.
   8. Invoke `superpowers:finishing-a-development-branch`.
   9. Call `update-handoff.ps1 -Action complete` to transition to `complete`.
5. **Boundary rules** (8 lines): "do not run `speckit.implement` during executing handoff; do not invoke `superpowers:writing-plans` or `:brainstorming` when Spec Kit artifacts exist." (The same policy as the hardcoded guard, expressed in prose.)
6. **Cross-agent notes** (6 lines): "the same SKILL.md exists in `.claude/skills/...` and `.agents/skills/...`; switch agents by re-running with `-Actor <new>`; AGENTS.md is the master."
7. **When something goes wrong** (8 lines): if implementation surfaces missing requirements → call `update-handoff.ps1 -Action block -BlockedReason "<why>"`; the bridge returns control to Spec Kit.

**Rationale**:
- The current 149-line Claude SKILL.md and 146-line Codex peer carry custom-feature documentation (matrix lookups, parity directives, event types, snapshot policies) that are all being cut. Removing those references gets us to ~100 lines naturally.
- The remaining content IS the bridge — orchestration prose telling the agent which native skills to call when.

**Alternatives considered**:
- Different content per agent: rejected — Principle III demands identical behavior; identical content is the simplest enforcement.
- Even shorter (~50 lines): rejected — the 9 orchestration steps + boundary rules are the core value; shorter risks losing them.

**Implementation note for tasks**:
- One task creates the new Claude SKILL.md; a parallel task creates the Codex peer with identical content (only the frontmatter `name` may differ by convention).

---

## R5 — `common-actor-resolution.ps1`: keep or inline?

**Decision**: Keep `common-actor-resolution.ps1` as a small (≤30 lines) dot-sourced helper. The 3-step resolution chain (explicit `-Actor` → `SPECKIT_BRIDGE_ACTOR` env → `"unknown"`) is used by all 3 retained scripts, so a helper is DRY-er than 3 copies of the same 20 lines.

**Rationale**:
- DRY: the resolver is called from `update-handoff.ps1`, `guard-command.ps1`, and `auto-archive-handoff.ps1`. Inlining triples maintenance cost.
- Constitutional fit: a 30-line dot-sourced PowerShell file at the same surface as the 3 callers is well within Principle I.
- Backward-compat: the existing helper already implements a 4-step chain (explicit → env → `default_integration` → `"unknown"`). Trimming the `default_integration` consultation is a 5-line edit.

**Alternatives considered**:
- Inline into each script: rejected — duplicates the 3-step logic and the env var name three times.
- Keep the 4-step chain unchanged: rejected — `default_integration` lives in `.specify/integration.json` which has its own simplification path; the 3-step chain is sufficient per FR-008.
- Move to a `lib/` subfolder: rejected — over-organization for one helper.

**Implementation note for tasks**:
- The helper file counts toward the script budget but does NOT count toward the 3-script hard cap (FR-001 enumerates the 3 caps as `update-handoff.ps1`, `guard-command.ps1`, `auto-archive-handoff.ps1`; the helper is a dot-sourced library, not a callable script).
- The simplification removes the `default_integration` branch and shrinks the function from 58 lines to ~25 lines.

---

## R6 — `update-handoff.ps1` parameter surface after trim (FR-006, FR-010)

**Decision**: Retain these parameters; drop the v3-specific ones:

| Parameter | Disposition | Notes |
|-----------|-------------|-------|
| `-Action` (`start`/`update`/`complete`/`block`/`read`/`reset`) | KEEP | Core verb. `read` and `reset` may be merged into `start`/`complete` to save lines. |
| `-Actor` | KEEP | Used by Principle III. |
| `-FeatureDirectory` | KEEP | Used to set/clear which feature is active. |
| `-ClearFeatureDirectory` | KEEP | Load-bearing for `auto-archive-handoff.ps1` per FR-010. |
| `-Status` | KEEP | Sets `ready`/`executing`/`complete`/`blocked`. |
| `-BlockedReason` | KEEP | Required when transitioning to `blocked`. |
| `-Notes` | KEEP | Free-form. |
| `-AppendArchiveEntry` | KEEP, optional | FR-010 allows drop; we keep it so `auto-archive-handoff.ps1` is simpler. The `archive_history` field becomes optional in the v1 schema. |
| `-AutonomousMode` | DROP | v3 introduction; removed per FR-006. |
| `-ResumeContext` | DROP | v3 introduction; removed. |
| `-PolicyRef` | DROP | Matrix is gone. |
| Any "set capabilities array" parameter | KEEP-MIN | `capabilities` field stays in the schema (FR-006 lists it) but the parameter may be hard-defaulted to `[]` if no caller needs it. |

**Rationale**:
- The kept set is the minimum required to satisfy the constitution's smooth-handoff principle.
- Dropping the v3 params is what makes the trim a trim; backward-read forgives their presence on read but doesn't write them.

**Alternatives considered**:
- Keep `-PolicyRef` for the bridge events log: rejected — the matrix it references is gone.
- Drop `-AppendArchiveEntry`: would force `auto-archive-handoff.ps1` to use a different mechanism. Rejected for simplicity.

**Implementation note for tasks**:
- Pre-trim `update-handoff.ps1` is 393 lines. Post-trim target is ~120 lines. The savings come from: removing v3 schema branches, removing matrix-aware event types, removing snapshot-id integration that's been moved elsewhere or accepted as state of nature.

---

## R7 — Marketplace listing refresh under 0.3.0 (FR-016, FR-019)

**Decision**: Update the 4 marketplace files to reflect 0.3.0:

1. `marketplace/catalog-entry.json`:
   - `version` → `0.3.0`
   - `provides.commands` → exactly 3 entries (execute, handoff, guard)
   - `description` → new prose: "A thin orchestrating bridge between Spec Kit (design) and Superpowers (implementation). Cross-agent (Codex + Claude Code). Native skills only."
   - `tags` → unchanged (6-tag locked set).
2. `marketplace/extensions-readme-row.md`: update the table row's description/version columns.
3. `marketplace/upstream-pr-body.md`: rewrite the body to describe 0.3.0; **keep the AI-assistance disclosure paragraph verbatim** per Spec Kit CONTRIBUTING.md. Update the "what's in this PR" bullets.
4. `marketplace/README.md`: brief update to describe the 0.3.0 listing.

**Rationale**:
- Marketplace is the bridge's external face; the four files are the canonical surface for catalog submission. Keeping all four is per the user's clarify answer.
- The AI-disclosure paragraph is a hard upstream requirement; it must not be lost in the rewrite.

**Alternatives considered**:
- Skip the marketplace refresh until ready to submit: rejected — the listing must match the shipped extension version.
- Slim to one file: rejected by clarify Q1.

**Implementation note for tasks**:
- One task per file. Bilingual parity does not apply to `marketplace/*` files; only the root READMEs are bilingual.

---

## R8 — README "When to Skip Spec Kit" section (FR-015, FR-021)

**Decision**: Add a new H2 section to both `README.md` and `README.zh-CN.md` titled `When to Skip Spec Kit` (English anchor preserved across both files per the bilingual-parity convention). Content:

> Not every change needs the full Spec Kit → bridge → Superpowers workflow. Use your judgment:
>
> | Change type | Recommended route |
> |-------------|-------------------|
> | Typo fix, single-line bug, tiny refactor | Invoke Superpowers directly. Skip `/speckit-specify`. |
> | New feature, multi-file refactor, anything requiring design decisions | Full flow: `/speckit-specify` → `/speckit-clarify` → `/speckit-plan` → `/speckit-tasks` → `/speckit-superpowers-bridge`. |
> | Investigation / spike with unknown scope | Start with Superpowers `brainstorming`; promote to full flow if a spec emerges. |
>
> The bridge no longer recommends this routing for you (the previous `recommend-route` command was removed in 0.3.0). You make the call.

**Rationale**:
- Replaces the deleted automated recommender with a human-readable decision table.
- Bilingual: the H2 anchor stays English (`when-to-skip-spec-kit`) for cross-link stability; the body is translated for `README.zh-CN.md`.

**Alternatives considered**:
- Put this in a separate document: rejected — README is the first place users look.
- Use a flowchart image: rejected — adds binary asset surface for marginal gain.

---

## R9 — Commit granularity for reversible trim (FR-018)

**Decision**: Structure the trim across **8 logical commits** in this order:

1. `chore(bridge): trim — remove parity-check, audit-install-state, validation-pass scripts + commands + tests` (5–6 files).
2. `chore(bridge): trim — remove submission-checklist, cleanup-audit, distribution-manifest scripts + commands + schema + tests` (6 files).
3. `chore(bridge): trim — remove recommend-route, emit-resume-signal, emit-skill-invocation, restore-snapshot scripts + commands + tests` (8 files; recommend-route is the standout per FR-021).
4. `chore(bridge): trim — remove disposition-matrix.json, verified-versions.json, common-actor-resolution simplification` (3 files modified, 2 deleted).
5. `feat(bridge): simplify update-handoff.ps1 to v1 schema; guard-command.ps1 to hardcoded rules` (3 files modified).
6. `feat(bridge): rewrite SKILL.md (Claude + Codex peers) for thin orchestrator role` (2 files).
7. `chore(repo): untrack docs/ and add to .gitignore; remove docs/parameter-reference.md from bridge` (2 files modified, 2 untracked/deleted).
8. `release(bridge): bump to 0.3.0 — extension.yml + marketplace/* + CHANGELOG + READMEs + extensions.yml hooks` (8 files modified).

**Rationale**:
- Each commit removes one logical feature group; a future reader can `git revert <hash>` any one of them to bring back exactly that capability.
- Order matters: removals first (commits 1–4), simplifications second (5–6), config/version bump last (7–8) so each intermediate commit leaves the repo in a consistent state.
- 8 commits comfortably satisfies SC-009's "≥ 3 distinct commits" requirement.

**Alternatives considered**:
- One big commit: rejected — violates FR-018 reversibility.
- More fine-grained (16+ commits): rejected — diminishing returns; some removals are not meaningfully separable (e.g., a script and its single test).

---

## Open items (none blocking)

All FRs in the spec are covered by the decisions above. No `NEEDS CLARIFICATION` markers remain. The plan is ready for Phase 1 design artifacts.
