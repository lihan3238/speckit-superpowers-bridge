# Cut Inventory — Feature 006 (Trim To Thin Bridge)

**Baseline SHA**: `845157b spec(006): trim-to-thin-bridge — spec, clarify, plan, tasks`
**Baseline spec-history checksum** (specs/001–005 byte-identical proof): `1f09423e4e91ec5b9edb396b7c7f2fe4a0a2a56a`
**Trim start**: 2026-05-15
**Executor**: claude

This inventory enumerates every path removed or modified by feature 006, grouped by the 8 reversible commits from `research.md` §R9. Every row should be auditable: `git log -- <path>` shows the path's history; the path is absent at HEAD; the commit hash deletes it.

---

## Commit 1 — Remove parity / audit / validate

| Path | Type | Reason |
|------|------|--------|
| `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/parity-check.ps1` | script | custom feature beyond thin-bridge scope |
| `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/audit-install-state.ps1` | script | install-diagnostics custom feature; not native to either Spec Kit or Superpowers |
| `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/validation-pass.ps1` | script | end-to-end validation custom feature; redundant with native superpowers:verification-before-completion |
| `.specify/extensions/speckit-superpowers-bridge/commands/speckit.speckit-superpowers-bridge.parity.md` | command md | partner of parity-check.ps1 |
| `.specify/extensions/speckit-superpowers-bridge/commands/speckit.speckit-superpowers-bridge.audit.md` | command md | partner of audit-install-state.ps1 |
| `.specify/extensions/speckit-superpowers-bridge/commands/speckit.speckit-superpowers-bridge.validate.md` | command md | partner of validation-pass.ps1 |
| `tests/test-parity-drift.ps1` | test | covers the deleted parity-check |
| `tests/test-install-state-audit.ps1` | test | covers the deleted install-state audit |
| `tests/test-validation-pass.ps1` | test | covers the deleted validation pass |

---

## Commit 2 — Remove submission-checklist / cleanup-audit / distribution-manifest

| Path | Type | Reason |
|------|------|--------|
| `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/submission-checklist.ps1` | script | marketplace-submission custom feature; manual catalog PR is fine |
| `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/cleanup-audit.ps1` | script | pre-release cleanup custom feature; redundant with manual review |
| `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/check-distribution-manifest.ps1` | script | manifest-validation custom feature; manifest itself is being removed |
| `.specify/extensions/speckit-superpowers-bridge/commands/speckit.speckit-superpowers-bridge.submission-checklist.md` | command md | partner of submission-checklist.ps1 |
| `.specify/extensions/speckit-superpowers-bridge/commands/speckit.speckit-superpowers-bridge.cleanup-audit.md` | command md | partner of cleanup-audit.ps1 |
| `.specify/extensions/speckit-superpowers-bridge/contracts/plugin-distribution-manifest.schema.json` | schema | manifest is gone; schema obsolete (contracts/ dir auto-removed) |
| `.specify/extensions/speckit-superpowers-bridge/plugin-distribution-manifest.yml` | data | distribution-manifest custom feature; marketplace catalog-entry.json is sufficient |
| `tests/test-submission-checklist.ps1` | test | covers the deleted submission-checklist |
| `tests/test-cleanup-audit.ps1` | test | covers the deleted cleanup-audit |
| `tests/test-distribution-manifest.ps1` | test | covers the deleted distribution-manifest |

---

## Commit 3 — Remove recommend-route / emit-resume-signal / emit-skill-invocation / restore-snapshot

