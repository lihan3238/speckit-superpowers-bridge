# Tasks: v1.0.0 Stable Protocol Release Hardening

**Input**: Design documents from `specs/013-v1-0-release-hardening/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/](./contracts/), [quickstart.md](./quickstart.md)

**Tests**: Required. This feature is release hardening; every user story includes validation or smoke coverage before the implementation work it protects.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing. US1 and US2 are both P1 release blockers; US3 and US4 are P2 trust/adoption blockers; US5 is P3 publish polish and evidence.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel because it touches different files and has no dependency on incomplete tasks.
- **[Story]**: User-story label. Setup, Foundational, and Polish tasks do not use a story label.
- Every task includes an exact file path.

## Path Conventions

- Bridge package: `.specify/extensions/speckit-superpowers-bridge/`
- Release tooling: `scripts/release/`
- Tests: `tests/`
- Workflow: `.github/workflows/release.yml`
- Docs: `README.md`, `README.zh-CN.md`, `docs/`, `marketplace/`
- Evidence: `specs/013-v1-0-release-hardening/verification.md`
- Sandbox: `../test_specify_superpower/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create the feature-local evidence surface and capture the current release baseline before implementation changes begin.

- [x] T001 Create release verification scaffold in `specs/013-v1-0-release-hardening/verification.md` using `specs/013-v1-0-release-hardening/contracts/verification-evidence-contract.md`.
- [x] T002 [P] Create current-state baseline notes in `specs/013-v1-0-release-hardening/release-baseline.md` covering current versions, missing WSL `pwsh`, missing `vhs`, current 0.7.2 metadata, and release workflow gap.
- [x] T003 [P] Record current release file inventory in `specs/013-v1-0-release-hardening/release-baseline.md` for `.specify/extensions/speckit-superpowers-bridge/`, `scripts/release/`, `tests/`, `.github/workflows/release.yml`, `docs/`, and `marketplace/`.
- [x] T004 [P] Add an implementation checklist section to `specs/013-v1-0-release-hardening/verification.md` mapping SC-001 through SC-015 from `specs/013-v1-0-release-hardening/spec.md`.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Establish tests and release-readiness contracts before any release metadata or docs are changed.

**CRITICAL**: No user story work should begin until these release gates exist.

- [x] T005 Extend release-readiness self-tests in `scripts/release/test-validate-release-readiness.ps1` with failing fixtures for command namespace mismatch, hook namespace mismatch, stale catalog id, missing ZIP script flavor, and release workflow references to nonexistent tests.
- [x] T006 [P] Create Windows bridge smoke test scaffold in `tests/test-release-powershell.ps1` covering `guard-command.ps1`, `update-handoff.ps1`, `bridge-status.ps1`, `auto-archive-handoff.ps1`, line endings, and readable output.
- [x] T007 [P] Create Linux package-inspection smoke test scaffold in `tests/test-release-package.sh` covering ZIP root manifest, portable `/` entries, bash scripts, PowerShell scripts, commands, README files, changelog, license, and `verified-versions.json`.
- [x] T008 [P] Create release verification prompt templates in `specs/013-v1-0-release-hardening/agent-prompts/codex-verification.md` and `specs/013-v1-0-release-hardening/agent-prompts/claude-verification.md`.
- [x] T009 [P] Create sandbox verification notes scaffold in `specs/013-v1-0-release-hardening/sandbox-verification.md` with Linux bash, Windows PowerShell, Codex, and Claude sections.

**Checkpoint**: Foundational tests and evidence surfaces exist. User-story work can proceed.

---

## Phase 3: User Story 1 - Release a stable lightweight 1.0.0 bridge (Priority: P1) MVP

**Goal**: Publish a 1.0.0 release candidate whose public bridge surface remains thin, additive, backward-compatible, and namespace-safe.

**Independent Test**: Release readiness validation fails on namespace/version/package drift and passes only when all 1.0.0 metadata, package contents, and no-heavy-runtime checks are aligned.

### Tests for User Story 1

