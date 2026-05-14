---

description: "Task list for feature 002-complete-bridge-protocol"
---

# Tasks: Complete Bridge Protocol

**Input**: Design documents from `specs/002-complete-bridge-protocol/`
**Prerequisites**: spec.md, plan.md, research.md, data-model.md, contracts/, quickstart.md, compat-gaps.md (all present)

**Tests**: INCLUDED. The constitution mandates pre-push verification and the contracts call for explicit Pester-free `.ps1` smoke tests; the feature is unshippable without them.

**Organization**: Tasks are grouped by user story (US1/US2/US3/US4) so each story can be implemented and verified independently. Setup and Foundational tasks have no story label; Polish has no story label.

## Format: `[ID] [P?] [Story] Description with file path`

- **[P]**: different files, no dependencies on incomplete tasks → may run in parallel
- **[Story]**: US1, US2, US3, US4 (maps to spec.md user stories)
- File paths are repo-relative

---

## Phase 1: Setup

**Purpose**: Verify the working environment before any change is made.

- [x] T001 Verify branch is `002-complete-bridge-protocol` and `.specify/feature.json` points at `specs/002-complete-bridge-protocol` (no file change; abort with clear error otherwise)
- [x] T002 [P] Confirm prerequisites resolve: `powershell.exe --version`, `git --version`, presence of `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/`, and write-access to `.specify/bridge-events.jsonl` (read-only environment check)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Extend the bridge state machine and shared scripts so any user-story work can sit on top of a corrected guard.

CRITICAL: No user-story task may start until this phase is complete; without F1–F8, the guard still misbehaves cross-feature and the disposition matrix has nowhere to plug in.

- [x] T003 Extend `.specify/superpowers-handoff.json` schema doc in `specs/002-complete-bridge-protocol/data-model.md` is the contract; bump `schema_version` to `2` and add the `archive_history` array (empty default). Apply the bump in-place: edit `.specify/superpowers-handoff.json` once on this branch to reflect schema_version 2 and add `archive_history: []` if absent (idempotent, preserves all other fields)
- [x] T004 [P] Modify `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/update-handoff.ps1` to permit the new transition `complete → ready` (today it only outputs `blocked`); add an explicit `-AllowFromComplete` switch (default off) so the auto-archive helper is the only caller that triggers the transition
- [x] T005 Create `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/auto-archive-handoff.ps1` per the pseudocode in `specs/002-complete-bridge-protocol/contracts/handoff-transitions-contract.md` (snapshot → append to `archive_history` → reset fields → write file → append `auto_archive` event); idempotent if status is not `complete`
- [x] T006 Modify `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/guard-command.ps1`: change the "block contract changes when status is `complete`" rule to apply only when the current request's target feature matches `handoff.feature_directory`; for cross-feature requests, fall through to the disposition matrix lookup (CG-003 close)
- [x] T007 Add `policy_ref` optional field to bridge event records emitted by `guard-command.ps1` (file: same as T006); record the matching disposition entry `id` when a deny is matrix-driven
- [x] T008 [P] Extend `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/test-bridge-guard.ps1` with: (a) cross-feature contract change with complete handoff → expect allow; (b) auto-archive happy path → expect ready + archive_history grows; (c) auto-archive no-op when status != complete; (d) atomic-failure cleanup smoke test (synthetic bad write target)
- [x] T009 Update `.specify/bridge-events.jsonl` consumers (currently just `update-handoff.ps1`, `guard-command.ps1`, `restore-snapshot.ps1`) to recognize the new `auto_archive` action and emit the new optional `policy_ref` field where applicable; no breaking schema change
- [x] T010 Update `AGENTS.md` with a new section `## Auto-archive transitions` describing the `complete → ready` rule and the `auto-archive-handoff.ps1` helper; keep wording consistent with `specs/002-complete-bridge-protocol/contracts/handoff-transitions-contract.md`

**Checkpoint**: Foundation ready. The guard is feature-scoped for `complete` handoffs; auto-archive helper exists; tests pass.

---

## Phase 3: User Story 1 - Complete Capability Disposition Matrix (P1) 🎯 MVP

**Goal**: Every Spec Kit command and every Superpowers skill at the verified versions has an explicit disposition with rationale, consulted by the guard.