| Path | Type | Reason |
|------|------|--------|
| `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/recommend-route.ps1` | script | per FR-021: routing decision is now user-driven; README §"When to Skip Spec Kit" replaces the automated recommender. Scheduled README addition in US4. |
| `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/emit-resume-signal.ps1` | script | custom resume-context emitter; v3-only; new v1 schema drops `resume_context` so the emitter is dead code |
| `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/emit-skill-invocation.ps1` | script | custom event-log emitter; bridge-events.jsonl no longer carries `skill_invocation` events (per data-model.md §2 trim) |
| `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/restore-snapshot.ps1` | script | snapshot rollback becomes manual `cp -r` per data-model.md §4 trim impact; automation surface removed |
| `.specify/extensions/speckit-superpowers-bridge/commands/speckit.speckit-superpowers-bridge.recommend-route.md` | command md | partner of recommend-route.ps1 |
| `tests/test-routing-recommender.ps1` | test | covers the deleted recommend-route |
| `tests/test-resume-signal.ps1` | test | covers the deleted emit-resume-signal |
| `tests/test-skill-invocation-event.ps1` | test | covers the deleted emit-skill-invocation |
| `tests/test-extension-manifest-install.ps1` | test | covers the now-deleted plugin-distribution-manifest install behavior |

---

## Commit 4 — Remove disposition-matrix / verified-versions / bilingual-parity; simplify common-actor-resolution

| Path | Type | Reason |
|------|------|--------|
| `.specify/extensions/speckit-superpowers-bridge/disposition-matrix.json` | data | matrix-driven guard replaced by 5 hardcoded `if/elseif` branches per FR-007 (scheduled in commit 5) |
| `.specify/extensions/speckit-superpowers-bridge/verified-versions.json` | data | machine-readable version-pinning custom feature; verification is now human inspection at release per assumptions |
| `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/check-readme-bilingual-parity.ps1` | script | bilingual parity preserved by hand; the parity check itself is a custom feature; H2 anchors stay English for stability |
| `tests/test-disposition-matrix.ps1` | test | covers the deleted matrix |
| `tests/test-verified-versions.ps1` | test | covers the deleted verified-versions |
| `tests/test-readme-bilingual-parity.ps1` | test | covers the deleted bilingual-parity script |
| `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/common-actor-resolution.ps1` | script (modified) | simplified per FR-008 + R5: drop 4-step chain (the `default_integration` branch), keep 3-step (explicit → env → "unknown"). `-RepoRoot` param retained as no-op for caller compat; commit 5 will remove it from callers and from this signature. 58 → 41 lines. |

---

## Commit 5 — Simplify update-handoff / guard-command / auto-archive-handoff

| Path | Type | Before | After | Reason |
|------|------|--------|-------|--------|
| `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/update-handoff.ps1` | script (modified) | 393 lines | 178 lines | Drop v3 fields (`autonomous_mode`, `resume_context`, `archive_history` round-trip) per FR-006. Keep snapshot taking (Principle IV). Tolerantly reads older shapes (FR-009). `blocked_reason` now only carries value when status is `blocked`. |
| `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/guard-command.ps1` | script (modified) | 259 lines | 92 lines | Replace matrix lookup with 5 hardcoded if/elseif branches per FR-007 + R3: deny `speckit.implement` during executing, deny `superpowers:writing-plans`/`:brainstorming` with artifacts, deny `speckit.constitution` during executing, allow `speckit.*` otherwise, default allow. |
| `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/auto-archive-handoff.ps1` | script (modified) | 97 lines | 54 lines | Delegate snapshot to update-handoff; drop `archive_history` patching (v1 schema makes it optional); emit `archive` event (renamed from `auto_archive`). Idempotent: no-op when status ≠ `complete`. |
| `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/test-bridge-context.ps1` | script (deleted) | 84 lines | 0 | Obsolete: tested resume-context plumbing that the v1 schema drops. |
| `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/test-bridge-guard.ps1` | script (deleted) | 235 lines | 0 | Obsolete: tested matrix-driven guard decisions that the hardcoded rules replace. Guard rule coverage is reinstated in `tests/test-guard-hardcoded-rules.ps1` in commit 8. |

**Surface budget after commit 5**: 4 retained scripts (3 callable + 1 dot-sourced helper) = 178 + 92 + 54 + 41 = **365 lines**.

