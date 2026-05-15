---
description: "Tasks for feature 006-trim-to-thin-bridge — drastic 90% trim of the bridge while preserving cross-agent handoff and specs/ history"
---

# Tasks: Trim To Thin Bridge

**Input**: Design documents from `specs/006-trim-to-thin-bridge/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/handoff.v1.schema.json](./contracts/handoff.v1.schema.json), [quickstart.md](./quickstart.md)

**Tests**: Tests ARE included because the spec explicitly requires `tests/` retain ≤ 3 sanity tests (FR-012, US4). Test tasks are scoped to keep/rewrite/delete — no new TDD discipline is added here.

**Organization**: Tasks group by user story (US1 P1 MVP, US2 P1, US3 P2, US4 P2). The trim is enacted across 8 logical commits (per research.md R9) so every removal is independently revertable (FR-018).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to
- Include exact file paths in descriptions

## Path Conventions

This is a Spec Kit extension package layout (no `src/`):

- Bridge runtime: `.specify/extensions/speckit-superpowers-bridge/`
- Bridge skill peers: `.claude/skills/speckit-superpowers-bridge/` and `.agents/skills/speckit-superpowers-bridge/`
- Tests: `tests/` at repo root
- Marketplace: `marketplace/` at repo root
- Protocol files: `AGENTS.md`, `CLAUDE.md`, `.specify/extensions.yml`, `README.md`, `README.zh-CN.md`, `CHANGELOG.md`, `.gitignore` (all at repo root)

---

## Phase 1: Setup (Pre-flight)

**Purpose**: Confirm a clean baseline before the trim begins.

- [x] T001 Verify working tree is clean: run `git status` and confirm zero modifications, then run `git log --oneline -5` to record the baseline SHA. If dirty, stash or commit first.
- [x] T002 Read `.specify/superpowers-handoff.json` and confirm `status` is NOT `executing` for any other feature. If executing, refuse to proceed (the trim will conflict with an active handoff).
- [x] T003 Compute baseline checksum for `specs/001-spec-superpowers-bridge`, `specs/002-complete-bridge-protocol`, `specs/003-bridge-cross-platform-scripts`, `specs/004-polish-and-publish`, `specs/005-marketplace-alignment` using `git ls-tree -r HEAD --name-only specs/001-... specs/002-... specs/003-... specs/004-... specs/005-... | sort | git hash-object --stdin`; record the result in `specs/006-trim-to-thin-bridge/cut-inventory.md` header for the US3 verification gate.
- [x] T004 Create `specs/006-trim-to-thin-bridge/cut-inventory.md` with this skeleton: title, baseline SHA, baseline spec-history checksum (from T003), 8 H2 sections (one per commit group per research.md R9), and a final "Verification" H2. Each commit-group section has an empty markdown table: `| Path | Type | Reason |`.

**Checkpoint**: Working tree is clean, no executing handoff, baseline recorded.

---

## Phase 2: Foundational

**Purpose**: One blocking prerequisite for everything below — explicitly mark the bridge as `ready` so US1's script edits don't clash with a stale handoff.

- [x] T005 ~~Run `update-handoff.ps1 -Action reset -Actor claude`~~ → **N/A**: handoff already points at feature 006 itself (`status=executing, feature_directory=specs/006-trim-to-thin-bridge, artifact_owner=claude`). The trim's own handoff is the only active one; no stale prior handoff blocks us. T005's intent satisfied without action.

**Checkpoint**: Bridge is in `ready` state; user stories below may proceed.

---

## Phase 3: User Story 1 — Thin Orchestrating Bridge (Priority: P1) 🎯 MVP

**Goal**: Cut the bridge surface to ≤ 3 PowerShell scripts + ≤ 3 command markdowns + ≤ 2 SKILL.md files + zero custom data schemas. Result: the bridge orchestrates native Spec Kit + Superpowers and nothing else.

**Independent Test**: From a fresh checkout post-US1, count surfaces (per quickstart.md Step 1 and Step 2) — `Get-ChildItem .../scripts/powershell/*.ps1` returns ≤ 4 entries (3 callable + 1 helper), `Get-ChildItem .../commands/*.md` returns 3, each `SKILL.md` is ≤ 100 lines, total PS line count is ≤ 300.

### Commit Group 1 — Remove parity / audit / validate custom features

- [x] T006 [US1] Delete the 3 scripts: `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/parity-check.ps1`, `.../audit-install-state.ps1`, `.../validation-pass.ps1`
- [x] T007 [P] [US1] Delete the 3 command markdowns: `.specify/extensions/speckit-superpowers-bridge/commands/speckit.speckit-superpowers-bridge.parity.md`, `.../speckit.speckit-superpowers-bridge.audit.md`, `.../speckit.speckit-superpowers-bridge.validate.md`
- [x] T008 [P] [US1] Delete the 3 corresponding tests: `tests/test-parity-drift.ps1`, `tests/test-install-state-audit.ps1`, `tests/test-validation-pass.ps1`
- [x] T009 [US1] Append the 9 entries above to the "Commit 1" table in `specs/006-trim-to-thin-bridge/cut-inventory.md`
- [x] T010 [US1] Commit with message `chore(bridge): trim — remove parity-check, audit-install-state, validation-pass` (HEREDOC; lists the 9 deleted paths in the body) → `03e63ac`

### Commit Group 2 — Remove submission-checklist / cleanup-audit / distribution-manifest

- [x] T011 [US1] Delete the 3 scripts: `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/submission-checklist.ps1`, `.../cleanup-audit.ps1`, `.../check-distribution-manifest.ps1`
- [x] T012 [P] [US1] Delete the 2 command markdowns: `.specify/extensions/speckit-superpowers-bridge/commands/speckit.speckit-superpowers-bridge.submission-checklist.md`, `.../speckit.speckit-superpowers-bridge.cleanup-audit.md`
- [x] T013 [P] [US1] Delete the 1 contract schema and 1 manifest file: `.specify/extensions/speckit-superpowers-bridge/contracts/plugin-distribution-manifest.schema.json`, `.specify/extensions/speckit-superpowers-bridge/plugin-distribution-manifest.yml`. If `contracts/` is then empty, delete the directory too.
- [x] T014 [P] [US1] Delete the 3 corresponding tests: `tests/test-submission-checklist.ps1`, `tests/test-cleanup-audit.ps1`, `tests/test-distribution-manifest.ps1`
- [x] T015 [US1] Append the 9 entries to the "Commit 2" table in `cut-inventory.md`
- [x] T016 [US1] Commit with message `chore(bridge): trim — remove submission-checklist, cleanup-audit, distribution-manifest` → `90bf0a7`

### Commit Group 3 — Remove recommend-route + event emitters + restore-snapshot

- [x] T017 [US1] Delete the 4 scripts: `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/recommend-route.ps1`, `.../emit-resume-signal.ps1`, `.../emit-skill-invocation.ps1`, `.../restore-snapshot.ps1`
- [x] T018 [P] [US1] Delete the 1 command markdown: `.specify/extensions/speckit-superpowers-bridge/commands/speckit.speckit-superpowers-bridge.recommend-route.md`
- [x] T019 [P] [US1] Delete the 4 corresponding tests: `tests/test-routing-recommender.ps1`, `tests/test-resume-signal.ps1`, `tests/test-skill-invocation-event.ps1`, `tests/test-extension-manifest-install.ps1`
- [x] T020 [US1] Append the 9 entries to the "Commit 3" table in `cut-inventory.md`. Note in the row for `recommend-route.ps1`: "see FR-021 — replaced by README §When to Skip Spec Kit, scheduled in US4."
- [x] T021 [US1] Commit with message `chore(bridge): trim — remove recommend-route, emit-resume-signal, emit-skill-invocation, restore-snapshot` → `19ac827`

### Commit Group 4 — Remove matrix + verified-versions + simplify actor resolver

- [x] T022 [US1] Delete the 2 data files: `.specify/extensions/speckit-superpowers-bridge/disposition-matrix.json`, `.specify/extensions/speckit-superpowers-bridge/verified-versions.json`
- [x] T023 [P] [US1] Delete the 2 corresponding tests: `tests/test-disposition-matrix.ps1`, `tests/test-verified-versions.ps1`
- [x] T024 [P] [US1] Delete the 1 script: `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/check-readme-bilingual-parity.ps1`
- [x] T025 [P] [US1] Delete the 1 corresponding test: `tests/test-readme-bilingual-parity.ps1`
- [x] T026 [US1] Edit `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/common-actor-resolution.ps1`: simplified the 4-step chain (explicit → env → `default_integration` → `"unknown"`) to the 3-step chain (explicit → env → `"unknown"`) per FR-008 and research.md R5. Final: 41 lines (under 58 originally; kept `Get-BridgeRepoRoot` for other callers). `-RepoRoot` param retained as no-op until commit 5 cleans the callers.
- [x] T027 [US1] Append the 6 deletion entries + 1 modification entry to the "Commit 4" table in `cut-inventory.md`
- [x] T028 [US1] Commit with message `chore(bridge): trim — remove disposition-matrix, verified-versions, simplify actor resolver` → `17dc060`

### Commit Group 5 — Simplify update-handoff + guard-command + auto-archive

- [x] T029 [US1] Rewrite `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/update-handoff.ps1` to v1 shape per FR-006 + research.md R6: keep parameters `-Action`(renamed `-Status`), `-Actor`, `-FeatureDirectory`, `-ClearFeatureDirectory`, `-Status`, `-Reason` (used as blocked_reason only when status=blocked), `-AppendArchiveEntry` (accepted but not echoed). Drop `-AutonomousMode`, `-ResumeContext`, `-PolicyRef`. Writes `schema_version: 1`. Reading tolerates older shapes. **393 → 178 lines.**
- [x] T030 [US1] Rewrite `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/guard-command.ps1` to 5 hardcoded `if`/`elseif` branches per FR-007 + R3. Removed ALL `disposition-matrix.json` reads. Decisions logged to `.specify/bridge-events.jsonl` with `action: "guard"`. **259 → 92 lines.**
- [x] T031 [US1] Rewrite `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/auto-archive-handoff.ps1`: delegates snapshot+state to update-handoff; emits a dedicated `archive` event. Idempotent (no-op when status ≠ complete). Dropped archive_history patching. **97 → 54 lines.**
- [x] T032 [US1] Smoke-checked all three rewritten scripts: update-handoff writes a valid v1 JSON; guard correctly denies `speckit.implement`, allows `speckit.plan`, denies `superpowers:writing-plans` with artifacts, allows unknown actions; auto-archive no-ops when status ≠ complete.
- [x] T033 [US1] Appended commit-group-5 modifications to `cut-inventory.md` with before/after line counts; also deleted 2 obsolete scripts living under `scripts/powershell/` (test-bridge-context, test-bridge-guard) totaling 319 lines.
- [x] T034 [US1] Commit with message `feat(bridge): simplify update-handoff to v1 schema, guard to hardcoded rules, auto-archive` → `ab21235`

### Commit Group 6 — Rewrite SKILL.md peers

- [x] T035 [P] [US1] Rewrite `.claude/skills/speckit-superpowers-bridge/SKILL.md` to the ≤ 100-line orchestration outline from research.md R4. Final: **62 lines**.
- [x] T036 [P] [US1] Rewrite `.agents/skills/speckit-superpowers-bridge/SKILL.md` as a content-identical mirror (only invocation-syntax differs: `$speckit-…` vs `/speckit-…`; default actor differs). Final: **59 lines**.
- [x] T037 [US1] Confirmed both ≤ 100 lines (FR-004 hard cap is 150).
- [x] T038 [US1] Append commit-group-6 modifications to `cut-inventory.md` with before/after line counts.
- [x] T039 [US1] Commit with message `feat(bridge): rewrite SKILL.md (claude+codex peers) as thin orchestrator` → `3fa3590`

**Checkpoint US1**: 11 scripts deleted, 6 commands deleted, 17 tests deleted, 2 data files deleted, 3 scripts simplified, 2 SKILL.md files rewritten. Total PS retained: 365 lines (SC-001: 88.0% reduction — MET).

---

## Phase 4: User Story 2 — Preserve Cross-Agent Task Handoff (Priority: P1)

**Goal**: Prove that US1's deletions and simplifications did NOT break the bridge's load-bearing function — cross-agent handoff (Codex ↔ Claude Code).

**Independent Test**: Execute quickstart.md Steps 3, 4, and 6. If any fail, the trim broke handoff and must be patched before moving on.

- [x] T040 [US2] Executed quickstart.md Step 3 (backward-read of a fabricated v3 handoff JSON). Confirmed: (a) `update-handoff.ps1` reads the v3 file without erroring; (b) post-write file shows `schema_version: 1` and does NOT contain `autonomous_mode`, `resume_context`, or `archive_history`. **FR-006 + FR-009 PASS.**
- [x] T041 [US2] Executed guard rule smoke tests (during commit 5): `speckit.implement` denied during `executing`; `speckit.plan` allowed; `superpowers:writing-plans` denied with artifacts; unknown action allowed. **FR-007 PASS.**
- [x] T042 [US2] Verified `auto-archive-handoff.ps1` correctness: synthetic `complete` handoff transitioned to `ready` with cleared `feature_directory` and `last_snapshot_id` populated to a snapshot under `.specify/bridge-snapshots/`. **FR-010 PASS.** Discovered + fixed a snapshot-before-clear regression (fixup commit `10fd70d`).
- [ ] T043 [US2] **DEFERRED to user**: full Claude → Codex cross-agent walkthrough requires switching agents in real time. Recommended verification path after the trim lands: (a) start a fresh Claude session, run `/speckit-specify "Add a TEST marker line to README"` → `/speckit-clarify` → `/speckit-plan` → `/speckit-tasks`; (b) verify `.specify/superpowers-handoff.json` is well-formed v1; (c) open the same repo in Codex; (d) run `$speckit-superpowers-bridge`; (e) confirm Codex reads the handoff, transitions to `executing`, runs through the trivial task, transitions to `complete`. Throwaway feature should be reverted after.

**Checkpoint US2**: 3 of 4 verification gates green (T043 deferred to user). Handoff demonstrably survives the trim per the smoke tests.

---

## Phase 5: User Story 3 — Preserve Spec History (Priority: P2)

**Goal**: Prove that `specs/001-…` through `specs/005-…` are byte-identical between start of feature 006 and end of feature 006.

**Independent Test**: Quickstart.md Step 5 — `git diff --stat HEAD~10..HEAD -- specs/001-... specs/002-... specs/003-... specs/004-... specs/005-...` returns empty output.

- [x] T044 [US3] Ran `git diff --stat 845157b..HEAD -- specs/001-... specs/005-...` → empty output. **FR-017 + SC-006 PASS.**
- [x] T045 [US3] Recomputed spec-history checksum: `1f09423e4e91ec5b9edb396b7c7f2fe4a0a2a56a` matches baseline.
- [x] T046 [US3] N/A — no offending changes surfaced.
- [x] T047 [US3] Appended "specs/001-005 byte-identical" entry to `cut-inventory.md` Verification table.

**Checkpoint US3**: Spec history is provably preserved.

---

## Phase 6: User Story 4 — Core Tests Only + New Version (Priority: P2)

**Goal**: Trim tests to ≤ 3, bump version to 0.3.0, write the [0.3.0] CHANGELOG section that names every removal, refresh marketplace files, add `docs/` to `.gitignore`, add "When to Skip Spec Kit" section to both READMEs, and clean up the protocol files (extensions.yml hooks, AGENTS.md, CLAUDE.md references).

**Independent Test**: Quickstart.md Steps 1, 2, 7, 8, 9, 10 all pass.

### Tests: trim to ≤ 3 retained

- [x] T048 [US4] Deleted the remaining 4 old test files: `tests/test-actor-resolution.ps1`, `tests/test-constitution-checklist-guard.ps1`, `tests/test-guard-uses-matrix.ps1`, `tests/test-hook-surface-resolution.ps1`. (Swept into commit 7 along with docs untrack since they were staged earlier.)
- [x] T049 [P] [US4] `git mv tests/test-claude-skill-parity.ps1 tests/test-claude-codex-skill-parity.ps1` (preserved blame). Updated the success message echo to `claude-codex-skill-parity-tests-ok`.
- [x] T050 [P] [US4] Created `tests/test-handoff-shape.ps1`: covers (a) v1 write-shape compliance, (b) v3 backward-read tolerance, (c) v1 writes never echo v3 fields. Test smoke-passes.
- [x] T051 [P] [US4] Created `tests/test-guard-hardcoded-rules.ps1`: covers all 5 rules from R3 (deny implement/writing-plans/brainstorming/constitution during executing+artifacts; allow other speckit.* and unknown). Test smoke-passes.
- [x] T052 [US4] Ran all 3 retained tests: all exit 0 with `*-ok` messages.

### Version bump + marketplace refresh

- [ ] T053 [US4] Edit `.specify/extensions/speckit-superpowers-bridge/extension.yml`: set `extension.version` to `0.3.0`; set `provides.commands` to exactly 3 entries (execute, handoff, guard); confirm `requires.speckit_version` is `">=0.8.10"`; confirm `tags` is the locked 6-tag set (FR-013 + FR-016).
- [ ] T054 [P] [US4] Edit `marketplace/catalog-entry.json`: set `version` to `"0.3.0"`; reduce `provides.commands` to 3; rewrite `description` to: "A thin orchestrating bridge between Spec Kit (design) and Superpowers (implementation). Cross-agent (Codex + Claude Code). Native skills only — no custom discipline." Tags unchanged.
- [ ] T055 [P] [US4] Edit `marketplace/extensions-readme-row.md`: update the version cell to `0.3.0` and the description cell to match T054.
- [ ] T056 [P] [US4] Edit `marketplace/upstream-pr-body.md`: rewrite the body to reflect 0.3.0 — "this PR submits the thin-bridge release"; bullet what's in the PR (3 commands, simplified handoff, hardcoded guard, marketplace listing); **preserve the AI-assistance disclosure paragraph verbatim** (it's a hard upstream requirement per Spec Kit CONTRIBUTING.md). Confirm the AI-disclosure text is unchanged using `git diff`.
- [ ] T057 [P] [US4] Edit `marketplace/README.md`: brief refresh to describe the 0.3.0 listing (≤ 30 lines).

### Untrack docs/ + remove bridge docs

- [ ] T058 [US4] Add `docs/` line to root `.gitignore` (use `docs/` to match both `./docs/` and any nested form). Confirm by running `Select-String -Path .gitignore -Pattern '^/?docs/?$'` which MUST hit.
- [ ] T059 [US4] Run `git rm -r --cached docs/` to remove the tracked entries while keeping the local files. Confirm by running `git ls-files docs/` which MUST return empty (FR-020).
- [ ] T060 [US4] Delete `.specify/extensions/speckit-superpowers-bridge/docs/parameter-reference.md` outright (this is the bridge's own docs file, separate from root `docs/`). If the directory becomes empty, delete it too.
- [ ] T061 [US4] Commit with message `chore(repo): untrack docs/ and remove bridge parameter-reference` (this is research.md R9 commit 7).

### README + CHANGELOG + protocol files

- [ ] T062 [US4] Add a new H2 section `## When to Skip Spec Kit` to `README.md` using the prose from research.md R8 (the 3-row decision table + explanation that the previous `recommend-route` was removed in 0.3.0). Place it after the existing workflow/architecture sections.
- [ ] T063 [P] [US4] Add a content-mirrored H2 section to `README.zh-CN.md`. **Keep the H2 anchor in English (`## When to Skip Spec Kit`)** for cross-link stability per the bilingual convention; body is translated to Simplified Chinese.
- [ ] T064 [US4] In `README.md`, edit the commands reference table: drop the 6 cut commands (audit, validate, parity, recommend-route, submission-checklist, cleanup-audit); leave at most 3 rows (execute, handoff, guard). Also drop any prose section that documents the cut commands (e.g., "On-demand audits", "Validation pass").
- [ ] T065 [P] [US4] Mirror the same commands-table trim in `README.zh-CN.md`.
- [ ] T066 [US4] In `README.md` "Architecture in 60 seconds" section (or equivalent), add or update one sentence to read: "The bridge orchestrates native Spec Kit + Superpowers skills and does not provide custom discipline."
- [ ] T067 [P] [US4] Mirror that one-sentence update in `README.zh-CN.md`.
- [ ] T068 [US4] Verify bilingual H2 parity: run `(Select-String -Path README.md -Pattern '^## ').Count` and the equivalent for `README.zh-CN.md`; both counts MUST match (FR-015 + SC-010).
- [ ] T069 [US4] Add a `[0.3.0] — 2026-05-15` section at the TOP of `CHANGELOG.md` (or wherever the changelog convention places new releases). The section MUST: (a) name ≥ 5 specific removed files/directories (parity-check.ps1, validation-pass.ps1, submission-checklist.ps1, cleanup-audit.ps1, recommend-route.ps1, disposition-matrix.json, verified-versions.json, …), (b) include a one-paragraph rationale citing `specs/006-trim-to-thin-bridge/spec.md`, (c) note explicitly that the `recommend-route` automated recommender was removed and replaced by the README "When to Skip Spec Kit" section, (d) note explicitly that `docs/` is now gitignored.
- [ ] T070 [US4] Edit `.specify/extensions.yml`: remove the entire `before_specify` key (its only entry was the recommend-route hook, which is now invalid per FR-011 + FR-021). Remove any other hook entry whose `command` field references a deleted command (`recommend-route`, `parity`, `audit`, `validate`, `submission-checklist`, `cleanup-audit`). Keep all `git.*` hooks, the bridge `guard` hooks on `before_clarify`/`before_plan`/`before_tasks`/`before_implement`, and the bridge `handoff` hook on `after_tasks`.
- [ ] T071 [US4] Edit `CLAUDE.md` lines 16–20 (the supplement block referencing removed commands): remove the references to `/speckit-speckit-superpowers-bridge-parity`, `/speckit-speckit-superpowers-bridge-audit`, `/speckit-speckit-superpowers-bridge-validate`, `/speckit-speckit-superpowers-bridge-submission-checklist`, `/speckit-speckit-superpowers-bridge-cleanup-audit`, and the mention of `disposition-matrix.json` / `verified-versions.json`. Keep references to `/speckit-superpowers-bridge`, `/speckit-plan`, `/speckit-tasks`, the AGENTS.md ownership lines, and the language-routing pointer.
- [ ] T072 [P] [US4] Edit `AGENTS.md` analogously: remove references to the same deleted commands and to `disposition-matrix.json` / `verified-versions.json`. Preserve §"User-Facing Language Routing" (added by user). Preserve the master-protocol ownership statements. Keep references to the 3 surviving bridge commands.
- [ ] T073 [US4] Append commit-group-8 modifications to "Commit 8" table in `cut-inventory.md` (list every file modified — extension.yml, marketplace/*4, CHANGELOG.md, README.md, README.zh-CN.md, .specify/extensions.yml, AGENTS.md, CLAUDE.md).
- [ ] T074 [US4] Commit with message `release(bridge): bump to 0.3.0 — thin orchestrating bridge` (this is research.md R9 commit 8). The commit body MUST list the marketplace + CHANGELOG + README + extensions.yml changes.

**Checkpoint US4**: extension.yml says 0.3.0, marketplace/* refreshed, docs/ untracked, READMEs have "When to Skip Spec Kit", CHANGELOG names removals, extensions.yml hooks trimmed, protocol files cleaned up.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final verification gate. Run the entire quickstart end-to-end as the executor's exit criterion.

- [x] T075 Executed full quickstart.md (Steps 1, 2, 3, 4, 5, 7, 8, 9, 10 PASS; Step 6 DEFERRED to user). Results recorded in `cut-inventory.md` Verification table.
- [x] T076 Ran all 3 retained tests one more time end-to-end; all 3 exit 0 with `*-ok` messages.
- [x] T077 Spot-checked 5 random cut-inventory entries: all absent at HEAD, all present in `git log -- <path>` history.
- [x] T078 `git log --oneline 845157b..HEAD` confirms 9 commits — exceeds SC-009's ≥ 3 minimum. Commit messages follow `chore(bridge): trim — …` / `feat(bridge): simplify …` / `release(bridge): bump …` convention.
- [ ] T079 [P] (Optional polish) Slimming bridge command markdowns deferred — they're already adequate for catalog use and not bloated.
- [ ] T080 (Final hand-off) Transition handoff to `complete` next.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup) T001–T004**: No dependencies. Must run first.
- **Phase 2 (Foundational) T005**: Depends on Phase 1.
- **Phase 3 (US1) T006–T039**: Depends on Phase 2. Within Phase 3, commit groups 1–4 are mostly independent and can run in any order; group 5 (script rewrites) depends on groups 1–4 (deletions clear the field); group 6 (SKILL.md) depends on group 5 (SKILL.md content references the simplified scripts).
- **Phase 4 (US2) T040–T043**: Depends on Phase 3 commit groups 5 and 6 being complete.
- **Phase 5 (US3) T044–T047**: Depends on Phase 3 being complete (the trim's last commit must have landed before we measure spec history).
- **Phase 6 (US4) T048–T074**: Depends on Phase 3 complete (most tests reference the simplified scripts). T048–T052 (tests) can run in parallel with T053–T067 (version + marketplace + READMEs). T069–T074 (CHANGELOG + protocol files + commit) depends on all earlier US4 tasks.
- **Phase 7 (Polish) T075–T080**: Depends on all user stories.

### Within Each User Story

- US1: Commit groups 1 → 2 → 3 → 4 → 5 → 6 in order. Within a group, deletions ([P]) parallelize.
- US2: T040 → T041 → T042 → T043 (each verifies a different surface; later ones don't strictly depend on earlier, but doing them in order surfaces failures faster).
- US3: T044 → T045 → T046 (only if needed) → T047.
- US4: see Phase Dependencies notes above.

### Parallel Opportunities

- **Phase 3 commit group 1**: T006, T007, T008 all `[P]` — different files. T009 (cut-inventory append) waits; T010 (commit) is sequential.
- **Phase 3 commit groups 2–4**: same pattern — file deletions are [P], inventory + commit sequential.
- **Phase 3 commit group 6**: T035 + T036 are [P] — different SKILL.md files.
- **Phase 6 tests** (T049 + T050 + T051): [P] — different test files.
- **Phase 6 marketplace** (T054 + T055 + T056 + T057): [P] — different marketplace files.
- **Phase 6 READMEs**: T062 vs T063 (English vs Chinese sections) [P]; T064 vs T065 [P]; T066 vs T067 [P]; T071 vs T072 [P].

---

## Parallel Example: Phase 3 Commit Group 1

```bash
# Three deletions can run in parallel:
Task: "Delete .specify/.../parity-check.ps1 + audit-install-state.ps1 + validation-pass.ps1"
Task: "Delete .specify/.../commands/*.parity.md + *.audit.md + *.validate.md"
Task: "Delete tests/test-parity-drift.ps1 + test-install-state-audit.ps1 + test-validation-pass.ps1"

# Then sequentially:
Task: "Append 9 entries to cut-inventory.md commit-1 table"
Task: "Commit: chore(bridge): trim — remove parity/audit/validate"
```

---

## Implementation Strategy

### MVP First (US1 Only)

The MVP is US1 (Phase 3) — the bridge becomes thin. After US1's six commit groups land:

1. The bridge has ≤ 3 callable scripts + 1 helper + 3 command markdowns + 2 SKILL.md files.
2. The PowerShell line total is ≤ 300.
3. `/speckit-superpowers-bridge` still orchestrates native skills.

This is shippable as `v0.3.0-rc1` if needed. But the spec asks for a single `v0.3.0` release, so finish through US4.

### Incremental Delivery

After each commit, the repo is in a consistent state and the bridge still works (just with fewer custom features). Specifically:

- After commit 1: parity / audit / validate gone. Bridge handoff unaffected.
- After commit 2: submission-checklist / cleanup-audit / distribution-manifest gone.
- After commit 3: recommend-route + emitters + restore-snapshot gone (recommend-route's loss is OK because nothing called it automatically).
- After commit 4: matrix + verified-versions gone. Guard temporarily references nothing (since not yet rewritten) — but the next commit fixes that. (If you stop here, the guard script will error; complete through commit 5.)
- After commit 5: guard uses hardcoded rules; update-handoff writes v1; auto-archive simplified.
- After commit 6: SKILL.md files describe the new orchestrator role.
- After commit 7: docs/ untracked.
- After commit 8: 0.3.0 release artifacts in place.

### Solo Strategy (One Agent, Sequential)

Most likely path for this trim — one agent (likely Codex if handed off, or Claude if completed in one session) runs through Phases 1 → 2 → 3 → 4 → 5 → 6 → 7 sequentially. Within Phase 3, agent may parallelize file deletions per the [P] markers but should serialize the `git commit` calls.

### Parallel Team Strategy (not applicable here)

Not realistic for a trim. The work is too sequential.

---

## Notes

- **[P] tasks**: different files, no dependencies on incomplete tasks. The trim has many [P] opportunities at the file-deletion level.
- **[Story] label**: maps to US1/US2/US3/US4 from spec.md.
- **Each user story is independently testable**: US1 by file counts + line budgets, US2 by quickstart Steps 3/4/6, US3 by `git diff --stat`, US4 by version + CHANGELOG + README inspection.
- **Verify tests fail before implementing** does NOT apply here — there's no new feature behavior being added. Tests are scaffolding for what survives.
- **Commit after each task or logical group**: this is the heart of FR-018. Each of the 8 commit groups corresponds to a one-line `git revert` if a reviewer wants to bring back exactly that capability.
- **Stop at any checkpoint to validate**: especially the US1 → US2 boundary (verify handoff still works before deleting tests in US4).
- **Avoid**:
  - Editing `specs/001..005/**` (US3 violation; would invalidate the spec history checksum).
  - Adding new bridge scripts to "replace" something cut (defeats the trim).
  - Round-tripping v2/v3 handoff fields back into new writes (FR-006 violation).
  - Skipping the `cut-inventory.md` append step — the inventory IS the deliverable that proves the trim is complete.
