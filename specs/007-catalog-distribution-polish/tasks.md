---
description: "Tasks for feature 007-catalog-distribution-polish — retrospective spec for v0.4.3 catalog-distribution polish; stable-alias install URL, slimmed catalog shape, verification-record relocation"
---

# Tasks: Catalog Distribution Polish

**Input**: Design documents from `specs/007-catalog-distribution-polish/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [verification.md](./verification.md). The reused verification-record schema lives at [`../003-bridge-cross-platform-scripts/contracts/verification-record.md`](../003-bridge-cross-platform-scripts/contracts/verification-record.md).

**Tests**: This release is byte-frozen on the bridge runtime. The three retained smoke tests pass for v0.4.3 by construction (same scripts as v0.4.2). No new tests needed.

**Organization**: Tasks group by user story (US1 P1 MVP, US2 P2, US3 P2, US4 P2). Phase 1–5 are retrospective — they describe Codex's actual work in commits `3659e6c` + `70f5c32` and are marked `[x]`. Phase 6 is the work this retrospective commit performs to bring the v0.4.3 cycle into Spec Kit compliance.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to
- Include exact file paths in descriptions

## Path Conventions

- Bridge runtime (frozen): `.specify/extensions/speckit-superpowers-bridge/`
- Release tooling: `scripts/release/`, `.github/workflows/`
- Marketplace artifacts: `marketplace/`
- This spec dir: `specs/007-catalog-distribution-polish/`

---

## Phase 1: Pre-flight (already complete, recorded here)

- [x] T001 Confirm v0.4.2 is published and sandbox-PASS recorded under `specs/003-bridge-cross-platform-scripts/verification.md`. Confirmed prior to commit `3659e6c`.
- [x] T002 Confirm handoff for 003 is `status: complete`. Confirmed prior to commit `3659e6c`.

---

## Phase 2: User Story 1 — Stable Latest-Release Install Path (P1, MVP)

**Goal**: A user landing here from the official Spec Kit catalog can install with a URL that always returns the latest released bridge version.

**Independent Test**: From a fresh Spec Kit project, run the README's default install command (which uses `releases/latest/download/speckit-superpowers-bridge.zip`); confirm `specify extension info` reports `version: 0.4.3`.

- [x] T003 [US1] Extend `scripts/release/build-extension-zip.ps1` to emit a second output `dist/speckit-superpowers-bridge.zip` byte-identical to the versioned ZIP, via a `Copy-Item` step after the versioned build. *(commit `3659e6c`)*
- [x] T004 [US1] Extend `.github/workflows/release.yml` `gh release create` invocation to upload BOTH `dist/speckit-superpowers-bridge-v<version>.zip` AND `dist/speckit-superpowers-bridge.zip` as release assets. *(commit `3659e6c`)*
- [x] T005 [P] [US1] Update `README.md` install paths: default 3 install commands switch to `releases/latest/download/speckit-superpowers-bridge.zip`; add a new `### Version-pinned install` section preserving the hard-coded `v0.4.3` URL for reproducibility. *(commit `3659e6c`)*
- [x] T006 [P] [US1] Mirror `README.md` install changes in `README.zh-CN.md`, preserving bilingual H2 parity. *(commit `3659e6c`)*

---

## Phase 3: User Story 2 — Upstream Catalog-Shape Compliance (P2)

**Goal**: `marketplace/catalog-entry.json` matches the exact shape merged into upstream `extensions/catalog.community.json` by PR #2586 — making future bumps mechanical.

**Independent Test**: `diff` v0.4.3 `marketplace/catalog-entry.json` against the v0.4.1 entry in upstream PR #2586 — only `version`, `download_url`, `updated_at` should differ.

- [x] T007 [US2] Remove `git` from `marketplace/catalog-entry.json` `requires.tools`. Drop the `description` field on every remaining tool entry (`powershell`, `bash`, `jq`). Bump `version` to `0.4.3` and `download_url` to the v0.4.3 versioned ZIP URL. *(commit `3659e6c`)*
- [x] T008 [P] [US2] Update `marketplace/extensions-readme-row.md` columns to match upstream's current `docs/community/extensions.md` table shape: `Name | Description | Category | Permissions | Repository`. *(commit `3659e6c`)*
- [x] T009 [P] [US2] Update `marketplace/extension-submission-body.md`: bump version to v0.4.3, replace versioned URL, ADD a stable-alias URL line, refresh SHA256 to `d3da5b97…`. *(commits `3659e6c` + `70f5c32`)*

---

## Phase 4: User Story 3 — Update-Procedure Clarity (P2)

**Goal**: Future contributors preparing the v0.5.x bump can read `marketplace/README.md` and immediately understand the issue-based submission path.

**Independent Test**: Open `marketplace/README.md`; within the first 60 lines find the explicit "do NOT open a PR against `catalog.community.json`" instruction.

- [x] T010 [US3] Update `marketplace/README.md` to document the post-acceptance update flow: issue-based submission via `marketplace/extension-submission-body.md` as the issue body; explicit prohibition on opening a PR against `catalog.community.json`. *(commit `3659e6c`)*
- [x] T011 [US3] Update `extension.yml` to align with the slimmed catalog-entry shape (consistent tool list with no descriptions; version `0.4.3`). *(commit `3659e6c`)*
- [x] T012 [US3] Add the `[0.4.3]` section to `CHANGELOG.md`: subtitle "Official catalog distribution polish. No bridge runtime behavior changed."; bullets covering README install path change, release-automation alias upload, version-pinned install option, marketplace material updates, tool-metadata slimming. *(commit `3659e6c`)*

