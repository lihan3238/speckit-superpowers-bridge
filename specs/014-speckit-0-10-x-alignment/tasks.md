# Tasks: Spec Kit 0.10.x Compatibility Alignment & Evidence Refresh

**Input**: Design documents from `specs/014-speckit-0-10-x-alignment/`
**Prerequisites**: plan.md, spec.md, research.md, quickstart.md

**Tests**: Required per spec FR-007 — the existing 6-test bash smoke suite and release validators must stay green at every commit; no new test files are planned unless a validator gap is discovered during US2.

**Organization**: Tasks grouped by user story. US1 (docs) is the MVP; US2 (metadata + evidence) and US3 (release + sandbox) build toward the v1.0.3 publication.

## Phase 1: Setup

- [ ] T001 Verify baseline: `specify version` reports 0.10.2, `bash tests/run-all.sh` passes 6/6, working tree clean on branch `014-speckit-0-10-x-alignment` (no file changes; abort and report if any check fails)

## Phase 2: Foundational

*(none — no shared infrastructure changes; all stories edit independent files)*

## Phase 3: User Story 1 — Fresh-clone contributor bootstraps with Spec Kit 0.10.x (P1) 🎯 MVP

**Goal**: AGENTS.md gives a 0.10.x-correct bootstrap path including the now-opt-in git extension.

**Independent Test**: quickstart.md §1 greps return clean; a scratch clone following the table reaches a working env (spot-checked against the empirical re-bootstrap already recorded in research.md R1).

- [ ] T002 [US1] Update AGENTS.md "Supported Host Environments" table: bump CLI floor wording from "0.9.1+" to "0.10.1+ (verified 0.10.2)", keep bridge runtime floor `>=0.8.10`, and extend the one-time bootstrap column/sequence to add `specify extension add git` (and note agent-context remains bundled) in AGENTS.md
- [ ] T003 [US1] Add a short "Spec Kit 0.10.0 migration notes" paragraph to AGENTS.md near the bootstrap table: git extension now opt-in (`--no-git` removed, init no longer auto-installs it), legacy `--ai`/`--ai-skills`/`--ai-commands-dir` removed in favor of `--integration`, and `init-options.json` renamed `branch_numbering`→`feature_numbering` (bridge scripts never read this field) in AGENTS.md
- [ ] T004 [US1] Run quickstart.md §1 verification greps over AGENTS.md, README.md, README.zh-CN.md and fix any remaining stale-floor/removed-flag mentions outside CHANGELOG/specs history (grep evidence recorded in specs/014-speckit-0-10-x-alignment/verification.md)

**Checkpoint**: AGENTS.md bootstrap path is 0.10.x-correct and self-contained.

## Phase 4: User Story 2 — Marketplace consumer sees accurate, current metadata (P2)

**Goal**: `category`/`effect` declared in bridge-owned metadata; evidence refreshed to 0.10.2.

**Independent Test**: quickstart.md §2 round-trip in a scratch 0.10.2 project shows Category: process / Effect: read-write; §3 greps confirm evidence rows.

- [ ] T005 [P] [US2] Add `category: process` and `effect: read-write` under the `extension:` mapping in .specify/extensions/speckit-superpowers-bridge/extension.yml (keep all other fields and ordering; do NOT bump version yet — that is T010)
- [ ] T006 [P] [US2] Confirm `category`/`effect` fields in marketplace/catalog-entry.json match upstream values (`process`/`read-write`); add them if absent (do NOT touch `download_url`; version bump is T010)
- [ ] T007 [US2] Refresh .specify/extensions/speckit-superpowers-bridge/verified-versions.json: add/update the Spec Kit `0.10.2` + Linux bash (WSL2) evidence row dated 2026-06-12 citing the 6/6 smoke-suite pass and re-bootstrap; retain prior Windows PowerShell / Codex / Claude Code rows with their original dates per research.md R3
- [ ] T008 [P] [US2] Update README.md badge `Spec_Kit-verified_0.9.3` → `verified_0.10.2` and the §"verified versions" prose (line ~362) to name Spec Kit 0.10.2 on Linux bash; mirror the same edits in README.zh-CN.md
- [ ] T009 [US2] Execute quickstart.md §2 manifest round-trip in a scratch 0.10.2 project (validator must accept the manifest and `extension info` must show Category: process / Effect: read-write); record the transcript in specs/014-speckit-0-10-x-alignment/verification.md

**Checkpoint**: Metadata + evidence accurate; smoke suite still 6/6.

## Phase 5: User Story 3 — End user installs v1.0.3 from the published release (P2)

**Goal**: v1.0.3 published; real-URL install verified in the sandbox on Spec Kit 0.10.2.

**Independent Test**: quickstart.md §4 sandbox cycle completes and is recorded in verification.md.

- [ ] T010 [US3] Bump version to 1.0.3 in .specify/extensions/speckit-superpowers-bridge/extension.yml and marketplace/catalog-entry.json (`download_url` unchanged — stable latest-release alias), and add the `[1.0.3]` CHANGELOG.md entry (Added: category/effect manifest fields; Changed: 0.10.x docs alignment + evidence refresh; Compatibility: runtime floor unchanged `>=0.8.10`)
- [ ] T011 [US3] Run full local release gate: `bash tests/run-all.sh` (6/6) plus the release validation script and `tests/test-release-package.sh` against a freshly built v1.0.3 ZIP in dist/ (build via the repo's existing packaging path); fix any validator findings
- [ ] T012 [US3] Commit, push branch, open PR to main, merge after review, tag `v1.0.3`, publish the GitHub release with the v1.0.3 ZIP asset, and verify the stable alias URL `releases/latest/download/speckit-superpowers-bridge.zip` serves the new ZIP
- [ ] T013 [US3] Execute quickstart.md §4 end-user sandbox verification in ../test_specify_superpower (fresh `specify init` on 0.10.2, install from published release URL, one full guard→handoff→status→archive cycle); record outcomes, versions, and dates in specs/014-speckit-0-10-x-alignment/verification.md

**Checkpoint**: Release shipped with constitution-mandated sandbox evidence.

## Phase 6: Polish & Cross-Cutting Concerns

- [ ] T014 Final consistency sweep: quickstart.md §§1–3 greps all clean on the release commit; mark handoff `complete` only after T013 evidence exists; consider upstream catalog version-bump PR (submission issue to github/spec-kit) as follow-up and note the decision in specs/014-speckit-0-10-x-alignment/verification.md

## Dependencies

- T001 → everything (baseline gate)
- US1 (T002–T004) independent of US2/US3
- T005, T006, T008 are parallel [P]; T007 after T001; T009 after T005+T006
- T010 after US1+US2 complete (version bump is the release commit)
- T011 after T010; T012 after T011; T013 after T012 (needs published URL); T014 last

## Implementation Strategy

MVP = US1 (docs correctness for contributors). US2 next (metadata/evidence — the substance of the release). US3 ships it. Single-session scope: ~8 files, no new code paths, every step gated by the existing test suite.
