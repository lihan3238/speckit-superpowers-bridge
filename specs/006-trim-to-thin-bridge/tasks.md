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

- [ ] T001 Verify working tree is clean: run `git status` and confirm zero modifications, then run `git log --oneline -5` to record the baseline SHA. If dirty, stash or commit first.
- [ ] T002 Read `.specify/superpowers-handoff.json` and confirm `status` is NOT `executing` for any other feature. If executing, refuse to proceed (the trim will conflict with an active handoff).
- [ ] T003 Compute baseline checksum for `specs/001-spec-superpowers-bridge`, `specs/002-complete-bridge-protocol`, `specs/003-bridge-cross-platform-scripts`, `specs/004-polish-and-publish`, `specs/005-marketplace-alignment` using `git ls-tree -r HEAD --name-only specs/001-... specs/002-... specs/003-... specs/004-... specs/005-... | sort | git hash-object --stdin`; record the result in `specs/006-trim-to-thin-bridge/cut-inventory.md` header for the US3 verification gate.
- [ ] T004 Create `specs/006-trim-to-thin-bridge/cut-inventory.md` with this skeleton: title, baseline SHA, baseline spec-history checksum (from T003), 8 H2 sections (one per commit group per research.md R9), and a final "Verification" H2. Each commit-group section has an empty markdown table: `| Path | Type | Reason |`.

**Checkpoint**: Working tree is clean, no executing handoff, baseline recorded.

---

## Phase 2: Foundational

**Purpose**: One blocking prerequisite for everything below — explicitly mark the bridge as `ready` so US1's script edits don't clash with a stale handoff.

- [ ] T005 Run `powershell.exe -NoProfile -File .specify/extensions/speckit-superpowers-bridge/scripts/powershell/update-handoff.ps1 -Action reset -Actor claude` (or whatever verb the current `update-handoff.ps1` provides for transitioning to `ready` and clearing `feature_directory`). Confirm `.specify/superpowers-handoff.json` shows `status: ready` and `feature_directory: null` afterward.

**Checkpoint**: Bridge is in `ready` state; user stories below may proceed.

---

## Phase 3: User Story 1 — Thin Orchestrating Bridge (Priority: P1) 🎯 MVP

**Goal**: Cut the bridge surface to ≤ 3 PowerShell scripts + ≤ 3 command markdowns + ≤ 2 SKILL.md files + zero custom data schemas. Result: the bridge orchestrates native Spec Kit + Superpowers and nothing else.

**Independent Test**: From a fresh checkout post-US1, count surfaces (per quickstart.md Step 1 and Step 2) — `Get-ChildItem .../scripts/powershell/*.ps1` returns ≤ 4 entries (3 callable + 1 helper), `Get-ChildItem .../commands/*.md` returns 3, each `SKILL.md` is ≤ 100 lines, total PS line count is ≤ 300.

### Commit Group 1 — Remove parity / audit / validate custom features

- [ ] T006 [US1] Delete the 3 scripts: `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/parity-check.ps1`, `.../audit-install-state.ps1`, `.../validation-pass.ps1`
- [ ] T007 [P] [US1] Delete the 3 command markdowns: `.specify/extensions/speckit-superpowers-bridge/commands/speckit.speckit-superpowers-bridge.parity.md`, `.../speckit.speckit-superpowers-bridge.audit.md`, `.../speckit.speckit-superpowers-bridge.validate.md`
- [ ] T008 [P] [US1] Delete the 3 corresponding tests: `tests/test-parity-drift.ps1`, `tests/test-install-state-audit.ps1`, `tests/test-validation-pass.ps1`
- [ ] T009 [US1] Append the 9 entries above to the "Commit 1" table in `specs/006-trim-to-thin-bridge/cut-inventory.md`
- [ ] T010 [US1] Commit with message `chore(bridge): trim — remove parity-check, audit-install-state, validation-pass` (HEREDOC; lists the 9 deleted paths in the body)

### Commit Group 2 — Remove submission-checklist / cleanup-audit / distribution-manifest

