# Implementation Plan: Polish & Publish

**Branch**: `004-polish-and-publish` | **Date**: 2026-05-15 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `specs/004-polish-and-publish/spec.md`

**Primary Design Reference**: [Spec Kit vs Superpowers — Comprehensive Comparison (truongpx396, dev.to)](https://dev.to/truongpx396/spec-kit-vs-superpowers-a-comprehensive-comparison-practical-guide-to-combining-both-52jj). The article is the project's canonical source for combination patterns; this plan honors its assertions (Spec Kit owns WHAT; Superpowers owns HOW; explicit invocation > auto-trigger).

**Planning Constraint**: This feature is **operational polish + distribution**, not new product architecture. The lightest diff that closes the four P1 user stories (US1 autonomous+resume, US2 cross-agent correctness, US3 validation pass, US4 marketplace readiness) and lands the P3 routing recommender (US5). No new runtimes; no new data stores; reuse the matrix + handoff schema established in feature 002.

## Summary

Add the operational discipline + distribution discipline the bridge needs to be both *usable for long hands-off sessions* and *installable by other teams via the Spec Kit marketplace*. Five focused work-streams:

1. **Autonomous + resume context** (US1): add an `autonomous_mode` field to the handoff schema (schema_version 3); persist `current_task_id` + `current_skill` + `current_phase` so an interrupted session resumes with full context in its first message. The bridge SKILL.md gains a "resume signal" instruction.
2. **Cross-agent correctness** (US2): close CG-006 by replacing the hard-coded `-Actor codex` defaults with a resolution order (explicit arg → `SPECKIT_BRIDGE_ACTOR` env → `default_integration` → `unknown`); add `audit-install-state.ps1` to surface per-agent skill gaps, default-integration, git-extension state, script flavour, and skill-divergence (hash diff between `.agents/skills/<id>/SKILL.md` and `.claude/skills/<id>/SKILL.md`).
3. **Validation pass** (US3): new script `validation-pass.ps1` that walks the documented happy path and asserts each step; the bridge SKILL.md (both agents) is rewritten to issue **explicit `Skill` tool invocations** at named phases (Q1 of clarify), and every invocation is logged as a new `skill_invocation` event.
4. **Marketplace readiness** (US4): bilingual `README.md` (EN) + `README.zh-CN.md` (zh-CN), a `plugin-distribution-manifest.yml` listing what an install copies, a parity-check script for the README, and an audited `.gitignore` that separates plugin assets from project-private state.
5. **Routing recommender** (US5, P3): tiny addition to `/speckit-specify` that emits a one-line "consider going direct to Superpowers" suggestion when the description matches a small-scope heuristic. Advisory only; never auto-routes.

## Technical Context

**Language/Version**: PowerShell 5.1+ / 7.x (Windows-first; Linux/macOS via the deferred 003-bridge-cross-platform-scripts feature), Markdown, JSON, YAML. No new languages.
**Primary Dependencies**: Spec Kit `0.8.9` (per `verified-versions.json`), Superpowers runtime-exposed skill set, git ≥ 2.30. **No** new dependencies introduced by this feature.
**Storage**: Repository files only — extends `.specify/superpowers-handoff.json` (schema_version 3), `.specify/bridge-events.jsonl` (new `skill_invocation` event type), adds three new config/data files (`plugin-distribution-manifest.yml`, `README.zh-CN.md`, updated `.gitignore`). No databases, no daemons.
**Testing**: PowerShell smoke tests under `tests/` following the existing pattern. New suites: `test-actor-resolution.ps1`, `test-resume-signal.ps1`, `test-install-state-audit.ps1`, `test-skill-invocation-event.ps1`, `test-readme-bilingual-parity.ps1`, `test-distribution-manifest.ps1`, `test-routing-recommender.ps1`.
**Target Platform**: Windows-first PowerShell workspace; cross-platform deferred (CG-005 → 003).
**Project Type**: Local Spec Kit extension + per-agent skill pack — same shape as features 001 + 002.
**Performance Goals**: Install-state audit under 5 seconds; validation pass under 10 minutes (SC-005); resume-signal emission within the first 200 characters of the first non-tool message (SC-004); zero bridge-event-log overhead from `skill_invocation` events beyond the current append-only write.
**Constraints**: No edits to upstream Spec Kit installation tree or upstream Superpowers plugin cache; no hand-edits to officially generated `.agents/skills/speckit-*` (core 9) or `.claude/skills/speckit-*` (core 9); the bridge skill files on each agent ARE editable (this feature's main change site). Autonomous mode default OFF (FR-004 explicit). Routing recommender is advisory-only (US5 acceptance criteria).
**Scale/Scope**: ≤ 35 new/changed files in the repo; ≤ 7 new test suites; the four P1 user stories ship together, US5 (P3) is independent.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate | Status |
|---|---|---|
| I. Lightweight & Repo-Local | No new runtime, daemon, service, marketplace package; smallest diff that delivers the capability; no global plugin cache edits | **PASS** — all changes are repo files; the "marketplace listing metadata" is itself a repo file per the Spec Kit catalog-driven extension model, not a separately-packaged artifact |
| II. Design/Implementation Separation (NON-NEGOTIABLE) | No overlap between Spec Kit design ownership and Superpowers execution ownership; matrix is source of policy | **PASS** — this feature does not alter the disposition matrix; it makes Superpowers invocation explicit (which the matrix already encodes via FORBID-UNDER-HANDOFF entries) |
| III. Agent-Neutral Protocol | Identical behavior on Codex and Claude Code; explicit syntax mapping; `-Actor` accepted; `AGENTS.md` master | **PASS** — this feature's US2 directly enforces this principle (kills hard-coded `-Actor codex`; adds install-state audit that flags divergence) |
| IV. Smooth Bidirectional Handoff | Handoff state machine discoverable; pre-write snapshots; agent switch requires only `-Actor` change | **PASS** — extends handoff schema with resume context; auto-archive (feature 002) plus new resume-signal close the cross-session smoothness gap |
| V. Vendor-Managed Boundaries | No hand-edits to `.agents/skills/speckit-*` or `.claude/skills/speckit-*` from upstream; custom behavior in `speckit-superpowers-bridge` skills + `.specify/extensions/` | **PASS** — only the bridge SKILL.md files are edited; upstream-generated skills untouched. Plugin distribution explicitly excludes the upstream-generated skills (they are managed by `specify integration` commands, not by our plugin) |

**Initial Constitution Check**: PASS.
**Post-Design Re-check (after Phase 1)**: PASS — see contracts and data-model; the explicit-invocation design is the principle II strengthening the article warned was necessary; no principle was relaxed.

## Project Structure

### Documentation (this feature)

```text
specs/004-polish-and-publish/
|-- spec.md                       # done (clarified, 3 Q&A recorded)
|-- plan.md                       # this file
|-- research.md                   # Phase 0 output (10 unknowns resolved)
|-- data-model.md                 # Phase 1 output
|-- quickstart.md                 # Phase 1 output
|-- contracts/
|   |-- install-state-audit-contract.md
|   |-- validation-pass-contract.md
|   |-- skill-invocation-event.schema.json
|   |-- resume-context.schema.json
|   |-- plugin-distribution-manifest.schema.json
|   |-- readme-bilingual-parity-contract.md
|-- checklists/
|   `-- requirements.md           # done (from /speckit-specify)
|-- compat-gaps.md                # Phase 1: receives CG records from US3 validation pass
|-- tasks.md                      # (NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
.specify/
|-- superpowers-handoff.json                          # schema_version -> 3; adds autonomous_mode + resume_context block
|-- bridge-events.jsonl                               # append-only; new event type `skill_invocation`
|-- extensions/
|   |-- speckit-superpowers-bridge/
|   |   |-- extension.yml                             # unchanged
|   |   |-- disposition-matrix.json                   # +2 entries: speckit.superpowers.audit + speckit.superpowers.validate (new meta-commands)
|   |   |-- verified-versions.json                    # unchanged
|   |   |-- plugin-distribution-manifest.yml          # NEW: enumerated list of files the marketplace install copies
|   |   |-- commands/
|   |   |   |-- speckit.superpowers.guard.md          # unchanged
|   |   |   |-- speckit.superpowers.handoff.md        # MODIFIED: -Actor argument made explicit (CG-006 close)
|   |   |   |-- speckit.superpowers.parity.md         # unchanged
|   |   |   |-- speckit.superpowers.audit.md          # NEW: invocation surface for install-state audit
|   |   |   |-- speckit.superpowers.validate.md       # NEW: invocation surface for validation pass
|   |   |   |-- speckit.superpowers.recommend-route.md # NEW: US5 routing recommender
|   |   `-- scripts/
|   |       `-- powershell/
|   |           |-- guard-command.ps1                 # MODIFIED: actor resolution per FR-003
|   |           |-- update-handoff.ps1                # MODIFIED: actor resolution + resume_context persistence + schema_version 3
|   |           |-- auto-archive-handoff.ps1          # MODIFIED: actor resolution
|   |           |-- restore-snapshot.ps1              # MODIFIED: actor resolution
|   |           |-- parity-check.ps1                  # unchanged
|   |           |-- audit-install-state.ps1           # NEW
|   |           |-- validation-pass.ps1               # NEW
|   |           |-- emit-skill-invocation.ps1         # NEW: helper that writes a skill_invocation event
|   |           |-- common-actor-resolution.ps1       # NEW: dot-sourced module for the shared resolver
|   |           |-- check-readme-bilingual-parity.ps1 # NEW
|   |           |-- check-distribution-manifest.ps1   # NEW
|   |           `-- test-bridge-guard.ps1             # extended

.agents/skills/speckit-superpowers-bridge/SKILL.md    # MODIFIED: explicit Skill-tool / $skill-name invocations at named phases; resume-signal instruction; routing-recommender note (cross-reference only)
.claude/skills/speckit-superpowers-bridge/SKILL.md    # MODIFIED: same content, Claude invocation syntax
.claude/skills/speckit-specify/SKILL.md               # NOT MODIFIED: vendor-managed (principle V); routing recommender lives in a separate wrapper extension command if needed (see R8)

tests/                                                # 7 new smoke tests (see Technical Context above)

AGENTS.md                                             # already updated this session with Primary Design Reference
CLAUDE.md                                             # already updated this session

README.md                                             # NEW: English; primary marketplace listing target
README.zh-CN.md                                       # NEW: Simplified Chinese; full parity with English
.gitignore                                            # NEW: audited list of project-private state vs plugin assets
```

**Structure Decision**: Keep the established shape (extensions under `.specify/`, agent skills under `.agents/skills/` + `.claude/skills/`, shared PowerShell scripts). Net additions: 9 new files (4 scripts, 3 new extension command md files, 1 plugin-distribution manifest, 2 README files), 1 `.gitignore`, 6 contracts, 7 test files. Net modifications: 5 existing scripts (actor resolution + schema bump), 2 bridge SKILL.md (explicit invocation rewrite), 1 disposition matrix entry add (+2 entries), 1 extension command md (handoff actor fix).

## Design Decisions

1. **Actor detection** — Resolution order: `-Actor <value>` explicit arg → `SPECKIT_BRIDGE_ACTOR` env var → `.specify/integration.json.default_integration` → `unknown`. Implemented once in `common-actor-resolution.ps1`, dot-sourced by every script that takes `-Actor`. Hard-coded defaults (`codex`, `speckit-superpowers-bridge`) removed.

2. **Autonomous-mode + resume-context location** — Both live in `superpowers-handoff.json` (schema_version 3), persisted at the same place all other handoff state lives. Env var `SPECKIT_BRIDGE_AUTONOMOUS=1` is an override for the autonomous flag only (CI/headless use). Resume context (current_task_id, current_skill, current_phase, next_expected_action) is bridge-script-managed; the bridge skill writes it before invoking each Superpowers skill and reads it on resume.

3. **Explicit Superpowers invocation** — The bridge SKILL.md on each agent rewrites the "Execution Rules" section to issue concrete invocations:
   - Before any code-modifying task: invoke `superpowers:test-driven-development`
   - On any failure: invoke `superpowers:systematic-debugging`
   - Before marking a phase complete: invoke `superpowers:verification-before-completion`
   - Before marking the feature complete: invoke `superpowers:requesting-code-review`, then `superpowers:finishing-a-development-branch`

   Each invocation is preceded by writing a `skill_invocation` event via `emit-skill-invocation.ps1` so the validation pass can verify by reading the event log.

4. **Validation pass design** — `validation-pass.ps1` walks: handoff state → matrix coverage → constitution+spec+plan+tasks artifact presence → quickstart smoke commands → per-step skill_invocation event count. Emits Compatibility Gap Records to `specs/<feature>/compat-gaps.md` for any failure. Reuses the CG record schema established in feature 002.

5. **Install-state audit design** — `audit-install-state.ps1` reads `.specify/integration.json`, `.specify/extensions/git/extension.yml`, enumerates `.agents/skills/` + `.claude/skills/`, hashes the bridge SKILL.md on each side, and emits JSON. Detects 4 conditions: missing git extension, missing per-agent skill peer, skill-content divergence, script-flavour mismatch.

6. **Bilingual README parity check** — `check-readme-bilingual-parity.ps1` compares heading sets between `README.md` and `README.zh-CN.md` (after sorting + lowercase normalization). Divergence → non-zero exit + diff. No content translation logic; humans own translation. Section anchors must match exactly.

7. **Plugin distribution manifest** — `plugin-distribution-manifest.yml` declares: `includes:` (the plugin's own files) and `excludes:` (project-private state). A clean install reads this manifest and copies only what's listed. Idempotent — re-install checks file hashes; conflict → fail with a list of differing files.

8. **Routing recommender (US5 P3)** — Implemented as a NEW extension command `speckit.superpowers.recommend-route.md` rather than modifying the vendor-managed `/speckit-specify`. The user can invoke it before `/speckit-specify` for an advisory check, OR set `SPECKIT_BRIDGE_RECOMMEND_ROUTE=1` to have the after_specify hook surface a recommendation post-hoc. Default off because P3.

9. **CG-006 close** — The `speckit.superpowers.handoff` command markdown is rewritten to remove the hard-coded `-Actor codex` from its example; both bridge SKILL.md files explain the actor-resolution order; tests verify.

10. **Marketplace listing format** — Plan-time research (R6) revealed that Spec Kit's "marketplace" is currently catalog-driven via the extension manifest format (`extension.yml`), not a separate package format. Our bridge already ships an `extension.yml`. The "listing" is just our README + the existing `extension.yml`; no separate registration format is needed at this Spec Kit version. Future Spec Kit releases may introduce a richer marketplace; we'll re-verify then.

## Minimal Implementation Scope

The fastest usable implementation should make these changes only:

- `common-actor-resolution.ps1` (NEW) — single source of resolution logic; dot-sourced by every actor-taking script.
- `update-handoff.ps1` — bump schema to 3; add `autonomous_mode` and `resume_context` fields; switch to common actor resolver.
- `guard-command.ps1`, `auto-archive-handoff.ps1`, `restore-snapshot.ps1` — switch to common actor resolver.
- `audit-install-state.ps1` (NEW) + `commands/speckit.superpowers.audit.md` + matrix entry.
- `validation-pass.ps1` (NEW) + `commands/speckit.superpowers.validate.md` + matrix entry.
- `emit-skill-invocation.ps1` (NEW) — write `skill_invocation` events; bumps event-log consumers.
- Rewrite both `speckit-superpowers-bridge/SKILL.md` files (Codex + Claude) with explicit Skill-tool invocations at named phases and a resume-signal preamble.
- New extension command `commands/speckit.superpowers.recommend-route.md` (US5; small-scope heuristic in plain prose).
- `README.md` (EN) + `README.zh-CN.md` (zh-CN) — bilingual; mutually linked.
- `.gitignore` — excludes `.specify/bridge-events.jsonl`, `.specify/bridge-snapshots/`, `.specify/superpowers-handoff.json`, `.specify/feature.json`, `specs/*/checklists/` (per-feature private); keeps plugin assets.
- `plugin-distribution-manifest.yml` — declared includes/excludes.
- `check-readme-bilingual-parity.ps1`, `check-distribution-manifest.ps1` — verification helpers.
- 7 new test suites under `tests/`.

## Carried-forward Compatibility Gaps

| ID | Severity | Status | Resolution path in this feature |
|---|---|---|---|
| CG-006 | P2 | OPEN → CLOSED-IN-FEATURE | Decision #1 + #9 — actor resolution + handoff command template rewrite |

## Complexity Tracking

No constitution violations. Two judgment calls worth recording:

| Choice | Why Not Simpler | Why Not More Complete |
|---|---|---|
| Resume context in handoff JSON (vs separate file) | Separate file would mean two write paths to keep in sync, defeating the smooth-handoff principle | A richer "session log" with full message history is out of scope; we only persist the four fields needed to emit the one-line resume signal |
| Routing recommender as separate extension command (vs editing `/speckit-specify`) | Modifying the vendor-managed `/speckit-specify` SKILL.md would violate principle V; copying it to bypass the upstream would lose future upstream improvements | An auto-recommendation hook that fires after every specify is over-engineered for a P3 feature; the explicit command + opt-in env-var hybrid keeps it small |