- SC-001 (≥ 88% reduction from pre-trim ~3,042 lines): `(3042 - 365) / 3042 = 88.0%` → **MET**.
- Plan target "≤ 300 lines" is a soft derivative of SC-001; 365 reflects load-bearing helpers (`Convert-ToProjectPath`, `Write-BridgeEvent`, `New-BridgeSnapshot`, snapshot logic) that the constitution's Principle IV requires. Squeezing further would inline helpers without saving net work. Trade-off accepted; documented here for the verification gate.

---

## Commit 6 — Rewrite SKILL.md peers (Claude + Codex)

| Path | Type | Before lines | After lines | Reason |
|------|------|--------------|-------------|--------|
| `.claude/skills/speckit-superpowers-bridge/SKILL.md` | skill (modified) | 149 | 62 | Per FR-004 + R4: 7-section thin-orchestrator outline (purpose / when to use / 8-step orchestration / boundary rules / cross-agent notes / on failure / logs+snapshots). Removed all references to disposition-matrix, verified-versions, parity-check, validation-pass, recommend-route, emit-skill-invocation, emit-resume-signal, restore-snapshot, distribution-manifest, submission-checklist, cleanup-audit. |
| `.agents/skills/speckit-superpowers-bridge/SKILL.md` | skill (modified) | 146 | 59 | Identical-content peer (only minor diff: `$speckit-...` vs `/speckit-...` invocation syntax, `Actor codex` vs `Actor claude`). |

---

## Commit 7 — Untrack docs/, remove bridge parameter-reference, trim test inventory

> Commit 7 also swept in the test deletions/rename that `git rm` + `git mv` had staged earlier (T048+T049). Recorded here for honesty; the changes were already revertable per FR-018.

| Path | Type | Reason |
|------|------|--------|
| `docs/` | gitignore entry added | Per FR-020: docs/ is maintainer-only; files remain on local disk but stop being tracked. |
| `docs/release-runbook.md` | tracked → untracked | Removed from git index via `git rm -r --cached docs/`; still present on maintainer's local disk. |
| `.specify/extensions/speckit-superpowers-bridge/docs/parameter-reference.md` | deleted | The bridge's own docs file; obsolete after the trim removes the parameters it documented (matrix entries, autonomous_mode, resume_context, etc.). The empty `docs/` directory under the bridge was removed too. |
| `.gitignore` | modified | Added `docs/` line under a new "Maintainer-only docs" section. Removed the obsolete reference to cleanup-audit in a comment. |
| `tests/test-actor-resolution.ps1` | test (deleted) | Custom 4-step actor-resolution chain is gone; behaviour is now exercised by test-handoff-shape (commit 8). |
| `tests/test-claude-skill-parity.ps1` → `tests/test-claude-codex-skill-parity.ps1` | test (renamed) | Renamed for clarity that the parity covers BOTH agents' bridge SKILL.md. |
| `tests/test-constitution-checklist-guard.ps1` | test (deleted) | Constitution guard rule now lives in the 5 hardcoded if/elseif branches; covered by test-guard-hardcoded-rules (commit 8). |
| `tests/test-guard-uses-matrix.ps1` | test (deleted) | Matrix is gone; the test premise is invalid. Hardcoded-rules test supersedes. |
| `tests/test-hook-surface-resolution.ps1` | test (deleted) | Tested hook surface that now has fewer entries; the simplified extensions.yml (commit 8) is hand-verifiable. |

---

## Commit 8 — Release v0.3.0 (extension.yml + marketplace/* + CHANGELOG + READMEs + extensions.yml + AGENTS.md + CLAUDE.md)