- [ ] T011 [US1] Delete the 3 scripts: `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/submission-checklist.ps1`, `.../cleanup-audit.ps1`, `.../check-distribution-manifest.ps1`
- [ ] T012 [P] [US1] Delete the 2 command markdowns: `.specify/extensions/speckit-superpowers-bridge/commands/speckit.speckit-superpowers-bridge.submission-checklist.md`, `.../speckit.speckit-superpowers-bridge.cleanup-audit.md`
- [ ] T013 [P] [US1] Delete the 1 contract schema and 1 manifest file: `.specify/extensions/speckit-superpowers-bridge/contracts/plugin-distribution-manifest.schema.json`, `.specify/extensions/speckit-superpowers-bridge/plugin-distribution-manifest.yml`. If `contracts/` is then empty, delete the directory too.
- [ ] T014 [P] [US1] Delete the 3 corresponding tests: `tests/test-submission-checklist.ps1`, `tests/test-cleanup-audit.ps1`, `tests/test-distribution-manifest.ps1`
- [ ] T015 [US1] Append the 9 entries to the "Commit 2" table in `cut-inventory.md`
- [ ] T016 [US1] Commit with message `chore(bridge): trim — remove submission-checklist, cleanup-audit, distribution-manifest`

### Commit Group 3 — Remove recommend-route + event emitters + restore-snapshot

- [ ] T017 [US1] Delete the 4 scripts: `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/recommend-route.ps1`, `.../emit-resume-signal.ps1`, `.../emit-skill-invocation.ps1`, `.../restore-snapshot.ps1`
- [ ] T018 [P] [US1] Delete the 1 command markdown: `.specify/extensions/speckit-superpowers-bridge/commands/speckit.speckit-superpowers-bridge.recommend-route.md`
- [ ] T019 [P] [US1] Delete the 4 corresponding tests: `tests/test-routing-recommender.ps1`, `tests/test-resume-signal.ps1`, `tests/test-skill-invocation-event.ps1`, `tests/test-extension-manifest-install.ps1`
- [ ] T020 [US1] Append the 9 entries to the "Commit 3" table in `cut-inventory.md`. Note in the row for `recommend-route.ps1`: "see FR-021 — replaced by README §When to Skip Spec Kit, scheduled in US4."
- [ ] T021 [US1] Commit with message `chore(bridge): trim — remove recommend-route, emit-resume-signal, emit-skill-invocation, restore-snapshot`

### Commit Group 4 — Remove matrix + verified-versions + simplify actor resolver

- [ ] T022 [US1] Delete the 2 data files: `.specify/extensions/speckit-superpowers-bridge/disposition-matrix.json`, `.specify/extensions/speckit-superpowers-bridge/verified-versions.json`
- [ ] T023 [P] [US1] Delete the 2 corresponding tests: `tests/test-disposition-matrix.ps1`, `tests/test-verified-versions.ps1`
- [ ] T024 [P] [US1] Delete the 1 script: `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/check-readme-bilingual-parity.ps1`
- [ ] T025 [P] [US1] Delete the 1 corresponding test: `tests/test-readme-bilingual-parity.ps1`
- [ ] T026 [US1] Edit `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/common-actor-resolution.ps1`: simplify the 4-step chain (explicit → env → `default_integration` → `"unknown"`) to the 3-step chain (explicit → env → `"unknown"`) per FR-008 and research.md R5. Target ≤ 30 lines. Remove any code that reads `.specify/integration.json`.
- [ ] T027 [US1] Append the 6 entries to the "Commit 4" table in `cut-inventory.md`
- [ ] T028 [US1] Commit with message `chore(bridge): trim — remove disposition-matrix, verified-versions, simplify actor resolver`

### Commit Group 5 — Simplify update-handoff + guard-command + auto-archive

