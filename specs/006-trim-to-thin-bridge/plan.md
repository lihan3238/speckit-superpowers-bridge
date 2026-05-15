# Implementation Plan: Trim To Thin Bridge

**Branch**: `006-trim-to-thin-bridge` | **Date**: 2026-05-15 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/006-trim-to-thin-bridge/spec.md`

## Summary

Drastically trim the `speckit-superpowers-bridge` extension package from ~3,000 lines of custom PowerShell + 18 test scripts + 9 command markdown files + 4 contract schemas down to a thin orchestrator: ≤3 PowerShell scripts (~300 lines total), ≤3 command markdown files, ≤3 tests, simplified v1-shape handoff schema, and a small hardcoded guard rule set. Preserve the two load-bearing capabilities — cross-agent task handoff (Codex ↔ Claude Code via `superpowers-handoff.json`) and `specs/` history (features 001–005 byte-identical). Cut everything else: matrix-driven dispositions, install audits, parity checks, validation passes, marketplace submission checklists, cleanup audits, routing recommender, resume signal emitter, skill invocation event emitter, bilingual-parity script, distribution-manifest schema. Replace `recommend-route` with a manual README "When to Skip Spec Kit" section. Add `docs/` to `.gitignore` and remove it from tracking. Keep `marketplace/` (all 4 files). Read v2/v3 handoff JSON gracefully (ignore unknown fields); new writes use v1 shape only. Ship as `v0.3.0` with a CHANGELOG entry that names every removal.

## Technical Context

**Language/Version**: PowerShell 5.1+ on Windows, PowerShell 7.x on macOS/Linux (Bash port deferred per CG-005 / feature 003 stub).

**Primary Dependencies**: Spec Kit `>=0.8.10`; Superpowers plugin (latest, both Codex `.agents/` and Claude Code `.claude/`). No new dependencies added; the trim only removes.

**Storage**: Repo-local filesystem — `.specify/superpowers-handoff.json` (state), `.specify/bridge-events.jsonl` (append-only audit log), `.specify/bridge-snapshots/<id>/` (rollback artifacts). All retained at simplified shapes.

**Testing**: PowerShell smoke tests (`tests/*.ps1`), invoked manually via `powershell.exe -NoProfile -File <test>`. No Pester framework dependency. Test count drops from 18 to ≤3.

**Target Platform**: Windows (primary). Cross-platform via PowerShell 7 deferred to feature 003 stub.

**Project Type**: Spec Kit extension package (`.specify/extensions/speckit-superpowers-bridge/`) plus mirrored skill folders (`.claude/skills/speckit-superpowers-bridge/`, `.agents/skills/speckit-superpowers-bridge/`) plus root-level marketplace listing (`marketplace/`).

**Performance Goals**: Each bridge script completes in ≤500 ms cold (single-file read + small JSON parse + decision). Not a runtime hot path.

**Constraints**:
- Hard cap: 3 PowerShell scripts (FR-001), 3 command md files (FR-002), 3 tests (FR-012), each bridge `SKILL.md` ≤ 150 lines (FR-004).
- Soft cap: total PowerShell line count ≤ 300 across the 3 retained scripts (SC-001 demands ≥ 88% reduction from current ~3,000 lines).
- Reversibility: every removal in its own commit (FR-018, SC-009).
- Byte-identical `specs/001..005/**` (FR-017, SC-006).
- Bilingual README parity (FR-015, SC-010) — hand-verified after the bilingual-parity script is removed.

**Scale/Scope**: Repo currently has 31 bridge files under `.specify/extensions/.../`. Post-trim: ≤8 (3 scripts + 3 commands + 1 extension.yml + 1 common-actor-resolution helper at most). 18 test scripts → ≤3. 4 marketplace files retained. 1 docs file → untracked. 0 new feature directories beyond 006.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Justification |
|-----------|--------|---------------|
| **I. Lightweight & Repo-Local** | ✅ PASS (strengthened) | The trim removes every accreted custom feature; restores Principle I in spirit. No new runtimes / daemons / services. Marketplace packaging stays as thin distribution layer for the same repo-local assets. |
| **II. Design/Implementation Separation (NON-NEGOTIABLE)** | ✅ PASS | Handoff state file still exists; `speckit.implement` still blocked when handoff is `executing`; `superpowers:writing-plans` + `:brainstorming` still denied during active Spec Kit features — but now via 5 hardcoded `if/elseif` branches in `guard-command.ps1` instead of a matrix lookup. Semantics preserved. |
| **III. Agent-Neutral Protocol** | ✅ PASS | Both `.claude/skills/speckit-superpowers-bridge/SKILL.md` and `.agents/skills/speckit-superpowers-bridge/SKILL.md` are slimmed identically; both scripts still accept `-Actor codex` / `-Actor claude`; events still log the actor. |
| **IV. Smooth Bidirectional Handoff** | ✅ PASS | `superpowers-handoff.json` still exists (simplified v1 shape per FR-006); `bridge-events.jsonl` still appended on every guard decision; snapshots still taken (handled inside `update-handoff.ps1`); switching agent is still actor-arg + re-read of `AGENTS.md`. Backward-read of v2/v3 (FR-009) ensures in-flight upgrades don't lose state. |
| **V. Vendor-Managed Boundaries** | ✅ PASS | The trim modifies only files under `speckit-superpowers-bridge/`, `marketplace/`, `tests/`, `docs/`, root protocol files (`AGENTS.md`, `CLAUDE.md`, `.specify/extensions.yml`, `CHANGELOG.md`, `README*.md`, `.gitignore`). Officially generated `.claude/skills/speckit-*` and `.agents/skills/speckit-*` are NOT touched (except the bridge's own peer skills, which are non-vendor by design). |

**Gate result**: PASS. No principle violations require Complexity Tracking.

### Post-Design Re-Check (after Phase 1 artifacts)

Re-running the same 5 principles after `research.md`, `data-model.md`, `contracts/handoff.v1.schema.json`, and `quickstart.md` are written:

| Principle | Post-design status | Notes |
|-----------|--------------------|-------|
| **I. Lightweight & Repo-Local** | ✅ STILL PASS | `data-model.md` lists 4 entities; 3 are runtime (handoff JSON, events JSONL, snapshots) and 1 is design-time (cut inventory). No new runtime, no new storage technology, no daemons. Schema `additionalProperties: true` is permissive (no validator added at runtime; this schema lives only in `specs/` as documentation). |
| **II. Design/Implementation Separation** | ✅ STILL PASS | R3's 5 hardcoded guard rules preserve the constitution's three required denials: `speckit.implement` during executing handoff (rule 1), `superpowers:writing-plans`/`brainstorming` while spec artifacts exist (rule 2), `speckit.constitution` during executing handoff (rule 3). Quickstart Step 4 verifies all three. |
| **III. Agent-Neutral Protocol** | ✅ STILL PASS | R4 mandates identical SKILL.md content in `.claude/skills/...` and `.agents/skills/...`. R5 keeps `-Actor` parameter on all three retained scripts. Quickstart Step 6 walks a Claude→Codex handoff to verify behavior is identical. |
| **IV. Smooth Bidirectional Handoff** | ✅ STILL PASS | Handoff entity (data-model §1) retains the four canonical state values and all 6 transitions. Snapshot taking is retained in `update-handoff.ps1` (R6); only `restore-snapshot.ps1` is removed (rollback becomes manual `cp -r`, which is documented in data-model §4 trim impact). `bridge-events.jsonl` is still appended on every handoff transition and every guard decision. |
| **V. Vendor-Managed Boundaries** | ✅ STILL PASS | No edits to vendor-generated `.claude/skills/speckit-*` or `.agents/skills/speckit-*` (excluding the bridge's own peer skills, which are non-vendor by design). Single-writer rule is preserved via `artifact_owner` (data-model §1). |

**Re-check verdict**: PASS. No new complexity introduced by Phase 1 artifacts. Ready for `/speckit-tasks`.

## Project Structure

### Documentation (this feature)

```text
specs/006-trim-to-thin-bridge/
├── plan.md              # This file (/speckit-plan output)
├── spec.md              # /speckit-specify + /speckit-clarify output (existing)
├── research.md          # Phase 0 output (/speckit-plan)
├── data-model.md        # Phase 1 output (/speckit-plan)
├── quickstart.md        # Phase 1 output (/speckit-plan)
├── contracts/
│   └── handoff.v1.schema.json   # Simplified handoff schema (FR-006)
├── cut-inventory.md     # Enumerated removal list (created during planning per FR-018)
├── checklists/
│   └── requirements.md  # /speckit-specify output (existing)
└── tasks.md             # /speckit-tasks output (NOT created by /speckit-plan)
```

### Repository Layout (the surfaces this feature edits)

This is a Spec Kit extension package, not a traditional `src/tests` codebase. The plan describes the **post-trim** target shape:

```text
codex_specify_superpower/
├── .specify/
│   ├── extensions/speckit-superpowers-bridge/
│   │   ├── extension.yml                       # version → 0.3.0, commands list → 3
│   │   ├── commands/
│   │   │   ├── speckit.speckit-superpowers-bridge.execute.md   # KEEP (slimmed)
│   │   │   ├── speckit.speckit-superpowers-bridge.handoff.md   # KEEP (slimmed)
│   │   │   └── speckit.speckit-superpowers-bridge.guard.md     # KEEP (slimmed)
│   │   └── scripts/powershell/
│   │       ├── update-handoff.ps1                              # KEEP (simplified, ~120 lines)
│   │       ├── guard-command.ps1                               # KEEP (hardcoded rules, ~80 lines)
│   │       ├── auto-archive-handoff.ps1                        # KEEP (simplified, ~70 lines)
│   │       └── common-actor-resolution.ps1                     # KEEP optional (≤30 lines)
│   ├── extensions.yml                          # hooks trimmed: before_specify removed
│   ├── superpowers-handoff.json                # v1 shape (runtime state)
│   ├── bridge-events.jsonl                     # append-only (still used)
│   └── bridge-snapshots/                       # still used
│
├── .claude/skills/speckit-superpowers-bridge/SKILL.md    # ≤100 lines, orchestration prose only
├── .agents/skills/speckit-superpowers-bridge/SKILL.md    # ≤100 lines, mirror of above
│
├── marketplace/                                # ALL 4 files retained (FR-019)
│   ├── catalog-entry.json                      # version 0.3.0, commands → 3
│   ├── extensions-readme-row.md                # description refresh
│   ├── upstream-pr-body.md                     # AI-disclosure preserved
│   └── README.md                               # description refresh
│
├── tests/                                      # ≤3 files (FR-012)
│   ├── test-handoff-shape.ps1                  # NEW (consolidates update-handoff + actor-resolution)
│   ├── test-guard-hardcoded-rules.ps1          # NEW (consolidates guard tests)
│   └── test-claude-codex-skill-parity.ps1      # KEEP (renamed from test-claude-skill-parity.ps1; verifies SKILL.md peers exist)
│
├── README.md                                   # commands table → 3; new "When to Skip Spec Kit" section
├── README.zh-CN.md                             # mirror of above
├── CHANGELOG.md                                # new [0.3.0] section names every removal
├── AGENTS.md                                   # commands references trimmed
├── CLAUDE.md                                   # commands references trimmed
├── .gitignore                                  # adds docs/
├── docs/                                       # UNTRACKED (still on local disk)
│
├── specs/001-spec-superpowers-bridge/          # UNCHANGED (FR-017)
├── specs/002-complete-bridge-protocol/         # UNCHANGED
├── specs/003-bridge-cross-platform-scripts/    # UNCHANGED
├── specs/004-polish-and-publish/               # UNCHANGED
├── specs/005-marketplace-alignment/            # UNCHANGED
└── specs/006-trim-to-thin-bridge/              # this feature
```

**Files DELETED by this feature** (recorded in `cut-inventory.md` with one git commit per logical group per FR-018):

Bridge scripts (14 files):
- `audit-install-state.ps1`, `check-distribution-manifest.ps1`, `check-readme-bilingual-parity.ps1`, `cleanup-audit.ps1`, `emit-resume-signal.ps1`, `emit-skill-invocation.ps1`, `parity-check.ps1`, `recommend-route.ps1`, `restore-snapshot.ps1`, `submission-checklist.ps1`, `test-bridge-context.ps1`, `test-bridge-guard.ps1`, `validation-pass.ps1`

Bridge command markdowns (6 files):
- `speckit.speckit-superpowers-bridge.audit.md`, `.cleanup-audit.md`, `.parity.md`, `.recommend-route.md`, `.submission-checklist.md`, `.validate.md`

Bridge data files (3 files):
- `disposition-matrix.json`, `plugin-distribution-manifest.yml`, `verified-versions.json`

Bridge contract schemas (1 file at runtime):
- `contracts/plugin-distribution-manifest.schema.json` (the runtime copy; historical copies in `specs/<feature>/contracts/` stay)

Bridge docs (1 file, runtime location):
- `docs/parameter-reference.md` under the extension — moved to git-untracked or removed entirely; the maintainer's `docs/release-runbook.md` is in repo-root `docs/` which becomes gitignored

Test scripts (15 files):
- `test-actor-resolution.ps1`, `test-cleanup-audit.ps1`, `test-constitution-checklist-guard.ps1`, `test-disposition-matrix.ps1`, `test-distribution-manifest.ps1`, `test-extension-manifest-install.ps1`, `test-guard-uses-matrix.ps1`, `test-hook-surface-resolution.ps1`, `test-install-state-audit.ps1`, `test-parity-drift.ps1`, `test-readme-bilingual-parity.ps1`, `test-resume-signal.ps1`, `test-routing-recommender.ps1`, `test-skill-invocation-event.ps1`, `test-submission-checklist.ps1`, `test-validation-pass.ps1`, `test-verified-versions.ps1` (17 of 18; one kept renamed)

**Structure Decision**: Spec Kit extension package layout, post-trim minimal. The bridge directory contains only what is needed to orchestrate native Spec Kit + Superpowers skills.

## Complexity Tracking

No constitution violations — no entries required.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| (none) | (n/a) | (n/a) |