| Path | Type | Reason |
|------|------|--------|
| `.specify/extensions/speckit-superpowers-bridge/extension.yml` | manifest (modified) | version → 0.3.0; provides.commands reduced from 9 to 3 (execute, handoff, guard); hooks reduced from 6 to 5 (before_specify bridge-handler removed); description refreshed to thin-bridge framing. |
| `marketplace/catalog-entry.json` | listing (modified) | version 0.3.0; provides.commands 3; provides.hooks 5; description refreshed; download_url bumped to v0.3.0. |
| `marketplace/extensions-readme-row.md` | listing (modified) | Description column refreshed. |
| `marketplace/upstream-pr-body.md` | listing (modified) | PR body rewritten for 0.3.0; AI-disclosure paragraph preserved verbatim. |
| `marketplace/README.md` | listing (modified) | Updated to describe the manual submission workflow (was: 11-step automated runbook). |
| `README.md` | doc (modified) | Rewrote workflow diagram, install URLs (v0.3.0), commands table (drop 6 removed commands), configuration (2-section actor chain), troubleshooting, maintenance, architecture sections. Added new `## When to Skip Spec Kit` H2 section per FR-021 (replaces deleted `recommend-route`). |
| `README.zh-CN.md` | doc (modified) | Bilingual mirror of README.md changes. H2 anchors stay English. Parity check: 10/10 H2s match between EN and ZH. |
| `CHANGELOG.md` | doc (modified) | New `[0.3.0] - 2026-05-15` section names all removed files (≥ 30 specific items), Changed entries describe the 3 simplified scripts and 2 rewritten SKILL.md peers, Compatibility notes call out v2/v3 read tolerance and CI updates required. AI-disclosure header amended to reflect Claude Code running the v0.3.0 trim. |
| `.specify/extensions.yml` | config (modified) | Removed the bridge's `recommend-route` entry under `before_specify` (the git.feature entry stays — it's owned by the git extension, not the bridge, and feature branch creation is still needed). All other hooks referencing deleted bridge commands were already absent (the hook file had 5 bridge-guard hooks + 1 bridge-handoff hook; all 6 stay, all reference surviving commands). |
| `AGENTS.md` | protocol (modified) | Removed all references to disposition-matrix.json, verified-versions.json, parity-check, validation-pass, submission-checklist, cleanup-audit, audit, recommend-route, autonomous_mode, resume_context, skill_invocation events, archive_history. Added a new "Guard rules" H2 listing the 5 hardcoded rules. Added a "Handoff schema" H2 pointing at the v1 schema. Preserved §"User-Facing Language Routing" (user-added) and the bridge ownership statements. |
| `CLAUDE.md` | protocol (modified) | Removed references to deleted commands (`/speckit-speckit-superpowers-bridge-parity`, `-audit`, `-validate`, `-submission-checklist`, `-cleanup-audit`); replaced with a one-line summary of the 5 hardcoded guard rules. Updated the slash-command example from `/speckit-speckit-superpowers-bridge-execute` to `/speckit-superpowers-bridge` (the canonical entry point). |

### FR-011 interpretation note

FR-011 reads "The `before_specify` hook MUST be removed entirely (its only prior handler was `recommend-route`)…". Strictly applied, this would also remove the `speckit.git.feature` entry under `before_specify`, which is owned by the **git extension** (creates feature branches when `/speckit-specify` runs) — unrelated to the bridge and load-bearing for the workflow. Constitution Principle V scopes the trim to `speckit-superpowers-bridge/` files only; deleting another extension's hook entry violates that principle. So the actual change: removed only the bridge's `recommend-route` handler, kept the git extension's `feature` handler. The spirit of FR-011 ("no bridge entry in before_specify") is satisfied; the literal "remove the entire hook key" is not. Documented here for the verification gate.

---

## Verification