- [ ] T029 [US1] Rewrite `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/update-handoff.ps1` to v1 shape per FR-006 + research.md R6: keep parameters `-Action`, `-Actor`, `-FeatureDirectory`, `-ClearFeatureDirectory`, `-Status`, `-BlockedReason`, `-Notes`, `-AppendArchiveEntry`; drop parameters `-AutonomousMode`, `-ResumeContext`, `-PolicyRef`. Schema written must match `specs/006-trim-to-thin-bridge/contracts/handoff.v1.schema.json` (only the v1 fields, `schema_version: 1`). Reading MUST tolerate older shapes (v2/v3 unknown fields ignored without error per FR-009). Target ≤ 130 lines.
- [ ] T030 [US1] Rewrite `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/guard-command.ps1` to use 5 hardcoded `if`/`elseif` branches per FR-007 + research.md R3: (1) deny `speckit.implement` when handoff status is `executing`, (2) deny `superpowers:writing-plans` / `:brainstorming` when active feature has `spec.md` AND `plan.md`, (3) deny `speckit.constitution` when handoff status is `executing`, (4) allow any other `speckit.*`, (5) allow default. Remove ALL `disposition-matrix.json` reads. Log every decision to `.specify/bridge-events.jsonl` with `action: "guard"`. Target ≤ 90 lines.
- [ ] T031 [US1] Rewrite `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/auto-archive-handoff.ps1` to: take snapshot of prior feature artifacts under `.specify/bridge-snapshots/<timestamp>/`, transition handoff `complete` → `ready`, clear `feature_directory`. Drop the `-AppendArchiveEntry` invocation if the v1 schema makes `archive_history` optional (FR-010 permits this). Target ≤ 75 lines. Confirm it dot-sources `common-actor-resolution.ps1` and accepts `-Actor`.
- [ ] T032 [US1] Run all three rewritten scripts with `powershell.exe -NoProfile -Command "$ErrorActionPreference='Stop'; & .\<script>.ps1 -Action ..."` smoke checks; confirm no syntax errors and that a roundtrip write→read of `superpowers-handoff.json` produces a valid v1 document.
- [ ] T033 [US1] Append commit-group-5 modifications to "Commit 5" table in `cut-inventory.md` (3 files modified — list before/after line counts).
- [ ] T034 [US1] Commit with message `feat(bridge): simplify update-handoff to v1 schema, guard to hardcoded rules, auto-archive`

### Commit Group 6 — Rewrite SKILL.md peers

- [ ] T035 [P] [US1] Rewrite `.claude/skills/speckit-superpowers-bridge/SKILL.md` to the ≤ 100-line orchestration outline from research.md R4: frontmatter (5 lines), Purpose (8), When to use (4), What this skill does (20-line numbered list with the 9 orchestration steps), Boundary rules (8 — same policy as the hardcoded guard, in prose), Cross-agent notes (6), When something goes wrong (8). Remove all references to `disposition-matrix.json`, `verified-versions.json`, parity, validation pass, submission checklist, cleanup audit, recommend-route, emit-skill-invocation, emit-resume-signal, restore-snapshot, distribution-manifest.
- [ ] T036 [P] [US1] Rewrite `.agents/skills/speckit-superpowers-bridge/SKILL.md` as a content-identical mirror of T035 (only the frontmatter `name` may differ if convention requires it — verify by comparing structures). The Codex peer MUST have the same numbered orchestration steps and same boundary rules.
- [ ] T037 [US1] Run `wc -l .claude/skills/speckit-superpowers-bridge/SKILL.md .agents/skills/speckit-superpowers-bridge/SKILL.md` and confirm both ≤ 100 lines (FR-004 hard cap is 150).
- [ ] T038 [US1] Append commit-group-6 modifications to "Commit 6" table in `cut-inventory.md` (2 files modified — list before/after line counts).
- [ ] T039 [US1] Commit with message `feat(bridge): rewrite SKILL.md (claude+codex peers) as thin orchestrator`

**Checkpoint US1**: 11 scripts deleted, 6 commands deleted, 17 tests deleted, 2 data files deleted, 3 scripts simplified, 2 SKILL.md files rewritten. Total PS line count must now be ≤ 300 (run `wc -l .specify/extensions/speckit-superpowers-bridge/scripts/powershell/*.ps1` to verify SC-001).

