# Tasks: Superpowers 6.0.0 Compatibility Alignment & Evidence Refresh

**Feature**: `specs/016-superpowers-6-0-0-alignment/` | **Branch**: `016-superpowers-6-0-0-alignment`

**Input**: [spec.md](spec.md), [plan.md](plan.md), [research.md](research.md)

**Release**: bridge **v1.1.0** (MINOR) — Superpowers verified baseline 5.1.0 → 6.0.0, **zero bridge runtime change**.

Legend: `[P]` = parallelizable (different file, no ordering dependency). Each task names its exact file(s).

## Phase 0 — Research (complete)

- [x] T001 Diff cached Superpowers 5.1.0 vs 6.0.0 trees + grep the bridge surface; record verdicts in `research.md`. (Outcome: no bridge change required.)

## Phase 1 — Evidence + metadata (US1, US2)

- [x] T002 [US1] Edit `.specify/extensions/speckit-superpowers-bridge/verified-versions.json`: `verified_at` → `2026-06-17`; `superpowers_version` `5.1.0` → `6.0.0`; `bridge_version` `1.0.3` → `1.1.0`; rewrite the Linux-bash row note to describe the 6.0.0 re-verification (grep audit + 6/6 smoke green under Superpowers 6.0.0); retain Windows PowerShell + agent rows with original dates and a "bytes unchanged in v1.1.0" note; refresh top-level `notes` to describe the 6.0.0 alignment.
- [x] T003 [US1] [P] Edit `.specify/extensions/speckit-superpowers-bridge/extension.yml`: `extension.version` `1.0.3` → `1.1.0`. (No other field changes — `category`/`effect`/floor/commands/hooks frozen.)
- [x] T004 [US1] [P] Edit `marketplace/catalog-entry.json`: `version` `1.0.3` → `1.1.0`; `updated_at` → `2026-06-17`; `download_url` UNCHANGED (stable latest-release alias).
- [x] T005 [US2] Edit `CHANGELOG.md`: add `## [1.1.0] - 2026-06-17` under `[Unreleased]` with (a) "Changed": Superpowers verified baseline 5.1.0 → 6.0.0, bridge MINOR bump; (b) an "Upstream notes (informational)" block listing the 6.0.0 reviewer-prompt consolidation, worktree relocation to `.worktrees/`, vendor-neutral prose, and new harnesses — each with an explicit "bridge surface unaffected / transparent" verdict (grep-verified, ref `research.md`).

## Phase 2 — Public claims (US1)

- [x] T006 [US1] [P] Edit `README.md`: Superpowers badge `verified_5.1.0` → `verified_6.0.0`; maintenance/verified section `Superpowers 5.1.0` → `6.0.0`; version-pinned install example `1.0.3` → `1.1.0`.
- [x] T007 [US1] [P] Edit `README.zh-CN.md`: same three edits as T006 (badge, maintenance, install example).
- [x] T008 [US1] [P] Edit `marketplace/extensions-readme-row.md`: version string and support summary → v1.1.0 / Superpowers 6.0.0.
- [x] T009 [US1] [P] Edit `marketplace/extension-submission-body.md`: `### Version` → 1.1.0; baseline naming Superpowers `6.0.0`; support matrix; Proposed Catalog Entry `version` + `updated_at` (2026-06-17); `download_url` unchanged.

## Phase 3 — Verify (US1, US2)

- [x] T010 Rebuild the release ZIP at v1.1.0 (`bash scripts/release/build-extension-zip.sh --version 1.1.0` or equivalent) so the release-package smoke test consumes the matching artifact; record SHA256.
- [x] T011 Run `bash tests/run-all.sh` → MUST be 6/6 green on the release commit (incl. release-package vs the v1.1.0 ZIP). Record in `verification.md`.
- [x] T012 Final sweep grep: confirm no current-version `5.1.0` Superpowers claim or `1.0.3` bridge-version claim remains in README.md / README.zh-CN.md / verified-versions.json / extension.yml / marketplace/ (historical CHANGELOG + prior specs/** exempt). Record in `verification.md`.
- [x] T013 Fill `verification.md`: environment table (Superpowers 6.0.0, Spec Kit 0.10.2, bridge 1.1.0), R1–R6 evidence pointers, smoke result, and the explicit note that the published-artifact sandbox cycle is **deferred to the maintainer's release/tag step** (handoff intentionally not driven to `complete` this session); record byte-identity of runtime files vs v1.0.3.

## Out of Scope (do NOT do)

- Any edit to `.claude/skills/speckit-superpowers-bridge/SKILL.md`, `.agents/skills/speckit-superpowers-bridge/SKILL.md`, the three command `.md` files, or any `scripts/{bash,powershell}/*` — frozen this release.
- Adopting Superpowers 6.0.0 plan-format blocks into `tasks.md`; adding Kimi/Pi/Antigravity bridge variants; raising the runtime floor; changing `download_url`.
- Pushing the git tag, cutting the GitHub release, or filing the upstream catalog submission (maintainer-triggered, separate step).