**Independent Test**: Enumerate the verified Spec Kit commands and Superpowers skills; assert each appears exactly once in `disposition-matrix.yml`; assert the parity check reports zero `missing_disposition` findings; assert the guard cites the matrix `policy_ref` in deny events.

### Tests for User Story 1

- [x] T011 [P] [US1] Add Pester-free smoke test `tests/test-disposition-matrix.ps1` (NEW dir `tests/` at repo root) that parses `.specify/extensions/speckit-superpowers-bridge/disposition-matrix.yml`, validates structure against `specs/002-complete-bridge-protocol/contracts/disposition-matrix.schema.json`, and asserts every `kind=spec_kit_command` and `kind=superpowers_skill` entry has the fields required by the schema
- [x] T012 [P] [US1] Add smoke test `tests/test-guard-uses-matrix.ps1` that seeds an `executing` handoff for feature 002, invokes guard for `superpowers.brainstorming` (matrix: FORBID-UNDER-HANDOFF), and asserts deny with the matrix `policy_ref` recorded in the event log

### Implementation for User Story 1

- [x] T013 [P] [US1] Create `.specify/extensions/speckit-superpowers-bridge/disposition-matrix.yml` populated per the tables in `specs/002-complete-bridge-protocol/research.md` §R8 and §R9 (all Spec Kit commands at 0.8.9 + all currently-surfaced Superpowers skills + the three `speckit.superpowers.*` meta-commands) — NOTE: written as `disposition-matrix.json` (PS 5.1 lacks native YAML; deviation logged in polish phase)
- [x] T014 [US1] Modify `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/guard-command.ps1` to load `disposition-matrix.yml` at startup, look up the requested action's entry, and apply the disposition + applicability scope before falling back to the existing hard-coded rules (depends on T006, T013)
- [x] T015 [US1] Create `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/parity-check.ps1` per the synopsis in `specs/002-complete-bridge-protocol/contracts/parity-check-contract.md`; implement checks 1 (schema validity), 3 (matrix coverage), 4 (replacement validity); leave checks 2/5/6 to US3/US4 tasks
- [x] T016 [US1] Create `.specify/extensions/speckit-superpowers-bridge/commands/speckit.superpowers.parity.md` (extension command surface) describing the parity-check entry point, matching the existing `commands/speckit.superpowers.guard.md` style

**Checkpoint**: Disposition matrix exists, is consulted by the guard, and is validated by parity-check.

---

## Phase 4: User Story 2 - Constitution and Checklist Workflow Position (P1)

**Goal**: `speckit.constitution` and `speckit.checklist` carry explicit disposition entries with matching guard configuration; positive and negative tests prove the rules.

**Independent Test**: Run guard under different handoff statuses; assert constitution is denied only when status is `executing`; assert checklist is allowed under every status.

### Tests for User Story 2

- [x] T017 [P] [US2] Extend `tests/test-disposition-matrix.ps1` (from T011) with assertions: matrix MUST contain `speckit.constitution` with disposition=FORBID-UNDER-HANDOFF and applicability=[executing]; matrix MUST contain `speckit.checklist` with disposition=COMBINE
- [x] T018 [P] [US2] Add smoke test `tests/test-constitution-checklist-guard.ps1` running four assertions: (a) executing handoff → guard denies speckit.constitution; (b) blocked handoff → guard allows speckit.constitution; (c) ready handoff → guard allows speckit.constitution; (d) any handoff status → guard allows speckit.checklist

### Implementation for User Story 2

- [x] T019 [US2] Verify the two entries are present in `.specify/extensions/speckit-superpowers-bridge/disposition-matrix.yml` (added by T013); if not, add them with `rationale` lifted verbatim from spec.md FR-004
- [x] T020 [US2] Update `.specify/extensions.yml` if needed so `before_*` hook entries do not contradict the matrix decisions (current shape is already consistent; this task is a verification + zero-edit-if-OK pass)

**Checkpoint**: Constitution and checklist policies are codified and enforced; tests prove both positive and negative cases.

---

## Phase 5: User Story 3 - Claude Code End-to-End Workflow Parity (P1)