---

## Phase 4: User Story 2 — Preserve Cross-Agent Task Handoff (Priority: P1)

**Goal**: Prove that US1's deletions and simplifications did NOT break the bridge's load-bearing function — cross-agent handoff (Codex ↔ Claude Code).

**Independent Test**: Execute quickstart.md Steps 3, 4, and 6. If any fail, the trim broke handoff and must be patched before moving on.

- [ ] T040 [US2] Execute quickstart.md Step 3 (backward-read of a fabricated v3 handoff JSON). Confirm: (a) `update-handoff.ps1` reads the v3 file without erroring, (b) after a write, the resulting file does NOT contain `autonomous_mode`, `resume_context`, or `archive_history` (FR-006 + FR-009 verification). If fails: patch T029.
- [ ] T041 [US2] Execute quickstart.md Step 4 (3 hardcoded guard rule checks). Confirm: (a) `speckit.implement` returns non-zero exit when handoff is `executing`, (b) `speckit.plan` returns 0, (c) `superpowers:writing-plans` returns non-zero exit when active feature has `spec.md` + `plan.md` (FR-007 verification). If fails: patch T030.
- [ ] T042 [US2] Verify `auto-archive-handoff.ps1` correctness manually: write a synthetic `complete` handoff JSON, invoke the script, confirm post-state is `ready` with `feature_directory: null` and a snapshot directory exists under `.specify/bridge-snapshots/` (FR-010 verification). If fails: patch T031.
- [ ] T043 [US2] Execute quickstart.md Step 6 (full Claude → Codex cross-agent walkthrough on a throwaway test feature). This is a real handoff — not a synthetic one. Run from a clean Claude session: `/speckit-specify` → `/speckit-clarify` → `/speckit-plan` → `/speckit-tasks` → confirm `.specify/superpowers-handoff.json` is well-formed → open Codex on the same repo → invoke `$speckit-superpowers-bridge` → confirm Codex reads the handoff, transitions to `executing`, runs through one task using `superpowers:executing-plans` → completes → transitions to `complete`. The throwaway feature should be trivial (e.g., add a test marker line to README and revert at the end).

**Checkpoint US2**: All 4 verification gates green. Handoff demonstrably survives the trim.

---

## Phase 5: User Story 3 — Preserve Spec History (Priority: P2)

**Goal**: Prove that `specs/001-…` through `specs/005-…` are byte-identical between start of feature 006 and end of feature 006.

**Independent Test**: Quickstart.md Step 5 — `git diff --stat HEAD~10..HEAD -- specs/001-... specs/002-... specs/003-... specs/004-... specs/005-...` returns empty output.

- [ ] T044 [US3] Run `git diff --stat <baseline-SHA-from-T001>..HEAD -- specs/001-spec-superpowers-bridge specs/002-complete-bridge-protocol specs/003-bridge-cross-platform-scripts specs/004-polish-and-publish specs/005-marketplace-alignment`. Confirm empty output (FR-017 + SC-006 verification).
- [ ] T045 [US3] Recompute the spec-history checksum (same command as T003) and compare against the baseline recorded in `cut-inventory.md`. They MUST match.
- [ ] T046 [US3] If T044 or T045 surfaces any change under `specs/001..005/`, identify the offending commit (likely a stray edit), `git restore --source=<baseline-SHA> <path>`, and amend the relevant commit. Re-run T044+T045.
- [ ] T047 [US3] Append "Verification: spec history byte-identical (checksum X)" line to `cut-inventory.md` under the final "Verification" H2.

**Checkpoint US3**: Spec history is provably preserved.

---

## Phase 6: User Story 4 — Core Tests Only + New Version (Priority: P2)