- [x] T010 [P] [US1] Add release readiness validator assertions for synchronized `1.0.0` version fields in `scripts/release/test-validate-release-readiness.ps1`.
- [x] T011 [P] [US1] Add release readiness validator assertions for extension id, catalog id, command namespace, and hook command namespace alignment in `scripts/release/test-validate-release-readiness.ps1`.
- [x] T012 [P] [US1] Add package content assertions for required files and both script flavors in `tests/test-release-package.sh`.
- [x] T013 [P] [US1] Add no-heavy-runtime and vendor-managed-skill diff checks to `tests/test-release-package.sh`.

### Implementation for User Story 1

- [x] T014 [US1] Update `.specify/extensions/speckit-superpowers-bridge/extension.yml` to version `1.0.0` while preserving existing extension id, command names, hook names, runtime floor, and command count.
- [x] T015 [US1] Update `marketplace/catalog-entry.json` to version `1.0.0` while preserving the stable latest-release `download_url` policy.
- [x] T016 [US1] Update `.specify/extensions/speckit-superpowers-bridge/verified-versions.json` with bridge `1.0.0`, current upstream versions, platform rows, and notes for any blocked row.
- [x] T017 [US1] Add a `## [1.0.0] - 2026-06-04` release section to `CHANGELOG.md` covering stable protocol positioning, compatibility gates, readiness diagnostics, real-agent verification, and demo truthfulness.
- [x] T018 [US1] Extend `scripts/release/validate-release-readiness.ps1` to validate `verified-versions.json`, command namespace alignment, hook namespace alignment, catalog id alignment, package contents when a ZIP path is provided, and release workflow test references.
- [x] T019 [US1] Update `scripts/release/build-extension-zip.ps1` only if needed to include new 1.0.0 evidence files without changing ZIP root layout or stable alias behavior.
- [x] T020 [US1] Record the no-heavy-runtime and vendor-managed-skill audit result in `specs/013-v1-0-release-hardening/verification.md`.

**Checkpoint**: 1.0.0 metadata and release-readiness validation are internally consistent, and the bridge remains thin.

---

## Phase 4: User Story 2 - Verify Windows and Linux as first-class release targets (Priority: P1)

**Goal**: Establish independent Linux bash and native Windows PowerShell release gates.

**Independent Test**: Linux bash smoke/package/sandbox evidence and Windows PowerShell smoke/package/sandbox evidence are both recorded. WSL bash is not counted as Windows evidence.

### Tests for User Story 2

- [x] T021 [P] [US2] Complete Linux package smoke checks in `tests/test-release-package.sh` and wire it into `tests/run-all.sh`.
- [x] T022 [P] [US2] Complete Windows PowerShell smoke checks in `tests/test-release-powershell.ps1` for the PowerShell bridge script flavor.
- [x] T023 [P] [US2] Add release workflow inventory assertions to `scripts/release/test-validate-release-readiness.ps1` so nonexistent test references fail validation.

### Implementation for User Story 2

- [x] T024 [US2] Update `.github/workflows/release.yml` to run current Linux bash tests on Ubuntu and focused Windows PowerShell release smoke checks on Windows.
- [x] T025 [US2] Update `docs/release-runbook.md` with the mandatory Linux bash and native Windows PowerShell 5.1+ release gate sequence.
- [x] T026 [US2] Update `.gitattributes` only if inspection shows missing or incorrect `*.sh text eol=lf` or `*.ps1 text eol=crlf` rules.
- [x] T027 [US2] Build a release-equivalent ZIP with `scripts/release/build-extension-zip.ps1` and record its path and SHA256 in `specs/013-v1-0-release-hardening/verification.md`.
- [x] T028 [US2] Run `bash tests/run-all.sh` on Linux bash and record command output summary in `specs/013-v1-0-release-hardening/verification.md`.
- [x] T029 [US2] Run `tests/test-release-powershell.ps1` from native Windows PowerShell 5.1+ and record command output summary in `specs/013-v1-0-release-hardening/verification.md`.
- [x] T030 [US2] Install the packaged artifact into `../test_specify_superpower/` through the Linux bash path and record sandbox results in `specs/013-v1-0-release-hardening/sandbox-verification.md`.
- [x] T031 [US2] Install the packaged artifact into `../test_specify_superpower/` through the native Windows PowerShell path and record sandbox results in `specs/013-v1-0-release-hardening/sandbox-verification.md`.

