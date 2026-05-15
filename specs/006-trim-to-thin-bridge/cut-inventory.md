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
|      |      |        |

---

## Commit 3 — Remove recommend-route / emit-resume-signal / emit-skill-invocation / restore-snapshot

| Path | Type | Reason |
|------|------|--------|
|      |      |        |

---

## Commit 4 — Remove disposition-matrix / verified-versions / bilingual-parity; simplify common-actor-resolution

| Path | Type | Reason |
|------|------|--------|
|      |      |        |

---

## Commit 5 — Simplify update-handoff / guard-command / auto-archive-handoff

| Path | Type | Before | After | Reason |
|------|------|--------|-------|--------|
|      |      |        |       |        |

---

## Commit 6 — Rewrite SKILL.md peers (Claude + Codex)

| Path | Type | Before lines | After lines | Reason |
|------|------|--------------|-------------|--------|
|      |      |              |             |        |

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
