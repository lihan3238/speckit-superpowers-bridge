---

description: "Task list for feature 004-polish-and-publish"
---

# Tasks: Polish & Publish

**Input**: Design documents from `specs/004-polish-and-publish/`
**Prerequisites**: spec.md, plan.md, research.md, data-model.md, contracts/ (6 files), quickstart.md, compat-gaps.md
**Primary Design Reference**: [Spec Kit vs Superpowers — dev.to article](https://dev.to/truongpx396/spec-kit-vs-superpowers-a-comprehensive-comparison-practical-guide-to-combining-both-52jj)

**Tests**: INCLUDED. The constitution mandates pre-push verification; the contracts call for explicit Pester-free `.ps1` smoke tests per new capability.

**Organization**: Tasks grouped by user story (US1–US5). Setup and Foundational have no story label; Polish has no story label.

## Format: `[ID] [P?] [Story] Description with file path`

- **[P]**: different files, no dependencies on incomplete tasks → may run in parallel
- **[Story]**: US1, US2, US3, US4, US5 (maps to spec.md user stories)
- File paths are repo-relative

---

## Phase 1: Setup

**Purpose**: Verify the working environment before any change is made.

- [X] T001 Verify branch is `004-polish-and-publish`, `.specify/feature.json` points at `specs/004-polish-and-publish`, and feature 002's outputs (disposition-matrix.json, verified-versions.json, all 4 bridge PowerShell scripts) are present (no file change; abort with clear error otherwise)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Land the schema bump (handoff v3), the shared actor resolver, the `skill_invocation` event helper, and the CG-006 fix. Every user story phase builds on these.

CRITICAL: No user-story task may start until this phase is complete; the shared scripts and schema must exist first.

- [X] T002 Create `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/common-actor-resolution.ps1` per `specs/004-polish-and-publish/research.md` §R1: a dot-sourced module exposing `Resolve-BridgeActor` that returns explicit `-Actor` arg → `SPECKIT_BRIDGE_ACTOR` env → `.specify/integration.json.default_integration` → `"unknown"`
- [X] T003 Modify `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/update-handoff.ps1`: dot-source the resolver from T002; replace the hard-coded `-Actor` default with `Resolve-BridgeActor -Argument $Actor`; bump `schema_version` to `3`; add `autonomous_mode` (default `false`) and `resume_context` (default `null`) fields per `specs/004-polish-and-publish/data-model.md`; preserve all existing fields including `archive_history`
- [X] T004 Modify `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/guard-command.ps1`: dot-source the resolver from T002; replace the hard-coded `-Actor` default with `Resolve-BridgeActor`
- [X] T005 Modify `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/auto-archive-handoff.ps1`: dot-source the resolver from T002; replace any hard-coded `-Actor` default with `Resolve-BridgeActor`
- [X] T006 Modify `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/restore-snapshot.ps1`: dot-source the resolver from T002; record `Resolve-BridgeActor`-returned actor in the bridge event instead of the hard-coded `speckit-superpowers-bridge`
- [X] T007 Rewrite `.specify/extensions/speckit-superpowers-bridge/commands/speckit.superpowers.handoff.md`: remove the hard-coded `-Actor codex` from the example; replace with a 3-line documentation of the resolution order (arg → env `SPECKIT_BRIDGE_ACTOR` → default_integration → unknown); reference [research.md §R1](../research.md#r1--actor-detection-env-var-name-and-precedence) (CG-006 close)
- [X] T008 Create `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/emit-skill-invocation.ps1` per `specs/004-polish-and-publish/contracts/skill-invocation-event.schema.json`: accepts `-SkillId`, `-Phase`, `-TaskId`, `-Actor`, `-Decision <invoked|failed>`, `-Reason`; appends a single JSON line to `.specify/bridge-events.jsonl` matching the schema
- [X] T009 Apply one-time migration to `.specify/superpowers-handoff.json`: read current state, bump `schema_version` to `3`, add `autonomous_mode: false` if absent, add `resume_context: null` if absent, write back (idempotent — does not duplicate fields)
- [X] T010 [P] Update `specs/001-spec-superpowers-bridge/contracts/handoff.schema.json`: extend `schema_version.maximum` from 2 to 3; add `autonomous_mode` (boolean, required) and `resume_context` (object \| null, required) to `properties` and `required`; reuse the structure from `specs/004-polish-and-publish/contracts/resume-context.schema.json`
- [X] T011 [P] Extend `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/test-bridge-guard.ps1` with: (a) schema_version=3 assertion after first update, (b) `autonomous_mode` field present + defaults to false, (c) `resume_context` field present + defaults to null, (d) actor-resolution tests for every actor-taking bridge script (`update-handoff.ps1`, `guard-command.ps1`, `auto-archive-handoff.ps1`, `restore-snapshot.ps1`) covering explicit `-Actor`, env `SPECKIT_BRIDGE_ACTOR`, `default_integration`, and documented fallback where applicable

**Checkpoint**: Foundation ready. Shared resolver lives in one place; handoff schema is v3; bridge events can carry skill_invocation rows; the existing tests pass on the new shape.

---

## Phase 3: User Story 1 — Autonomous Implementation with Resume Context (P1) 🎯 MVP

**Goal**: With autonomous mode enabled, the bridge proceeds through tasks without prompting at task boundaries (only pauses at named review checkpoints). On any interrupt, the next session's first non-tool output names the active task ID + skill within 200 chars.

**Independent Test**: Run the bridge against a tasks.md ≥10 tasks with `autonomous_mode: true` in the handoff; assert zero prompts at task boundaries; interrupt mid-run; resume; assert the first output line carries `T###` + `superpowers:<skill>`.

### Tests for User Story 1

- [X] T012 [P] [US1] Add smoke test `tests/test-actor-resolution.ps1` exercising every branch of `Resolve-BridgeActor`: (a) explicit arg wins over env, (b) env wins over default_integration, (c) default_integration when no arg/env, (d) `unknown` when nothing set, (e) each script that accepts `-Actor` records the resolved actor instead of a hard-coded historical default
- [X] T013 [P] [US1] Add smoke test `tests/test-resume-signal.ps1`: seed a handoff with `resume_context = {current_task_id: "T042", current_skill: "superpowers:test-driven-development", current_phase: "before-implementation-task", next_expected_action: "write failing test for T042"}`; invoke the bridge SKILL.md preamble logic via a helper script `scripts/powershell/emit-resume-signal.ps1` (created in T014); assert stdout's first line contains both `T042` and `superpowers:test-driven-development` within the first 200 characters; additionally seed a mock `tasks.md` with at least 10 queued tasks and `autonomous_mode: true`, then assert the bridge emits no task-boundary confirmation prompts except the named review checkpoints

### Implementation for User Story 1

- [X] T014 [US1] Create `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/emit-resume-signal.ps1`: reads `.specify/superpowers-handoff.json`, formats a one-line resume signal from `resume_context` fields (e.g. `"Resuming T042 via superpowers:test-driven-development (phase: before-implementation-task) — next: write failing test for T042"`); writes to stdout; ≤200 chars
- [X] T015 [US1] Rewrite `.claude/skills/speckit-superpowers-bridge/SKILL.md`: insert a "Resume Signal" section at the top of the Execution Rules instructing the agent to invoke `emit-resume-signal.ps1` as its first action on session resume when `resume_context` is non-null; insert an "Autonomous Mode" section explaining the `autonomous_mode` field and the env var override; preserve existing sections
- [X] T016 [US1] Apply the same Resume Signal + Autonomous Mode sections to `.agents/skills/speckit-superpowers-bridge/SKILL.md` (Codex peer); keep the bridge SKILL.md files structurally aligned per the audit script's structural-parity rule (research.md §R5 allowed-divergence)
- [X] T017 [US1] Extend `update-handoff.ps1` with an `-AutonomousMode <bool>` switch that, when supplied, sets the new field on the handoff. Defaults to NOT changing the existing value (so callers without this switch are no-ops on the new field)
- [X] T018 [US1] Extend `update-handoff.ps1` with optional `-ResumeContext <hashtable>` parameter that, when supplied, sets the `resume_context` object on the handoff. Used by the bridge SKILL.md before each Superpowers skill invocation

**Checkpoint**: Autonomous mode persists, resume context persists + drives the resume signal, both bridge SKILL.md files describe the new behavior.

---

## Phase 4: User Story 2 — Cross-Agent Skill Sync + Actor Detection (P1)

**Goal**: The bridge auto-detects the active agent (no more silent codex defaulting), reports per-agent skill parity + content divergence + git extension state via a single audit command, and surfaces clear remediation when peer skills are missing.

**Independent Test**: Run `audit-install-state.ps1 -Json`; assert all fields populated, no missing-skill findings on this repo, divergence-check exempts the bridge SKILL.md correctly. Then synthetically remove a `.claude/skills/speckit-git-*` directory and re-run; assert P1 finding.

### Tests for User Story 2

- [X] T019 [P] [US2] Add smoke test `tests/test-install-state-audit.ps1` covering: (a) happy-path exit 0 on this repo; (b) synthetic missing-peer test (temporarily remove `.claude/skills/speckit-git-feature` → expect P1 + finding code `missing_per_agent_skill`; restore in `finally`); (c) synthetic content-divergence test on a non-bridge skill (append a comment to `.agents/skills/speckit-git-feature/SKILL.md` → expect P2 + `skill_content_diverged`; restore); (d) structural-parity exemption verified: appending a harmless line to bridge SKILL.md does NOT raise a finding because structural parity holds

### Implementation for User Story 2

- [X] T020 [US2] Create `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/audit-install-state.ps1` per `specs/004-polish-and-publish/contracts/install-state-audit-contract.md`: 6 checks (Spec Kit version, default integration, integration manifests, git extension, per-agent skill parity with SHA-256 + structural-exemption for `speckit-superpowers-bridge`, script flavour); emits Install-State Audit Report JSON when `-Json`; reuses `Resolve-BridgeActor` from T002; reuses the `Finding` shape from parity-check.ps1; every missing-peer or divergence finding MUST include a concrete remediation string using `specify integration upgrade <agent>` plus a manual copy fallback when upstream cannot mirror extension skills
- [X] T021 [US2] Create `.specify/extensions/speckit-superpowers-bridge/commands/speckit.superpowers.audit.md` describing the on-demand audit entry point, matching the style of `commands/speckit.superpowers.parity.md`, including the official Codex/Claude sync procedure and manual fallback steps
- [X] T022 [US2] Add `speckit.superpowers.audit` entry to `.specify/extensions/speckit-superpowers-bridge/disposition-matrix.json` as `kind: bridge_meta_command`, `disposition: COMBINE`, `rationale: "New meta-command introduced by feature 004 for one-shot install diagnostics; always available."`, `verified_against: "bridge@004"`
- [X] T023 [US2] Update `specs/004-polish-and-publish/compat-gaps.md`: flip CG-006 status from OPEN to CLOSED-IN-FEATURE once T007 + T002–T006 land

**Checkpoint**: Install-state audit works end-to-end; CG-006 closed; matrix carries the new audit meta-command entry.

---

## Phase 5: User Story 3 — End-to-End Claude Code Validation Pass (P1)

**Goal**: A single command walks the documented happy path and asserts every step works, with every Superpowers skill invocation observable in the bridge event log. Replaces the informal "did I follow the protocol?" check with a verifiable contract.

**Independent Test**: Run `validation-pass.ps1 -Json` on this repo; expect exit 0 with no findings. Then synthetically remove the explicit-invocation phrases from the bridge SKILL.md; re-run; expect P1 finding `bridge_skill_missing_explicit_invocation`.

### Tests for User Story 3

- [X] T024 [P] [US3] Add smoke test `tests/test-skill-invocation-event.ps1`: invoke `emit-skill-invocation.ps1` (from T008) with valid + invalid arguments; assert the JSON line in `bridge-events.jsonl` matches `contracts/skill-invocation-event.schema.json` (validate fields, regex on `skill_id` and `phase`); restore the events log via tail-trim in `finally`
- [X] T025 [P] [US3] Add smoke test `tests/test-validation-pass.ps1` (meta-test): (a) happy path on this repo exits 0; (b) synthetic broken-bridge-SKILL test (remove "superpowers:" lines from `.claude/skills/speckit-superpowers-bridge/SKILL.md` → expect P1 + `bridge_skill_missing_explicit_invocation`; restore); (c) idempotency — run twice; the second run does not duplicate CG records

### Implementation for User Story 3

- [X] T026 [US3] Create `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/validation-pass.ps1` per `specs/004-polish-and-publish/contracts/validation-pass-contract.md`: walks the 10 ordered checks (handoff state, matrix + verified-versions, parity-check, audit-install-state, feature artifacts, skill_invocation events in last 24h, per-phase skill coverage, bridge SKILL.md content phrases, test-bridge-guard.ps1 suite, emit feature_validation_pass event)
- [X] T027 [US3] Create `.specify/extensions/speckit-superpowers-bridge/commands/speckit.superpowers.validate.md` matching the style of `commands/speckit.superpowers.audit.md`
- [X] T028 [US3] Add `speckit.superpowers.validate` entry to `.specify/extensions/speckit-superpowers-bridge/disposition-matrix.json` as `kind: bridge_meta_command`, `disposition: COMBINE`, `rationale: "End-to-end validation pass introduced by feature 004; always available."`, `verified_against: "bridge@004"`
- [X] T029 [US3] Rewrite the Execution Rules section of `.claude/skills/speckit-superpowers-bridge/SKILL.md` to issue concrete `Skill` tool invocations at named phases; before EACH listed Superpowers invocation, first run `emit-skill-invocation.ps1` with `-SkillId`, `-Phase`, `-TaskId` when applicable, `-Actor`, `-Decision invoked`, and a short reason:
  - Before any code-modifying task in tasks.md: emit event, then invoke `superpowers:test-driven-development`
  - On any failure: emit event, then invoke `superpowers:systematic-debugging`
  - Before marking a phase complete: emit event, then invoke `superpowers:verification-before-completion`
  - Before marking the feature complete: emit events, then invoke `superpowers:requesting-code-review` and `superpowers:finishing-a-development-branch`
  Include the exact Claude-side `Skill` tool call syntax for each invocation
- [X] T030 [US3] Apply the same explicit-invocation rewrite to `.agents/skills/speckit-superpowers-bridge/SKILL.md` using Codex's `$superpowers-<name>` syntax and the same "emit event before every Superpowers invocation" rule. Keep structural parity with the Claude peer per research §R5 exemption
- [X] T031 [US3] Add a regex-detection unit assertion in `tests/test-validation-pass.ps1` checking that BOTH bridge SKILL.md files contain at least one occurrence each of the five named Superpowers skill IDs in the expected order, so future edits that drift won't slip past

**Checkpoint**: validation-pass runs end-to-end; bridge SKILL.md on both agents calls Superpowers explicitly; events log carries the audit trail.

---

## Phase 6: User Story 4 — Marketplace Publication Readiness (P2)

**Goal**: Repo is installable from the Spec Kit marketplace (per the catalog-driven model documented in research.md §R6), with bilingual README, distribution manifest, and audited .gitignore.

**Independent Test**: Run all three verification scripts (check-readme-bilingual-parity, check-distribution-manifest, audit-install-state); each exits 0. Then clone the repo to a temp dir, simulate-install per the manifest, and assert only the listed files land.

### Tests for User Story 4

- [X] T032 [P] [US4] Add smoke test `tests/test-readme-bilingual-parity.ps1` per `specs/004-polish-and-publish/contracts/readme-bilingual-parity-contract.md`: (a) happy path on this repo's `README.md` + `README.zh-CN.md` exits 0; (b) synthetic break (add `## TEMP` heading only to EN) → expect failure exit 2 + diff naming the orphan; restore
- [X] T033 [P] [US4] Add smoke test `tests/test-distribution-manifest.ps1`: (a) every `includes[].path` resolves to a real file/glob; (b) no path appears in both `includes` and `excludes`; (c) the manifest validates against `contracts/plugin-distribution-manifest.schema.json`; (d) clean-room simulate install creates only manifest-listed files and copies no `specs/`, `bridge-events.jsonl`, snapshots, or handoff state; (e) re-install over a user-modified target file fails with a concrete no-clobber conflict instead of overwriting

### Implementation for User Story 4

- [X] T034 [P] [US4] Create `README.md` (English) at repo root: bilingual toggle on first line linking to `README.zh-CN.md`; sections — Installation, Quick Usage Example, Configuration (env vars + handoff field summary), Architecture (one paragraph + link to dev.to article), Commands (the new audit/validate/parity meta-commands), Skill Sync & Upgrade (`specify integration upgrade codex`, `specify integration upgrade claude`, and manual fallback), Troubleshooting, License. Keep H2 anchors as English slugs for cross-link stability
- [X] T035 [P] [US4] Create `README.zh-CN.md` (Simplified Chinese) at repo root: bilingual toggle on first line linking to `README.md`; same section structure as `README.md` (H2 anchors stay English for parity), including the same Skill Sync & Upgrade procedure; body translated to Simplified Chinese
- [X] T036 [P] [US4] Create `.specify/extensions/speckit-superpowers-bridge/plugin-distribution-manifest.yml` per `specs/004-polish-and-publish/research.md` §R9: `includes` lists plugin assets (`.specify/extensions/speckit-superpowers-bridge/**`, `.agents/skills/speckit-superpowers-bridge/SKILL.md`, `.claude/skills/speckit-superpowers-bridge/SKILL.md`, `README.md`, `README.zh-CN.md`, `AGENTS.md`, `CLAUDE.md`); `excludes` lists project-private state with reasons (bridge-events.jsonl, bridge-snapshots/, superpowers-handoff.json, feature.json, specs/**, tests/**)
- [X] T037 [P] [US4] Create `.gitignore` at repo root per `specs/004-polish-and-publish/research.md` §R10: excludes `.specify/bridge-events.jsonl`, `.specify/bridge-snapshots/`, `.specify/superpowers-handoff.json`, `.specify/feature.json`, `specs/*/checklists/protocol-quality.md`, OS-junk (`.DS_Store`, `Thumbs.db`), `*.bak-parity-drift`
- [X] T038 [US4] Create `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/check-readme-bilingual-parity.ps1` per `specs/004-polish-and-publish/contracts/readme-bilingual-parity-contract.md`: comparison rules, exit codes, JSON + human output modes
- [X] T039 [US4] Create `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/check-distribution-manifest.ps1`: parses `plugin-distribution-manifest.yml`, asserts every `includes[].path` resolves on disk, asserts no path overlaps between includes/excludes, validates against the JSON Schema, and supports a `-SimulateInstall <path>` mode that performs a dry-run copy plan plus no-clobber conflict detection for user-modified target files

**Checkpoint**: Bilingual README parity tests pass; distribution manifest validates; .gitignore is in place. Plugin is marketplace-ready.

---

## Phase 7: User Story 5 — Workflow Routing Recommender (P3)

**Goal**: When a user invokes `/speckit-specify`, the bridge `before_specify` hook invokes `/speckit-superpowers-recommend-route` and emits a one-line "consider going direct to Superpowers" suggestion for small-scope inputs. Never auto-routes; always advisory.

**Independent Test**: Invoke `/speckit-specify` through the hook path with three sample descriptions (`"fix the typo"`, `"rename a variable"`, `"design a new auth module with OAuth2"`); assert the first two surface the advisory `direct-superpowers` recommendation before continuing or aborting by user choice, and the third proceeds with the full pipeline without a routing prompt.

### Tests for User Story 5

- [X] T040 [P] [US5] Add smoke test `tests/test-routing-recommender.ps1`: parameterized over 5+ feature descriptions covering all three outcomes (direct-superpowers, full-pipeline, no-recommendation); asserts the recommendation matches the heuristic in `specs/004-polish-and-publish/research.md` §R8 and that the `before_specify` hook causes `/speckit-specify` to surface the same advisory without editing the vendor-managed skill

### Implementation for User Story 5

- [X] T041 [P] [US5] Create `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/recommend-route.ps1`: accepts `-Description <string>` (required) and `-Json` switch; applies the small-scope AND-condition heuristic (length<200 AND contains small-scope keyword AND not contains big-scope keyword); emits Workflow Routing Recommendation per `specs/004-polish-and-publish/data-model.md`; exits cleanly with no prompt output when the input does not match the recommendation heuristic
- [X] T042 [P] [US5] Create `.specify/extensions/speckit-superpowers-bridge/commands/speckit.superpowers.recommend-route.md` matching the style of the other meta-command markdown files and documenting that it is normally reached by the `/speckit-specify` `before_specify` hook
- [X] T043 [US5] Add `speckit.superpowers.recommend-route` entry to `.specify/extensions/speckit-superpowers-bridge/disposition-matrix.json` as `kind: bridge_meta_command`, `disposition: COMBINE`, `rationale: "Advisory routing recommender introduced by feature 004 (US5 P3); always available, never auto-routes."`, `verified_against: "bridge@004"`; register it in `.specify/extensions.yml` under `before_specify` so `/speckit-specify` is the user-visible command that emits the advisory

**Checkpoint**: Routing recommender works as advisory tool; never modifies state.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Doc alignment, full-test sweep, validation pass against live state.

- [X] T044 [P] Update `AGENTS.md` §Disposition Matrix subsection to list the three new meta-commands (`speckit.superpowers.audit`, `speckit.superpowers.validate`, `speckit.superpowers.recommend-route`) and the new `skill_invocation` event type
- [X] T045 [P] Update `CLAUDE.md` Claude Code Supplement with one-line pointers to `/speckit-superpowers-audit` and `/speckit-superpowers-validate`
- [X] T046 Run the full quickstart `specs/004-polish-and-publish/quickstart.md` end-to-end on this repo; capture any deviation as a new CG-NNN row in `specs/004-polish-and-publish/compat-gaps.md`
- [X] T047 Run `validation-pass.ps1` against this repo; assert exit 0; if any P0/P1 findings, address them in this phase before declaring complete
- [X] T048 Re-run `test-bridge-guard.ps1` and every new `tests/*.ps1` smoke test (7 new for feature 004 + 8 existing from feature 002 = 15 total); the full suite MUST pass with zero failures
- [X] T049 Append a final `feature_validation_pass` bridge event referencing this branch's HEAD SHA after T048 succeeds
- [X] T050 Update `specs/002-complete-bridge-protocol/checklists/protocol-quality.md` with one-line notes flipping CHK008 ("matrix file missing/unparseable") and CHK028 ("corrupted handoff recovery") from DEFERRED-TO-004 to CLOSED-IN-FEATURE if T020 (audit-install-state) and T026 (validation-pass) actually cover those paths

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: T001 only. No deps.
- **Phase 2 (Foundational)**: Depends on Phase 1. BLOCKS Phases 3–7.
  - T002 must precede T003–T006 (they dot-source the resolver).
  - T003 must precede T009 (live migration depends on the bumped script).
  - T007 is independent (markdown edit) but groups thematically with the resolver work.
  - T008 must precede any task that emits `skill_invocation` events.
  - T010 and T011 [P] can run alongside T009.
- **Phase 3 (US1)**: Depends on Phase 2 fully. T014 must precede T013 (test uses `emit-resume-signal.ps1`). T015 + T016 are content-twin rewrites; do T015 first then mirror to T016.
- **Phase 4 (US2)**: Depends on Phase 2 fully. T020 implementation precedes T019 if practicing TDD-after; if TDD-first, T019 first.
- **Phase 5 (US3)**: Depends on Phase 2 (especially T008) and Phase 3 (T015/T016 bridge SKILL.md changes). T029 must precede T030 (mirror); T031 must follow T029/T030.
- **Phase 6 (US4)**: Depends on Phase 2; mostly independent of Phases 3/4/5. T034/T035/T036/T037 are all [P] file creations. T038/T039 follow their respective contract files.
- **Phase 7 (US5)**: Depends on Phase 2 only. Fully independent of US1–US4.
- **Phase 8 (Polish)**: Depends on every prior phase. T046 must precede T047; T047 must precede T048; T048 must precede T049.

### User Story Dependencies

- **US1**: Foundation only.
- **US2**: Foundation only. Independent of US1.
- **US3**: Foundation + US1 (because US3's validation pass checks the bridge SKILL.md content rewritten in US1).
- **US4**: Foundation only.
- **US5**: Foundation only. Truly independent.

### Parallel Opportunities

- **Setup**: T001 only (no [P]).
- **Foundational**: T010 [P], T011 [P] after their deps.
- **US1 tests**: T012 [P], T013 [P].
- **US2 tests**: T019 [P].
- **US3 tests**: T024 [P], T025 [P].
- **US4**: T032 [P], T033 [P], T034 [P], T035 [P], T036 [P], T037 [P] — six [P] file creations.
- **US5**: T040 [P], T041 [P], T042 [P].
- **Polish**: T044 [P], T045 [P].

### Parallel Example: US4 in one batch

```bash
Task: T034 — create README.md
Task: T035 — create README.zh-CN.md
Task: T036 — create plugin-distribution-manifest.yml
Task: T037 — create .gitignore
# (T032 and T033 tests can also batch with these)
```

---

## Implementation Strategy

### MVP First (US1 alone)

1. Complete Phase 1 (Setup) and Phase 2 (Foundational).
2. Complete Phase 3 (US1).
3. **STOP and VALIDATE**: Test autonomous-mode + resume-signal end-to-end; confirm the bridge stops prompting at task boundaries and resume signals work.
4. The bridge is now strictly better than v3 (no more per-phase interruptions for long sessions).

### Incremental Delivery

1. Foundation → schema v3, shared resolver, CG-006 closed.
2. US1 → MVP shipped: autonomous + resume.
3. US2 → install-state audit available; ownership defaults sane.
4. US3 → validation pass + explicit Superpowers invocation observable in event log.
5. US4 → bilingual README + manifest + .gitignore = marketplace-ready.
6. US5 → routing recommender (P3, optional).
7. Polish → validate, full test sweep, docs aligned.

### Parallel Team Strategy

With multiple contributors:
- One on Phase 2 + US1 (core schema + autonomous + resume).
- One on US2 (audit) — starts after Phase 2.
- One on US4 (README + manifest) — starts after Phase 2; independent of US1/US2/US3.
- US3 + US5 fold in last (US3 needs the bridge SKILL.md changes from US1; US5 is small).

---

## Notes

- Every task lists an absolute or repo-relative file path.
- [P] tasks touch different files; any [P] cluster can be batched.
- Tests precede implementation within each story when practicing TDD; otherwise tests may run last as smoke checks.
- The after_tasks hook will create the Superpowers handoff (per `.specify/extensions.yml`); do NOT manually advance handoff status to `executing` until the hook runs.
- Per CG-006 awareness: when the after_tasks handoff hook fires from Claude Code, the handoff may default `artifact_owner` to `codex`. After T007 lands this is fixed. Until then, re-claim ownership manually after `/speckit-tasks` if you observe this.
- Avoid: hand-editing officially-generated `.claude/skills/speckit-*` or `.agents/skills/speckit-*` (vendor-managed, constitution Principle V); the bridge SKILL.md on each agent IS editable and is the main change site.
- The primary design reference (the dev.to article) is the canonical north star for any architectural question that surfaces during implementation; consult it first.