**Checkpoint**: Both platform rows are present and passing. The release is blocked if either row is missing or failed.

---

## Phase 5: User Story 3 - Prove real Codex and Claude compatibility in an end-user sandbox (Priority: P2)

**Goal**: Record bounded real-agent verification for Codex and Claude Code in the sandbox.

**Independent Test**: `verification.md` contains one Codex row and one Claude Code row with exact version, prompt boundary, operations exercised, result, and evidence path.

### Tests for User Story 3

- [x] T032 [P] [US3] Add verification evidence lint checks to `scripts/release/test-validate-release-readiness.ps1` requiring Codex and Claude rows in `specs/013-v1-0-release-hardening/verification.md`.
- [x] T033 [P] [US3] Add prompt-boundary validation notes to `specs/013-v1-0-release-hardening/agent-prompts/codex-verification.md` ensuring Codex stays inside `../test_specify_superpower/`.
- [x] T034 [P] [US3] Add prompt-boundary validation notes to `specs/013-v1-0-release-hardening/agent-prompts/claude-verification.md` ensuring Claude Code stays inside `../test_specify_superpower/`.

### Implementation for User Story 3

- [x] T035 [US3] Run bounded Codex verification in `../test_specify_superpower/` using the prompt in `specs/013-v1-0-release-hardening/agent-prompts/codex-verification.md` and record result in `specs/013-v1-0-release-hardening/verification.md`.
- [x] T036 [US3] Run bounded Claude Code verification in `../test_specify_superpower/` using the prompt in `specs/013-v1-0-release-hardening/agent-prompts/claude-verification.md` and record result in `specs/013-v1-0-release-hardening/verification.md`.
- [x] T037 [US3] Update `.specify/extensions/speckit-superpowers-bridge/verified-versions.json` with final Codex and Claude verification outcomes.

**Checkpoint**: Agent compatibility claims are evidence-backed. Blocked rows may be recorded, but blocked agents cannot be advertised as verified.

---

## Phase 6: User Story 4 - Give users a trustworthy readiness and documentation surface (Priority: P2)

**Goal**: Provide a lightweight readiness/status surface and bilingual docs explaining 1.0.0 support and positioning.

**Independent Test**: A user can run the documented readiness/status flow and read either README language to understand platform support, bridge boundaries, and competitor differences.

### Tests for User Story 4

- [x] T038 [P] [US4] Add readiness output tests for bash mode in `tests/test-release-package.sh` covering script flavor, required tools, namespace status, package files, bridge state, and next action.
- [x] T039 [P] [US4] Add readiness output checks for PowerShell mode in `tests/test-release-powershell.ps1`.
- [x] T040 [P] [US4] Add README parity checks for 1.0.0 support, Windows/Linux support, readiness/status usage, Codex, Claude, Superspec, SuperB, and Comet in `tests/test-release-package.sh`.

### Implementation for User Story 4

- [x] T041 [US4] Extend `.specify/extensions/speckit-superpowers-bridge/scripts/bash/bridge-status.sh` with the lightweight readiness/report mode defined in `specs/013-v1-0-release-hardening/contracts/readiness-report-contract.md`.
- [x] T042 [US4] Extend `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/bridge-status.ps1` with the equivalent lightweight readiness/report mode.
- [x] T043 [US4] Update `README.md` with 1.0.0 positioning, Windows/Linux support matrix, readiness/status usage, verified versions, sandbox verification expectations, and factual comparison to Superspec, SuperB, and Comet.
- [x] T044 [US4] Update `README.zh-CN.md` with content equivalent to `README.md` for 1.0.0 positioning, Windows/Linux support, readiness/status usage, verified versions, sandbox verification, and competitor comparison.
- [x] T045 [US4] Update `.agents/skills/speckit-superpowers-bridge/SKILL.md` and `.claude/skills/speckit-superpowers-bridge/SKILL.md` only where needed to reference actual 1.0.0 readiness/status behavior.
- [x] T046 [US4] Update `AGENTS.md` and `CLAUDE.md` only if 1.0.0 changes durable contributor guidance beyond the existing plan pointer.

