---

description: "Task list for feature 005-marketplace-alignment"
---

# Tasks: Marketplace Alignment

**Input**: Design documents from `specs/005-marketplace-alignment/`
**Prerequisites**: spec.md, plan.md, research.md, data-model.md, contracts/ (4 files), quickstart.md, compat-gaps.md
**Primary Design Reference**: [Spec Kit vs Superpowers — dev.to article](https://dev.to/truongpx396/spec-kit-vs-superpowers-a-comprehensive-comparison-practical-guide-to-combining-both-52jj)
**Spec Kit baseline**: 0.8.10 (locked by clarify Q2)

**Tests**: INCLUDED. New scripts (submission-checklist, cleanup-audit) must have smoke-test coverage per their contracts.

**Organization**: Tasks grouped by user story (US1–US4). Setup and Foundational have no story label; Polish has no story label.

## Format: `[ID] [P?] [Story] Description with file path`

- **[P]**: different files, no dependencies on incomplete tasks → may run in parallel
- **[Story]**: US1, US2, US3, US4 (maps to spec.md user stories)
- File paths are repo-relative

---

## Phase 1: Setup

**Purpose**: Verify the working environment + that prior features' outputs are intact.

- [x] T001 Verify branch is `005-marketplace-alignment`, `.specify/feature.json` points at `specs/005-marketplace-alignment`, and feature 002 + 004 outputs (disposition-matrix.json, verified-versions.json, parity-check.ps1, audit-install-state.ps1, validation-pass.ps1, 15+ tests under `tests/`) are present (no file change; abort with clear error otherwise)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Land the version pin updates and metadata changes that every user story builds on.

CRITICAL: No user-story task may start until this phase is complete; downstream tasks read these values.

- [x] T002 Update `.specify/extensions/speckit-superpowers-bridge/extension.yml`: set `extension.version` to `"0.2.0"` (next release); set `requires.speckit_version` to `">=0.8.10"`; ensure `extension.license` is `"MIT"`; ensure `extension.repository`, `extension.homepage`, `extension.documentation` URLs are present and consistent
- [x] T003 Update `.specify/extensions/speckit-superpowers-bridge/extension.yml`: add or replace the `tags` field with exactly the locked 6-tag set per clarify Q3: `[bridge, superpowers, cross-agent, governance, tdd, workflow]` (lowercase-hyphenated, in declared order)
- [x] T004 Update `.specify/extensions/speckit-superpowers-bridge/extension.yml`: add `provides.commands` and `provides.hooks` integer counts computed at edit time — `provides.commands` = count of `.md` files under `.specify/extensions/speckit-superpowers-bridge/commands/`; `provides.hooks` = count of hook command IDs published by this extension for external consumers (currently `0` per research §R6)
- [x] T005 [P] Update `.specify/extensions/speckit-superpowers-bridge/verified-versions.json`: set `spec_kit_version` to `"0.8.10"`; update `verified_at` to the current ISO 8601 UTC timestamp; preserve `superpowers_skills[]` and `spec_kit_commands[]` arrays as-is
- [x] T006 [P] Run `parity-check.ps1` and `validation-pass.ps1` from the existing bridge scripts to confirm zero new findings after the version-pin updates; do not proceed if either exits non-zero

**Checkpoint**: Foundation ready. Version pin is 0.8.10; tag set is locked; manifest counts are accurate. Parity + validation still green.

---

## Phase 3: User Story 1 — Marketplace Listing Acceptance (P1) 🎯 MVP

**Goal**: Every required file the Spec Kit publishing guide names exists; the catalog entry + extensions/README.md row + upstream PR body are drafted; the submission-checklist script mirrors the upstream maintainer verification and exits 0.

**Independent Test**: Run `submission-checklist.ps1 -Json` against the next release tag; assert exit 0 and zero findings.

### Tests for User Story 1

- [x] T007 [P] [US1] Add smoke test `tests/test-submission-checklist.ps1` covering: (a) happy path at current repo state exits 0; (b) synthetic missing LICENSE → expect P0 `license_missing`; restore in `finally`; (c) synthetic broken catalog-entry.json (set `version: "not-semver"`) → expect P0 `catalog_entry_invalid`; restore; (d) synthetic missing AI-disclosure paragraph in upstream-pr-body.md → expect P1 `ai_disclosure_missing`; restore; (e) `-OfflineOnly` mode: check 7 reports `skipped`, others run normally

### Implementation for User Story 1

- [x] T008 [US1] Create `LICENSE` at repo root with the MIT License text, copyright year 2026, holder `lihan3238` (or as documented in `extension.yml.extension.author`)
- [x] T009 [US1] Create `CHANGELOG.md` at repo root following Keep-a-Changelog 1.1.0, with the three sections per research §R8: `[Unreleased]` (skeleton), `[0.1.1] — <commit-date-of-15d0376>` (feature 004 content), `[0.1.0] — <commit-date-of-initial>` (features 001+002 content). Dates pulled from `git log` at edit time. Add an intro paragraph with the AI-disclosure one-liner per research §R9
- [x] T010 [P] [US1] Create `marketplace/` directory at repo root with a brief `README.md` inside explaining what the directory is for (per research §R5: source-repo-only, excluded from distribution, feeds upstream PR)
- [x] T011 [P] [US1] Create `marketplace/catalog-entry.json` matching `specs/005-marketplace-alignment/contracts/catalog-entry.schema.json`: populate `id`, `name`, `description ≤200 chars`, `author`, `version` (`"0.2.0"`), `license`, `repository`, `download_url` (pointing at the v0.2.0 release ZIP), `homepage`, `documentation`, `changelog`, `requires.speckit_version`, `requires.tools[]`, `provides.commands/hooks` (counts from T004), `tags` (locked 6-tag set)
- [x] T012 [P] [US1] Create `marketplace/extensions-readme-row.md` containing the Markdown table row pasted into upstream `extensions/README.md`. Single row, matches the upstream's existing column structure (name link, tags, description)
- [x] T013 [P] [US1] Create `marketplace/upstream-pr-body.md` containing the PR description template with the AI-assistance disclosure paragraph per research §R9 (canonical text). Include sections: Summary, Catalog entry rationale, Validation (link to submission-checklist output), AI-assistance disclosure, Contact
- [x] T014 [US1] Create `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/submission-checklist.ps1` per `specs/005-marketplace-alignment/contracts/submission-checklist-contract.md`: 8 checks, JSON + human output modes, exit codes 0/1/2/3, dot-sources common helpers from existing scripts where possible. The HTTP HEAD check uses `[System.Net.Http.HttpClient]` (Windows-native) with a 10-second timeout
- [x] T015 [US1] Update `.specify/extensions/speckit-superpowers-bridge/disposition-matrix.json` to add a new entry for `speckit.speckit-superpowers-bridge.submission-checklist` as `kind: bridge_meta_command, disposition: COMBINE, rationale: "Local mirror of upstream submission verification; always available."`, `verified_against: "bridge@005"`
- [x] T016 [US1] Create `.specify/extensions/speckit-superpowers-bridge/commands/speckit.speckit-superpowers-bridge.submission-checklist.md` describing the on-demand submission-checklist entry point, matching the style of existing `commands/speckit.speckit-superpowers-bridge.*.md` files

**Checkpoint**: All required marketplace files exist; submission-checklist script exits 0; catalog entry drafted.

---

## Phase 4: User Story 2 — User-Friendly Documentation Covering Multi-Environment Setup (P1)

**Goal**: A first-time reader understands what the bridge does, picks their setup (pure Codex / pure Claude / dual-agent), and completes one feature workflow in ≤30 minutes. Bilingual READMEs cover identical sections.

**Independent Test**: Hand the README to a developer who has never used the bridge; measure time to first successful workflow completion. Existing `check-readme-bilingual-parity.ps1` verifies structural parity.

### Implementation for User Story 2

- [x] T017 [US2] Rewrite `README.md` (English) at repo root using the 11-section structure from research §R4: bilingual toggle line → 4 trust badges → H1 title → "What it does" (one paragraph + dev.to article link) → Workflow diagram (ASCII chart of Spec Kit → bridge → Superpowers) → Installation (with `### Pure Codex` / `### Pure Claude Code` / `### Both` subsections) → "Your first feature in 10 minutes" walkthrough → Commands reference (table) → Configuration (env vars + handoff fields) → Troubleshooting (matrix) → Maintenance & Versioning → Architecture in 60 seconds → Contributing & License. Each H2 anchor stays English (`## installation`, `## troubleshooting`, etc.). Preserve existing useful prose where relevant
- [x] T018 [US2] Add the 4 Shields.io badges to `README.md` per research §R7 (license / version / last-commit / Spec Kit compatibility); place them on the line immediately after the bilingual toggle and before the H1
- [x] T019 [US2] In `README.md`'s "Installation" section, write three sub-sections covering exactly the three setups: Pure Codex (no Claude Code dependency; `specify init --integration codex` → `specify extension add ...`), Pure Claude Code (`specify init --integration claude` → `specify extension add ...`), Both (initialize with either, `specify integration add <other>` later, then add extension once)
- [x] T020 [US2] In `README.md`'s "Configuration" section, document: `SPECKIT_BRIDGE_ACTOR` env var, `SPECKIT_BRIDGE_AUTONOMOUS` env var, the `autonomous_mode` and `resume_context` handoff fields, and the 4-step actor-resolution chain. Cross-reference `AGENTS.md` for the master protocol
- [x] T021 [US2] In `README.md`'s "Troubleshooting" section, write the matrix per FR-010 covering at minimum: handoff stuck in `executing`, parity check P1 finding, missing per-agent peer skill, autonomous-mode not activating, validation-pass failing on first run. Each row: Symptom / Likely cause / Fix command
- [x] T022 [US2] In `README.md`'s "Architecture in 60 seconds" section, paraphrase the dev.to article's WHAT-vs-HOW split with attribution (link to article), and link to `.specify/extensions/speckit-superpowers-bridge/disposition-matrix.json` as the codification
- [x] T023 [US2] Mirror `README.md` into `README.zh-CN.md` (Simplified Chinese): preserve identical H2 anchor structure (anchors stay English for cross-link stability); translate body prose to Simplified Chinese; keep code fences, commands, and JSON/YAML keys untranslated; ensure the bilingual toggle line (first line) links back to `README.md`
- [x] T024 [US2] Run `check-readme-bilingual-parity.ps1` and confirm zero structural divergence between the two READMEs

**Checkpoint**: Both READMEs reflect the new structure; bilingual parity passes; install paths cover all three environments.

---

## Phase 5: User Story 3 — Slim & Iterate (P2)

**Goal**: The release ZIP contains only assets the host needs; the source repo's `.gitignore` covers all per-developer state; no stale files remain.

**Independent Test**: Run `cleanup-audit.ps1`; assert zero P0/P1 findings. Run `check-distribution-manifest.ps1 -SimulateInstall`; assert installed file set equals `plugin-distribution-manifest.yml.includes[]` byte-for-byte.

### Tests for User Story 3

- [x] T025 [P] [US3] Add smoke test `tests/test-cleanup-audit.ps1` per `specs/005-marketplace-alignment/contracts/cleanup-audit-contract.md`: (a) happy path on this repo: 0 P0/P1 findings; (b) synthetic backup file (`foo.bak` in temp location within repo) → expect P2 `backup_file_present`; delete in `finally`; (c) synthetic unreferenced doc → expect P2 `unreferenced_doc`; remove in `finally`; (d) synthetic manifest inconsistency → expect P0 `manifest_path_inconsistency`; restore in `finally`; (e) `-Fix` mode: synthesize a backup file, run with `-Fix`, assert it's deleted

### Implementation for User Story 3

- [x] T026 [US3] Create `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/cleanup-audit.ps1` per `specs/005-marketplace-alignment/contracts/cleanup-audit-contract.md`: 5 checks, JSON + human output modes, `-Fix` opt-in destructive mode. `-Fix` refuses to auto-fix `manifest_path_inconsistency` (requires human review). Dot-sources common helpers; reuses `Finding` shape from parity-check
- [x] T027 [US3] Re-audit `.gitignore` at repo root: confirm all 5 categories are covered per research §R10 logic — (a) per-developer state (`.specify/bridge-events.jsonl`, `.specify/bridge-snapshots/`, `.specify/superpowers-handoff.json`, `.specify/feature.json`, `specs/*/checklists/protocol-quality.md`), (b) OS junk (`.DS_Store`, `Thumbs.db`, `desktop.ini`), (c) backup patterns (`*.bak`, `*.bak-*`, `*.orig`, `*.tmp`), (d) editor scratch (`*.swp`, `.vscode/settings.local.json` if relevant), (e) build artifacts (none currently, but add a comment placeholder)
- [x] T028 [US3] Re-confirm `.specify/extensions/speckit-superpowers-bridge/plugin-distribution-manifest.yml`: every `includes[].path` resolves on disk; `LICENSE` and `CHANGELOG.md` are in `includes`; `marketplace/**` is added to `excludes` with `reason: "Upstream PR artifacts are source-repo-only; not relevant to host projects."` per research §R5; no path appears in both lists
- [x] T029 [US3] Update `.specify/extensions/speckit-superpowers-bridge/disposition-matrix.json` to add a new entry for `speckit.speckit-superpowers-bridge.cleanup-audit` as `kind: bridge_meta_command, disposition: COMBINE, rationale: "Pre-release source repo cleanup audit; always available."`, `verified_against: "bridge@005"`
- [x] T030 [US3] Create `.specify/extensions/speckit-superpowers-bridge/commands/speckit.speckit-superpowers-bridge.cleanup-audit.md` describing the cleanup-audit entry point
- [x] T031 [US3] Run `cleanup-audit.ps1` against the live repo and resolve any P0/P1 findings (delete or document-as-kept); P2 findings reviewed and either fixed or accepted with a one-line note in CHANGELOG.md

**Checkpoint**: Cleanup audit exits 0 on this repo; `.gitignore` covers all five categories; distribution manifest is internally consistent.

---

## Phase 6: User Story 4 — Discoverability & Trust Signals (P3)

**Goal**: A user searching the catalog has enough signal to install us over alternatives.

**Independent Test**: Open the README on github.com; confirm all 4 badges render with valid data; confirm the north-star article link works; confirm the "Architecture in 60 seconds" section paraphrases the article with attribution.

### Implementation for User Story 4

- [x] T032 [P] [US4] Verify the 4 trust badges in `README.md` (added by T018) render correctly on github.com — license badge resolves, version badge shows latest tag, last-commit shows recent date, Spec Kit compatibility badge shows `>=0.8.10` (static Shields.io endpoint per research §R7). No additional file changes; this task is the manual verification step
- [x] T033 [P] [US4] Verify the dev.to north-star article link in `README.md` (added by T017 and T022) resolves; capture the link as a bridge event (optional) so any future link rot is detected by the validation pass
- [x] T034 [P] [US4] In `README.md`'s "Architecture in 60 seconds" section (from T022), add a brief peer-comparison paragraph naming notable Spec Kit community extensions (AIDE, architect-preview, api-contract-evolution, impact-predictor per research) and how the bridge differs (we connect Spec Kit + Superpowers; they expand Spec Kit only); cite each peer's repo

**Checkpoint**: README presents trust signals; peer-comparison contextualizes the bridge in the catalog ecosystem.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Release runbook, full test sweep, CHANGELOG finalization, validation pass.

- [x] T035 [P] Create `docs/release-runbook.md` per `specs/005-marketplace-alignment/contracts/release-runbook-contract.md`: 11 ordered steps; each step has a `Verify:` line; step 4 invokes `submission-checklist.ps1`; step 5 invokes the full test suite
- [x] T036 [P] Update `AGENTS.md` to add a brief mention of `submission-checklist.ps1` and `cleanup-audit.ps1` in the meta-commands list (mirror of CLAUDE.md edits)
- [x] T037 [P] Update `CLAUDE.md` Claude Code Supplement with one-line pointers to `/speckit-speckit-superpowers-bridge-submission-checklist` and `/speckit-speckit-superpowers-bridge-cleanup-audit`
- [x] T038 Update `CHANGELOG.md` `[Unreleased]` section with the feature 005 content: marketplace listing prep (LICENSE, CHANGELOG, catalog entry, submission checklist, release runbook), README polish (bilingual reflow, trust badges, multi-env install paths), cleanup audit + manifest re-confirmation; mention closure of any P0/P1 cleanup findings
- [x] T039 Run the full quickstart `specs/005-marketplace-alignment/quickstart.md` end-to-end; capture any deviation as a new CG-NNN row in `specs/005-marketplace-alignment/compat-gaps.md`
- [x] T040 Run `submission-checklist.ps1` against the repo at this branch's HEAD; assert exit 0 with zero P0 findings
- [x] T041 Re-run `test-bridge-guard.ps1` and every `tests/*.ps1` smoke test (15 existing + 2 new for feature 005 = 17 total); the full suite MUST pass with zero failures
- [x] T042 Run `parity-check.ps1` and `validation-pass.ps1`; both must exit 0
- [x] T043 Append a final `feature_validation_pass` bridge event to `.specify/bridge-events.jsonl` referencing this branch's HEAD SHA after T041–T042 succeed

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: T001 only. No deps.
- **Phase 2 (Foundational)**: Depends on Phase 1. BLOCKS Phases 3–7.
  - T002 must precede T003 and T004 (same file edits).
  - T005 and T006 [P] can run alongside.
- **Phase 3 (US1)**: Depends on Phase 2. T008 (LICENSE) precedes T009 (CHANGELOG can reference license). T010–T013 are [P] file creations. T014 depends on T011 (script reads catalog-entry.json). T015 and T016 are matrix + command-doc additions.
- **Phase 4 (US2)**: Depends on Phase 2. T017 must precede T018–T022 (the section edits add content to the rewritten README). T023 depends on T017–T022 (zh-CN mirror is generated AFTER EN settles). T024 depends on T023.
- **Phase 5 (US3)**: Depends on Phase 2. T026 implementation precedes T025 (if practicing TDD-after) or T025 first if TDD-first. T027/T028/T029/T030 are mostly [P]. T031 depends on T026.
- **Phase 6 (US4)**: Depends on Phase 4 (the README must exist and have the relevant sections). T032/T033/T034 are [P].
- **Phase 7 (Polish)**: Depends on every prior phase. T038 must precede T039 (quickstart references the CHANGELOG). T039–T043 run in sequence.

### User Story Dependencies

- **US1**: Foundation only.
- **US2**: Foundation only. Independent of US1 file-wise; conceptually depends on US1 tags/version for the README "Maintenance & Versioning" section.
- **US3**: Foundation only. Independent of US1/US2 (cleanup runs against current state).
- **US4**: Depends on US2 (badges live in README; Architecture section lives in README).

### Parallel Opportunities

- **Foundational**: T005 [P], T006 [P].
- **US1**: T010 [P], T011 [P], T012 [P], T013 [P] — four [P] file creations.
- **US1 tests**: T007 [P].
- **US3 tests**: T025 [P].
- **US3 implementation**: T027, T028 are [P] (different files); T030 is [P] (markdown).
- **US4**: T032 [P], T033 [P], T034 [P] — three [P] verification-or-content tasks.
- **Polish**: T035 [P], T036 [P], T037 [P].

### Parallel Example: US1 marketplace file batch

```bash
Task: T010 marketplace/README.md (directory notes)
Task: T011 marketplace/catalog-entry.json
Task: T012 marketplace/extensions-readme-row.md
Task: T013 marketplace/upstream-pr-body.md
# Plus the test in parallel:
Task: T007 tests/test-submission-checklist.ps1
```

---

## Implementation Strategy

### MVP First (US1 alone)

1. Complete Phase 1 (Setup) and Phase 2 (Foundational).
2. Complete Phase 3 (US1).
3. **STOP and VALIDATE**: Run `submission-checklist.ps1` and confirm exit 0 with all 8 checks passing.
4. The repo is now marketplace-submission-ready; the upstream PR could be opened with what's in MVP.

### Incremental Delivery

1. Foundation → version pin updated, tags locked, parity intact.
2. US1 → MVP shipped: all required files exist; submission checklist passes.
3. US2 → README polished for first-time readers in all three setups.
4. US3 → cleanup audit + manifest enforced; repo is slim.
5. US4 → trust signals in README; discoverability optimized.
6. Polish → release runbook + full test sweep + validation pass.

### Parallel Team Strategy

With multiple contributors:
- One on US1 (marketplace files + submission-checklist script).
- One on US2 (README reflow + zh-CN mirror) — independent of US1's file changes (touches different files).
- One on US3 (cleanup-audit script + .gitignore audit) — independent.
- US4 folds in last as a small polish.

---

## Notes

- Every task lists a repo-relative file path.
- [P] tasks touch different files; any [P] cluster can be batched.
- Tests precede implementation within each story when practicing TDD; otherwise tests run last as smoke checks.
- The after_tasks hook will create the Superpowers handoff (per `.specify/extensions.yml`); CG-006 is already closed so the hook should pick up `claude` as the active actor automatically (per the actor-resolution chain implemented in feature 004).
- Per the constitution principle V (vendor-managed boundaries): do NOT hand-edit officially-generated `.claude/skills/speckit-*` or `.agents/skills/speckit-*` (core 9 each); only the bridge SKILL.md on each agent is editable; this feature does NOT touch the bridge SKILL.md files.
- The Primary Design Reference (dev.to article) is the canonical north star; cite it where appropriate in the README's Architecture-in-60-seconds section per FR-018.
- All historical references to Spec Kit `0.8.9` in feature 001/002/003/004 specs are LEFT UNCHANGED (research §R10) — only forward-facing assets get the 0.8.10 update.
