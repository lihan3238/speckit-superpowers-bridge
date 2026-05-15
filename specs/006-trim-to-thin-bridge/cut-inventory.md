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

## Commit 7 — Untrack docs/ and remove bridge parameter-reference

| Path | Type | Reason |
|------|------|--------|
|      |      |        |

---

## Commit 8 — Release v0.3.0 (extension.yml + marketplace/* + CHANGELOG + READMEs + extensions.yml + AGENTS.md + CLAUDE.md)

| Path | Type | Reason |
|------|------|--------|
|      |      |        |

---

## Verification

Filled in during Phase 7 polish (T075–T078).