**Checkpoint**: Users can diagnose bridge health and understand why the 1.0.0 bridge remains intentionally lightweight.

---

## Phase 7: User Story 5 - Publish with reproducible release evidence and truthful demo material (Priority: P3)

**Goal**: Prepare release notes, marketplace submission, demo/transcript evidence, and final publication checks.

**Independent Test**: The release evidence contains artifact hash, platform matrix, agent matrix, release workflow status, demo/transcript truth labels, and upstream catalog submission material.

### Tests for User Story 5

- [x] T047 [P] [US5] Add demo truth-label checks to `tests/test-release-package.sh` for `docs/demo/README.md`, `docs/demo/hero.tape`, and `docs/demo/full-cycle.tape`.
- [x] T048 [P] [US5] Add marketplace metadata checks to `scripts/release/test-validate-release-readiness.ps1` for `marketplace/catalog-entry.json`, `marketplace/extensions-readme-row.md`, and `marketplace/extension-submission-body.md`.
- [x] T049 [P] [US5] Add final verification evidence completeness checks to `scripts/release/test-validate-release-readiness.ps1` for artifact SHA256, platform rows, agent rows, workflow status, and blocker section.

### Implementation for User Story 5

- [x] T050 [US5] Update `docs/demo/README.md` to distinguish real sandbox recordings, transcript-derived evidence, and illustrative assets for 1.0.0.
- [x] T051 [US5] Update `docs/demo/hero.tape` and `docs/demo/full-cycle.tape` only if real sandbox transcript data is available; otherwise record the no-regeneration decision in `specs/013-v1-0-release-hardening/verification.md`.
- [x] T052 [US5] Update `scripts/render-demos.sh` only if needed to fail clearly when `vhs`, `ttyd`, or `ffmpeg` are missing and to avoid presenting fake shell output as real verification.
- [x] T053 [US5] Update `marketplace/catalog-entry.json`, `marketplace/extensions-readme-row.md`, and `marketplace/extension-submission-body.md` with 1.0.0 support matrix, capability counts, stable alias policy, and verification summary.
- [x] T054 [US5] Run final `scripts/release/validate-release-readiness.ps1 -Version 1.0.0` and record the result in `specs/013-v1-0-release-hardening/verification.md`.
- [x] T055 [US5] Run final `scripts/release/test-validate-release-readiness.ps1` and record the result in `specs/013-v1-0-release-hardening/verification.md`.
- [x] T056 [US5] Run final `scripts/release/build-extension-zip.ps1 -Version 1.0.0` and record final artifact SHA256 in `specs/013-v1-0-release-hardening/verification.md`.
- [ ] T057 [US5] Tag and publish `v1.0.0` following `docs/release-runbook.md` and record release URL plus stable alias verification in `specs/013-v1-0-release-hardening/verification.md`.
- [ ] T058 [US5] Prepare or open the upstream Spec Kit catalog submission using `marketplace/extension-submission-body.md` and record the issue or PR link in `specs/013-v1-0-release-hardening/verification.md`.

T057 and T058 are intentionally deferred until the maintainer authorizes remote tag/release and upstream catalog side effects.

**Checkpoint**: Release evidence and distribution material are truthful, reproducible, and aligned with the shipped artifact.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies.
- **Foundational (Phase 2)**: Depends on Setup; blocks all user-story implementation.
- **US1 (Phase 3)**: Depends on Foundational; provides version, namespace, package, and no-heavy-runtime release gates.
- **US2 (Phase 4)**: Depends on Foundational and the release validator/package work from US1.
- **US3 (Phase 5)**: Depends on a release-equivalent package from US2 and the prompt templates from Foundational.
- **US4 (Phase 6)**: Depends on US1 metadata and can run partly in parallel with US2/US3 after readiness test scaffolds exist.
- **US5 (Phase 7)**: Depends on US1-US4; final publication tasks depend on all mandatory verification rows.

### User Story Dependencies

