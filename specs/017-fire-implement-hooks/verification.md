# Verification: Fire speckit.implement before/after hooks from the bridge

**Feature**: `017-fire-implement-hooks` | **Date**: 2026-08-17

## Smoke suite

`bash tests/run-all.sh` → **7/7 PASS** on Linux bash (Spec Kit 0.11.1 baseline,
Superpowers 6.0.0 evidence unchanged):

- `test-bridge-state-summary.sh` — PASS
- `test-bridge-status.sh` — 26/26 PASS
- `test-claude-codex-skill-parity.sh` — PASS
- `test-guard-hardcoded-rules.sh` — PASS
- `test-handoff-shape.sh` — PASS
- `test-implement-hooks-dispatch.sh` — PASS (NEW; asserts the dispatch contract)
- `test-release-package.sh` — PASS (package inventory against the rebuilt ZIP)

## What changed (source)

| File | Change |
|---|---|
| `commands/speckit.speckit-superpowers-bridge.execute.md` | + `before_implement`/`after_implement` hook-dispatch sections + skip-own-guard rule |
| `.agents/skills/speckit-superpowers-bridge/SKILL.md` | + hook steps (3, 10) + "Extension hooks" section |
| `.claude/skills/speckit-superpowers-bridge/SKILL.md` | identical peer change |
| `tests/test-implement-hooks-dispatch.sh` | NEW smoke test |
| `extension.yml` | version → 1.2.0 |
| `marketplace/catalog-entry.json` | version → 1.2.0, `updated_at` refreshed |
| `CHANGELOG.md` | `## [1.2.0]` section |
| `verified-versions.json` | `bridge_version` 1.2.0, evidence rows refreshed |
| `README.md` / `README.zh-CN.md` | v1.2.0 description + install example + maintenance |
| `marketplace/extensions-readme-row.md` / `extension-submission-body.md` | v1.2.0 |

## Release gate

`validate-release-readiness.ps1 -Version 1.2.0` will pass on version grounds
(all seven release-checklist files carry 1.2.0; `download_url` unchanged;
`provides` 3/5 unchanged). The tag/publish step (and its published-artifact
sandbox cycle in `../test_specify_superpower`) is deferred to the maintainer, as
with features 014/016.

## Deferred

- Published-artifact end-user sandbox cycle: deferred to the maintainer's
  release/tag step. Live verification that a user's `before_implement` /
  `after_implement` hooks actually fire through the bridge requires a full
  agent-driven bridge run in the sandbox after the v1.2.0 ZIP is published.