**Goal**: Trim tests to ≤ 3, bump version to 0.3.0, write the [0.3.0] CHANGELOG section that names every removal, refresh marketplace files, add `docs/` to `.gitignore`, add "When to Skip Spec Kit" section to both READMEs, and clean up the protocol files (extensions.yml hooks, AGENTS.md, CLAUDE.md references).

**Independent Test**: Quickstart.md Steps 1, 2, 7, 8, 9, 10 all pass.

### Tests: trim to ≤ 3 retained

- [ ] T048 [US4] Delete the remaining 4 old test files NOT yet removed by US1: `tests/test-actor-resolution.ps1`, `tests/test-constitution-checklist-guard.ps1`, `tests/test-guard-uses-matrix.ps1`, `tests/test-hook-surface-resolution.ps1`. (US1 commits 1–4 deleted 13 test files; this completes the cut.)
- [ ] T049 [P] [US4] `git mv tests/test-claude-skill-parity.ps1 tests/test-claude-codex-skill-parity.ps1` (preserves blame). Edit the renamed file to verify both `.claude/skills/speckit-superpowers-bridge/SKILL.md` AND `.agents/skills/speckit-superpowers-bridge/SKILL.md` exist and are equal in content (excluding frontmatter `name` field).
- [ ] T050 [P] [US4] Create `tests/test-handoff-shape.ps1` (new). It MUST cover: (a) a fresh write through `update-handoff.ps1 -Action start` produces a JSON document that matches `contracts/handoff.v1.schema.json` (validate against the schema using a simple PowerShell JSON parse + property-set check — no external validator), (b) reading a fabricated v3 JSON does not error (FR-009 backward read). Target ≤ 80 lines.
- [ ] T051 [P] [US4] Create `tests/test-guard-hardcoded-rules.ps1` (new). It MUST cover the 5 rules from research.md R3: (1) deny `speckit.implement` during executing, (2) deny `superpowers:writing-plans` with artifacts, (3) deny `speckit.constitution` during executing, (4) allow `speckit.plan` always, (5) allow unknown action by default. Use temp working directory to set up the handoff JSON state per test case. Target ≤ 90 lines.
- [ ] T052 [US4] Run all 3 retained tests: `powershell.exe -NoProfile -File tests/test-claude-codex-skill-parity.ps1; powershell.exe -NoProfile -File tests/test-handoff-shape.ps1; powershell.exe -NoProfile -File tests/test-guard-hardcoded-rules.ps1`. All three MUST exit with code 0.

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

- [ ] T075 Execute the full quickstart.md (all 10 steps, in order). Record pass/fail for each step in `cut-inventory.md` under the "Verification" H2.
- [ ] T076 Run all 3 retained tests one more time end-to-end on a fresh PowerShell session (`Start-Process` a new shell to invalidate any cached state). All 3 MUST pass.
- [ ] T077 Inspect the final `cut-inventory.md`: every path listed in the 8 commit-group tables MUST be absent at HEAD; every path MUST appear in `git log -- <path>` history. Run `Get-ChildItem` spot-checks for at least 5 random rows.
- [ ] T078 Run `git log --oneline HEAD~10..HEAD` and confirm ≥ 8 commits attributable to the trim (SC-009 ≥ 3 minimum easily satisfied). Confirm commit messages follow the conventional pattern (`chore(bridge): trim — ...`, `feat(bridge): simplify ...`, `release(bridge): bump to 0.3.0 ...`).
- [ ] T079 [P] (Optional polish) Slim each of the 3 retained bridge command markdowns to ≤ 60 lines (no FR mandates this, but it aligns with US1's "thin bridge" spirit): `.specify/extensions/speckit-superpowers-bridge/commands/speckit.speckit-superpowers-bridge.execute.md`, `.../handoff.md`, `.../guard.md`. Keep only the runbook-style instructions the agent needs.
- [ ] T080 (Final hand-off) Update `.specify/superpowers-handoff.json` to `status: complete`, `feature_directory: specs/006-trim-to-thin-bridge` via `update-handoff.ps1 -Action complete -Actor claude`. This triggers auto-archive on the next `/speckit-specify`.

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