| Check | Result | Notes |
|-------|--------|-------|
| US3 — specs/001–005 byte-identical | ✅ PASS | `git diff --stat 845157b..HEAD -- specs/001..005/` empty; checksum `1f09423e…56a` matches baseline exactly (T044+T045). |
| Quickstart Step 1 — bridge surface | ✅ PASS | 4 scripts (3 callable + 1 helper); 3 command markdowns; matches FR-001/002. All 11 removed scripts absent. |
| Quickstart Step 2 — line budgets | ⚠️ PARTIAL | PS total **376** vs ≤300 target (over by 76). SC-001 reduction (2984 → 376) = **87.4%** vs ≥88% target (0.6pt under). Trade-off: keeping load-bearing snapshot logic in `update-handoff.ps1` (constitution Principle IV requires snapshots before guarded writes; the 11-line snapshot-prior-directory fix from `10fd70d` was non-negotiable). Documented in cut-inventory Commit 5 surface-budget note. |
| Quickstart Step 2 — SKILL.md ≤ 100 | ✅ PASS | Claude 62 lines, Codex 59 lines. |
| Quickstart Step 2 — tests ≤ 3 | ✅ PASS | Exactly 3 files in `tests/`: claude-codex-skill-parity, handoff-shape, guard-hardcoded-rules. |
| Quickstart Step 3 — v3 backward read | ✅ PASS | Synthetic v3 JSON read without error; subsequent write contains no v3 fields. (T040) |
| Quickstart Step 4 — guard rules | ✅ PASS | All 5 rules behave as specified. (T041 + `tests/test-guard-hardcoded-rules.ps1`) |
| Quickstart Step 5 — spec history | ✅ PASS | Same as US3 above. |
| Quickstart Step 6 — cross-agent walkthrough | ⏳ DEFERRED | T043 requires switching between Claude Code and Codex in real time; not executable within a single agent session. Recommended for user-side smoke test. |
| Quickstart Step 7 — version + CHANGELOG | ✅ PASS | extension.yml `0.3.0`, catalog-entry.json `0.3.0`, CHANGELOG `[0.3.0]` section names ≥30 removed items. |
| Quickstart Step 8 — docs untracked | ✅ PASS | `git ls-files docs/` empty; `.gitignore` contains `docs/`. |
| Quickstart Step 9 — README "When to Skip Spec Kit" | ✅ PASS | Section present in both READMEs with English H2 anchor. |
| Quickstart Step 10 — bilingual H2 parity | ✅ PASS | 10/10 H2s match between README.md and README.zh-CN.md. |
| All 3 retained tests green | ✅ PASS | `test-claude-codex-skill-parity-ok`, `handoff-shape-tests-ok`, `guard-hardcoded-rules-tests-ok` all exit 0. |
| FR-018 commit reversibility | ✅ PASS | 9 commits between baseline and HEAD (8 R9 commits + 1 fixup). Each independently `git revert`-able. |
| Cut-inventory paths absent at HEAD | ✅ PASS | Spot-checked 5 random paths; all gone. |
| Cut-inventory paths in git log history | ✅ PASS | Spot-checked 2 random paths; both show in `git log --oneline -- <path>`. |

### Final disposition

- **SC-001 (PS reduction ≥ 88%)**: 87.4% — 0.6pt under target. Justified by the constitutional snapshot fix in `10fd70d`. Spec author may accept or require further squeeze in a follow-up.
- **SC-002 (commands ≤ 3)**: 3 ✓
- **SC-003 (tests ≤ 3)**: 3 ✓
- **SC-004 (orchestration through native skills)**: ✓ structurally (bridge SKILL.md describes the 8-step orchestration calling native Superpowers skills only).
- **SC-005 (cross-agent demonstrable)**: ⏳ deferred to user.
- **SC-006 (specs/001–005 byte-identical)**: ✓
- **SC-007 (version 0.3.0)**: ✓
- **SC-008 (CHANGELOG names ≥ 5 removed)**: ≥30 ✓
- **SC-009 (≥ 3 commits)**: 9 ✓
- **SC-010 (bilingual README parity)**: ✓

The trim is structurally complete. The only outstanding items are:
1. User-side T043 cross-agent walkthrough (recommended before tagging release).
2. Optional SC-001 reconciliation: either accept 87.4% as constitutionally compliant, or amend the spec to set the target at ≥ 87%.