- **US1 (P1)**: MVP; no dependency on other user stories after Foundational.
- **US2 (P1)**: Depends on US1 package/validator work for artifact checks.
- **US3 (P2)**: Depends on US2 sandbox/package preparation.
- **US4 (P2)**: Can start after Foundational, but final docs depend on US1-US3 evidence.
- **US5 (P3)**: Depends on US1-US4 completion.

### Within-Story DAG

**US1**:

```text
T010, T011, T012, T013 -> T014, T015, T016, T017, T018, T019 -> T020
```

**US2**:

```text
T021, T022, T023 -> T024, T025, T026 -> T027 -> T028, T029 -> T030, T031
```

**US3**:

```text
T032, T033, T034 -> T035, T036 -> T037
```

**US4**:

```text
T038, T039, T040 -> T041, T042 -> T043, T044, T045, T046
```

**US5**:

```text
T047, T048, T049 -> T050, T051, T052, T053 -> T054, T055, T056 -> T057 -> T058
```

---

## Parallel Opportunities

- **Phase 1**: T002, T003, and T004 can run in parallel after T001.
- **Phase 2**: T006, T007, T008, and T009 can run in parallel; T005 can run independently in the release self-test file.
- **US1**: T010, T011, T012, and T013 can run in parallel; T014-T017 touch different metadata/docs and can run in parallel after tests exist.
- **US2**: T021, T022, and T023 can run in parallel; T028 and T029 can run independently once platform environments are available.
- **US3**: T033 and T034 can run in parallel; T035 and T036 can run independently in the sandbox after package install is ready.
- **US4**: T038, T039, and T040 can run in parallel; T041 and T042 can run in parallel; T043 and T044 can run in parallel.
- **US5**: T047, T048, and T049 can run in parallel; T050, T052, and T053 can run in parallel.

---

## Parallel Example: User Story 4

```bash
Task: "Add bash readiness output tests in tests/test-bridge-status.sh or tests/test-release-package.sh"
Task: "Add PowerShell readiness output checks in tests/test-release-powershell.ps1"
Task: "Add README parity checks in tests/test-release-package.sh"
```

After those tests exist:

```bash
Task: "Extend bash bridge-status readiness mode in .specify/extensions/speckit-superpowers-bridge/scripts/bash/bridge-status.sh"
Task: "Extend PowerShell bridge-status readiness mode in .specify/extensions/speckit-superpowers-bridge/scripts/powershell/bridge-status.ps1"
Task: "Update English README for 1.0.0 support and positioning"
Task: "Update Chinese README for 1.0.0 support and positioning"
```

---

## Implementation Strategy

### MVP First (US1 Only)

1. Complete Setup and Foundational tasks.
2. Complete US1 tests and implementation.
3. Validate that version sync, namespace alignment, package inspection, and no-heavy-runtime checks pass.
4. Stop and review: the 1.0.0 artifact is not releasable yet, but the release foundation is safe.

### Full P1 Release Gate

1. Complete US1.
2. Complete US2 to prove Linux and Windows compatibility.
3. Stop and review platform evidence. Missing Windows or Linux rows block release progress.

### Agent Trust and User-Facing Surface

1. Complete US3 real-agent sandbox verification.
2. Complete US4 readiness and documentation updates.
3. Stop and review claims in README and `verified-versions.json` against recorded evidence.

### Publication

1. Complete US5 tests and demo/catalog updates.
2. Run final release validators and build the final ZIP.
3. Publish, verify stable alias, and prepare upstream catalog submission.

---

## Notes

- Tests are required because the feature is release hardening and every claim must be evidence-backed.
- `[P]` marks tasks that touch independent files; do not parallelize tasks that update the same file.
- Do not edit vendor-managed generated Spec Kit skills under `.agents/skills/speckit-*` or `.claude/skills/speckit-*`; only bridge-owned `speckit-superpowers-bridge` skill files may change.
- Do not add a daemon, service, database, custom DSL, task runner, or independent state machine.
- Do not modify `marketplace/catalog-entry.json.download_url` away from the stable latest-release alias unless a future spec explicitly changes that policy.
- The Windows PowerShell row must be native Windows evidence; WSL bash is Linux evidence only.
- Real Codex and Claude verification must stay inside `../test_specify_superpower/` and must not modify this source repository except for recorded evidence files.