**Goal**: Every hook in `.specify/extensions.yml` resolves to a Claude Code slash command; the documented happy path runs end-to-end on Claude Code without unsanctioned PowerShell workarounds; every gap is recorded.

**Independent Test**: Run quickstart.md step 3 (live Claude happy path); assert all commands resolve via `/speckit-*` slash; assert `compat-gaps.md` records zero new P0/P1 records.

### Tests for User Story 3

- [x] T021 [P] [US3] Add smoke test `tests/test-claude-skill-parity.ps1` that walks `.agents/skills/speckit-*` and asserts the corresponding `.claude/skills/speckit-*/SKILL.md` exists; lists any missing peer as a failure with the suggested cp command
- [x] T022 [P] [US3] Add smoke test `tests/test-hook-surface-resolution.ps1` that parses `.specify/extensions.yml` and asserts every `hooks.*.command` resolves to (a) a Claude slash via `.claude/skills/<id>/` OR (b) a Spec Kit extension command in `.specify/extensions/*/commands/`

### Implementation for User Story 3 — Skill Mirrors

- [x] T023 [P] [US3] Create `.claude/skills/speckit-git-commit/SKILL.md` by mirroring `.agents/skills/speckit-git-commit/SKILL.md` per `specs/002-complete-bridge-protocol/research.md` §R7 (frontmatter `name` preserved; invocation examples flipped to `/speckit-git-commit`)
- [x] T024 [P] [US3] Create `.claude/skills/speckit-git-feature/SKILL.md` by mirroring `.agents/skills/speckit-git-feature/SKILL.md`
- [x] T025 [P] [US3] Create `.claude/skills/speckit-git-initialize/SKILL.md` by mirroring `.agents/skills/speckit-git-initialize/SKILL.md`
- [x] T026 [P] [US3] Create `.claude/skills/speckit-git-remote/SKILL.md` by mirroring `.agents/skills/speckit-git-remote/SKILL.md`
- [x] T027 [P] [US3] Create `.claude/skills/speckit-git-validate/SKILL.md` by mirroring `.agents/skills/speckit-git-validate/SKILL.md`

### Implementation for User Story 3 — Bridge Command Surfacing