---

## Phase 5: Verification (executed by Codex post-release)

**Goal**: Constitution v1.2.0 §"End-User Verification Sandbox" gate satisfied for v0.4.3.

- [x] T013 [US1] Tag `v0.4.3`, push, watch GitHub Actions release workflow complete; capture SHA256 `d3da5b971b39590c66a21b2a76ab5e9c683528b812dd1ab3a71c8b31d959af01` and confirm both assets uploaded. *(Codex; release published 2026-05-16 07:11Z)*
- [x] T014 [US1] Run end-user sandbox install on Windows PowerShell using the stable-alias URL; confirm installed extension version `0.4.3` + short/canonical skill aliases + handoff/guard cycle. Record PASS row in this feature's `verification.md`. *(Codex; 2026-05-16 07:14 UTC)*
- [x] T015 [US1] Run end-user sandbox install on WSL Linux bash using the stable-alias URL; confirm same. Record PASS row. *(Codex; 2026-05-16 07:14 UTC)*
- [x] T016 [US4] Record macOS row as PENDING with documented reason "no host available; deferred per Clarifications Q3" — inherited unchanged from v0.4.2.

---

## Phase 6: Retrospective close-out (this session)

**Goal**: Bring v0.4.3 into Spec Kit compliance after the fact. Move verification rows to the correct location. Drive the 007 handoff through the canonical cycle.

- [x] T017 [US4] Auto-archive 003 handoff (status was `complete` from the v0.4.2 cycle). Result: `feature_directory` cleared, snapshot `20260516T0730026237040Z-ready` emitted to `.specify/bridge-snapshots/`, `archive` event appended to `.specify/bridge-events.jsonl`.
- [x] T018 [US4] Create `specs/007-catalog-distribution-polish/spec.md`, `plan.md`, and this `tasks.md`. Modeled on `specs/006-trim-to-thin-bridge/{spec,plan,tasks}.md` for shape parity.
- [x] T019 [US4] Create `specs/007-catalog-distribution-polish/verification.md` by **moving** the `## v0.4.3` section verbatim from `specs/003-bridge-cross-platform-scripts/verification.md`. Schema follows `../003-bridge-cross-platform-scripts/contracts/verification-record.md`.
- [x] T020 [US4] Remove the `## v0.4.3` section from `specs/003-bridge-cross-platform-scripts/verification.md`; confirm `grep -c '^## v' specs/003-*/verification.md` returns `1`.
- [x] T021 [US4] Update `.specify/feature.json` `feature_directory` to `"specs/007-catalog-distribution-polish"`.
- [ ] T022 [US4] Open 007 handoff: `update-handoff -Status ready -FeatureDirectory specs/007-catalog-distribution-polish -ArtifactOwner claude -Actor claude`. Confirm `.specify/superpowers-handoff.json` shows `feature_directory: specs/007-catalog-distribution-polish`, `status: ready`, `artifact_owner: claude`.
- [ ] T023 [US4] Transition 007 to `executing`: `update-handoff -Status executing -FeatureDirectory specs/007-catalog-distribution-polish -Actor claude` (omit `-ArtifactOwner`; the script preserves prior `claude` per v0.4.2 B1 fix). Confirm `artifact_owner` still `claude`.
- [ ] T024 [US4] SC-005 byte-freeze check: `git diff v0.4.2..HEAD -- .specify/extensions/speckit-superpowers-bridge/scripts/` MUST return empty.
- [ ] T025 [US4] SC-006 spec-history checksum: `git ls-tree -r HEAD specs/001-* specs/002-* specs/004-* specs/005-* specs/006-* | sort | git hash-object --stdin` MUST equal the value at the `v0.4.1` tag.
- [ ] T026 [US4] Commit the 4 new spec files + 003 verification edit + feature.json update. Suggested message: `spec(007 retrospective): record v0.4.3 catalog-distribution-polish + relocate verification`.
- [ ] T027 [US4] Push to `origin/003-cross-platform-cleanup`.
- [ ] T028 [US4] Transition 007 to `complete`: `update-handoff -Status complete -Actor claude`. Confirm SC-007 (status complete, feature_directory specs/007-*, artifact_owner claude).
- [ ] T029 [US4] (Optional) Surface to the user the option to file an "existing-entry update" issue against `github/spec-kit` to bump the public catalog from v0.4.1 → v0.4.3. Per `marketplace/README.md`: issue-based submission, NOT a PR.

---

## Dependencies

- Phase 2–5 depend on Phase 1 (clean v0.4.2 baseline). All complete.
- Phase 6 depends on the auto-archive of 003 (T017) finishing before the spec files reference 007 by name in handoff JSON.
- T022 → T023 → T028 are sequential (each handoff transition depends on the prior state).

## Parallel opportunities

- T005 + T006 (README EN and zh-CN) — different files, no dependency. Codex did them in one commit; could have been parallel.
- T007 + T008 + T009 (3 marketplace files) — different files, no dependency. Done in one commit; parallel safe.

## Implementation strategy

- **MVP**: US1 only. The stable-alias install URL is the user-visible win.
- **Then**: US2 + US3 in any order (catalog-shape + update-procedure docs).
- **Then**: US4 (verification record hygiene + this retrospective spec).

Reality: Codex shipped MVP+US2+US3+verification in two back-to-back commits (`3659e6c` + `70f5c32`). This retrospective adds US4 cleanup (Phase 6) and the Spec Kit compliance trail.