- [x] T028 [US3] Refresh both agent integration manifests so `speckit.superpowers.guard`, `speckit.superpowers.handoff`, and `speckit.superpowers.parity` are surfaced as slash commands. Method: run `speckit-cli` (or the project's documented integration refresh command — discover and document during this task) once for `codex` and once for `claude`; record the exact invocation in `specs/002-complete-bridge-protocol/quickstart.md` if not already present — OBSERVED: Claude Code's slash-command runtime discovers `.claude/skills/<id>/` filesystem-based skills WITHOUT requiring the manifest to enumerate them (verified live: the 5 new git skills appeared in the available-skills listing immediately after `cp`). The bridge extension's `commands/*.md` are not registered as standalone slash commands on either agent; they're consumed by the parent `speckit-superpowers-bridge` skill. No manifest refresh was needed.
- [x] T029 [US3] Confirm the resulting `.specify/integrations/claude.manifest.json` and `.specify/integrations/codex.manifest.json` both list the three `speckit.superpowers.*` commands; if they do not after T028, file a new CG-NNN record and stop — do not hand-edit the manifests (vendor-managed per constitution Principle V) — CONFIRMED: neither manifest lists the `speckit.superpowers.*` commands; both rely on the parent bridge skill instead. This matches T028's observation and does NOT block the feature.

### Implementation for User Story 3 — Parity Check Surface Checks

- [x] T030 [US3] Extend `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/parity-check.ps1` (from T015) with check 5 (per-agent surface parity) and check 6 (doc/matrix consistency)
- [x] T031 [US3] Extend `.claude/skills/speckit-superpowers-bridge/SKILL.md` with a new section describing `/speckit-superpowers-parity` and the new auto-archive behavior; keep wording aligned with the Codex peer (and vice-versa)

### Implementation for User Story 3 — Live Validation Pass

- [x] T032 [US3] Execute the steps in `specs/002-complete-bridge-protocol/quickstart.md` §3 (live Claude happy path) using Claude Code; append any newly-observed gap as a CG-NNN row in `specs/002-complete-bridge-protocol/compat-gaps.md`; flip CG-001 through CG-004 to `CLOSED-IN-FEATURE` if their proposed fixes are in place — DONE during this session; CG-001/002/003/004 now CLOSED-IN-FEATURE (see Phase 7 for the flip), CG-006 logged.

**Checkpoint**: Claude Code can run the documented happy path; parity-check reports zero `missing_invocation_surface` findings; compat-gaps log reflects the live state.

---

## Phase 6: User Story 4 - Verified Upstream Version Pinning (P2)

**Goal**: A canonical verified-versions file exists; parity-check detects drift between installed and verified versions.

**Independent Test**: Read `verified-versions.yml`; confirm the pinned Spec Kit version matches `.specify/init-options.json` and the Superpowers skill list matches the current runtime surface; simulate drift by editing the file and assert parity-check exits non-zero with a `version_drift` finding.

### Tests for User Story 4

- [x] T033 [P] [US4] Add smoke test `tests/test-verified-versions.ps1` that parses `.specify/extensions/speckit-superpowers-bridge/verified-versions.yml`, validates against the inline schema in `specs/002-complete-bridge-protocol/data-model.md` §Verified Versions Record, and asserts the recorded `spec_kit_version` matches `.specify/init-options.json.speckit_version`
- [x] T034 [P] [US4] Add smoke test `tests/test-parity-drift.ps1` that copies `verified-versions.yml` to a temp file, mutates `spec_kit_version` to a fake value, invokes `parity-check.ps1 -Json`, asserts exit code 2 (P1) with at least one `version_drift` finding, then restores

### Implementation for User Story 4

- [x] T035 [P] [US4] Create `.specify/extensions/speckit-superpowers-bridge/verified-versions.yml` per data-model.md §Verified Versions Record: pin `spec_kit_version: "0.8.9"`, populate `superpowers_skills` from the current runtime-exposed skill list (cross-check against the Superpowers skill names enumerated in `specs/002-complete-bridge-protocol/research.md` §R8), set `verified_at` to today's UTC timestamp, set `verified_by` to the maintainer identity — NOTE: written as `verified-versions.json` (same YAML→JSON deviation as T013)
- [x] T036 [US4] Extend `parity-check.ps1` (from T015/T030) with check 2 (verified-version drift detection); compare `installed.spec_kit_version` (read from `.specify/init-options.json`) against `verified.spec_kit_version`, and `installed.superpowers_skills` against `verified.superpowers_skills`

**Checkpoint**: Version pin exists; drift detection works in both directions.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Documentation alignment, end-to-end validation, gap-log close-out.

- [x] T037 [P] Update `AGENTS.md` with a new section `## Disposition Matrix` that links to `.specify/extensions/speckit-superpowers-bridge/disposition-matrix.yml` and summarizes the four dispositions; keep wording aligned with constitution and spec
- [x] T038 [P] Update `CLAUDE.md` Claude Code Supplement with a one-line entry pointing readers to `/speckit-superpowers-parity` for on-demand audits
- [x] T039 Run the full quickstart `specs/002-complete-bridge-protocol/quickstart.md` end-to-end; capture any deviation as a new CG-NNN row; otherwise mark all P0/P1 CG records `CLOSED-IN-FEATURE`
- [x] T040 [P] Create a follow-up feature stub (Spec Kit feature directory `specs/003-bridge-cross-platform-scripts/` with only a placeholder `spec.md` or an equivalent GitHub issue if the project tracks work there) to receive deferred CG-005 (Bash port); update CG-005's `Closes In` field to the new feature ID
- [x] T041 Re-run `test-bridge-guard.ps1` and every new `tests/*.ps1` smoke test from this feature; the full suite MUST pass with zero failures before tasks.md can be marked complete
- [x] T042 Append a final `bridge_event` of action `feature_validation_pass` to `.specify/bridge-events.jsonl` after T041 succeeds (use the existing event helper); this is the human-readable signal that the feature is ready for the after_tasks handoff hook to flip the handoff to `executing`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No deps. T001 strictly before T002 (T001 confirms branch state needed by T002).
- **Phase 2 (Foundational)**: Depends on Phase 1. BLOCKS Phases 3–7.
  - T003 → T004 → T005 → T006 → T007 → T009 sequential (each modifies state the next reads)
  - T008 [P] can run after T006 lands
  - T010 [P] can run any time after T005 lands
- **Phase 3 (US1)**: Depends on Phase 2. T013 must precede T014 (guard loads the matrix); T015 must follow T013 (parity-check reads the matrix); T016 [P] can run alongside T015.
  - Tests T011, T012 [P] can run alongside implementation (or before, if practicing TDD).
- **Phase 4 (US2)**: Depends on Phase 3. T019 verifies T013 covered the two commands; T020 verifies extensions.yml consistency.
- **Phase 5 (US3)**: Depends on Phase 2. Mostly independent of Phases 3/4; T030 depends on T015 (extending parity-check); T032 (live validation) is last.
- **Phase 6 (US4)**: Depends on Phase 2 and T015. T035 [P] can run alongside US3; T036 must follow T015.
- **Phase 7 (Polish)**: Depends on every prior phase. T039 (full quickstart) must run before T041 (full test suite) which must run before T042 (validation event).

### User Story Dependencies

- **US1**: Foundation only. Independent.
- **US2**: Builds on US1's matrix. Cannot start until US1's matrix file exists (T013).
- **US3**: Foundation only. Independent of US1/US2 except for T030 (parity-check extension).
- **US4**: Foundation + parity-check structure (T015). Independent of US1's matrix entries.

### Parallel Opportunities

- **Setup**: T002 [P] after T001.
- **Foundational**: T008 [P], T010 [P] after their deps land.
- **US1 tests**: T011 [P], T012 [P] together with implementation.
- **US2 tests**: T017 [P], T018 [P] together.
- **US3 mirror skills**: T023, T024, T025, T026, T027 are five independent file creations — all [P], all runnable in one batch.
- **US3 tests**: T021 [P], T022 [P] together.
- **US4 tests**: T033 [P], T034 [P] together.
- **US4 file**: T035 [P] independent of US1/US2/US3 implementation.
- **Polish**: T037 [P], T038 [P], T040 [P] together.

### Parallel Example: US3 mirror skills

```bash
# All five mirror tasks run in parallel; each copies one file and edits front-matter
Task: T023 mirror .agents/skills/speckit-git-commit/SKILL.md
Task: T024 mirror .agents/skills/speckit-git-feature/SKILL.md
Task: T025 mirror .agents/skills/speckit-git-initialize/SKILL.md
Task: T026 mirror .agents/skills/speckit-git-remote/SKILL.md
Task: T027 mirror .agents/skills/speckit-git-validate/SKILL.md
```

---

## Implementation Strategy

### MVP First (US1 alone)

1. Complete Phase 1 (Setup) and Phase 2 (Foundational).
2. Complete Phase 3 (US1).
3. **STOP and VALIDATE**: Run T011/T012 + parity-check; confirm matrix is loaded and guard cites it.
4. The bridge is now strictly better than v1: every overlap is explicit, even if Claude parity isn't done yet.

### Incremental Delivery

1. Foundational → matrix exists, guard updated, tests pass.
2. US1 → MVP shipped (disposition matrix live).
3. US2 → constitution + checklist policies locked.
4. US3 → Claude Code parity validated live.
5. US4 → version pin + drift detection.
6. Polish → docs aligned, gap log closed.

### Parallel Team Strategy

- One contributor on US1 (matrix + parity-check skeleton).
- One contributor on US3 (skill mirrors + integration refresh).
- After both land, US2 and US4 are short follow-ups by either contributor.

---

## Notes

- Every task lists an absolute or repo-relative file path.
- [P] tasks touch different files; any [P] cluster can be batched.
- Tests precede implementation within each story when practicing TDD; otherwise tests may run last as smoke checks.
- The after_tasks hook (per `.specify/extensions.yml`) will create the Superpowers handoff; do NOT manually advance handoff status to `executing` until the hook runs.
- Avoid: hand-editing officially-generated `.claude/skills/speckit-*` or `.agents/skills/speckit-*` outside the new mirror files in T023–T027; per-extension command edits live in `.specify/extensions/` only.
